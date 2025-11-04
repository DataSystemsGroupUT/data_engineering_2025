import duckdb

# ------------------------------
# DuckDB Connection & S3 Setup
# ------------------------------
conn = duckdb.connect("lab.duckdb")  # persistent DB file
conn.install_extension("httpfs")
conn.load_extension("httpfs")

# Configure S3 (MinIO)
conn.sql("""
SET s3_region='us-east-1';
SET s3_url_style='path';
SET s3_endpoint='minio:9000';
SET s3_access_key_id='minioadmin';
SET s3_secret_access_key='minioadmin';
SET s3_use_ssl=false;
""")

# ------------------------------
# Load CSVs from MinIO into DuckDB
# ------------------------------
tables = [
    'dim_date', 'dim_customer', 'dim_store',
    'dim_product', 'dim_supplier', 'dim_payment', 'fact_sales'
]

for table in tables:
    s3_path = f's3://practice-bucket/{table}.csv'
    conn.sql(f"CREATE OR REPLACE TABLE {table} AS SELECT * FROM read_csv('{s3_path}')")

print("✅ DuckDB tables created from MinIO CSVs")

# ------------------------------
# Test query
# ------------------------------
print(conn.sql("SELECT * FROM fact_sales LIMIT 5"))
