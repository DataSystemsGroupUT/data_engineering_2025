

SELECT
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.City AS CustomerCity,
    p.ProductKey,
    p.ProductName,
    s.StoreKey,
    s.StoreName,
    COUNT(f.SaleID) AS TotalOrders,
    SUM(f.SalesAmount) AS TotalSales,
    MAX(f.FullDate) AS LastOrderDate
FROM `default`.`fact_sales` AS f
LEFT JOIN `default`.`dim_customer` AS c
    ON f.CustomerKey = c.CustomerKey
LEFT JOIN `default`.`dim_product` AS p
    ON f.ProductKey = p.ProductKey
LEFT JOIN `default`.`dim_store` AS s
    ON f.StoreKey = s.StoreKey


  -- Only include new sales since the last run
  WHERE f.FullDate > (SELECT MAX(LastOrderDate) FROM `default`.`cust_sales_detailed_summary`)


GROUP BY
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.City,
    p.ProductKey,
    p.ProductName,
    s.StoreKey,
    s.StoreName