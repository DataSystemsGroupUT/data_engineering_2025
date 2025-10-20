SELECT
    *
FROM {{ ref('stg_fact_sales') }}
