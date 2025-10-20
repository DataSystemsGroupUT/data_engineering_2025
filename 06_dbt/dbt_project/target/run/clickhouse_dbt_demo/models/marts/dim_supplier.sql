
  
    
    
    
        
         


        insert into `default`.`dim_supplier__dbt_backup`
        ("SupplierKey", "SupplierName", "ContactInfo")SELECT
    *
FROM `default`.`stg_dim_supplier`
  