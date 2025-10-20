
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select CustomerKey
from `default`.`fact_sales`
where CustomerKey is null



  
  
    ) dbt_internal_test