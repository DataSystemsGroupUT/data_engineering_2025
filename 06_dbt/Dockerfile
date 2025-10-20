FROM python:3.11-slim

# Install git
RUN apt-get update && apt-get install -y git

# Install ClickHouse driver and dbt
RUN pip install --no-cache-dir dbt-core dbt-clickhouse clickhouse-connect

# keep working dir minimal; volumes will handle your project
WORKDIR /dbt
ENTRYPOINT ["bash"]
