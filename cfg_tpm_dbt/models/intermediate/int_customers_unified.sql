/*
    int_customers_unified.sql
    --------------------------
    Unifies customer master data across all ERP sources.
    Generates surrogate key to handle same customer appearing in multiple ERPs.
    Adds business-derived fields: payment_days, credit_tier.
*/

WITH staged AS (

    SELECT * FROM {{ ref('stg_erp_customers') }}

),

enriched AS (

    SELECT
        -- Surrogate key: unique per customer per ERP source
        MD5(CONCAT(customer_id, '|', erp_source))  AS customer_key,

        customer_id,
        customer_name,
        email,
        payment_terms,
        credit_limit,
        sales_territory,
        erp_source,
        created_date,

        -- Derived: numeric payment days for calculations
        CASE payment_terms
            WHEN 'NET30' THEN 30
            WHEN 'NET45' THEN 45
            WHEN 'NET60' THEN 60
            ELSE NULL
        END                                         AS payment_days,

        -- Derived: credit tier classification
        CASE
            WHEN credit_limit >= 500000 THEN 'PLATINUM'
            WHEN credit_limit >= 200000 THEN 'GOLD'
            WHEN credit_limit >= 100000 THEN 'SILVER'
            ELSE 'STANDARD'
        END                                         AS credit_tier,

        _ingestion_timestamp,
        CURRENT_TIMESTAMP()                         AS _dbt_processed_at

    FROM staged

)

SELECT * FROM enriched
