# dags/price_trend_analyzer.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from airflow.hooks.postgres_hook import PostgresHook
from datetime import datetime, timedelta
import json
import os
import requests

# Directory to store JSON order files
DATA_DIR = "/tmp/data/orders"
os.makedirs(DATA_DIR, exist_ok=True)

def fetch_and_store_price(**ctx):
    # 1) Fetch BTC price from CoinGecko API
    try:
        resp = requests.get(
            "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
        )
        resp.raise_for_status()
        price = float(resp.json()["bitcoin"]["usd"])
        ts = datetime.utcnow()
    except Exception as e:
        print(f"Error fetching price: {e}")
        return

    # 2) Insert into btc_prices
    pg = PostgresHook(postgres_conn_id="prices_db")
    pg.run(
        "INSERT INTO btc_prices (ts, price) VALUES (%s, %s)",
        parameters=(ts, price)
    )

    # 3) Compute rolling average over last 15 minutes
    cutoff = ts - timedelta(minutes=15)
    rows = pg.get_first(
        "SELECT AVG(price) FROM btc_prices WHERE ts >= %s",
        parameters=(cutoff,)
    )
    rolling_avg = float(rows[0]) if rows and rows[0] is not None else price

    # 4) Insert into btc_rolling_avg
    pg.run(
        "INSERT INTO btc_rolling_avg (ts, rolling_avg) VALUES (%s, %s)",
        parameters=(ts, rolling_avg)
    )

    # 5) Check buy/sell rule
    last_prices = pg.get_records(
        "SELECT ts, price FROM btc_prices ORDER BY ts DESC LIMIT 4"
    )
    last_prices = list(reversed(last_prices))

    order = None
    if len(last_prices) >= 4:
        prev3 = last_prices[:-1]
        curr = float(last_prices[-1][1])
        below_prev3 = all(float(p[1]) < rolling_avg for p in prev3)
        above_prev3 = all(float(p[1]) > rolling_avg for p in prev3)

        if below_prev3 and curr > rolling_avg:
            order = {
                "orderType": "Buy",
                "currentPrice": curr,
                "rollingAveragePrice": rolling_avg
            }
        elif above_prev3 and curr < rolling_avg:
            order = {
                "orderType": "Sell",
                "currentPrice": curr,
                "rollingAveragePrice": rolling_avg
            }

    print("Rolling average is", rolling_avg)
    print("This is order", order)
    print("This is prev3", prev3)
    print("This is curr", curr)
    print("This is below_prev3", below_prev3)
    print("This is above_prev3", above_prev3)

    # 6) Store order if triggered
    if order:
        # Write JSON file for trigger DAG
        filename = os.path.join(DATA_DIR, f"order_{ts.strftime('%Y%m%dT%H%M%S')}.json")
        with open(filename, "w") as f:
            json.dump(order, f)

        # Log order in orders_log
        pg.run(
            "INSERT INTO orders_log (payload, status) VALUES (%s, %s)",
            parameters=(json.dumps(order), "created")
        )

# Define the DAG
with DAG(
    dag_id="price_trend_analyzer",
    start_date=days_ago(1),
    schedule_interval="*/1 * * * *",  # every 1 minute
    catchup=False,
    max_active_runs=1
) as dag:

    fetch_task = PythonOperator(
        task_id="fetch_and_store_price",
        python_callable=fetch_and_store_price,
        provide_context=True
    )
