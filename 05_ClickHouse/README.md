
# ClickHouse Practice: Implementing a High-Performance Star Schema


## Table of Contents
- [1. Introduction](#1-introduction)
  - [Learning Objectives](#learning-objectives)
- [2. Session Agenda (90 Minutes)](#2-session-agenda-90-minutes)
- [3. Environment Setup](#3-environment-setup)
- [4. The ClickHouse Way: Core Concepts Explained](#4-the-clickhouse-way-core-concepts-explained)
- [5. Task 1: Creating the Star Schema](#5-task-1-creating-the-star-schema)
- [6. Task 2: Preparing CSVs and Loading Data Robustly](#6-task-2-preparing-csvs-and-loading-data-robustly)
- [7. Task 3: Running Analytical Queries](#7-task-3-running-analytical-queries)
- [8. Task 4: Handling Data Changes (SCD Type 2)](#8-task-4-handling-data-changes-scd-type-2)
- [9. Conclusion & Key Takeaways](#9-conclusion--key-takeaways)
- [10. Appendix: Deep Dive into ClickHouse Concepts](#10-appendix-deep-dive-into-clickhouse-concepts)
  - [`ENGINE = MergeTree()` — what it *really* means](#engine--mergetree-in-depth)
  - [`ORDER BY`: Your Physical Primary Key](#order-by-your-physical-primary-key)
  - [`PARTITION BY`: Data Lifecycle and Pruning](#partition-by-data-lifecycle-and-pruning)
  - [ORDER BY vs PARTITION BY](#order-by-vs-partition-by)
  - [Simple Design Checklist for Star Schemas](#simple-design-checklist-for-star-schemas)
  - [Quick contrasts with PostgreSQL](#quick-contrast-with-postgresql)


---



## 1. Introduction

In the previous session with Hasan, you designed a star schema for supermarket analytics and implemented it in a traditional OLTP database, PostgreSQL. Today, we will take that same schema and implement it in **ClickHouse**, a true columnar OLAP database built for extreme analytical performance.

Our goal is not just to run SQL, but to understand **the ClickHouse way of thinking**. We will focus on the architectural concepts that make it so powerful and learn how to handle data ingestion and updates in a manner suited for large-scale data warehousing.
### Learning Objectives:

By the end of this session, you will:
1.  Have a working ClickHouse instance running via Docker.
2.  Understand the core concepts of the `MergeTree` engine.
3.  Know the critical importance of `ORDER BY` and `PARTITION BY` for query performance.
4.  Implement a star schema with dimension and fact tables in ClickHouse.
5.  Load data from local files using a robust, production-grade ingestion pattern.
6.  Demonstrate how to handle data changes, including updating dimensions (SCD Type 2).

---

## 2. Session Agenda (90 Minutes)

| Duration | Topic                                           | Goal                                                        |
|----------|-------------------------------------------------|-------------------------------------------------------------|
| 5 min    | Introduction & Objectives                       | Align on the session's goals and learning outcomes.         |
| 10 min   | Environment Setup                               | Get Docker and the project structure ready.                 |
| 15 min   | The ClickHouse Way: Core Concepts               | Explain `MergeTree`, `ORDER BY`, and `PARTITION BY`.        |
| 15 min   | **Task 1:** Creating the Star Schema            | Implement the database and table structures from a script.  |
| 15 min   | **Task 2:** Loading Data Robustly               | Prepare CSV files and load them using a foolproof method.   |
| 10 min   | **Task 3:** Running Analytical Queries          | Verify data loading and run management queries.             |
| 15 min   | **Task 4:** Handling Data Changes (SCD Type 2)  | Implement a dimension update and see its effect.            |
| 5 min    | Wrap-up & Key Takeaways                         | Summarize key learnings and answer questions.               |


---

## 3. Environment Setup

### **Step 3.1: Project Structure**

First, create a main folder for this practice session and structure it exactly as follows. This is crucial for Docker's volume mapping to work correctly.

```
05_ClickHouse/
├── compose.yml
├── README.md
└── sample_data/
    ├── dim_customer.csv
    ├── dim_date.csv
    ├── dim_payment.csv
    ├── dim_product.csv
    ├── dim_store.csv
    ├── dim_supplier.csv
    └── fact_sales.csv
└── sql/
    ├── 01_create_db_and_tables.sql
    ├── 02_load_queries.sql
    ├── 03_scd2_and_queries.sql
    ├── 04_analytical_questions.sql

```

### **Step 3.2: Create the `compose.yml` File**

In the root of your `clickhouse_practice` directory, create a file named `compose.yml` and paste the following content.

```yaml
services:
  clickhouse-server:
    image: clickhouse/clickhouse-server
    container_name: clickhouse-server

    ports:
      - "8123:8123" # HTTP interface
      - "9000:9000" # Native client interface
    volumes:
      # This persists our database data on our local machine.
      - ./clickhouse_data:/var/lib/clickhouse/
      # This makes our local CSVs available inside the container.
      - ./sample_data:/var/lib/clickhouse/user_files
      # mount SQL to run them via client
      - ./sql:/sql
    # Best practice from official docs to prevent "too many open files" errors.
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
```

### **Step 3.3: Start and Connect to ClickHouse**

1.  **Start the Services**: Open a terminal in the `05_ClickHouse` directory and run:
    ```bash
    docker compose up -d
    ```
    This will download the image (if you don't have it) and start the ClickHouse server in the background.

2.  **Connect to the Client**: To start an interactive SQL session, run:
    ```bash
    docker exec -it clickhouse-server clickhouse-client
    ```
    You should see a prompt like `clickhouse-server :)`. You are now ready to run queries!

---

## 4. The ClickHouse Way: Core Concepts Explained

Before we write any code, it's vital to understand the concepts that make ClickHouse different from PostgreSQL.

*   **`ENGINE = MergeTree()`**: This is the heart of ClickHouse. The `MergeTree` family of engines is the workhorse for nearly all data warehousing tasks. It automatically sorts data, compresses it, and creates a sparse primary index. Unlike an OLTP database, you **must** specify an engine for every table you create. For analytics, you will almost always use a `MergeTree` variant.

*   **`ORDER BY` (The Primary Key)**: This is the **single most important setting for query performance**. It tells `MergeTree` how to physically sort data on disk. Queries that filter (`WHERE`) on the columns in the `ORDER BY` clause are exceptionally fast because ClickHouse can read contiguous blocks of data and skip massive amounts of irrelevant data.
    *   **Simple Thing to Remember:** Order by the columns you filter on most frequently. For fact tables, this is almost always a `Date` or `DateTime` column, followed by other high-cardinality dimension keys.

*   **`PARTITION BY`**: This physically splits your table's data into separate directories based on a key. We will partition our fact table by month. When a query filters by a specific date range (e.g., `WHERE FullDate = '2025-09-18'`), ClickHouse is smart enough to only read the data in the `202509` partition (folder), completely ignoring all other months of data. This provides a massive performance boost.
    *   **Simple Thing to Remember:** Partition by a low-cardinality column, which is almost always a date (typically by month).

---

## 5. Creating the Star Schema

Our script is **idempotent**, meaning it can be run multiple times without causing errors. We achieve this by first dropping the database if it exists, ensuring a clean slate every time.

**Run the entire SQL block in the ClickHouse client.**

```bash
docker exec -it clickhouse-server clickhouse-client --multiquery --queries-file=/sql/01_create_db_and_tables.sql
```
---

## 6. Preparing and Loading Data from Files

Loading data is where many first-time users stumble. A simple `INSERT` can silently fail if ClickHouse cannot perfectly infer the data types from your CSV. We will use a **robust, production-grade pattern** that eliminates this risk.

> **The Robust Ingestion Pattern**
> Instead of the simple `INSERT INTO ... FROM INFILE`, we will use `INSERT INTO ... SELECT ... FROM file()`. This pattern treats the CSV as a temporary table and lets us explicitly `CAST` each column to its correct data type (e.g., `toString()`, `toDate()`, `toUInt32()`). This prevents silent zero-row inserts and guarantees that either the data loads correctly or you get a clear error message.

### **Step 6.1: Create the CSV Files**

Create the following files inside your `sample_data` directory. Ensure the headers and column counts match **exactly**.

<details>
<summary>Click here for all definitive CSV data content</summary>

**`dim_date.csv`**
```csv
DateKey,FullDate,Year,Month,Day,DayOfWeek
1,2025-09-18,2025,9,18,Thursday
2,2025-09-19,2025,9,19,Friday
3,2025-09-20,2025,9,20,Saturday
4,2025-09-21,2025,9,21,Sunday
```
**`dim_store.csv`**
```csv
StoreKey,StoreName,City,Region
1,"SuperMart Downtown","Tallinn","North"
2,"SuperMart Suburb","Tartu","South"
```
**`dim_product.csv`**
```csv
ProductKey,ProductName,Category,Brand
1,"Apple","Fruit","FreshFarm"
2,"Banana","Fruit","Tropicana"
3,"Milk","Dairy","DairyBest"
4,"Bread","Bakery","BakeHouse"```
**`dim_supplier.csv`**
```csv
SupplierKey,SupplierName,ContactInfo
1,"FreshFarm Supplier","fresh@farm.com"
2,"Tropicana Supplier","contact@tropicana.com"
3,"DairyBest Supplier","sales@dairybest.com"
4,"BakeHouse Supplier","info@bakehouse.com"
```
**`dim_customer.csv`**
```csv
CustomerKey,CustomerID,FirstName,LastName,Segment,City,ValidFrom,ValidTo
1,1,"Alice","Smith","Regular","Tallinn","2025-01-01","9999-12-31"
2,2,"Bob","Jones","VIP","Tartu","2025-01-01","9999-12-31"
```
**`dim_payment.csv`**
```csv
PaymentKey,PaymentType
1,"Cash"
2,"Card"
3,"Voucher"
```
**`fact_sales.csv`**
```csv
SaleID,DateKey,StoreKey,ProductKey,SupplierKey,CustomerKey,PaymentKey,Quantity,SalesAmount,FullDate
1,1,1,1,1,1,2,5,6.00,2025-09-18
2,1,1,2,2,1,1,3,2.40,2025-09-18
3,2,2,3,3,2,2,2,5.00,2025-09-19
4,2,2,4,4,2,2,1,1.50,2025-09-19
5,3,1,1,1,2,1,10,12.00,2025-09-20
6,3,1,3,3,1,2,1,2.50,2025-09-20
```
</details>

### **Step 6.2: Run the Robust Ingestion Script**

```bash
docker exec -it clickhouse-server clickhouse-client --multiquery --queries-file=/sql/02_load_queries.sql
```

After running the script, you should see a result confirming the row counts in your tables. Your data is now loaded correctly!

---
### **Step 7: Run the Analytial Questions Script**

```bash
docker exec -it clickhouse-server clickhouse-client --multiquery --queries-file=/sql/03_analytical_questions.sql
```


## 8. Handling Data Changes (Upserting & SCD Type 2)

This section is crucial for Project 2. How do we handle changes to our data, like a customer moving? In data warehousing, we aim to preserve history. We will implement a **Slowly Changing Dimension (SCD) Type 2**.

**Scenario:** Customer `Alice Smith` (CustomerID `1`) moves from `Tallinn` to `Tartu`.

In ClickHouse, we don't use a traditional `UPDATE` to overwrite the row. Instead, we use a two-step process:
1.  **Expire the old record**: We use an `ALTER TABLE ... UPDATE` command, which is an asynchronous **mutation**, to set the `ValidTo` date on her old record.
2.  **Insert the new record**: We `INSERT` a completely new row for Alice with her new address and a new validity period.



```bash
docker exec -it clickhouse-server clickhouse-client --multiquery --queries-file=/sql/04_scd2_and_queries.sql
```
---

## 9. Conclusion & Key Takeaways

Congratulations! You have successfully implemented a star schema in a high-performance OLAP database.

*   We learned that while the query language is standard SQL, the underlying **storage design** (`ENGINE`, `PARTITION BY`, `ORDER BY`) is fundamentally different from OLTP databases and is the key to performance.
*   We demonstrated a **robust data ingestion pattern** (`INSERT ... SELECT ... FROM file()`) that prevents common, silent errors and is suitable for production environments.
*   We implemented a **Slowly Changing Dimension (SCD Type 2)** using ClickHouse's mutation feature, a core skill for data warehousing that preserves historical accuracy.

## 10. Appendix: Deep Dive into ClickHouse Concepts
---

### ENGINE = MergeTree() In-Depth

**PostgreSQL mental model:** a row store with B-tree indexes; you can create a table without naming a storage engine, and you add indexes later.

**ClickHouse mental model:** a column store where the **table engine is the storage design**. You must pick one. For analytics, you’ll almost always use a MergeTree variant.

#### How MergeTree stores your data

* **Columnar files:** Each column is stored separately (great for scanning a few columns over millions of rows).
* **Parts:** Inserts create immutable **parts** on disk (think: mini data files). Background threads later **merge** parts (hence *Merge*Tree).
* **Primary key (ORDER BY):** Data inside each part is **sorted** by the ORDER BY expression. This sort order drives **skipping**.
* **Sparse primary index (“marks”):** Every N rows (default granularity ~8192 rows), ClickHouse stores the **min/max** of the ORDER BY tuple plus a pointer into the file. When filtering on ORDER BY columns, the engine consults these tiny in-memory marks and **skips entire ranges** without reading them.
* **Compression:** Columns are compressed by default (LZ4). You can override per column (e.g., `CODEC(ZSTD(3))` for high compression on text).
* **Background merges:** Merge threads compact parts, re-encode columns, and preserve the sort order. This keeps read-amplification low and compression high.

#### Why this matters

* There’s **no traditional secondary index** like PostgreSQL’s B-tree to rescue a bad layout. If you choose a poor ORDER BY / PARTITION BY, you’ll read a lot more data than necessary.
* Mutations (`ALTER ... UPDATE/DELETE`) **rewrite parts** in the background (async). Great for SCD housekeeping; not for chatty OLTP updates.

#### MergeTree family (when to use what)

* **MergeTree**: the default for general facts/dims.
* **ReplacingMergeTree(version)**: Deduplicate newer rows with same key during merges (useful for late-arriving facts if you have a natural key).
* **SummingMergeTree**: auto-aggregates additive columns for same key during merge (careful with non-additive metrics).
* **AggregatingMergeTree**: stores `AggregateFunction(...)` states for rollups.
* **CollapsingMergeTree**: model upserts with sign columns (+1/-1).
* **VersionedCollapsingMergeTree**: like Collapsing but version-aware.

> Rule of thumb for teaching: **start with plain `MergeTree`**. Introduce variants only when the problem clearly maps to them.

---

### ORDER BY: Your Physical Primary Key

**What it is:** The **sort key** for each part. It **is not** a uniqueness or constraint mechanism. It’s purely for **read performance**.

**Why it’s the #1 performance knob**

* ClickHouse builds a **sparse index** over the ORDER BY tuple. On `WHERE` filters that start with those columns, it jumps to the relevant “marks” and **reads only the stripes** that can match.
* Think of it as **binary search + block skipping** on each part.

#### Good ORDER BY for a star-schema fact

For time-series facts that you query by time ranges and then slice by dimensions:

```sql
ORDER BY (FullDate, StoreKey, ProductKey)
```

* Put **time first** if almost every query filters by time windows.
* Then add the **most selective / frequently filtered** keys.
* Keep it **short**: each extra column makes marks wider and can reduce skipping if they’re noisy or high-cardinality in the wrong place.

#### Anti-patterns

* **ORDER BY (UserID)** on a dashboard where every query is `WHERE date BETWEEN ...`. You’ll scan lots of marks across many parts.
* **Throwing every dimension into ORDER BY**. Wider tuples ≠ faster. They can hurt mark density and compression.
* **Relying on ORDER BY for uniqueness.** It won’t enforce it; use variant engines (Replacing/Collapsing) or ETL discipline.

#### How skipping actually works

* Suppose `ORDER BY (FullDate, StoreKey)`, mark granularity ~8192.
* Query: `WHERE FullDate BETWEEN '2025-09-01' AND '2025-09-30' AND StoreKey = 42`.
* The engine:

  1. Finds the **smallest mark** whose `(FullDate, StoreKey)` range can intersect your filter.
  2. Jumps there and reads **only** relevant stripes.
  3. Skips any marks whose min/max show they **cannot** satisfy the predicate.

This is why **putting your most common leading filter first** saves orders of magnitude of I/O.

---

### PARTITION BY: Data Lifecycle and Pruning

**What it is:** A function that groups rows into **separate directories** (“partitions”) on disk (e.g., one per month). Each partition contains many sorted parts.

#### Why partition

* **Partition pruning:** If you filter by a partitionable predicate (`toYYYYMM(FullDate) IN (202509, 202510)`), ClickHouse **skips entire directories**—zero file opens inside other partitions.
* **Data lifecycle ops:** You can `DETACH/DROP PARTITION`, `MOVE PARTITION`, or apply **TTL** policies (e.g., move old partitions to cheaper disks or drop after N months). This is huge for cost and hygiene.

#### Choosing a partition key

* Pick a **low-cardinality** function of time for facts:

  * Common: `PARTITION BY toYYYYMM(FullDate)` (monthly)
  * Sometimes weekly or daily—but **avoid daily** unless you ingest *massive* data per day. Too many tiny partitions increase metadata overhead and slow merges.
* Dimensions often **don’t need partitions**. Use plain MergeTree (no PARTITION BY) unless you have a serious lifecycle reason.

### ORDER BY vs PARTITION BY

* **Partition** is **coarse** pruning (whole folders).
* **Order** is **fine-grained** skipping (inside files).
* They **work together**: first prune partitions, then skip marks within remaining parts.

#### Anti-patterns

* Partitioning by a **high-cardinality** key (e.g., `UserID`) → thousands of tiny partitions → awful performance and management.
* Extremely **fine** time partitions (hour/day) without volume to justify them → too many partitions, slower queries/merges.

---

#### Putting it together

**Fact table (time-series analytics default):**

```sql
ENGINE = MergeTree
PARTITION BY toYYYYMM(FullDate)
ORDER BY (FullDate, StoreKey, ProductKey)
```

**Why this works:**

* Most queries filter on dates → **partition pruning** nukes other months.
* Within those months, filtering or grouping by store/product → **mark skipping** reduces I/O.
* Joins to dims are small and cheap in a star schema.

**Dimension tables:**

```sql
ENGINE = MergeTree
ORDER BY (SurrogateKey)
-- usually NO PARTITION BY
```

**Why:**

* Dims are smaller; partitioning buys little and adds complexity.
* Keeping them simple speeds joins and mutations (for SCD).

---



### Simple Design Checklist for Star Schemas

1. **Fact**

   * Partition by month: `toYYYYMM(FullDate)`
   * Order by: `(FullDate, <most common slice key>, <second most common>)`
   * Keep tuple short (2–3 columns).
   * Append-only; use variants (Replacing/Collapsing) only if your ingestion semantics need them.

2. **Dims**

   * Plain MergeTree, ordered by surrogate key.
   * For SCD2, mutations to expire old versions + insert new ones.

3. **Queries**

   * Always include date predicates → unlock partition pruning.
   * Filter early on ORDER BY leading columns.
   * Join to dims by numeric surrogate keys.

---

### Quick contrasts with PostgreSQL

* **Indexing model:** Postgres: many B-trees + planner chooses. ClickHouse: one **sort key** per table (+ optional skipping indexes). Get the sort key wrong → big scans.
* **Updates/deletes:** Postgres row-level. ClickHouse **mutations** rewrite parts asynchronously; design ETL as **append-majority**.
* **Storage layout:** Postgres row-oriented (great for OLTP writes/point lookups). ClickHouse column-oriented (great for scans/aggregations).
* **Vacuum vs merges:** Postgres VACUUM reclaims space; ClickHouse **merges** compactparts and maintain sort/compression.