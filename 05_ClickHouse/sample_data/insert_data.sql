/*
-- This is the single setup script.
-- It will be executed in batch mode.
-- We add 'IF NOT EXISTS' to make it safe to re-run.
*/

CREATE DATABASE IF NOT EXISTS supermarket;

-- Dimension Tables
CREATE TABLE IF NOT EXISTS supermarket.DimDate (
    DateKey         UInt32,
    FullDate        Date,
    Year            UInt16,
    Month           UInt8,
    Day             UInt8,
    DayOfWeek       String
) ENGINE = MergeTree()
ORDER BY (DateKey);

CREATE TABLE IF NOT EXISTS supermarket.DimStore (
    StoreKey        UInt32,
    StoreName       String,
    City            String,
    Region          String
) ENGINE = MergeTree()
ORDER BY (StoreKey);

CREATE TABLE IF NOT EXISTS supermarket.DimProduct (
    ProductKey      UInt32,
    ProductName     String,
    Category        String,
    Brand           String
) ENGINE = MergeTree()
ORDER BY (ProductKey);

CREATE TABLE IF NOT EXISTS supermarket.DimSupplier (
    SupplierKey     UInt32,
    SupplierName    String,
    ContactInfo     String
) ENGINE = MergeTree()
ORDER BY (SupplierKey);

CREATE TABLE IF NOT EXISTS supermarket.DimCustomer (
    CustomerSurrKey UInt32,
    CustomerID      UInt32,
    FullName        String,
    City            String,
    ValidFrom       Date,
    ValidTo         Date
) ENGINE = MergeTree()
ORDER BY (CustomerSurrKey);

-- Fact Table
CREATE TABLE IF NOT EXISTS supermarket.FactSales (
    SalesKey        UInt64,
    DateKey         UInt32,
    CustomerSurrKey UInt32,
    ProductKey      UInt32,
    StoreKey        UInt32,
    SupplierKey     UInt32,
    QuantitySold    UInt16,
    SalesAmount     Decimal(10, 2),
    FullDate        Date
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(FullDate)
ORDER BY (FullDate, StoreKey, ProductKey);

-- Clear out any partial data from previous failed runs.
TRUNCATE TABLE supermarket.DimDate;
TRUNCATE TABLE supermarket.DimStore;
TRUNCATE TABLE supermarket.DimProduct;
TRUNCATE TABLE supermarket.DimSupplier;
TRUNCATE TABLE supermarket.DimCustomer;
TRUNCATE TABLE supermarket.FactSales;

-- Now, insert all data in one go.
INSERT INTO supermarket.DimDate FORMAT CSVWithNames FROM file('dim_date.csv');
INSERT INTO supermarket.DimStore FORMAT CSVWithNames FROM file('dim_store.csv');
INSERT INTO supermarket.DimProduct FORMAT CSVWithNames FROM file('dim_product.csv');
INSERT INTO supermarket.DimSupplier FORMAT CSVWithNames FROM file('dim_supplier.csv');
INSERT INTO supermarket.DimCustomer FORMAT CSVWithNames FROM file('dim_customer.csv');
INSERT INTO supermarket.FactSales FORMAT CSVWithNames FROM file('fact_sales.csv');