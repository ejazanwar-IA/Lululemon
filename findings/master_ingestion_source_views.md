# Master Tables → Ingestion Source Tables → Raw GCS Views

**As of:** 2026-06-22
**Owner:** Ejaz Anwar
**Purpose:** For each master, the live ingestion-pipeline intermediate, the `lulu_sourcing_dev` source tables it reads, and the raw GCS file views that feed those sources.

Sources: periodic build headers in [`queries/sourcing/`](../queries/sourcing/) and [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md).

---

| Master table | Ingestion intermediate | Source tables used (`lulu_sourcing_dev`) | Original outbound source (`lululemon_souricng_outbound`) | Raw GCS file views |
|---|---|---|---|---|
| **product_master** | `product_intermediate` | `product_group_hierarchy`, `sku_details`, `product_attribute_s` | `product_group_hierarchy_cleaned_20251119`, `sku_details_cleaned_20251119`, `product_attribute_s_20251119` | `product_group_hierarchy_*.csv`, `sku_details_*.csv`, `product_attribute_s_*.csv` |
| **store_master** | `store_intermediate` | `location_group_hierarchy`, `location_details` | `location_group_hierarchy_cleaned_20251119`, `location_details_cleaned_20251119` | `location_group_hierarchy_*.csv`, `location_details_*.csv` |
| **transaction_master** | `transaction_intermediate` | `sales_transactions` (+ joins `product_intermediate`, `store_intermediate`, `sku_details`) | `sales_transactions_4y_cleaned_20251119` (+ `product_group_hierarchy_cleaned_20251119`, `sku_details_cleaned_20251119`, `store_master_20251119`) | `sales_transactions_*.csv` |
| **inventory_master** | `inventory_intermediate` | `inventory_snapshot_cleaned`, `location_group_hierarchy`, `location_details` | `inventory_snapshot_cleaned`, `product_group_hierarchy_cleaned` (+ `location_group_hierarchy_cleaned_20251119`, `location_details_cleaned_20251119`) | `inventory_snapshot_*.csv` |
| **fiscal_date_mapping** | `fiscal_calendar_intermediate` | `calendar_hierarchy` | `calendar_hierarchy` | None - BQ-only, no GCS view |

---

## Notes

- **Driving (incremental) source** per master, filtered on `SYNCSTARTDATETIME` / `SNAPSHOT_TIME > filter_param`:
  - product → `product_group_hierarchy` / `sku_details` / `product_attribute_s`
  - store → `location_group_hierarchy` / `location_details`
  - transaction → `sales_transactions`
  - inventory → `inventory_snapshot_cleaned`
- **transaction_intermediate** also joins the already-built `product_intermediate` and `store_intermediate`, so those must be current before it runs.
- **inventory_intermediate** uses `location_group_hierarchy` + `location_details` only for channel derivation; the fact rows come from `inventory_snapshot_cleaned`.
- **fiscal calendar** has no raw GCS feed; `calendar_hierarchy` is bootstrapped in BQ and full-replaced each run.
- `events_master` is **not** in the active ingestion pipeline (no `promotional_events` intermediate registered), so it is omitted here.

## Original outbound source mapping

The "Original outbound source" column lists the `lululemon_souricng_outbound` tables that existed **before** the ingestion pipelines were built. The pipeline re-lands these as cleaner, unsuffixed extraction tables in `lulu_sourcing_dev`:

| `lulu_sourcing_dev` source | Original `lululemon_souricng_outbound` table |
|---|---|
| `product_group_hierarchy` | `product_group_hierarchy_cleaned_20251119` |
| `sku_details` | `sku_details_cleaned_20251119` |
| `product_attribute_s` | `product_attribute_s_20251119` |
| `location_group_hierarchy` | `location_group_hierarchy_cleaned_20251119` |
| `location_details` | `location_details_cleaned_20251119` |
| `sales_transactions` | `sales_transactions_4y_cleaned_20251119` |
| `inventory_snapshot_cleaned` | `inventory_snapshot_cleaned` (sync-copied via CTAS, same name) |
| `calendar_hierarchy` | `calendar_hierarchy` (BQ-only, same name) |
