
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select StoreKey
from `default`.`fact_sales`
where StoreKey is null



  
  
    ) dbt_internal_test