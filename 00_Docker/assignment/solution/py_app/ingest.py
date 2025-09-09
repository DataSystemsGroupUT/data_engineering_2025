from sqlalchemy import create_engine, text
import os 
import polars as pl
import requests 

API_PATH = os.environ['API_PATH']
POSTGRES_USER = os.environ['POSTGRES_USER']
POSTGRES_PASSWORD = os.environ['POSTGRES_PASSWORD']
POSTGRES_DB = os.environ['POSTGRES_DB']

POSTGRES_PATH = "db"
POSTGRES_PORT = 5432

DATABASE_URL = f"postgresql+psycopg2://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_PATH}:{POSTGRES_PORT}/{POSTGRES_DB}"

engine = create_engine(DATABASE_URL)

r = requests.get(API_PATH)
data = {k:v for k,v in r.json()["results"][0].items() if k in ["name","location"]}
df = pl.json_normalize(data,separator="_")

# note: if this is the first ingest, then it creates the table.
# this might result in incorrectly inferring some data types, e.g. having a string (zip code, phone number) as int
df.write_database(table_name="users",connection=DATABASE_URL,if_table_exists="append")
