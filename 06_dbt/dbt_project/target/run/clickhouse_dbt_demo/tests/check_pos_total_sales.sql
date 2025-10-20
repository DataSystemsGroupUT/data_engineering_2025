
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  SELECT *
FROM `default`.`cust_sales_detailed_summary`
WHERE TotalSales < 0
  
  
    ) dbt_internal_test