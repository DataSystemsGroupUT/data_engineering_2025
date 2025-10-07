# BTC Price Analyzer — Airflow Practice Assignment

## 🧭 Table of Contents
| Section | Duration | Description |
|----------|-----------|-------------|
| 1. Introduction to Apache Airflow | 5 mins | Overview of Airflow and its use in data engineering |
| 2. Discussion: When (and When Not) to Use Airflow | 10 mins | Advanced discussion of Airflow pros & cons |
| 3. Setting up Airflow Environment | 20 mins | Step-by-step setup using Docker Compose |
| 4. Assignment: BTC Price Analyzer DAG | 1 hour | Hands-on project with Postgres integration |
| 5. Wrap-up and Q&A | 10 mins | Summary and troubleshooting |

---

## 🚀 Introduction to Apache Airflow

[![Apache Airflow Logo](https://upload.wikimedia.org/wikipedia/commons/d/de/AirflowLogo.png)](https://airflow.apache.org)

**Apache Airflow** is an open-source platform designed to **author, schedule, and monitor data pipelines**.  
Workflows are defined as **Directed Acyclic Graphs (DAGs)** written in Python, giving engineers full control and flexibility over task orchestration.

### ✨ Core Features
- **Python-based DAGs:** Define complex workflows programmatically with dependencies and conditions.
- **Dynamic Scheduling:** Trigger workflows at fixed intervals, based on events, or manually.
- **Rich UI & Monitoring:** Visualize DAG runs, dependencies, and task logs in real time.
- **XComs & Task Communication:** Share small data between tasks.
- **Retry & SLA Management:** Robust handling of task failures and performance alerts.
- **Plugins & Extensibility:** Integrate with AWS, GCP, Databricks, Spark, or any custom operator.
- **Task Sensors:** Wait for events (like file creation, API responses, or DB updates) before triggering downstream tasks.

---
### Architecture 

[![Apache Airflow Logo](https://airflow.apache.org/docs/apache-airflow/stable/_images/diagram_basic_airflow_architecture.png)](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/overview.html)

## Advanced Capabilities

- **Dynamic DAG Generation:** DAGs can be generated dynamically at runtime using Python logic.
- **Task Groups & Dependencies:** Simplify DAG readability and structure.
- **Kubernetes Executor:** Scales task execution across a Kubernetes cluster.
- **REST API:** Allows external services or CI/CD pipelines to trigger and monitor workflows programmatically.
- **Secrets Backend Integration:** Securely manage credentials via AWS Secrets Manager, HashiCorp Vault, etc.
- **Airflow Smart Sensors:** Efficiently handle thousands of waiting sensors without overloading the scheduler.

---

## Disadvantages and Industry Trade-offs

Despite its popularity, **Airflow isn’t always the right tool** for every orchestration need:

### Disadvantages
- **Operational Overhead:** Requires maintaining a scheduler, metadata DB, and workers — not ideal for small workloads.
- **Scaling Challenges:** The Celery/Kubernetes executors require additional configuration to scale reliably.
- **Latency:** Airflow is **not real-time** — designed for batch or scheduled pipelines, not streaming.
- **Complex Debugging:** Failures in dynamic DAGs or multi-dependency tasks can be difficult to trace.
- **Version Drift:** Upgrading across Airflow versions can break DAG compatibility.
- **Limited Local Development Experience:** DAG testing locally can be slow due to scheduler reliance.

### 💡 When Airflow Might *Not* Be Ideal
- For **low-latency or event-driven** data pipelines → use **Prefect**, **Dagster**, or **dbt Cloud**.
- For **microservice orchestration** → tools like **Temporal**, **AWS Step Functions**, or **Argo Workflows** may fit better.

---

## 🛠️ Setting Up Airflow with Docker Compose

This project includes a ready-to-run Docker Compose setup with:
- Airflow webserver
- Airflow scheduler
- Two Postgres databases
- Optional pgAdmin for database management

### Project Structure

Drawn in board. 
<pre>
03_Airflow/
├── docker-compose.yml
├── solution/
│   ├── price_trend_analyzer.py
│   └── create_tables.sql
└── airflow/
    └── dags/ 
</pre>



---

## Services

| Service | Description |
|----------|--------------|
| **airflow-db** | Postgres database for Airflow metadata. Stores DAG runs, task instances, and logs. |
| **prices-db** | Dedicated Postgres database for BTC price tracking, rolling averages, and order logs. Keeps data clean and separate from Airflow metadata. |
| **pgadmin** | Web UI to browse and manage databases. Accessible via browser. |
| **airflow-webserver** | Web interface for monitoring and managing Airflow DAGs. |
| **airflow-scheduler** | Core service responsible for parsing and executing DAGs based on schedule intervals. |

---

## How to Run
# Initialize the environment

```
docker-compose up -d
```

## Login credentials

Username: airflow
Password: airflow

---

## Credentials

| Component | Username | Password | Port |
|------------|-----------|-----------|------|
| **airflow-db** | `airflow` | `airflow` | 5432 |
| **prices-db** | `prices_user` | `prices_pass` | 5433 |
| **pgAdmin** | `admin@example.com` | `admin` | 5050 |

Access pgAdmin at:  
[http://localhost:5050](http://localhost:5050)

Access Airflow at:  
[http://localhost:8080](http://localhost:8080)

Connecting `prices-db` through PgAdmin

| Field                    | Value                                                |
| ------------------------ | ---------------------------------------------------- |
| **Host name / address**  | `prices-db` *(use service name from docker-compose)* |
| **Port**                 | `5432`                                               |
| **Maintenance database** | `prices_db`                                          |
| **Username**             | `prices_user`                                        |
| **Password**             | `prices_pass`                                        |

---


## Practice Assignment: BTC Price Analyzer

This hands-on assignment demonstrates a real-world use case:
tracking Bitcoin prices, calculating a rolling average, and triggering buy/sell orders based on market conditions.

### 📈 DAG: `price_trend_analyzer`
1. Fetches BTC price periodically (e.g., every minute) from CoinGecko API (no authentication required).
2. Stores it in a dedicated Postgres database (`prices-db`) in `btc_prices` table.
3. Computes 15-minute rolling average and stores in `rolling_averages`.
4. Makes a decision:
   - **BUY** if the price drops below the rolling average.
   - **SELL** if the price exceeds the rolling average.
5. Logs all results and decisions into the `orders` table.

---

## SQL Schema Setup

You can initialize your `prices-db` with:

```sql
-- Database: prices_db
-- Replace with: CREATE DATABASE prices_db; if needed

-- Table to store raw BTC prices
CREATE TABLE IF NOT EXISTS btc_prices (
    id SERIAL PRIMARY KEY,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    price NUMERIC(18,8) NOT NULL
);

-- Table to store rolling averages
CREATE TABLE IF NOT EXISTS btc_rolling_avg (
    id SERIAL PRIMARY KEY,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    rolling_avg NUMERIC(18,8) NOT NULL
);

-- Table to log triggered orders
CREATE TABLE IF NOT EXISTS orders_log (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    payload JSONB,
    response JSONB,
    status VARCHAR(32)
);

```
---

## DAG — Price Trend Analyzer

The DAG (`price_trend_analyzer.py`) is located in the `solution/` folder.
When setting up Airflow, you need to copy this file into the Airflow DAGs directory:

```cp solution/price_trend_analyzer.py airflow/dags/```

### DAG Overview

This DAG simulates the process of tracking Bitcoin (BTC) price movements, calculating rolling averages, and generating buy/sell signals.

It performs the following key tasks:

- Fetch Latest BTC Price
- Retrieves (or simulates) the latest BTC price at each scheduled interval.

Store Price in Database
Inserts the current timestamp and price into the btc_prices table.

Compute Rolling Average
Calculates a rolling average over the last 15 minutes and stores it in btc_rolling_avg.

Analyze Price Trends
Compares recent prices to detect upward or downward trends relative to the rolling average.

Trigger Buy/Sell Orders
If a signal is detected:

A Buy order is generated when prices rise above the rolling average after being below it.

A Sell order is generated when prices drop below the rolling average after being above it.

Log Orders
Each triggered order is:

Written as a JSON file under /tmp/data/orders/

Logged into the orders_log table for auditability.

### DAG Schedule

The DAG runs every minute (`*/1 * * * *`), simulating continuous BTC market monitoring and analysis.
It fetches simulated price data, calculates a 15-minute rolling average, and logs potential Buy or Sell triggers.

Airflow automatically manages backfilling, meaning if the DAG was paused or Airflow was down, it can retroactively execute any missed runs to ensure data continuity.
This is especially useful in production pipelines where historical data consistency matters.

The DAG file is provided in the `solution/` folder.
Once Airflow is running, copy it into the `airflow/dags/` directory. First time it does not automatically detect the dag, you need to run airflow init. 

```airflow db init```
Or click run for airflow-init service in the running container from Dcoker Desktop 

### Discussion Pointers

* Why batch scheduling still matters in modern data pipelines.

* How Airflow compares to Prefect and Dagster in orchestration.

* When to replace task-based DAGs with event-based architectures.

* Common scaling pitfalls and deployment best practices.
