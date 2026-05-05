/*
    snap_product_pricing.sql
    ------------------------
    SCD Type 2 snapshot for product pricing per ERP source.

    Tracks changes to: list_price, cost_price, price_list_code
    Each ERP has slightly different prices — tracked separately per ERP.
*/

{% snapshot snap_product_pricing %}

{{
    config(
      target_schema='cfg_tpm_snapshots',
      unique_key='price_list_id',
      strategy='check',
      check_cols=['list_price', 'cost_price', 'price_list_code']
    )
}}

SELECT
    price_list_id,
    product_id,
    erp_source,
    price_list_code,
    list_price,
    cost_price,
    currency,
    effective_from,
    _ingestion_timestamp AS updated_at
FROM {{ source('bronze', 'price_list_raw') }}

{% endsnapshot %}
