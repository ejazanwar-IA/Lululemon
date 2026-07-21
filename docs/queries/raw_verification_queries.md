# Raw Source Verification — V1–V15

The authoritative script that re-tests each master-table anomaly against its raw upstream source. Every anomaly in [`anomaly_status_with_verification_sql.md`](../anomaly_status_with_verification_sql.md) traces back to one of these V-numbered checks.

---

## Table existence check

Run first to confirm which raw tables are populated and their correct names (handles the `_20251119` vs `_cleaned` vs plain-name trap).

??? example "`raw_source_table_existence_check.sql`"
    ```sql
    --8<-- "queries/raw_source_table_existence_check.sql"
    ```

---

## Phase 1 verification — V1 through V15 stacked

Single query, single result set. Each row is one V-check with a `results_json` payload.

??? example "`raw_source_verification_phase1.sql`"
    ```sql
    --8<-- "queries/raw_source_verification_phase1.sql"
    ```

### What each V-check targets

| # | Target | Master anomaly it verifies |
|:-:|---|---|
| V1 | `sku_details_cleaned` cost / selling_price | transaction_master cost/msrp 100% zero |
| V2 | `product_attribute_s_20251119` fit_classification NULLs | product_master fit_classification 24.7% NULL |
| V3 | `product_attribute_s_20251119` size_scale distribution | product_master size_scale codes (45 distinct) |
| V4 | `location_group_hierarchy` CMNTY / COMMUNITY | store_master channel spelling split |
| V5 | `location_group_hierarchy` LOC_CLOSED_IND | store_master active flag polarity |
| V6 | `location_group_hierarchy` lat/long types | store_master lat/long STRING |
| V7 | `inventory_snapshot_cleaned` pre-2023 rows | inventory_master missing 9.3B rows |
| V8 | `product_group_hierarchy` launch/date columns | product_master launch_date 100% NULL |
| V9 | `sales_transactions_4y_cleaned` outliers | transaction_master extreme outliers, negative prices |
| V10 | `inventory_snapshot_cleaned` negative OH | inventory_master 64M negative-OH rows |
| V11 | `product_group_hierarchy` brand distribution | inventory_master 8M ivivva rows |
| V12 | `product_group_hierarchy` short-code SKUs | product_master 1,248 placeholder SKUs |
| V13 | `location_group_hierarchy` LOC_FORMAT | store_master store_format_code 21% NULL |
| V14 | `product_attribute_s` gender coverage | product_master gender 73% NULL |
| V15 | `calendar_hierarchy` extent + fiscal coverage | fiscal_date_mapping coverage through FY27 |
