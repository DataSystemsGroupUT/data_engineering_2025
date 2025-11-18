# OpenMetadata Practice

## Table of contents

- [Introduction and learning objectives](#introduction-and-learning-objectives)
- [Task 0: Check OpenMetadata UI](#task-0-check-openmetadata-ui)
- [Task 1: Add ClickHouse connection](#task-1-add-clickhouse-connection)
- [Task 2: Add table and column descriptions](#task-2-add-table-and-column-descriptions)
- [Task 3: Configure data quality tests](#task-3-configure-data-quality-tests)
- [Task 4: Define Business Glossary terms](#task-4-define-business-glossary-terms)
- [Task 5: Create data lineage](#task-5-create-data-lineage)
- [Appendix: Debugging, documentation](#appendix-debugging-documentation)

---

## Introduction and learning objectives

In this practice session you will use **OpenMetadata** as a lightweight data governance layer on top of **ClickHouse**.

You will:

- Connect OpenMetadata to a ClickHouse database service  
- Explore and catalog tables (facts & dimensions)  
- Add **human-readable descriptions** for tables and columns  
- Configure and run **data quality tests**  
- Define **Business Glossary** terms and link them to data assets  
- Create basic **data lineage** between tables  

> **Timebox:**  
> - 10–15 min: instructor overview & environment setup  
> - ~60 min: Tasks 1–5 (core lab)  
> - Remaining time: questions & extra polishing for project work

---

## Task 0: Check OpenMetadata UI

Use `docker compose up -d` to start the OpenMetadata services.  
Note: this can take several minutes. 

Then, navigate to the OpenMetadata UI by opening your browser and going to `localhost:8585`

The default Username and Password are:
```
Username - admin@open-metadata.org
Password - admin
```

---

## Task 1: Add ClickHouse connection

In this task, you will register ClickHouse as a **Database Service** in OpenMetadata and ingest its metadata (schemas and tables).

First, you need to add Clickhouse as a docker service to the compose file and start the Clickhouse service. 
Name the Clickhouse service `clickhouse-server-omd`   
Note: make sure the Clickhouse service is on the same network, if you want to modify Docker networks.

<details>  
<summary>Example addition to compose.yml</summary>  

```
  clickhouse-server-omd:
    image: clickhouse/clickhouse-server
    container_name: clickhouse-server-omd
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
      - clickhouse-omd-data:/var/lib/clickhouse/ 
      # mount SQL to run them via client
      - ./sql:/sql
      - ./sample_data:/var/lib/clickhouse/user_files
    # Best practice from official docs to prevent "too many open files" errors.
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
volumes:
    # NB! make sure you have only one "volumes" highest level block
    ingestion-volume-dag-airflow:
    ingestion-volume-dags:
    ingestion-volume-tmp:
    es-data:
    clickhouse-omd-data:
```
</details>

Second, create example database with tables and insert data (run the scripts in ./sql folder). 


<details>
<summary>Example scripts</summary>  

`docker exec -it clickhouse-server-omd bash`  
`clickhouse-client --multiquery --queries-file=/sql/01_create_db_and_tables.sql`  
`clickhouse-client --multiquery --queries-file=/sql/02_load_queries.sql`  

</details>

Next, you need to create a Clickhouse user for OpenMetadata. Create the user `service_openmetadata` and assign it to a role `role_openmetadata`.  
Add the role SELECT and SHOW access to `system` database.  
Then, add the role SELECT rights on the `supermarket` database.

<details>
<summary>Example solution</summary>  

```
CREATE ROLE role_openmetadata;

CREATE USER service_openmetadata IDENTIFIED WITH sha256_password BY 'omd_very_secret_password';

GRANT role_openmetadata TO service_openmetadata;

GRANT SELECT, SHOW ON system.* to role_openmetadata;

GRANT SELECT ON supermarket.* TO role_openmetadata;
```  
</details>

Now, you need to create the Clickhouse service in the OMD UI. 


<details>
<summary>Example solution</summary>  

In the OpenMetadata UI:  
* Go to **Settings → Services → Databases**
* Click **+ Add New Service**
* Choose **ClickHouse** as the service type
* Fill in the connection details (adapt as needed):
  * **Service Name:**  
  e.g. `clickhouse_warehouse`, can be whatever you would like
  * **Host and Port:**  
  Use the Docker service name and HTTP port, for example:  
  `clickhouse-server-omd:8123`
  * **Username:** `service_openmetadata`
  * **Password:** `omd_very_secret_password`
  * **Database / Schema:**  
  you can leave empty
  * **Https / Secure:**  
  leave them off, we have not configured Clickhouse for HTTPS or SSL/TLS.
  * Click **Test Connection**  
  * If successful, click **Next** and **Save** the service.  

</details>  

You are then taken to the database services page. Here, you can see:
* general information about the service you added  
* modify the connection parameters
* set up and/or trigger _agents_ 
  _note: an "agent" here refers to a specific pipeline. Some of the main ones are "metadata agent", "usage agent", "lineage agent" "profiler agent".

Trigger the Metadata Agent (if it's not running automatically already). You might need to wait 1-2 minutes for the job to finish.  
You can see the logs in OpenMetadata UI, or login to the associated Airflow service (localhost:8080).  

#### Once the Metadata Agent has successfully run, you can see the tables and columns in OpenMetadata!

---

## Task 2: Add table and column descriptions

Now that ClickHouse tables are visible in OpenMetadata, you will make them understandable for other people by adding **descriptions**.

Add descriptions to at least 1 fact and 2 dimension tables.  

You can see that 1 dimension table already has descriptions. Try modifying one of the existing column descriptions.

BONUS: try also modifying the descriptions in the SQL and rerunning the create db and tables statement (`./sql/01_create_db_and_tables.sql`).  
Does OpenMetadata persist the descriptions you added, or does it fetch the descriptions from Clickhouse?  
Why might one or the other option be preferred?

<details>
<summary>Example solution</summary>  
</details>


#### Tips
**Table-level descriptions**
- Add a short description (1–3 sentences), for example:
    - What this table represents
    - Typical use in analytics
    - Any important caveats

**Column-level descriptions**
- Add a short explanation:
    - What the column means
    - Typical values/units
    - If it is a key, foreign key, or derived field

**Mark sensitive columns (optional but recommended)**
- For any PII-like columns (email, phone, names, etc.), add a short note that it is sensitive.
- You can apply tags (e.g. `PII`, `SENSITIVE`).

A good way to self-check if descriptions are enough, ask yourself:  
"If someone new joins the team and only sees OpenMetadata, can they reasonably understand what these tables and columns mean, without asking you?"

---

## Task 3: Configure data quality tests

In this task, you will configure and run basic **data quality tests** on a ClickHouse table, directly from OpenMetadata.

### Instructions

1. **Choose a table for testing**

   - You can go for **fact_sales table** :

2. **Open the Data Quality tab**

   - On the table page, navigate to the **Data Quality** (or **Profiler & Data Quality**) tab.
   - If needed, run a **Profile** first so OpenMetadata can show statistics.

3. **Add table-level tests**

   Add at least one table-level test, such as:

   - **Row count > 0**
   - **Row count > some minimum** (e.g. 100)
   - **% of nulls in a key column is 0**

4. **Add column-level tests**

   Configure at least **3 column-level tests**, for example:

   - **Uniqueness** of the primary key column (e.g. `SaleID` is unique)
   - **Not null** on key columns (`SaleID`, `CustomerKey`, etc all dimension FKs should be not null)
   - **Value range** checks on numeric metrics:
     - `SalesAmount >= 0`
     - `Quantity > 0 and Quantity <= 1000`
   - **Valid values** for enums (there is not one in fact_sales, but you can force in dim_store to have `Region` in {'Tallinn', 'Tartu'})

5. **Run the tests**

   - Save the tests.
   - Trigger a test run from the UI (**Run** button).
   - Inspect the results and see which tests pass/fail.

After running the tests:

- You should see a **test run history** with each test marked as **Success** or **Failed**.
- For practice purposes, make sure to have at least one test that fails (e.g. because of negative revenue), so you can observe how these results are shown.

The important outcome: you can define checks **without changing ClickHouse SQL** directly, and still enforce expectations on your data.


---

## Task 4: Define Business Glossary terms

Business Glossary helps align **business language** with the underlying data assets.

### Instructions

1. **Open the Glossary section**

   - In the left navigation, find **Glossary** (under **Govern → Glossary**).
   - First, create a glossary (e.g. `Data Engineering Course Glossary`).

2. **Create at least 2 Glossary terms**

   For each term:

   - Click **+ Add Term**.
   - Fill in:
     - **Name:** e.g. `Net Revenue`, `Active Customer`, `Order`
     - **Description:** 2–4 sentences describing what this means in business terms.
     - Optional: synonyms, owners, reviewers, related terms.

3. **Link Glossary terms to columns**

   - Navigate back to your tables and columns.
   - For a metric column (e.g. `net_revenue`), attach the corresponding Business Glossary term (`Net Revenue`).
   - For a key column (`customer_id`), link it to a term like `Customer` or `Active Customer`.

4. **Verify glossary usage**

   - Return to the Glossary view and confirm that the terms show which tables/columns they are linked to.
   - This helps you see which data assets implement which business concepts.

---

## Task 5: Create data lineage

Data lineage shows **how data flows** between tables and systems. For this lab, you will create a simple **manual table-to-table lineage**.

### Instructions

1. **Pick 3–4 related tables**

   For example:

   - One fact table: `fact_sales`
   - Two dimension tables: `dim_customer`, `dim_product`

2. **Open the Lineage view**

   - From a table page (e.g. `fact_sales`), go to the **Lineage** tab.
   - You will see a graph (may be empty at first).

3. **Add manual lineage edges**

   - Click on **Edit Lineage** (pencil icon on the right side) to start adding tables, and connecting them:
     - `dim_customer` → `fact_sales` (customer dimension feeds the fact table)
     - `dim_product` → `fact_sales`
   - For each connection, add a short description, e.g.
     - "Customer attributes joined by CustomerKey"
     - "Product attributes joined by ProductKey"

4. **Explore the lineage graph**

   - Zoom and pan to see the graph.
   - Verify that the edges and directions make sense: upstream → downstream.

---

## Appendix: Debugging, documentation

### Troubleshooting (debugging)

- **OpenMetadata UI not loading**
  - Check container status:
    ```bash
    docker ps
    ```
  - If `openmetadata_server` is restarting, check logs:
    ```bash
    docker logs openmetadata_server --tail=100
    ```

- **No tables visible after successful test**
  - Confirm the database actually contains tables.
  - Check database/schema settings in the OpenMetadata service configuration.

### Useful documentation links

You can explore these for more background (not required to finish the lab):

- OpenMetadata Docs – Databases & Ingestion  
  https://docs.open-metadata.org/latest/connectors/database

- ClickHouse Connector
  https://docs.open-metadata.org/latest/connectors/database/clickhouse

- How-to Guides
  https://docs.open-metadata.org/latest/how-to-guides 

- Data Quality & Observability  
  https://docs.open-metadata.org/latest/how-to-guides/data-quality-observability

- Business Glossary  
  https://docs.open-metadata.org/latest/how-to-guides/data-governance/glossary

- Lineage  
  https://docs.open-metadata.org/latest/connectors/ingestion/lineage

---

You now have the minimal, end-to-end governance flow:
**ClickHouse → OpenMetadata (catalog, descriptions, quality, glossary, lineage)**,  
which directly supports your final project requirements.
