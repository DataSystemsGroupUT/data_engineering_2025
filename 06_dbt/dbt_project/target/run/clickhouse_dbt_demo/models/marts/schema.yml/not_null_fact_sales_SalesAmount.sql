
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select SalesAmount
from `default`.`fact_sales`
where SalesAmount is null



  
  
    ) dbt_internal_test