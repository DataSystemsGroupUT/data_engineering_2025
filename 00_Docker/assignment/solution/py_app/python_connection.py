from sqlalchemy import create_engine, text
import os 

POSTGRES_USER = os.environ['POSTGRES_USER']
POSTGRES_PASSWORD = os.environ['POSTGRES_PASSWORD']
POSTGRES_DB = os.environ['POSTGRES_DB']

POSTGRES_PATH = "db"
POSTGRES_PORT = 5432

# Replace with your actual database credentials
DATABASE_URL = f"postgresql+psycopg2://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_PATH}:{POSTGRES_PORT}/{POSTGRES_DB}"

# Create an engine
engine = create_engine(DATABASE_URL)

with engine.connect() as connection:

    result = connection.execute(text("SELECT datname FROM pg_database;"))

    for row in result:
        print(row)
        
    # # the following will work if you have created the countries table
    # result = connection.execute(text("SELECT * FROM countries WHERE name = :name"), {"name":"Estonia"})

    # for row in result:
    #     print(row)
    #     break