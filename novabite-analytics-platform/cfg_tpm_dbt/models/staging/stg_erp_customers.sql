/*
    stg_erp_customers.sql
    ----------------------
    Staging model for customer master data from all ERP sources.

    Transformations applied:
    - Filter: removes records with NULL customer_id (data quality gate)
    - Standardise: UPPER/TRIM on name and territory fields
    - Type cast: credit_limit to DECIMAL, created_date to DATE
    - Default: COALESCE payment_terms to 'UNKNOWN' where missing

    Source: main.cfg_tpm_bronze.erp_customers_raw
    Materialization: view (lightweight — no storage cost)
*/

WITH source AS (

    SELECT * FROM {{ source('bronze', 'erp_customers_raw') }}

),

cleaned AS (

    SELECT
        customer_id,
        UPPER(TRIM(customer_name))           AS customer_name,
        LOWER(TRIM(email))                   AS email,
        COALESCE(payment_terms, 'UNKNOWN')   AS payment_terms,
        CAST(credit_limit AS DECIMAL(18,2))  AS credit_limit,
        UPPER(TRIM(sales_territory))         AS sales_territory,
        UPPER(TRIM(erp_source))              AS erp_source,
        CAST(created_date AS DATE)           AS created_date,
        _ingestion_timestamp

    FROM source

    -- Data quality gate: remove records with no customer identifier
    WHERE customer_id IS NOT NULL

)

SELECT * FROM cleaned
