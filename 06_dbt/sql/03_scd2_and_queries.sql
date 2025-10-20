-- 1) Expire Alice's current row (mutation = async background rewrite)
ALTER TABLE supermarket.DimCustomer
  UPDATE ValidTo = toDate('2025-09-20')
  WHERE CustomerID = 1 AND ValidTo = toDate('9999-12-31');

-- Optional: watch mutation progress (run until is_done = 1)
-- SELECT table, command, is_done, latest_failed_part
-- FROM system.mutations
-- WHERE database = 'supermarket' AND table = 'DimCustomer';

-- 2) Insert new current row with a new surrogate key (3)
INSERT INTO supermarket.DimCustomer (
  CustomerKey, CustomerID, FirstName, LastName, Segment, City, ValidFrom, ValidTo
) VALUES (
  3, 1, 'Alice', 'Smith', 'Regular', 'Tartu', toDate('2025-09-21'), toDate('9999-12-31')
);

-- 3) New sale after the move (ETL should link to the NEW surrogate key = 3)
INSERT INTO supermarket.FactSales (
  SaleID, DateKey, StoreKey, ProductKey, SupplierKey, CustomerKey, PaymentKey, Quantity, SalesAmount, FullDate
) VALUES (
  7, 4, 2, 2, 2, 3, 2, 4, toDecimal32(3.20, 2), toDate('2025-09-21')
);

-- Verify SCD correctness
SELECT c.City, sum(f.SalesAmount) AS TotalSales
FROM supermarket.FactSales f
JOIN supermarket.DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY c.City
ORDER BY TotalSales DESC;

-- Show Alice's history
SELECT * FROM supermarket.DimCustomer
WHERE CustomerID = 1
ORDER BY ValidFrom;
