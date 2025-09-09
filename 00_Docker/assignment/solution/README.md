### Solution

#### Level 1
`compose.yml`

#### Level 2 
Login to pgAdmin (http://localhost:5050/).  
Credentials are in `.env`.  
* `Add new server`
* Give a name as you would like
* Under `Connection` tab, Host is the container name (`db`), Username and Password are in `.env`.

For access via the python container, you can first install the requirements:
`docker exec -it py bash -c "pip install -r /scripts/requirements.txt"`  
And then run the test script for connection:  
`docker exec -it py bash -c "python /scripts/python_connection.py"`

#### Level 3
Create the table: 
`docker exec -it db bash -c "psql -f /tmp/create_table.sql"`
Copy the data from the csv file:  
`docker exec -it db bash -c "psql -f /tmp/copy_countries.sql"`

#### Level 4
Run the ingest script:  


#### Level 5
Create the view as in `pgtmp/create_view.sql`.

