CREATE DATABASE IF NOT EXISTS sec_demo;

CREATE TABLE sec_demo.employees
(
    employee_id  UInt32,
    first_name   String,
    last_name    String,
    email        String,         
    phone        String,         
    ssn          String,         
    salary       Decimal(12,2),  
    department   String,
    location     String,
    hire_date    Date,
    birth_date   Date            
)
ENGINE = MergeTree
ORDER BY employee_id
SETTINGS enable_block_number_column = 1, enable_block_offset_column=1;

INSERT INTO sec_demo.employees VALUES
(1001,'Ava','Kask','ava.kask@testcompany.ee','+3725551001','49505122348', 3200.00,'Finance','Tallinn','2021-03-01','1995-05-12'),
(1002,'Marek','Tamm','marek.tamm@testcompany.ee','+3725551002','39008234561', 4200.00,'Engineering','Tartu','2019-10-15','1990-08-23'),
(1003,'Liisa','Puu','liisa.puu@testcompany.ee','+3725551003','49301043458', 3900.00,'Sales','Tallinn','2020-06-10','1993-01-04'),
(1004,'Karl','Mets','karl.mets@testcompany.ee','+3725551004','38812304564', 2900.00,'Engineering','Tallinn','2018-02-20','1988-12-30'),
(1005,'Helena','Saar','helena.saar@testcompany.ee','+3725551005','49704182347', 3800.00,'HR','Narva','2022-09-05','1997-04-18');
