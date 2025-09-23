-- DimDate
INSERT INTO DimDate (FullDate, Year, Month, Day, DayOfWeek)
VALUES 
('2025-09-18', 2025, 9, 18, 'Thursday'),
('2025-09-19', 2025, 9, 19, 'Friday'),
('2025-09-20', 2025, 9, 20, 'Saturday');

-- DimStore
INSERT INTO DimStore (StoreName, City, Region)
VALUES
('SuperMart Downtown', 'Tallinn', 'North'),
('SuperMart Suburb', 'Tartu', 'South');

-- DimProduct
INSERT INTO DimProduct (ProductName, Category, Brand)
VALUES
('Apple', 'Fruit', 'FreshFarm'),
('Banana', 'Fruit', 'Tropicana'),
('Milk', 'Dairy', 'DairyBest'),
('Bread', 'Bakery', 'BakeHouse');

-- DimSupplier
INSERT INTO DimSupplier (SupplierName, ContactInfo)
VALUES
('FreshFarm Supplier', 'fresh@farm.com'),
('Tropicana Supplier', 'contact@tropicana.com'),
('DairyBest Supplier', 'sales@dairybest.com'),
('BakeHouse Supplier', 'info@bakehouse.com');

--dimcustomer
INSERT INTO DimCustomer (CustomerKey, FirstName, LastName, Segment, City, ValidFrom, ValidTo)
VALUES
(1, 'Alice', 'Smith', 'Regular', 'Tallinn', '2025-01-01', '9999-12-31'),
(2, 'Bob', 'Jones', 'VIP', 'Tartu', '2025-01-01', '9999-12-31');

-- DimPayment
INSERT INTO DimPayment (PaymentType)
VALUES
('Cash'), ('Card'), ('Voucher');

-- FactSales
INSERT INTO FactSales (DateKey, StoreKey, ProductKey, SupplierKey, CustomerKey, PaymentKey, Quantity, SalesAmount)
VALUES
(1, 1, 1, 1, 1, 2, 5, 5*1.2),
(1, 1, 2, 2, 1, 1, 3, 3*0.8),
(2, 2, 3, 3, 2, 2, 2, 2*2.5),
(2, 2, 4, 4, 2, 2, 1, 1*1.5),
(3, 1, 1, 1, 2, 1, 10, 10*1.2),
(3, 1, 3, 3, 1, 2, 1, 1*2.5);
