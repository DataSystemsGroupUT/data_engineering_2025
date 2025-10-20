SELECT
    CustomerKey,
    FirstName,
    LastName,
    Segment,
    City,
    ValidFrom,
    ValidTo
FROM {{ ref('stg_dim_customer') }}
