
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select SaleID
from `default`.`fact_sales`
where SaleID is null



  
  
    ) dbt_internal_test