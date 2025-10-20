
  
    
    
    
        
         


        insert into `default`.`dim_product__dbt_backup`
        ("ProductKey", "ProductName", "Category", "Brand")SELECT
    *
FROM `default`.`stg_dim_product`
  