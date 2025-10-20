
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select FullDate
from `default`.`fact_sales`
where FullDate is null



  
  
    ) dbt_internal_test