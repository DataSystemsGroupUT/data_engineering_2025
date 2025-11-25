DROP DATABASE IF EXISTS supermarket;

CREATE DATABASE supermarket;

-- ========== Dimensions ==========
CREATE TABLE supermarket.DimDate (
    DateKey   UInt32 ,
    FullDate  Date ,
    Year      UInt16 ,
    Month     UInt8 ,
    Day       UInt8 ,
    DayOfWeek String 
) ENGINE = MergeTree
ORDER BY (DateKey);

CREATE TABLE supermarket.DimStore (
    StoreKey  UInt32,
    StoreName String,
    City      String,
    Region    String
) ENGINE = MergeTree
ORDER BY (StoreKey);

CREATE TABLE supermarket.DimProduct (
    ProductKey   UInt32,
    ProductName  String,
    Category     String,
    Brand        String
) ENGINE = MergeTree
ORDER BY (ProductKey);

CREATE TABLE supermarket.DimSupplier (
    SupplierKey  UInt32,
    SupplierName String,
    ContactInfo  String
) ENGINE = MergeTree
ORDER BY (SupplierKey);

-- SCD2-friendly dimension: surrogate key (CustomerKey) + business key (CustomerID)
CREATE TABLE supermarket.DimCustomer (
    CustomerKey  UInt32,  -- surrogate key (unique per version)
    CustomerID   UInt32,  -- stable business key
    FirstName    String,
    LastName     String,
    Segment      String,
    City         String,
    ValidFrom    Date,
    ValidTo      Date
) ENGINE = MergeTree
ORDER BY (CustomerKey);

CREATE TABLE supermarket.DimPayment (
    PaymentKey  UInt32,
    PaymentType String
) ENGINE = MergeTree
ORDER BY (PaymentKey);

-- ========== Fact ==========
-- Denormalize FullDate onto fact for partitioning and fast time filtering.
CREATE TABLE supermarket.FactSales (
    SaleID         UInt64,
    DateKey        UInt32,
    StoreKey       UInt32,
    ProductKey     UInt32,
    SupplierKey    UInt32,
    CustomerKey    UInt32,
    PaymentKey     UInt32,
    Quantity       UInt16,
    SalesAmount    Decimal(10,2),
    FullDate       Date
) ENGINE = MergeTree
PARTITION BY toYYYYMM(FullDate)
ORDER BY (FullDate, StoreKey, ProductKey);
