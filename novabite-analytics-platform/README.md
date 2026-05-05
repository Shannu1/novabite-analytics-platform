#  NovaBite Analytics Platform — dbt on Databricks

![dbt](https://img.shields.io/badge/dbt-1.8-orange?logo=dbt)
![Databricks](https://img.shields.io/badge/Databricks-Unity%20Catalog-red?logo=databricks)
![Delta Lake](https://img.shields.io/badge/Delta%20Lake-3.0-blue)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-green?logo=githubactions)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)

A production-style analytics engineering platform built with **dbt Core on Databricks**, implementing a fully tested, documented, and CI/CD-deployed transformation layer over a multi-ERP data source — mirroring the architecture patterns used in real enterprise food manufacturing data platforms.

---

##  Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SOURCE LAYER                            │
│   NAV1 · NAV2 · M3_V133 · CloudSuite · TROPOS · Sage       │
│              (5 ERP systems, 12 sites)                      │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  BRONZE — Delta Lake                        │
│         Raw ingestion via ADF / Auto Loader                 │
│         Immutable · Schema-on-read · Full history           │
└──────────────────────────┬──────────────────────────────────┘
                           ↓ dbt run
┌─────────────────────────────────────────────────────────────┐
│               SILVER — dbt Staging Models                   │
│   stg_erp_customers · stg_erp_promotions · stg_products     │
│   Cleaned · Typed · Validated · Null-filtered               │
└──────────────────────────┬──────────────────────────────────┘
                           ↓ dbt run
┌─────────────────────────────────────────────────────────────┐
│            INTERMEDIATE — dbt Models                        │
│   int_customers_unified · int_promotions_enriched           │
│   Cross-ERP harmonisation · Surrogate keys · Credit tiers   │
└──────────────────────────┬──────────────────────────────────┘
                           ↓ dbt run
┌─────────────────────────────────────────────────────────────┐
│               GOLD — dbt Marts + Snapshots                  │
│   fct_tpm_promotions (incremental)                         │
│   dim_customer (from SCD2 snapshot)                        │
│   snap_customer_master · snap_product_pricing               │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  CONSUMPTION LAYER                          │
│         Power BI · Reporting teams · Analytics              │
└─────────────────────────────────────────────────────────────┘
```

---

##  Project Structure

```
novabite-analytics-platform/
├── .github/
│   └── workflows/
│       └── dbt_ci.yml              # CI: runs dbt tests on every PR
├── cfg_tpm_dbt/
│   ├── models/
│   │   ├── staging/
│   │   │   ├── sources.yml         # Bronze Delta table declarations
│   │   │   ├── schema.yml          # Staging model tests & docs
│   │   │   ├── stg_erp_customers.sql
│   │   │   └── stg_erp_promotions.sql
│   │   ├── intermediate/
│   │   │   ├── schema.yml
│   │   │   └── int_customers_unified.sql
│   │   └── marts/
│   │       ├── schema.yml
│   │       └── fct_tpm_promotions.sql  # incremental, merge strategy
│   ├── snapshots/
│   │   ├── snap_customer_master.sql    # SCD2 — payment terms, credit limit
│   │   └── snap_product_pricing.sql   # SCD2 — price changes per ERP
│   ├── tests/
│   │   └── assert_positive_discount.sql
│   ├── macros/
│   │   └── generate_surrogate_key.sql
│   ├── seeds/
│   │   └── erp_source_lookup.csv
│   ├── dbt_project.yml
│   └── packages.yml
├── data/
│   └── sample/                     # Sample CSV data for local testing
│       ├── bronze_customers_nav1.csv
│       ├── bronze_customers_nav2.csv
│       ├── bronze_trade_promotions.csv
│       └── README.md
├── docs/
│   ├── architecture.png
│   └── lineage_dag.png
└── README.md
```

---

## Data Quality Tests

| Model | Tests | Coverage |
|-------|-------|----------|
| stg_erp_customers | not_null(customer_id), unique(customer_id), accepted_values(erp_source), not_null(customer_name) | Primary key + ERP validation |
| stg_erp_promotions | not_null(promotion_id), unique(promotion_id), not_null(customer_id), relationships(→ customers), not_null(baseline_price) | Referential integrity |
| int_customers_unified | not_null(customer_key), unique(customer_key), not_null(erp_source) | Surrogate key integrity |
| fct_tpm_promotions | not_null(promotion_transaction_key), unique(promotion_transaction_key) | Fact table uniqueness |
| assert_positive_discount | Custom SQL: discount_pct BETWEEN 0 AND 100 | Business rule validation |

**15+ tests total · GitHub Actions runs all tests on every PR**

---

## Key Technical Decisions

| Decision | Approach | Why |
|----------|----------|-----|
| SCD2 | dbt snapshots (check strategy) | Replaces 60+ lines of manual PySpark MERGE — 10 lines of config, automatic __START_AT/__END_AT management |
| Incremental strategy | merge on unique_key | Handles late-arriving ERP data correctly; avoids rebuilding 1M+ row table daily |
| Surrogate keys | MD5(customer_id \| erp_source) | Same customer exists in multiple ERPs — composite key prevents collisions |
| Schema changes | on_schema_change='sync_all_columns' | ERP systems add columns without warning — pipeline must not break |
| Test philosophy | 15 focused tests, not 50+ | Tests should catch real data quality issues, not create maintenance overhead |

---

## 🚀 How to Run

```bash
# 1. Install dependencies
pip install dbt-databricks==1.8.0

# 2. Configure connection
# Create ~/.dbt/profiles.yml with your Databricks credentials
# See profiles.yml.example for structure

# 3. Set token
export DBT_TOKEN="your-databricks-token"
export DBT_HOST="your-workspace.azuredatabricks.net"

# 4. Verify connection
cd cfg_tpm_dbt
dbt debug

# 5. Load sample data to Databricks
# Upload data/sample/*.csv to DBFS
# Run setup notebook in Databricks

# 6. Run full project
dbt build          # run + test all models
dbt snapshot       # run SCD2 snapshots
dbt docs generate  # generate lineage docs
dbt docs serve     # view in browser at localhost:8080
```

---

## 📊 Sample Queries

```sql
-- Point-in-time customer analysis: What were CUST002's terms before July 2024?
SELECT customer_id, payment_terms, credit_limit, __START_AT, __END_AT
FROM main.cfg_tpm_snapshots.snap_customer_master
WHERE customer_id = 'CUST002'
  AND __START_AT <= '2024-06-01'
  AND (__END_AT > '2024-06-01' OR __END_AT IS NULL);

-- Join promotions to correct customer terms at time of transaction
SELECT p.promotion_id, p.discount_pct, p.trade_spend_amount,
       c.payment_terms AS terms_at_time_of_promo
FROM main.cfg_tpm_dev.fct_tpm_promotions p
JOIN main.cfg_tpm_snapshots.snap_customer_master c
  ON  p.customer_id = c.customer_id
  AND p.transaction_date >= c.__START_AT
  AND (p.transaction_date < c.__END_AT OR c.__END_AT IS NULL);
```

---

## 🛠️ Stack

| Tool | Version | Purpose |
|------|---------|---------|
| dbt Core | 1.8 | Transformation framework |
| dbt-databricks | 1.8 | Databricks adapter |
| Databricks | Latest | Compute + Unity Catalog |
| Delta Lake | 3.0 | Storage format |
| ADLS Gen2 | — | Raw data storage |
| GitHub Actions | — | CI/CD |

---

## 📌 Status

- [x] Staging models — stg_erp_customers, stg_erp_promotions
- [x] Intermediate model — int_customers_unified
- [x] Incremental fact model — fct_tpm_promotions
- [x] SCD2 snapshots — customer master + product pricing
- [x] 15+ data quality tests
- [x] GitHub Actions CI/CD
- [x] Sample data included
- [ ] dbt metrics layer (coming soon)
- [ ] Power BI semantic model connection (coming soon)
