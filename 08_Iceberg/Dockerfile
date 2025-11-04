
FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl iputils-ping wget && rm -rf /var/lib/apt/lists/*


# Install dependencies
RUN pip install duckdb pyarrow pyiceberg pandas

WORKDIR /lab
COPY sample_data/ ./sample_data/
COPY sql/ ./sql/
