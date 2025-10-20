
  
    
    
    
        
         


        insert into `default`.`dim_payment__dbt_backup`
        ("ProductKey", "ProductName", "Category", "Brand")SELECT
    *
FROM `default`.`stg_dim_product`
  