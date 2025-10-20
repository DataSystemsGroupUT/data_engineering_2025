
  
    
    
    
        
         


        insert into `default`.`dim_store__dbt_backup`
        ("StoreKey", "StoreName", "City", "Region")SELECT
    *
FROM `default`.`stg_dim_store`
  