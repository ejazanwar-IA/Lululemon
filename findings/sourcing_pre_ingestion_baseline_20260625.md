# Sourcing Pre-Ingestion Baseline — 2026-06-25

`Captured before Self-Help GCS replace run for gs://client_data_lululemon/2026-06-25/.`

## Raw GCS Tables

| Full table name | Rows | Size GB | Size GiB | Current sync timestamp(s) | Business date range | Key counts |
|---|---:|---:|---:|---|---|---|
| `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy` | 18,249,385 | 1.194 | 1.112 | `2026-05-08T00:00:00` only | n/a | 988,764 SKU_ID |
| `lululemon-01042025.lulu_sourcing_dev.sku_details` | 3,955,056 | 1.170 | 1.090 | `2026-05-08T00:00:00` only | n/a | 988,764 ID |
| `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` | 258,405 | 0.176 | 0.164 | `2026-05-08T00:00:00` only | n/a | 86,135 STYLE_ID |
| `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy` | 1,853 | 0.001 | 0.001 | `2026-05-08T00:00:00` only | n/a | 1,853 LOC_ID |
| `lululemon-01042025.lulu_sourcing_dev.location_details` | 1,853 | 0.000 | 0.000 | `2026-05-08T00:00:00` only | n/a | 1,853 ID |
| `lululemon-01042025.lulu_sourcing_dev.sales_transactions` | 683,582,361 | 97.526 | 90.828 | `2026-05-08T00:00:00` only | 2015-02-02 to 2025-11-18 | 765,813 SKU_ID; 1,217 LOCATION_ID_SALES |
| `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot` | 403,567,770 | 27.650 | 25.874 | `2026-05-08T00:00:00` only | 2023-02-23 to 2025-11-17 | 851,314 SKU_ID; 1,568 LOCATION_ID |

## Synced / Bootstrapped Tables

| Table | Rows | Size GiB | Last modified |
|---|---:|---:|---|
| `inventory_snapshot_cleaned` | 16,424,322,768 | 1299.052 | 2026-05-07 08:13:19 |
| `calendar_hierarchy` | 4,746 | 0.001 | 2026-05-27 06:57:49 |

## Intermediate Tables

| Table | Rows | Size GiB | Last modified |
|---|---:|---:|---|
| `product_intermediate` | 1,977,528 | 1.055 | 2026-06-25 08:48:47 |
| `store_intermediate` | 1,853 | 0.001 | 2026-06-25 08:44:52 |
| `inventory_intermediate` | 15,331,941,895 | 1876.422 | 2026-06-25 08:42:31 |
| `transaction_intermediate` | 345,074,008 | 68.366 | 2026-06-25 08:52:51 |
| `fiscal_calendar_intermediate` | 4,746 | 0.002 | 2026-05-27 06:58:13 |

## Platform Config Snapshot

Current BigQuery `view_mapping_table` rows still show `replace=false` and `extraction_sync_dt=2026-05-08T00:00:00`.

The local upload CSV was edited separately at `/Users/ejazanwarmd/Downloads/export (19).csv` to set:

- `replace=true`
- `dataingestion_filterparam=1900-01-01T00:00:00`
- `filter_param=1900-01-01T00:00:00`
- `extraction_sync_dt=2026-06-25T00:00:00`

## Expected Post-Run Checks

After the Self-Help replace run, compare:

1. Raw GCS table `row_count`, `size_bytes`, and `last_modified_time` from `__TABLES__`.
2. Raw table `MAX(SYNCSTARTDATETIME)`, expected to move from `2026-05-08T00:00:00` to `2026-06-25T00:00:00` if the extraction config is honored.
3. Raw table business-date ranges:
   - `inventory_snapshot` should expand materially if DEC04 (2025-12-05) was loaded.
   - `sales_transactions` should reflect the 2025-11-18 batch copied into the dated folder.
4. Intermediate tables only after their Self-Help build queries are triggered.

