
  
    
    
    
        
         


        insert into `default`.`dim_date__dbt_backup`
        ("DateKey", "FullDate", "Year", "Month", "Day", "DayOfWeek")SELECT
    *
FROM `default`.`stg_dim_date`
  