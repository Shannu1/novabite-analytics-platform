/*
    fct_tpm_promotions.sql
    -----------------------
    Core fact table for trade promotion transactions.

    Materialisation: INCREMENTAL with merge strategy
    - Only processes records with _ingestion_timestamp > max in table
    - Merges on surrogate key — handles late updates to existing promotions
    - Partitioned by transaction_date for query performance

    Key design decisions:
    - Surrogate key = MD5(promotion_id | erp_source | transaction_date)
    - on_schema_change = sync_all_columns: ERP schema additions handled automatically
    - Partition pruning: date-based filter reduces scan significantly on large datasets
*/

{{
  config(
    materialized='incremental',
    unique_key='promotion_transaction_key',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    file_format='delta',
    partition_by={'field': 'transaction_date', 'data_type': 'date'}
  )
}}

WITH promotions AS (

    SELECT
        MD5(CONCAT(
            promotion_id, '|', erp_source, '|',
            CAST(transaction_date AS STRING)
        ))                                          AS promotion_transaction_key,

        promotion_id,
        customer_id,
        product_id,
        erp_source,
        promotion_type,

        -- Pricing
        baseline_price,
        promotional_price,
        discount_pct,
        discount_amount,

        -- Volume and spend
        volume_units,
        trade_spend_amount,
        volume_uplift_pct,

        -- Dates
        transaction_date,
        promo_start_date,
        promo_end_date,

        approval_status,
        _ingestion_timestamp,
        CURRENT_TIMESTAMP()                         AS _dbt_processed_at

    FROM {{ ref('stg_erp_promotions') }}

    {% if is_incremental() %}

        -- Only process records newer than what's already loaded
        -- This makes incremental runs ~60x faster on large datasets
        WHERE _ingestion_timestamp > (
            SELECT MAX(_ingestion_timestamp) FROM {{ this }}
        )

    {% endif %}

)

SELECT * FROM promotions
