-- Daily & Monthly sales by store
-- Daily
SELECT d.FullDate, s.StoreName, sum(f.SalesAmount) AS DailySales
FROM supermarket.FactSales f
JOIN supermarket.DimDate  d ON f.DateKey  = d.DateKey
JOIN supermarket.DimStore s ON f.StoreKey = s.StoreKey
GROUP BY d.FullDate, s.StoreName
ORDER BY d.FullDate, s.StoreName;

-- Monthly
SELECT d.Year, d.Month, s.StoreName, sum(f.SalesAmount) AS MonthlySales
FROM supermarket.FactSales f
JOIN supermarket.DimDate  d ON f.DateKey  = d.DateKey
JOIN supermarket.DimStore s ON f.StoreKey = s.StoreKey
GROUP BY d.Year, d.Month, s.StoreName
ORDER BY d.Year, d.Month, s.StoreName;


-- Total sales by product category
SELECT p.Category, sum(f.SalesAmount) AS TotalSales
FROM supermarket.FactSales f
JOIN supermarket.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY TotalSales DESC;

-- Top 5 products by sales
SELECT p.ProductName, sum(f.SalesAmount) AS TotalSales
FROM supermarket.FactSales f
JOIN supermarket.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY TotalSales DESC
LIMIT 5;
-- Top 5 suppliers by sales
SELECT sp.SupplierName, sum(f.SalesAmount) AS TotalSales
FROM supermarket.FactSales f
JOIN supermarket.DimSupplier sp ON f.SupplierKey = sp.SupplierKey
GROUP BY sp.SupplierName
ORDER BY TotalSales DESC
LIMIT 5;

-- Average basket size (quantity) by customer per day
SELECT c.CustomerID, d.FullDate, avg(f.Quantity) AS AvgBasketSize
FROM supermarket.FactSales f
JOIN supermarket.DimCustomer c ON f.CustomerKey = c.CustomerKey
JOIN supermarket.DimDate     d ON f.DateKey     = d.DateKey
GROUP BY c.CustomerID, d.FullDate
ORDER BY c.CustomerID, d.FullDate;
