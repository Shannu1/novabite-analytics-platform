/*
    snap_customer_master.sql
    ------------------------
    SCD Type 2 snapshot for customer master data.

    Tracks changes to: payment_terms, credit_limit, sales_territory, status
    Strategy: check — compares column values, not timestamps
    dbt adds: __START_AT, __END_AT (NULL = current record), dbt_scd_id, dbt_updated_at

    Why check over timestamp?
    - ERP systems don't always update timestamps reliably
    - check strategy compares actual column values — more reliable for this use case

    Usage:
    -- Current records:   WHERE __END_AT IS NULL
    -- Historical query:  WHERE __START_AT <= '2024-06-01' AND (__END_AT > '2024-06-01' OR __END_AT IS NULL)
*/

{% snapshot snap_customer_master %}

{{
    config(
      target_schema='cfg_tpm_snapshots',
      unique_key='customer_id',
      strategy='check',
      check_cols=[
          'payment_terms',
          'credit_limit',
          'sales_territory',
          'credit_tier',
          'status'
      ],
      invalidate_hard_deletes=True
    )
}}

SELECT
    customer_id,
    customer_name,
    email,
    payment_terms,
    credit_limit,
    sales_territory,
    credit_tier,
    erp_source,
    created_date,
    'ACTIVE'            AS status,
    _ingestion_timestamp AS updated_at
FROM {{ ref('int_customers_unified') }}

{% endsnapshot %}
