### Assignment

You need to setup a Postgres database.  
You will start pulling user data from an API into this database.  
The user data has incorrect coordinates, which you can fix using a static countries' dataset.

The assignment is separated into following levels.  
Everyone should at least finish level 1.   
If you reach level 5 during the allotted time, you may earn bonus points towards the course grade.

#### Level 1
You have a Docker Compose file that has three services:  
* Postgres database, version 16.4
* Python 3.12.5
* pgAdmin version 8.10 or greater 

All of the services start and run successfully.

#### Level 2 
You can access Postgres from pgAdmin UI.  
You can access Postgres from the Python container using the Python package SQLAlchemy version 2.0.34 or greater.

#### Level 3 
Create a `countries` table based on the data from this csv file:   
`https://github.com/dr5hn/countries-states-cities-database/blob/master/csv/countries.csv`

Create the table beforehand and use the Postgres `COPY` function to load the data into the table.

#### Level 4
Create a Python script that extracts user data from this API:   
`https://randomuser.me/api/`

Flatten the following fields and the associated subfields to tabular form and ingest them into the database `users` table:  
`name`  
`location`

Concatenate subfields with `_`, e.g., `location_city`.

Create the `users` table if it doesn't exist.

#### Level 5
Create a database view that joins the `countries` and `users` tables.   
The view should contain the `name` fields, `country`, and coordinates from both tables.
