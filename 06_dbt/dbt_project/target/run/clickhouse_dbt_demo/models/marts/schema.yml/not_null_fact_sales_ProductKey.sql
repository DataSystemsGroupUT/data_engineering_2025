
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select ProductKey
from `default`.`fact_sales`
where ProductKey is null



  
  
    ) dbt_internal_test