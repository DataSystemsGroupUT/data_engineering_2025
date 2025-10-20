# 🧱 DBT + ClickHouse Practice: Building a Modern Analytics Stack

## 📘 Table of Contents
- [1. Introduction](#1-introduction)
  - [Learning Objectives](#learning-objectives)
- [2. Session Agenda (90 Minutes)](#2-session-agenda-90-minutes)
- [3. Environment Setup](#3-environment-setup)
- [4. DBT + ClickHouse: Core Concepts Explained](#4-dbt--clickhouse-core-concepts-explained)
- [5. Task 1: Setting up Models in DBT](#5-task-1-setting-up-models-in-dbt)
- [6. Task 2: Running DBT Models and Validating Data](#6-task-2-running-dbt-models-and-validating-data)
- [7. Task 3: Incremental Models and Data Updates](#7-task-3-incremental-models-and-data-updates)
- [8. Task 4: SCD Type 2 with DBT](#8-task-4-scd-type-2-with-dbt)
- [9. Conclusion & Key Takeaways](#9-conclusion--key-takeaways)
- [10. Appendix: Why DBT + ClickHouse](#10-appendix-why-dbt--clickhouse)
  - [Why use a Dockerfile instead of only Compose](#why-use-a-dockerfile-instead-of-only-compose)
  - [DBT vs Raw SQL: Conceptual Shift](#dbt-vs-raw-sql-conceptual-shift)

---

## 1. Introduction

In the previous session, you built a **ClickHouse star schema** manually using SQL scripts.  
Now, we’re taking the next step — automating it using **dbt (Data Build Tool)** on top of **ClickHouse**.

You’ll experience how dbt:
- Converts SQL logic into reusable, testable models  
- Handles schema changes and dependencies automatically  
- Fits naturally into modern data engineering workflows  

### 🎯 Learning Objectives

By the end of this session, you will:
1. Have a functional **ClickHouse + dbt** setup using Docker  
2. Understand how dbt connects to ClickHouse via the adapter  
3. Build and run dbt models that materialize tables/views  
4. Use dbt’s incremental and dependency logic  
5. Understand SCD Type 2 modeling with dbt  

---

## 2. Session Agenda (90 Minutes)

| Duration | Topic                                            | Goal |
|-----------|--------------------------------------------------|------|
| 5 min     | Introduction & Objectives                        | Align on dbt goals |
| 10 min    | Environment Setup                                | Run Docker services |
| 15 min    | DBT Core Concepts                                | Models, profiles, and targets |
| 20 min    | **Task 1:** Setting up Models in DBT             | Create reusable transformations |
| 15 min    | **Task 2:** Running DBT models                   | Automate schema builds |
| 15 min    | **Task 3:** Incremental Update                   | Handle data history |
| 10 min    | Wrap-up & Key Takeaways                          | Summarize learnings |

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
    # ClickHouse analytical database server
    image: clickhouse/clickhouse-server
    container_name: clickhouse-server
    environment:
      CLICKHOUSE_USER: default
      CLICKHOUSE_PASSWORD: ""
      CLICKHOUSE_DB: default
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1

    ports:
      - "8123:8123" # HTTP interface
      - "9000:9000" # Native client interface
    volumes:
      # This makes our local CSVs available inside the container.
      - ./sample_data:/var/lib/clickhouse/user_files
      # Mount local SQL files to run them via the ClickHouse client.
      - ./sql:/sql
    # Best practice from official docs to prevent "too many open files" errors.
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8123/ping"]
      interval: 5s
      retries: 20

  dbt:
    # dbt container for building and testing ClickHouse models
    build:
      context: .               # Build context is the current directory
      dockerfile: Dockerfile   # Use the Dockerfile in this directory to build dbt image
    container_name: dbt
    depends_on:
      - clickhouse-server      # Ensure ClickHouse starts before dbt
    volumes:
      - ./sample_data:/var/lib/clickhouse/user_files # Shared folder for input files
      - ./sql:/sql                                  # Shared SQL scripts
      - ./dbt_project:/dbt                                  # Mount local dbt project directory
    working_dir: /dbt          # Set dbt project directory as the working directory
    tty: true                  # Keep container running for interactive dbt commands
```

### Step 3.3: Why a Dockerfile for DBT?

We use a **Dockerfile** instead of an image from Compose because:
- Official dbt-clickhouse images need authentication (`ghcr.io` access)
- Building locally allows control over Python dependencies  
- Custom versions or packages (e.g., `git`, `pandas`, `clickhouse-connect`) can be installed  

🧩 **Compose** orchestrates containers  
🧱 **Dockerfile** defines how your dbt container is built  

---

## 4. DBT + ClickHouse: Core Concepts Explained

Think of dbt as a **SQL compiler** for your data warehouse.

| Concept | Description |
|----------|-------------|
| **Models** | SQL files that define transformations (`SELECT ...`) |
| **Materializations** | Define how dbt builds each model (`view`, `table`, `incremental`) |
| **Dependencies** | `{{ ref('model_name') }}` creates build order automatically |
| **Profiles** | Connection details to ClickHouse |
| **Targets** | Environment context like `dev` or `prod` |

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

### Example: `models/staging/stg_dim_product.sql` (renamed seed)

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
1.a. `stg_dim_customer` we use a function called file () to read the css file directly. 

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

By default our queries created table because it is mentioned `+materialized: table` in `dbt_project.yml` file. However you can override the config by adding, such as:

```sql
{{ config(materialized='incremental') }}
```

To your models (sql files). There are a few materialisation methods. 


| Materialization | Description                                                                               |
| --------------- | ----------------------------------------------------------------------------------------- |
| **table**       | Physical table in ClickHouse. Good for snapshots or SCDs.                                 |
| **view**        | Logical view, always recomputed. Lightweight but slower for large datasets.               |
| **incremental** | Adds new data to existing table instead of rebuilding everything. Useful for fact tables. |
| **ephemeral**   | Temporary CTE; never materialized, used for intermediate transformations.                 |
| **seed**        | CSV loaded as a table; used for static refere                                             |


## 7. Incremental Models and Data Updates
# Task 3: Incremental Models and Data Updates

Now let's create an incremental report on top of the `fact_sales` table, leveraging multiple dimension tables (`dim_customer`, `dim_product`, `dim_store`, `dim_payment`) for richer insights. Create a sql file in the following directory `dbt_project/models/marts/cust_sales_detailed_summary.sql` (`dbt_project` because your docker sees this as dbt).

## Example: `models/marts/cust_sales_detailed_summary.sql`

```sql
{{ config(materialized='incremental', unique_key='CustomerKey') }}

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
  -- Only include new sales since the last run
  WHERE f.FullDate > (SELECT MAX(LastOrderDate) FROM {{ this }})
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

## Run incrementally:

```bash
docker exec -it dbt dbt run --select cust_sales_detailed_summary
```

## Key Points:

1. **Materialization type**: `incremental`

   * Only new rows from the fact table are processed.
   * Existing summary rows remain intact.

2. **Multiple dimension tables**:

   * `dim_customer` → Customer info
   * `dim_product` → Product info
   * `dim_store` → Store info

3. **Why this is powerful**:

   * Provides richer insights across multiple dimensions.
   * Incremental processing avoids full recomputation every time.
   * Supports historical growth of fact data efficiently.
---

## 8. Task 4: Snapshots with DBT

In this task, we will **track changes in the `fact_sales` table over time** using dbt snapshots. This is useful when source data can change (e.g., late-arriving sales, corrections) and you want to preserve history.

---

### Step 8.1: Define a Snapshot

Create a snapshot file: `snapshots/fact_sales_snapshot.sql`
But this does not work in click house. Should work in other adapter. 

```sql
{% snapshot fact_sales_snapshot %}
{{ config(
    target_schema='snapshots',
    unique_key='SaleID',
    strategy='timestamp',
    updated_at='FullDate'
) }}

SELECT
    SaleID,
    DateKey,
    StoreKey,
    ProductKey,
    SupplierKey,
    CustomerKey,
    PaymentKey,
    Quantity,
    SalesAmount,
    FullDate
FROM {{ ref('fact_sales') }}
{% endsnapshot %}
```

#### Explanation of config:

- target_schema: where snapshot table will be stored

- unique_key: identifies each row uniquely

- strategy: 'timestamp' will check for changes in updated_at column

- updated_at: column dbt uses to detect row changes

### Step 8.2: Run the Snapshot
```
docker exec -it dbt dbt snapshot --select fact_sales_snapshot

```
---



## 9. Data Quality & Testing with DBT
9.1 Schema-based Tests

`models/schema.yml`:

```
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

```docker exec -it dbt dbt test```

9.2 Custom SQL Tests

Create `tests/test_total_sales_positive.sql`:

```sql
SELECT *
FROM {{ ref('cust_sales_detailed_summary') }}
WHERE TotalSales < 0
```


Run SQL tests:

```docker exec -it dbt dbt test --select test_total_sales_positive```


Summary:

Schema tests: Quick, declarative validation

SQL tests: Flexible, business-logic-focused unit tests

### 10. Selectors
We have run these models separately in dat which is cumbersome. You can run them using selectors. 
Create yaml file in `dbt_project/selectors.yml`

```
selectors:
  - name: all_models
    description: "Run all models in staging and marts folders using FQN"
    definition:
      union:
        - method: fqn
          value: staging  # all staging models
        - method: fqn
          value: marts    # all mart models
```
To run the models, run following query in the terminal under dot service in the docker container

```
dbt run --selector all_models
```
TO run the tests 
```
dbt test --selector all_models
```

✅ **You now have a modern analytics stack: ClickHouse + dbt**

**Key learnings:**
- dbt automates schema builds and dependencies  
- Docker Compose isolates ClickHouse (storage) and dbt (transformation)  
- Dockerfile adds reproducibility and control  
- Incremental + Snapshot
- Built in Data Quality control 
- Further dependency using selector   

---

## 10. Appendix: Why DBT + ClickHouse

### Why use a Dockerfile instead of only Compose

| Use | Description |
|------|--------------|
| **Dockerfile** | Defines *how* your dbt environment is built (Python, adapters) |
| **docker-compose.yml** | Defines *how containers run together* (networking, ports, volumes) |

Compose orchestrates both; Dockerfile builds dbt’s custom runtime — ensuring **customizability + portability**.

---

### DBT vs Raw SQL: Conceptual Shift

| Concept | Raw SQL Approach | DBT Approach |
|----------|------------------|--------------|
| Schema creation | Manual `CREATE TABLE` | dbt auto-materializes |
| Data dependencies | Manually ordered scripts | `ref()`-based DAG |
| Version control | Ad-hoc | Git integrated |
| Testing | Manual queries | `dbt test` + schema.yml |
| Documentation | README/manual | `dbt docs generate` |
