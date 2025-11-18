DROP DATABASE IF EXISTS supermarket;

CREATE DATABASE supermarket;

-- ========== Dimensions ==========
CREATE TABLE supermarket.DimDate (
    DateKey   UInt32 COMMENT 'This is typically in the format YYYYMMDD',
    FullDate  Date COMMENT 'This is in date format for easier parsing by BI/ML tools.',
    Year      UInt16 COMMENT 'This is the year, for example ''2025''',
    Month     UInt8 COMMENT 'This is the month, for example ''12''',
    Day       UInt8 COMMENT 'This is the day of the month, for example ''31''',
    DayOfWeek String COMMENT 'This is the day of the week, 1-7 (1=Monday, 7=Sunday)'
) ENGINE = MergeTree
ORDER BY (DateKey)
COMMENT 'DimDate is the teacher''s favourite table';

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
