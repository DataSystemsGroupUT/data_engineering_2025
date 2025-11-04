# DuckDB + PyIceberg Lab: Star Schema on Iceberg Tables

![Iceberg Intro](https://miro.medium.com/v2/0*M09SFm3ZA9oUXpIe.gif)

## Table of Contents

* [1. Introduction](#1-introduction)
* [2. Learning Objectives](#2-learning-objectives)
* [3. Folder Structure](#3-folder-structure)
* [4. Docker Compose & Dockerfile](#4-docker-compose--dockerfile)
* [5. Environment Setup](#5-environment-setup)
* [6. Python Scripts Overview](#6-python-scripts-overview)
* [7. Creating Iceberg Tables](#7-creating-iceberg-tables)
* [8. Querying Iceberg Tables](#8-querying-iceberg-tables)
* [9. Partitioning & Time Travel Exercises](#9-partitioning--time-travel-exercises)
* [10. Conclusion & Key Takeaways](#10-conclusion--key-takeaways)
* [11. Appendix: PyIceberg & DuckDB Concepts](#11-appendix-pyiceberg--duckdb-concepts)
* [12. Diagram](#12-diagram)

---

## 1. Introduction

In this lab, you will learn how to:

* Load a **star-schema dataset** into DuckDB
* Use **MinIO**, an S3-compatible object storage
* Create and query **Apache Iceberg tables** via PyIceberg
* Explore **partitioning and time travel** features

> **MinIO**: Local S3-compatible object storage server.
> **S3**: Amazon Simple Storage Service; cloud object storage.

---

## 2. Learning Objectives

By the end of this lab, you will:

1. Understand DuckDB + PyIceberg + MinIO setup in Docker
   > **DuckDB**: Lightweight SQL engine optimized for analytics.
2. Load CSV data into DuckDB tables
3. Create Iceberg tables and append data
4. Query Iceberg tables using DuckDB and Arrow
   > **Arrow**: Columnar in-memory format for fast analytics.
5. Explore partitioning and historical snapshots (time travel)
   > **Partitioning**: Splitting table data into chunks for faster queries.
   > **Time Travel**: Query historical snapshots of a table.
6. Work with PyIceberg’s Python API for table management
   > **Catalog**: Metadata manager for Iceberg tables, schemas, snapshots, and partitions.

---

## 3. Folder Structure

```
08_Iceberg/
├── compose.yml
├── Dockerfile
├── sample_data/
│   ├── dim_date.csv
│   ├── dim_customer.csv
│   ├── dim_store.csv
│   ├── dim_product.csv
│   ├── dim_payment.csv
│   ├── dim_supplier.csv
│   ├── fact_sales.csv
│   └── .pyiceberg.yaml
├── scripts/
│   ├── 01_duckdb_minio_setup.py
│   ├── 02_pyiceberg_create_table.py
│   └── 03_pyiceberg_time_travel.py
└── README.md
```

---

## 4. Docker Compose & Dockerfile

Docker orchestrates services: MinIO, DuckDB container, and Iceberg REST catalog.

* **MinIO**: Local object storage (S3-compatible)
* **DuckDB container**: Runs Python + DuckDB
* **Iceberg REST**: Exposes Iceberg catalog API

---

## 5. Environment Setup

1. Start services:

```bash
docker compose up --build -d
```

2. Create MinIO bucket:

* Login: [http://localhost:9001](http://localhost:9001)
* Bucket: `practice-bucket`

3. Access DuckDB container:

```bash
docker exec -it duckdb_lab bash
python
```

4. Connect DuckDB to MinIO:

```python
import duckdb
conn = duckdb.connect()
conn.install_extension("httpfs")
conn.load_extension("httpfs")

conn.sql("""
SET s3_region='us-east-1';
SET s3_url_style='path';
SET s3_endpoint='minio:9000';
SET s3_access_key_id='minioadmin';
SET s3_secret_access_key='minioadmin';
SET s3_use_ssl=false;
""")
```

---

## 6. Python Scripts Overview

* **01_duckdb_minio_setup.py**: Connects DuckDB to MinIO and loads CSVs into DuckDB tables
* **02_pyiceberg_create_table.py**: Creates Iceberg table, appends data, stores metadata in catalog
* **03_pyiceberg_time_travel.py**: Demonstrates time travel, registers current and previous snapshots

---

## 7. Creating Iceberg Tables

Run:

```bash
python scripts/02_pyiceberg_create_table.py
```

* Creates `fact_sales_iceberg` table
* Appends DuckDB data
* Stores metadata for snapshots, partitions, and schema evolution

---

## 8. Querying Iceberg Tables

```python
from scripts.02_pyiceberg_create_table import table
import duckdb

conn = duckdb.connect()
arrow_table_read = table.scan().to_arrow()
conn.register('fact_sales_iceberg', arrow_table_read)
conn.sql("SELECT * FROM fact_sales_iceberg LIMIT 10").fetchdf()
```

---

## 9. Partitioning & Time Travel Exercises

Run:

```bash
python scripts/03_pyiceberg_time_travel.py
```

* **Partitioning**: Improves query performance by physically splitting data
* **Time Travel**: Access historical snapshots efficiently
* Iceberg stores metadata separately for fast historical queries

---

## 10. Conclusion & Key Takeaways

* Self-contained DuckDB + PyIceberg + MinIO setup
* Practice manual/bulk table creation, Iceberg table management, and time travel queries
* Star-schema dataset ideal for analytics
* Iceberg metadata handling enables efficient queries and ACID support

---

## 11. Appendix: PyIceberg & DuckDB Concepts

* **PyIceberg**: Python client for Iceberg tables
* **DuckDB**: Lightweight SQL engine for analytics
* **MinIO**: Local S3-compatible object storage
* **Arrow**: In-memory columnar format
* **Snapshots / Time Travel**: Query historical versions
* **Catalog**: Stores metadata, schema, snapshots, partitions
* **Partitioning**: Splits data for faster queries
* **Iceberg Advantages**: ACID, metadata efficiency, schema evolution, time travel

---

## 12. Diagram

```text
CSV Files (sample_data/) --> DuckDB Tables --> PyIceberg --> Iceberg Table (fact_sales_iceberg)
                                                  |
                                                  v
                                            Snapshots / Time Travel
                                                  |
                                                  v
                                     Query historical data in DuckDB
```

*Arrow shows data flow: CSV -> DuckDB -> Iceberg -> Snapshots -> Time Travel Queries*

