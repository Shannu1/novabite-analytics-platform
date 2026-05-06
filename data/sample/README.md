# Sample Data

Sample CSV files simulating raw ERP Bronze layer data for NovaBite Foods Group.

## Files

| File | Description | Rows |
|------|-------------|------|
| bronze_customers_nav1.csv | NAV1 customers — North England | 4 |
| bronze_customers_nav2.csv | NAV2 customers — Midlands | 4 |
| bronze_customers_all_erps.csv | M3_V133 / CloudSuite / TROPOS customers | 6 |
| bronze_trade_promotions.csv | Promotion transactions across all ERPs | 30 |
| bronze_customer_changes.csv | SCD2 test data — customer attribute changes | 6 |

## Known Anomalies (for MLflow anomaly detection testing)
- PROMO00016: 50% discount on NAV1 — above normal approval threshold
- PROMO00024: 60% discount on NAV2 with negative volume uplift — clear anomaly
- PROMO00030: 50% discount M3_V133 with very low volume uplift

## SCD2 Test Changes
- CUST002: payment_terms NET45 to NET30 on 2024-07-15
- CUST010: payment_terms NET60 to NET45 on 2024-09-01
- CUST004: sales_territory UK_NORTH to UK_MIDLANDS on 2024-05-01
