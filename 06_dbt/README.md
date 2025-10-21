# 🧱 DBT + ClickHouse Practice: Building a Modern Analytics Stack

## 📘 Table of Contents

* [1. Introduction](#1-introduction)

  * [Learning Objectives](#learning-objectives)
* [2. Session Agenda (90 Minutes)](#2-session-agenda-90-minutes)
* [3. Environment Setup](#3-environment-setup)
* [4. DBT + ClickHouse: Core Concepts Explained](#4-dbt--clickhouse-core-concepts-explained)
* [5. Task 1: Setting up Models in DBT](#5-task-1-setting-up-models-in-dbt)
* [6. Task 2: Running DBT Models and Validating Data](#6-task-2-running-dbt-models-and-validating-data)
* [7. Task 3: Incremental Models and Data Updates](#7-task-3-incremental-models-and-data-updates)
* [8. Task 4: Snapshots with DBT](#8-task-4-snapshots-with-dbt)
* [9. Data Quality & Testing with DBT](#9-data-quality--testing-with-dbt)
* [10. Selectors](#10-selectors)
* [11. Conclusion & Key Takeaways](#11-conclusion--key-takeaways)
* [12. Appendix: Why DBT + ClickHouse](#12-appendix-why-dbt--clickhouse)


---

## 1. Introduction

This guide demonstrates how to build a **modern analytics stack** using **DBT and ClickHouse**. You will automate transformations, track data changes, and implement tests.

### 🎯 Learning Objectives

By the end of this session, you will:

1. Have a functional **ClickHouse + dbt** setup using Docker.
2. Understand how dbt connects to ClickHouse via the adapter.
3. Build and run dbt models that materialize tables/views.
4. Use dbt’s incremental and dependency logic.
5. Implement basic data quality testing.

---

## 2. Session Agenda (90 Minutes)

| Duration | Topic                                | Goal                            |
| -------- | ------------------------------------ | ------------------------------- |
| 5 min    | Introduction & Objectives            | Align on dbt goals              |
| 10 min   | Environment Setup                    | Run Docker services             |
| 15 min   | DBT Core Concepts                    | Models, profiles, and targets   |
| 20 min   | **Task 1:** Setting up Models in DBT | Create reusable transformations |
| 15 min   | **Task 2:** Running DBT models       | Automate schema builds          |
| 15 min   | **Task 3:** Incremental Update       | Handle data history             |
| 10 min   | Wrap-up & Key Takeaways              | Summarize learnings             |

---

## 3. Environment Setup

### Step 3.1: Project Structure

```
06_dbt/
├── compose.yml
├── Dockerfile
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── models/
│   │   ├── staging/
│   │   │   ├── stg_dim_customer.sql
│   │   │   ├── stg_dim_product.sql
│   │   │   └── stg_fact_sales.sql
│   │   └── marts/
│   │       ├── dim_customer.sql
│   │       ├── fact_sales.sql
│   │       └── metrics_sales_summary.sql
│   └── seeds/
│       ├── dim_customer.csv
│       ├── dim_product.csv
│       └── fact_sales.csv
├── clickhouse_data/
├── sample_data/
└── sql/
```

### Step 3.2: Docker Compose File

```yaml
services:
  clickhouse-server:
    image: clickhouse/clickhouse-server
    container_name: clickhouse-server
    environment:
      CLICKHOUSE_USER: default
      CLICKHOUSE_PASSWORD: ""
      CLICKHOUSE_DB: default
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - ./sample_data:/var/lib/clickhouse/user_files
      - ./sql:/sql
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8123/ping"]
      interval: 5s
      retries: 20

  dbt:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: dbt
    depends_on:
      - clickhouse-server
    volumes:
      - ./sample_data:/var/lib/clickhouse/user_files
      - ./sql:/sql
      - ./dbt_project:/dbt
    working_dir: /dbt
    tty: true
```

### Step 3.3: Why a Dockerfile for DBT?

We use a **Dockerfile** instead of an image from Compose because:

* Official dbt-clickhouse images need authentication (`ghcr.io` access)
* Building locally allows control over Python dependencies
* Custom versions or packages (e.g., `git`, `pandas`, `clickhouse-connect`) can be installed

Compose orchestrates containers; Dockerfile defines how your dbt container is built.

---

## 4. DBT + ClickHouse: Core Concepts Explained

Think of dbt as a **SQL compiler** for your data warehouse.

| Concept              | Description                                                       |
| -------------------- | ----------------------------------------------------------------- |
| **Models**           | SQL files that define transformations (`SELECT ...`)              |
| **Materializations** | Define how dbt builds each model (`view`, `table`, `incremental`) |
| **Dependencies**     | `{{ ref('model_name') }}` creates build order automatically       |
| **Profiles**         | Connection details to ClickHouse                                  |
| **Targets**          | Environment context like `dev` or `prod`                          |

---

## 5. Task 1: Setting up Models in DBT

We’re using a hybrid approach for staging models:

* **dbt seed files**: For most dimension tables (`dim_product.csv`, `dim_store.csv`, etc.), we load them as seeds.
* **Direct file reads**: For `stg_dim_customer.sql`, we read CSV directly using ClickHouse’s `file()` function.

### Example: `models/staging/stg_dim_customer.sql`

```sql
SELECT
    CustomerKey,
    FirstName,
    LastName,
    Segment,
    City,
    ValidFrom,
    ValidTo
FROM file('/var/lib/clickhouse/user_files/dim_customer.csv')
```

### Example: `models/staging/stg_dim_product.sql`

```sql
SELECT *
FROM {{ ref('stg_dim_product') }}
```

### Example: `models/marts/dim_product.sql`

```sql
SELECT *
FROM {{ ref('stg_dim_product') }}
```

**Workflow explanation:**

1. Seeds provide ready-to-use tables (`stg_dim_*`) for all dimensions except `stg_dim_customer`.
2. Mart models (`dim_*`) select from the staging tables via `ref()` — this ensures dependency order and reproducibility.

---

## 6. Task 2: Running DBT Models and Validating Data

### Step 6.1: Run staging model for customer

```bash
docker exec -it dbt dbt run --select stg_dim_customer
docker exec -it dbt dbt run --select dim_customer
```

**Why:**

* Customer data is read directly from the CSV file, so we must run it first.
* Mart tables depend on the staging tables (`ref()` ensures correct order).

### Step 6.2: Seed all other dimension tables

```bash
docker exec -it dbt dbt seed
```

### Step 6.3: Run all mart models

```bash
docker exec -it dbt dbt run
```

### Validate in ClickHouse:

```bash
docker exec -it clickhouse-server clickhouse-client --query="SHOW TABLES"
```

**Materializations overview:**

| Materialization | Description                                                                               |
| --------------- | ----------------------------------------------------------------------------------------- |
| **table**       | Physical table in ClickHouse. Good for snapshots or SCDs.                                 |
| **view**        | Logical view, always recomputed. Lightweight but slower for large datasets.               |
| **incremental** | Adds new data to existing table instead of rebuilding everything. Useful for fact tables. |
| **ephemeral**   | Temporary CTE; never materialized, used for intermediate transformations.                 |
| **seed**        | CSV loaded as a table; used for static reference                                          |

---

## 7. Task 3: Incremental Models and Data Updates

Now let's create an incremental report on top of the `fact_sales` table, leveraging multiple dimension tables (`dim_customer`, `dim_product`, `dim_store`) for richer insights.

### Example: `models/marts/cust_sales_detailed_summary.sql`

```sql
{{ config(
    materialized='incremental',
    unique_key='CustomerKey',
    incremental_strategy='append'
) }}

SELECT
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.City AS CustomerCity,
    p.ProductKey,
    p.ProductName,
    s.StoreKey,
    s.StoreName,
    COUNT(f.SaleID) AS TotalOrders,
    SUM(f.SalesAmount) AS TotalSales,
    MAX(f.FullDate) AS LastOrderDate
FROM {{ ref('fact_sales') }} AS f
LEFT JOIN {{ ref('dim_customer') }} AS c
    ON f.CustomerKey = c.CustomerKey
LEFT JOIN {{ ref('dim_product') }} AS p
    ON f.ProductKey = p.ProductKey
LEFT JOIN {{ ref('dim_store') }} AS s
    ON f.StoreKey = s.StoreKey

{% if is_incremental() %}
WHERE f.FullDate > (SELECT max(LastOrderDate) FROM {{ this }})
{% endif %}

GROUP BY
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.City,
    p.ProductKey,
    p.ProductName,
    s.StoreKey,
    s.StoreName
```

### Run incrementally:

```bash
docker exec -it dbt dbt run --select cust_sales_detailed_summary
```

**Key Points:**

1. **Materialization type**: `incremental` – only new rows from the fact table are processed.
2. **Multiple dimension tables** provide richer insights.
3. Incremental processing avoids full recomputation.

---

## 8. Task 4: Snapshots with DBT

Snapshots track historical changes in tables over time. We demonstrate this on `dim_supplier`.

### Step 8.1: Define a Snapshot

`snapshots/dim_supplier_snapshot.sql`

```sql
{% snapshot dim_supplier_snapshot %}
{{ config(
    unique_key='SupplierKey',
    strategy='check',
    check_cols=['SupplierName', 'ContactInfo']
) }}

SELECT
    SupplierKey,
    SupplierName,
    ContactInfo
FROM {{ ref('dim_supplier') }}
{% endsnapshot %}
```

### Step 8.2: Run the Snapshot

```bash
docker exec -it dbt dbt snapshot --select dim_supplier_snapshot
```

---

## 9. Data Quality & Testing with DBT

DBT allows **schema-based tests** and **custom SQL tests**.

### 9.1 Schema-based Tests

`models/schema.yml`

```yaml
version: 2

models:
  - name: fact_sales
    columns:
      - name: SaleID
        tests:
          - not_null
      - name: SalesAmount
        tests:
          - not_null
          - expression_is_true:
              expression: "SalesAmount >= 0"

  - name: cust_sales_detailed_summary
    columns:
      - name: CustomerKey
        tests:
          - not_null
      - name: TotalSales
        tests:
          - not_null
          - expression_is_true:
              expression: "TotalSales >= 0"
      - name: TotalOrders
        tests:
          - not_null
          - expression_is_true:
              expression: "TotalOrders >= 0"
```

Run tests:

```bash
docker exec -it dbt dbt test
```

### 9.2 Custom SQL Tests

`tests/test_total_sales_positive.sql`

```sql
SELECT *
FROM {{ ref('cust_sales_detailed_summary') }}
WHERE TotalSales < 0
```

Run SQL tests:

```bash
docker exec -it dbt dbt test --select test_total_sales_positive
```

---

## 10. Selectors

Selectors help run groups of models without listing each individually.

`dbt_project/selectors.yml`

```yaml
selectors:
  - name: all_models
    description: "Run all models in staging and marts folders using FQN"
    definition:
      union:
        - method: fqn
          value: staging
        - method: fqn
          value: marts
```

Run all models using selector:

```bash
dbt run --selector all_models
```

Run tests using selector:

```bash
dbt test --selector all_models
```

---

## 11. Appendix: Why DBT + ClickHouse

### Why use a Dockerfile instead of only Compose

| Use                    | Description                                                        |
| ---------------------- | ------------------------------------------------------------------ |
| **Dockerfile**         | Defines *how* your dbt environment is built (Python, adapters)     |
| **docker-compose.yml** | Defines *how containers run together* (networking, ports, volumes) |

Compose orchestrates both; Dockerfile builds dbt’s custom runtime — ensuring **customizability + portability**.

### DBT vs Raw SQL: Conceptual Shift

| Concept           | Raw SQL Approach         | DBT Approach            |
| ----------------- | ------------------------ | ----------------------- |
| Schema creation   | Manual `CREATE TABLE`    | dbt auto-materializes   |
| Data dependencies | Manually ordered scripts | `ref()`-based DAG       |
| Version control   | Ad-hoc                   | Git integrated          |
| Testing           | Manual queries           | `dbt test` + schema.yml |
| Documentation     | README/manual            | `dbt docs generate`     |

----

## 11. Conclusion & Key Takeaways

In this practice session, you have learned to:

* Build **DBT models** on top of ClickHouse for staging and marts.
* Use **incremental models** to process only new data.
* Apply **snapshots** to track changes in source tables over time.
* Implement **data quality tests** via schema.yml and custom SQL tests.
* Use **selectors** to run multiple models or tests efficiently.

**Key points:**

* `ref()` ensures correct dependency order between models.
* Incremental materializations save computation on large fact tables.
* Snapshots are best suited for slowly changing dimensions or data corrections.
* DBT + ClickHouse supports modular, testable, and maintainable analytics.

---

## 12. Appendix: Why DBT + ClickHouse

### Why use a Dockerfile instead of only Compose

| Use                    | Description                                                               |
| ---------------------- | ------------------------------------------------------------------------- |
| **Dockerfile**         | Defines the dbt environment, dependencies, and adapter version.           |
| **docker-compose.yml** | Orchestrates ClickHouse and dbt containers, handles networking & volumes. |

### DBT vs Raw SQL: Conceptual Shift

| Concept         | Raw SQL                | DBT Approach                         |
| --------------- | ---------------------- | ------------------------------------ |
| Schema creation | Manual `CREATE TABLE`  | dbt auto-materializes tables/views   |
| Dependencies    | Manual execution order | `ref()` DAG ensures build order      |
| Version control | Ad-hoc                 | Git integrated                       |
| Testing         | Manual queries         | `dbt test` + schema.yml or SQL tests |
| Documentation   | README/manual          | `dbt docs generate`                  |

---

✅ **Outcome:** You now understand the workflow of building a modern analytics stack with **ClickHouse + dbt**, including modeling, incremental updates, snapshots, testing, and orchestration.
