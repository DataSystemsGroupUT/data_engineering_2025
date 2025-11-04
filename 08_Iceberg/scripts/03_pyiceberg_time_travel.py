# 03_pyiceberg_time_travel.py
import duckdb
from pyiceberg.catalog import load_catalog
import pyarrow as pa
import pandas as pd

# ------------------------------
# DuckDB connection
# ------------------------------
conn = duckdb.connect("lab.duckdb")  # persistent DB file

# ------------------------------
# Load PyIceberg Catalog
# ------------------------------
catalog = load_catalog(name="rest")
table = catalog.load_table("default.fact_sales_iceberg")

# ------------------------------
# Append new rows to create a visible new snapshot
# ------------------------------
new_data = pd.DataFrame({
    "SaleID": [6, 7],
    "DateKey": [4, 4],
    "StoreKey": [2, 1],
    "ProductKey": [5, 3],
    "SupplierKey": [2, 1],
    "CustomerKey": [3, 2],
    "PaymentKey": [1, 2],
    "Quantity": [7, 8],
    "SalesAmount": [20.0, 15.0],
    "FullDate": ["2025-09-21", "2025-09-21"]
})

# ✅ Convert FullDate to date
new_data["FullDate"] = pd.to_datetime(new_data["FullDate"]).dt.date

arrow_update = pa.Table.from_pandas(new_data)
table.append(arrow_update)
print("✅ New rows appended to create a new snapshot")

# ------------------------------
# Register updated table in DuckDB
# ------------------------------
arrow_current = table.scan().to_arrow()
conn.register('fact_sales_iceberg', arrow_current)

# ------------------------------
# Register previous snapshot for time travel
# ------------------------------
# Get the snapshot *before* the last append
if len(table.snapshots()) > 1:
    previous_snapshot_id = table.snapshots()[-2].snapshot_id
    arrow_prev = table.scan(snapshot_id=previous_snapshot_id).to_arrow()
    conn.register('fact_sales_prev', arrow_prev)
else:
    print("⚠ No previous snapshot found")
    arrow_prev = None

# ------------------------------
# Test queries
# ------------------------------
print("\nCurrent table:")
print(conn.sql("SELECT * FROM fact_sales_iceberg"))

if arrow_prev is not None:
    print("\nPrevious snapshot table:")
    print(conn.sql("SELECT * FROM fact_sales_prev"))

print("\n✅ Time travel snapshot registered in DuckDB")
