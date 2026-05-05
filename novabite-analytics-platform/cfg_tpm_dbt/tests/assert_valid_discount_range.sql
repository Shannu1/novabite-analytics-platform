/*
    assert_valid_discount_range.sql
    --------------------------------
    Custom singular test: ensures no promotion has a discount outside 0-100%.
    Negative discounts or discounts > 100% indicate data entry errors in source ERP.
    Returns rows where the assertion FAILS — dbt fails the test if any rows returned.
*/

SELECT
    promotion_id,
    erp_source,
    discount_pct,
    'Discount outside valid range 0-100%' AS failure_reason
FROM {{ ref('stg_erp_promotions') }}
WHERE discount_pct < 0
   OR discount_pct > 100
