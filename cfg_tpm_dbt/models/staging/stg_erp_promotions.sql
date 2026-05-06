/*
    stg_erp_promotions.sql
    ----------------------
    Staging model for trade promotion transactions from all ERP sources.

    Transformations applied:
    - Filter: removes NULL promotion_id, NULL customer_id, zero/negative prices
    - Type cast: prices to DECIMAL(18,4), dates to DATE, volume to INT
    - Derived: discount_amount calculated from baseline - promotional price
    - Standardise: erp_source UPPER/TRIM

    Note: discount_pct comes pre-calculated from source — validated in tests
*/

WITH source AS (

    SELECT * FROM {{ source('bronze', 'trade_promotions_raw') }}

),

cleaned AS (

    SELECT
        promotion_id,
        customer_id,
        product_id,
        UPPER(TRIM(erp_source))                          AS erp_source,
        promotion_type,

        -- Pricing fields
        CAST(baseline_price AS DECIMAL(18,4))            AS baseline_price,
        CAST(promotional_price AS DECIMAL(18,4))         AS promotional_price,
        CAST(discount_pct AS DECIMAL(10,2))              AS discount_pct,
        ROUND(baseline_price - promotional_price, 4)     AS discount_amount,

        -- Volume and spend
        CAST(volume_units AS INT)                        AS volume_units,
        CAST(trade_spend_amount AS DECIMAL(18,2))        AS trade_spend_amount,
        CAST(volume_uplift_pct AS DECIMAL(10,2))         AS volume_uplift_pct,

        -- Dates
        CAST(transaction_date AS DATE)                   AS transaction_date,
        CAST(promo_start_date AS DATE)                   AS promo_start_date,
        CAST(promo_end_date AS DATE)                     AS promo_end_date,
        approval_status,
        _ingestion_timestamp

    FROM source

    WHERE promotion_id      IS NOT NULL
      AND customer_id       IS NOT NULL
      AND baseline_price    > 0
      AND promotional_price >= 0

)

SELECT * FROM cleaned
