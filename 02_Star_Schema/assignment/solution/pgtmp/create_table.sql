CREATE TABLE DimDate (
    DateKey SERIAL PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT,
    Month INT,
    Day INT,
    DayOfWeek VARCHAR(10)
);

CREATE TABLE DimStore (
    StoreKey SERIAL PRIMARY KEY,
    StoreName VARCHAR(100),
    City VARCHAR(50),
    Region VARCHAR(50)
);

CREATE TABLE DimProduct (
    ProductKey SERIAL PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Brand VARCHAR(50)
);

CREATE TABLE DimSupplier (
    SupplierKey SERIAL PRIMARY KEY,
    SupplierName VARCHAR(100),
    ContactInfo VARCHAR(255)
);

CREATE TABLE DimCustomer (
    CustomerKey INT NOT NULL,         -- stable business key
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Segment VARCHAR(50),
    City VARCHAR(50),
    ValidFrom DATE,
    ValidTo DATE
);

CREATE TABLE DimPayment (
    PaymentKey SERIAL PRIMARY KEY,
    PaymentType VARCHAR(20)
);

CREATE TABLE FactSales (
    SaleID SERIAL PRIMARY KEY,
    DateKey INT REFERENCES DimDate(DateKey),
    StoreKey INT REFERENCES DimStore(StoreKey),
    ProductKey INT REFERENCES DimProduct(ProductKey),
    SupplierKey INT REFERENCES DimSupplier(SupplierKey),
    CustomerKey INT,
    PaymentKey INT REFERENCES DimPayment(PaymentKey),
    Quantity INT,
    SalesAmount NUMERIC(10,2)
);