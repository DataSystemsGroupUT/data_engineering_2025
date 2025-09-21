-- FactSales automatically references the correct CustomerKey at transaction time
INSERT INTO FactSales (DateKey, StoreKey, ProductKey, SupplierKey, CustomerKey, PaymentKey, Quantity, SalesAmount)
VALUES (3, 2, 2, 2, 3, 2, 4, 4*0.8);