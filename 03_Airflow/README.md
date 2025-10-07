# BTC Price Trend Analyzer

This setup runs **Airflow** with a separate **Postgres database** to track Bitcoin prices and generate buy/sell alerts.

---

## Services

* **airflow-db**:
  Postgres database used to store Airflow metadata (DAGs, task instances, users). Credentials (from `docker-compose.yml`):

  * **User:** `airflow`
  * **Password:** `airflow`
  * **Database:** `airflow`
  * **Host / Port (from host):** `localhost:5432`

* **prices-db**:
  A separate Postgres database dedicated to storing Bitcoin price data, rolling averages, and order logs. Credentials:

  * **User:** `prices_user`
  * **Password:** `prices_pass`
  * **Database:** `prices_db`
  * **Host / Port (from host):** `localhost:5433`

* **pgadmin**:
  Web-based management UI for Postgres databases. Use it to connect to both `airflow-db` and `prices-db` for inspection and running ad-hoc queries. Default login (from `docker-compose.yml`):

  * **Email:** `admin@example.com`
  * **Password:** `admin`
  * **URL:** `http://localhost:5050`

* **airflow-webserver**:
  Airflow’s web interface, where you can view DAGs, monitor task progress, trigger DAGs manually, and inspect logs. Accessible on port `8080`.

* **airflow-scheduler**:
  Background service responsible for executing scheduled DAGs. It monitors DAG definitions, queues tasks, and ensures workflows run according to schedule.

---

## How to Run

1. Start services:

```bash
docker-compose up -d
```

2. Wait for **airflow-init** to finish (initializes Airflow DB and admin user).

3. Access Airflow UI: [http://localhost:8080](http://localhost:8080)

   * Username: `airflow`
   * Password: `airflow`

4. Place DAG in `./dags` folder (already included: `price_trend_analyzer.py`).

5. JSON order files will be written to: `./data/orders`.

---

## Price Trend Analyzer DAG

* Fetches BTC price every 1 minute from CoinGecko API.
* Stores price in `btc_prices` table.
* Computes 15-minute rolling average and stores in `btc_rolling_avg`.
* Triggers buy/sell alerts:

  * **Buy**: if price was below rolling average for 3 minutes, now above.
  * **Sell**: if price was above rolling average for 3 minutes, now below.
* Logs triggered orders in `orders_log` and as JSON files.

---

## Database Tables

You can create the required tables in the **prices-db** database using the following SQL:

```sql
-- BTC Prices Table
CREATE TABLE IF NOT EXISTS btc_prices (
  id SERIAL PRIMARY KEY,
  ts TIMESTAMP WITH TIME ZONE NOT NULL,
  price NUMERIC(18,8) NOT NULL
);

-- BTC Rolling Averages Table
CREATE TABLE IF NOT EXISTS btc_rolling_avg (
  id SERIAL PRIMARY KEY,
  ts TIMESTAMP WITH TIME ZONE NOT NULL,
  rolling_avg NUMERIC(18,8) NOT NULL
);

-- Orders Log Table
CREATE TABLE IF NOT EXISTS orders_log (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  payload JSONB,
  response JSONB,
  status VARCHAR(32)
);
```

---

## Notes

* Airflow logs: `./logs`
* Ports:

  * Airflow UI: `8080`
  * pgAdmin: `5050`
  * Airflow DB: `5432`
  * Prices DB: `5433`
* JSON order files location: `./data/orders`
