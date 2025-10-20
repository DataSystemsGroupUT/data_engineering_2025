
  
    
    
    
        
         


        insert into `default`.`fact_sales__dbt_backup`
        ("SaleID", "DateKey", "StoreKey", "ProductKey", "SupplierKey", "CustomerKey", "PaymentKey", "Quantity", "SalesAmount", "FullDate")SELECT
    *
FROM `default`.`stg_fact_sales`
  