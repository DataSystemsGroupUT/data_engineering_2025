# 02_pyiceberg_create_table.py
import duckdb
import pyarrow as pa
from pyiceberg.catalog import load_catalog
from pyiceberg.exceptions import NoSuchTableError, NamespaceAlreadyExistsError

# ------------------------------
# DuckDB Connection (persistent DB file)
# ------------------------------
conn = duckdb.connect("lab.duckdb")  # persistent DB file
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

# ------------------------------
# Load PyIceberg REST Catalog
# ------------------------------
catalog = load_catalog(name="rest")
namespace = "default"
table_name = "fact_sales_iceberg"

# ------------------------------
# Create namespace if it doesn't exist
# ------------------------------
try:
    catalog.create_namespace(namespace)
    print(f"✅ Namespace '{namespace}' created")
except NamespaceAlreadyExistsError:
    print(f"⚠ Namespace '{namespace}' already exists, skipping creation")

# ------------------------------
# Fetch DuckDB table as PyArrow Table
# ------------------------------
arrow_reader = conn.sql("SELECT * FROM fact_sales").arrow()
arrow_table = pa.Table.from_batches(arrow_reader)  # convert RecordBatchReader to Table

# ------------------------------
# Drop table if exists
# ------------------------------
try:
    catalog.drop_table(f"{namespace}.{table_name}")
    print(f"⚠ Table '{namespace}.{table_name}' existed and was dropped")
except NoSuchTableError:
    print(f"⚠ Table '{namespace}.{table_name}' did not exist, skipping drop")

# ------------------------------
# Create Iceberg table
# ------------------------------
table = catalog.create_table(
    identifier=f"{namespace}.{table_name}",
    schema=arrow_table.schema,
)
print(f"✅ Table '{namespace}.{table_name}' created")

# ------------------------------
# Append data
# ------------------------------
table.append(arrow_table)
print(f"✅ Data appended to '{namespace}.{table_name}'")
