# SQL Queries

All BigQuery scripts that drove the Phase-1 EDA and the raw-source verification phase. Each file lives in `queries/` in the repo and is embedded here verbatim — copy/paste or click to view raw.

## How to run

All queries target `lululemon-01042025.lululemon_souricng_outbound`. Paste into the BigQuery Console or run via `bq query --use_legacy_sql=false < file.sql`.

!!! tip "Cost guardrails"
    - `inventory_master` (650 GB) and `inventory_snapshot_cleaned` (3.3 TB) — **always filter by `date`**.
    - `transaction_master` (74 GB) — filter by `date` or `channel`.
    - Small tables (`store_master`, `calendar_hierarchy`, `product_master`) have no partition — full scans are cheap.

---

## Catalog

| # | File | Purpose | Approx cost |
|:-:|---|---|:-:|
| 1 | `schema_dump_all_canonical.sql` | Dumps INFORMATION_SCHEMA.COLUMNS for all 26 canonical tables | Free |
| 2 | `sample_rows_all_canonical.sql` | 1 random row per canonical table (uses `ORDER BY RAND()`) | Low |
| 3 | `list_all_tables.sql` | Row counts + sizes for every table in the dataset | Free |
| 4 | `product_master_eda_phase1.sql` | Product Master initial shape + null analysis | Low |
| 5 | `product_master_eda_phase1_consolidated.sql` | Product Master Phase-1 full battery (16 queries stacked) | Low |
| 6 | `product_master_eda_phase2_consolidated.sql` | Product Master Phase-2 (duplicates, orphans, short-codes) | Low |
| 7 | `product_master_eda_phase3_consolidated.sql` | Product Master Phase-3 (hierarchy integrity, gender derivation) | Low |
| 8 | `product_master_eda_phase3_diagnostic.sql` | Spot-check diagnostic queries for Phase 3 findings | Low |
| 9 | `product_master_clean_view.sql` | Proposed `product_master_clean` view DDL | N/A (DDL) |
| 10 | `product_master_clean_validation.sql` | Validates the clean view output vs raw master | Low |
| 11 | `transaction_master_eda_phase1_consolidated.sql` | Transaction Master Phase-1 (shape, nulls, outliers) | Med (filtered) |
| 12 | `transaction_master_eda_phase2_zero_qty.sql` | Zero-qty row concentration analysis | Med |
| 13 | `transaction_master_eda_phase3_cross_table.sql` | Cross-table integrity with product + store masters | Med |
| 14 | `inventory_master_eda_phase1_consolidated.sql` | Inventory Master Phase-1 (1-year partition-scoped) | Med |
| 15 | `store_master_eda_phase1_consolidated.sql` | Store Master Phase-1 (all 7 queries stacked) | Free |
| 16 | `fiscal_calendar_eda_phase1_consolidated.sql` | Calendar Hierarchy Phase-1 | Free |
| 17 | `raw_source_table_existence_check.sql` | Confirms which raw tables exist and their sizes | Free |
| 18 | `raw_source_verification_phase1.sql` | **V1–V15** — verifies observed master-table anomalies against raw sources | Low-Med |

---

## Organization by page

- **Schema & Inventory** → schema dumps, samples, dataset-wide table listing
- **Product Master** → all 4 phases + the proposed clean view + its validation
- **Transaction Master** → all 3 phases
- **Inventory Master** → Phase 1 (only phase run due to 7.2B rows)
- **Store Master** → Phase 1 (complete; no further phases needed — table is clean)
- **Fiscal Calendar** → Phase 1 (complete)
- **Raw Verification** → V1–V15 stacked query + existence check — the definitive upstream anomaly check
