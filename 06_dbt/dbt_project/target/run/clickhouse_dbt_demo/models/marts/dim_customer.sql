
  
    
    
    
        
         


        insert into `default`.`dim_customer__dbt_backup`
        ("CustomerKey", "FirstName", "LastName", "Segment", "City", "ValidFrom", "ValidTo")SELECT
    CustomerKey,
    FirstName,
    LastName,
    Segment,
    City,
    ValidFrom,
    ValidTo
FROM `default`.`stg_dim_customer`
  