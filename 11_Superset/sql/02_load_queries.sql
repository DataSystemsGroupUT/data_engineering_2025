-- Dimensions
INSERT INTO supermarket.DimDate
SELECT toUInt32(DateKey), toDate(FullDate), toUInt16(Year), toUInt8(Month), toUInt8(Day), toString(DayOfWeek)
FROM file('dim_date.csv', 'CSVWithNames');

INSERT INTO supermarket.DimStore
SELECT toUInt32(StoreKey), toString(StoreName), toString(City), toString(Region)
FROM file('dim_store.csv', 'CSVWithNames');

INSERT INTO supermarket.DimProduct
SELECT toUInt32(ProductKey), toString(ProductName), toString(Category), toString(Brand)
FROM file('dim_product.csv', 'CSVWithNames');

INSERT INTO supermarket.DimSupplier
SELECT toUInt32(SupplierKey), toString(SupplierName), toString(ContactInfo)
FROM file('dim_supplier.csv', 'CSVWithNames');

INSERT INTO supermarket.DimCustomer
SELECT toUInt32(CustomerKey), toUInt32(CustomerID), toString(FirstName), toString(LastName),
       toString(Segment), toString(City), toDate(ValidFrom), toDate(ValidTo)
FROM file('dim_customer.csv', 'CSVWithNames');

INSERT INTO supermarket.DimPayment
SELECT toUInt32(PaymentKey), toString(PaymentType)
FROM file('dim_payment.csv', 'CSVWithNames');

-- Fact
INSERT INTO supermarket.FactSales
SELECT toUInt64(SaleID), toUInt32(DateKey), toUInt32(StoreKey), toUInt32(ProductKey), toUInt32(SupplierKey),
       toUInt32(CustomerKey), toUInt32(PaymentKey), toUInt16(Quantity), toDecimal32(SalesAmount, 2), toDate(FullDate)
FROM file('fact_sales.csv', 'CSVWithNames');

-- Quick verification
SELECT 'DimDate' AS table_name, count() AS rows FROM supermarket.DimDate
UNION ALL SELECT 'DimStore', count() FROM supermarket.DimStore
UNION ALL SELECT 'DimProduct', count() FROM supermarket.DimProduct
UNION ALL SELECT 'DimSupplier', count() FROM supermarket.DimSupplier
UNION ALL SELECT 'DimCustomer', count() FROM supermarket.DimCustomer
UNION ALL SELECT 'DimPayment', count() FROM supermarket.DimPayment
UNION ALL SELECT 'FactSales', count() FROM supermarket.FactSales;
