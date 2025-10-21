{{ config(
    materialized='incremental',
    unique_key='CustomerKey',
    incremental_strategy='append'
) }}

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
FROM {{ ref('fact_sales') }} AS f
LEFT JOIN {{ ref('dim_customer') }} AS c
    ON f.CustomerKey = c.CustomerKey
LEFT JOIN {{ ref('dim_product') }} AS p
    ON f.ProductKey = p.ProductKey
LEFT JOIN {{ ref('dim_store') }} AS s
    ON f.StoreKey = s.StoreKey

{% if is_incremental() %}
WHERE f.FullDate > (SELECT max(LastOrderDate) FROM {{ this }})
{% endif %}

GROUP BY
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.City,
    p.ProductKey,
    p.ProductName,
    s.StoreKey,
    s.StoreName
