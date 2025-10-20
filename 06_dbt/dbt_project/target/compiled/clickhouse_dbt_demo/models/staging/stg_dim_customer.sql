SELECT
    CustomerKey,
    FirstName,
    LastName,
    Segment,
    City,
    ValidFrom,
    ValidTo
FROM file('/var/lib/clickhouse/user_files/dim_customer.csv')