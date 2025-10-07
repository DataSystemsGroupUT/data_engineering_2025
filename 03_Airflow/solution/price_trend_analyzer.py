from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from airflow.hooks.postgres_hook import PostgresHook
import json
import os
import requests
import time
from datetime import datetime, timedelta

DATA_DIR = "/tmp/data/orders"
API_URL = "https://example.com/api/orders"  # replace with real API

def fetch_and_store_price(**ctx):
    ts = datetime.utcnow()
    try:
        response = requests.get("https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT")
        price = float(response.json()["price"])
        pg = PostgresHook(postgres_conn_id="prices_db")
        # Insert into btc_prices
        pg.run(
            "INSERT INTO btc_prices (ts, price) VALUES (%s, %s)",
            parameters=(ts, price)
        )
        print("Inserted BTC price into database successfully.")

    except requests.RequestException as e:
        print(f"Error fetching BTC price: {e}")
        raise

    except Exception as e:
        print(f"Database insertion failed: {e}")
        raise

    # 2) Compute rolling average over last 15 minutes
    cutoff = ts - timedelta(minutes=15)
    rows = pg.get_first(
        "SELECT AVG(price) FROM btc_prices WHERE ts >= %s",
        parameters=(cutoff,)
    )
    rolling_avg = float(rows[0]) if rows and rows[0] is not None else price

    # 3) Insert into btc_rolling_avg
    pg.run(
        "INSERT INTO btc_rolling_avg (ts, rolling_avg) VALUES (%s, %s)",
        parameters=(ts, rolling_avg)
    )

    # 4) Optionally, check buy/sell signals
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

    # 5) Store order if triggered
    if order:
        # Write JSON file
        filename = os.path.join(DATA_DIR, f"order_{ts.strftime('%Y%m%dT%H%M%S')}.json")
        os.makedirs(DATA_DIR, exist_ok=True)
        with open(filename, "w") as f:
            json.dump(order, f)

        # Log order in orders_log (response is optional)
        pg.run(
            "INSERT INTO orders_log (payload, response, status) VALUES (%s, %s, %s)",
            parameters=(json.dumps(order), None, "created")
        )

with DAG(
    dag_id="price_trend_analyzer",
    start_date=days_ago(1),
    schedule_interval="*/1 * * * *",  # every minute
    catchup=False,
    max_active_runs=1
) as dag:

    fetch_task = PythonOperator(
        task_id="fetch_and_store_price",
        python_callable=fetch_and_store_price,
        provide_context=True
    )
