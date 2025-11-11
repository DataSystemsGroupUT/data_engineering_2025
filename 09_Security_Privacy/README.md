# ClickHouse Practice: Security & Privacy (90 minutes)

## 1. Introduction

This is a hands-on session to practice **RBAC**, **column-level permissions**, **masked views**, and **auditing** in ClickHouse.

### Learning Objectives
- Apply **least privilege** with roles and column-level `GRANT`s.  
- Publish a **masked view** for safe analytics.  
- **Audit** a change to find **who** changed **what** and **when**.

---

## 2. Agenda
1. Project 3 context – 5 min  
2. Concepts recap (roles, rights, masking) – 5–10 min  
3. Environment setup (Docker) – 5–10 min  
4. Tasks – 60 min  
   - Task 1: Junior analyst role & column-level access  
   - Task 2: Masked view + rights  
   - Task 3: Write rights + audit an update  
5. Wrap-up – 5 min

---

## 3. Environment Setup

Check the associated `compose.yml`. 

You can use a clickhouse setup from previous session or your project, the important part is to add the environment variables:
```
    environment:
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1 # https://clickhouse.com/docs/operations/settings/settings-users#access_management-user-setting
      CLICKHOUSE_USER: admin
      CLICKHOUSE_PASSWORD: admin_password
```

PS: can you detect what are some aspects to improve, security-wise, in the compose file? There are at least 2 covered in lecture. 

### Start and verify that it works

`docker compose up -d`  
`docker exec -it clickhouse-server-secpriv clickhouse-client -u admin --password admin_password -q "SELECT version()"`  
_Note: modify the container name if needed in the above command_

### Seed data
Create the database objects and insert rows. You can find the queries in the `./sql` folder, or you can check and run them manually in an IDE.

`docker exec -it clickhouse-server-secpriv clickhouse-client --multiquery --queries-file=/sql/01_create_db_and_tables_and_load_data.sql`


## 4. Task 1 — Column-Level RBAC (Least Privilege)

Create a junior analyst role and user. 
The role requires to be able to see salary information per department, location, and hiring date.

Relevant documentation:  
https://clickhouse.com/docs/sql-reference/statements/grant 


<details>
<summary>Click here for an example answer</summary>

```
-- create role
CREATE ROLE IF NOT EXISTS junior_analyst;

-- create user 
CREATE USER IF NOT EXISTS jr_user
IDENTIFIED BY 'demo_strong_password';

-- give the user this role 
GRANT junior_analyst TO jr_user;

-- give the user select rights only on required columns.
-- note: employee_id may or may not be included, depends on risk assessment (likelihood of cross )
GRANT SELECT (employee_id, salary, department, location, hire_date)
ON sec_demo.employees
TO junior_analyst;

```
</details>

Verify that the junior analyst user is able to see the required data, but not data that is not allowed.

<details>
<summary>Click here for an example answer</summary>

Login as user (you can use IDE)
```
docker exec -it clickhouse-server-secpriv clickhouse-client -u jr_user --password demo_strong_password
```

Run different queries as this user:
``` 
-- This should work (allowed columns)
SELECT employee_id, salary, department, location, hire_date
FROM sec_demo.employees;

-- This should fail (wildcard)
SELECT * FROM sec_demo.employees;

-- This should fail (sensitive)
SELECT email FROM sec_demo.employees;
```
</details>


## 5. Task 2 — Data Masking

Create a view `sec_demo.v_employees_masked` that masks PII/sensitive fields, then grant the role full select access to the view.

The required fields to be masked are email, phone, ssn, salary, birth_date:

| Raw                       | Masked               |
| ------------------------- | -------------------- |
| `ava.kask@testcompany.ee` | `***@testcompany.ee` |
| `+3725551001`             | `***001`             |
| `49505122348`             | `49******48`         |
| `3200.00`                 | `3000–3999`          |
| `1995-05-12`              | `NULL`               |

Relevant documentation:  
https://clickhouse.com/docs/cloud/guides/data-masking

<details>
<summary>Click here for tips on masking functions</summary>
You can use `replaceRegexpAll` for regex masking, you can use it for e-mail and SSN.   
You can use concat for phone (also for SSN).   
You can use intDiv and a few other methods for getting the salary ranges.  
</details>

<details>
<summary>Click here for an example answer</summary>

```
CREATE OR REPLACE VIEW sec_demo.v_employees_masked AS
SELECT
    employee_id,
    first_name,
    last_name,
    department,
    location,
    hire_date,

    -- Email: keep domain, redact username
    replaceRegexpAll(email, '^[^@]+', '***') AS email_masked,

    -- Phone: keep only last 3 digits
    concat('***', right(phone, 3)) AS phone_masked,

    -- Estonian personal code (isikukood): show only first 2 digits and last 2
    replaceRegexpAll(ssn, '^([0-9]{2})[0-9]+([0-9]{2})$', '\\1******\\2') AS ssn_masked,

    -- Salary: bucket into ranges
    concat(
        toString(intDiv(toUInt64(salary), 1000) * 1000),
        '–',
        toString(intDiv(toUInt64(salary), 1000) * 1000 + 999)
    ) AS salary_range,

    -- Birth date: replace with NULL or fixed date for privacy
    NULL AS birth_date_masked
FROM sec_demo.employees;

```
</details>


## 6. Task 3 — Check the logs

DELETE and UPDATE data in the employees table as the admin user.  
Find the information about these DELETEs and UPDATEs in the logs.  
_Hint: you can find it using SQL, and you can also find it from a file-based log_

Relevant documentation:  
https://clickhouse.com/docs/cloud/security/audit-logging/database-audit-log  
https://clickhouse.com/docs/guides/troubleshooting  

<details>
<summary>Click here for an example query</summary>

```
DELETE FROM sec_demo.employees 
WHERE employee_id = 1005;

UPDATE sec_demo.employees
SET salary = 6000
WHERE employee_id = 1004;
```
</details>

<details>
<summary>Click here for an example how to check logs in SQL</summary>

```
SYSTEM FLUSH LOGS;

-- Find the finished UPDATE
SELECT
  event_time,
  user,
  query_id,
  query,
  read_rows,
  written_rows,
  client_hostname
FROM system.query_log
WHERE query LIKE 'UPDATE sec_demo.employees%'
OR query LIKE 'DELETE FROM sec_demo.employees%'
ORDER BY event_time DESC
LIMIT 5;
```
</details>

<details>
<summary>Click here for an example how to check logs from file</summary>

Go into the docker container  
`docker exec -it clickhouse-server-secpriv bash`

Navigate to logs folder  
`cd var/log/clickhouse-server/`

Grep the log file, e.g.:
`cat clickhouse-server.log | grep "DELETE FROM"`

</details>


## 7. Further information

One aspect we do not cover in this course, but is relevant, in general, is row-level security.  
For ClickHouse documentation, check the row policies:  
https://clickhouse.com/docs/sql-reference/statements/create/row-policy