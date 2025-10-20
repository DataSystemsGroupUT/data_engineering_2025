SELECT *
FROM {{ ref('cust_sales_detailed_summary') }}
WHERE TotalSales < 0