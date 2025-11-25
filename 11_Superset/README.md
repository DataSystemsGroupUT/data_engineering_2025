
# Apache Superset Practice

## Table of contents

- [Introduction and learning objectives](#introduction-and-learning-objectives)  
- [Task 0: Start environment & sample data](#task-0-start-environment--sample-data)  
- [Task 1: Connect Superset to ClickHouse](#task-1-connect-superset-to-clickhouse)  
- [Task 2: Explore data with SQL Lab](#task-2-explore-data-with-sql-lab)  
- [Task 3: Register datasets (table & SQL)](#task-3-register-datasets-table--sql)  
- [Task 4: Build charts](#task-4-build-charts)  
- [Task 5: Build a dashboard](#task-5-build-a-dashboard)  
- [Appendix](#appendix)  

---

## Introduction and learning objectives

In this practice session you will use **Apache Superset** as a BI / visualization tool on top of **ClickHouse**.

You will:

- Connect Superset to the ClickHouse **`supermarket`** database  
- Run SQL queries using **SQL Lab**  
- Register **datasets** from:
  - Existing tables (e.g. `FactSales`)
  - Custom SQL (joins between fact & dimensions)  
- Build a few **charts**  
- Combine them into a simple **dashboard**

> Timebox:  
> - 10–15 min: introduction, environment setup  
> - ~45–60 min: Tasks 1–5  
> - _Optional_: Use time to work on Project 3 SuperSet integration.

---

## Task 0: Start environment & sample data

### 0.1 Start Superset

From the Superset project folder:

```bash
docker compose up -d
```

Then open Superset in your browser:

- URL: http://localhost:8088  
- Login: for now, use the default credentials ( `admin` / `admin`)

Make sure the UI loads and you can see the main Superset homepage.

---

### 0.2 Make sure ClickHouse and sample tables exist

Include ClickHouse service in the docker compose file. You can use the sample below, or add your own ClickHouse container you are using in the project.  

<details>  
<summary>Example addition to compose.yml</summary>  

### under services add
  clickhouse-server-viz:
    image: clickhouse/clickhouse-server
    container_name: clickhouse-server-viz
    environment:
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1 # https://clickhouse.com/docs/operations/settings/settings-users#access_management-user-setting
      CLICKHOUSE_USER: admin
      CLICKHOUSE_PASSWORD: admin_password

    ports:
      - "8123:8123" # HTTP interface
      - "9000:9000" # Native client interface
    volumes:
      # NOTE: modify these paths as needed. E.g., you want to persist data somewhere else, you want to use your project data, etc.
      # This persists our database data on our local machine.
      - clickhouse-viz-data:/var/lib/clickhouse/ 
      # mount SQL to run them via client
      - ./sql:/sql
      - ./sample_data:/var/lib/clickhouse/user_files
    # Best practice from official docs to prevent "too many open files" errors.
    ulimits:
      nofile:
        soft: 262144
        hard: 262144

### under volumes add

  clickhouse-viz-data:

</details>  

If you want to use the practice session data, (re)load the sample schema inside the ClickHouse container using the sql and csv files under `./sql` and `./sample_data`.

<details>  
<summary>Example scripts to run</summary>  
```bash
docker exec -it clickhouse-server-viz bash
clickhouse-client --multiquery --queries-file=/sql/01_create_db_and_tables.sql  
clickhouse-client --multiquery --queries-file=/sql/02_load_queries.sql 
```
</details>  


### 0.3 Create a Superset service account

Create a service account in ClickHouse for Superset application. It should have SELECT rights on supermarket schema.

<details>
<summary>Example solution</summary>  

```
CREATE ROLE role_superset_full;

CREATE USER service_superset_full IDENTIFIED WITH sha256_password BY 'superset_very_secret_password';

GRANT role_superset_full TO service_superset_full;

GRANT SELECT ON supermarket.* TO role_superset_full;
```  
</details>

---

## Task 1: Connect Superset to ClickHouse

1. In Superset, go to **Settings → Database connections**  

2. Click **+ Database**

3. Choose **ClickHouse Connect** as the database type  

4. Use the credentials as you created them above

---

## Task 2: Explore data with SQL Lab

Open **SQL → SQL Lab**.

Run:

```sql
SELECT *
FROM supermarket.FactSales
```

More advanced example:

```sql
SELECT
    d.FullDate,
    p.Category,
    SUM(f.SalesAmount) AS total_sales
FROM supermarket.FactSales f
JOIN supermarket.DimDate d
    ON f.DateKey = d.DateKey
JOIN supermarket.DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY d.FullDate, p.Category
ORDER BY d.FullDate, p.Category
```

---

## Task 3: Register datasets (table & SQL)

### 3.1 Dataset from table

- Go to **Datasets → + Dataset**
- Database: ClickHouse
- Schema: `supermarket`
- Table: `FactSales`
- Save as **`FactSales`**

### 3.2 Dataset from SQL

Use:

```sql
SELECT
    d.FullDate,
    toStartOfMonth(d.FullDate) AS MonthStart,
    s.Region,
    p.Category,
    SUM(f.SalesAmount) AS total_sales,
    SUM(f.Quantity) AS total_quantity
FROM supermarket.FactSales f
JOIN supermarket.DimDate d ON f.DateKey = d.DateKey
JOIN supermarket.DimStore s ON f.StoreKey = s.StoreKey
JOIN supermarket.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY d.FullDate, MonthStart, s.Region, p.Category
ORDER BY MonthStart, s.Region, p.Category;
```

Save dataset as **`Sales_By_Date_Region_Category`** (Under Save (arrow) --> Save dataset).

---

## Task 4: Build charts

### 4.1 Chart from FactSales

- Visualization: Table / Big Number
- Metric: `SUM(SalesAmount)`
- Time column: `FullDate`
- Save as **`Total Sales over Time (FactSales)`**

### 4.2 Chart from SQL dataset

Options:

- Bar chart grouped by Region & Category  
- Line chart by MonthStart  

Save as **`Monthly Sales by Region and Category`**

---

## Task 5: Build a dashboard

1. Go to **Dashboards → + Dashboard**
2. Name: **Supermarket Overview**
3. Add charts:
   - Total Sales over Time (FactSales)
   - Monthly Sales by Region and Category
4. Arrange layout
5. Add filters (optional)
6. Save

---

## Appendix

### Relevant documentation

Connecting ClickHouse to Superset:  
https://clickhouse.com/docs/integrations/superset 

Enabling additional features in Superset:  
https://superset.apache.org/docs/using-superset/exploring-data

Security in Superset:  
https://superset.apache.org/docs/security/

### Role-based accesses

For your project 3, you can do the following:  
* Create two separate schemas and two separate users/roles in ClickHouse  
* Create two connections in Superset, name them clearly to distinguish between full and limited access rights  
* Create new roles, new users under the roles, and assign the connections to the specific roles in Superset (note: this is not mandatory for project 3, but recommended to go through so you understand the steps)  

