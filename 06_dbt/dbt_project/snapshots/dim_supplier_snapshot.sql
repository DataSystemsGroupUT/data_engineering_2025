{% snapshot dim_supplier_snapshot %}
{{ config(
    unique_key='SupplierKey',
    strategy='check',
    check_cols=['SupplierName', 'ContactInfo']
) }}

SELECT
    SupplierKey,
    SupplierName,
    ContactInfo
FROM {{ ref('dim_supplier') }}
{% endsnapshot %}
