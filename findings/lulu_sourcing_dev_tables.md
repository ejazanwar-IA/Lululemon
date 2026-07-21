# `lulu_sourcing_dev`: full table list (Lululemon)

**Project:** `lululemon-01042025`  
**Dataset:** `lulu_sourcing_dev`  
**Full name pattern:** `` `lululemon-01042025.lulu_sourcing_dev.<table_name>` ``  
**As of:** 2026-06-23 (live `__TABLES__` snapshot)


## Production pipeline tables

### GCS CSV extraction (sourcing extraction DAG)

| Full table name | GCS CSV source | Row count | Size (GB) |
|-----------------|----------------|----------:|----------:|
| `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy` | `product_group_hierarchy_*.csv` | 18,249,385 | 1.11 |
| `lululemon-01042025.lulu_sourcing_dev.sku_details` | `sku_details_*.csv` | 3,955,056 | 1.09 |
| `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` | `product_attribute_s_*.csv` | 258,405 | 0.16 |
| `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy` | `location_group_hierarchy_*.csv` | 1,853 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.location_details` | `location_details_*.csv` | 1,853 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.sales_transactions` | `sales_transactions_*.csv` | 683,582,361 | 90.83 |
| `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot` | `inventory_snapshot_*.csv` | 403,567,770 | 25.87 |

Batch comparison (6 GCS drops vs BQ load): [`inventory_snapshot_batch_compare.md`](inventory_snapshot_batch_compare.md). DEC04 deep-dive: [`raw_inventory_snapshot_dec04_eda.md`](raw_inventory_snapshot_dec04_eda.md). Source CSVs = 192M grains; BQ rows ~2.1× from load duplication; not the latest batch (consolidated uses DEC 20251204).

### Synced / bootstrapped (not a normal GCS landing)

| Full table name | Origin | Row count | Size (GB) |
|-----------------|--------|----------:|----------:|
| `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot_cleaned` | CTAS copy from `lululemon_souricng_outbound.inventory_snapshot_cleaned` | 16,424,322,768 | 1,299.05 |
| `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy` | Bootstrapped from outbound BQ (no GCS connector) | 4,746 | 0.00 |

### Periodic intermediates (Ejaz / Self-Help SQL builds)

| Full table name | Built from | Row count | Size (GB) |
|-----------------|------------|----------:|----------:|
| `lululemon-01042025.lulu_sourcing_dev.product_intermediate` | PGH + sku_details + product_attribute_s | 1,977,528 | 1.06 |
| `lululemon-01042025.lulu_sourcing_dev.store_intermediate` | location_group_hierarchy + location_details | 1,853 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate` | inventory_snapshot_cleaned + location feeds | 5,539,053 | 0.68 |
| `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate` | sales_transactions + product/store intermediate + sku_details | 352,353,925 | 69.81 |
| `lululemon-01042025.lulu_sourcing_dev.fiscal_calendar_intermediate` | calendar_hierarchy | 4,746 | 0.00 |

### Platform config

| Full table name | Purpose | Row count | Size (GB) |
|-----------------|---------|----------:|----------:|
| `lululemon-01042025.lulu_sourcing_dev.mapping` | Periodic build checkpoints / intermediate wiring | 67 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.view_mapping_table` | GCS extraction DAG view mapping | 97 | 0.00 |


## Legacy / POC / test tables (in dataset, not active pipeline)

| Full table name | Notes | Row count | Size (GB) |
|-----------------|-------|----------:|----------:|
| `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy_cleaned` | POC-style cleaned PGH pivot snapshot | 1,977,528 | 0.59 |
| `lululemon-01042025.lulu_sourcing_dev.fiscal_date_mapping_intermediate` | Alternate naming for fiscal intermediate | 4,746 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.ada_visual_driver_significance` | ADA / visual driver table | 9,618,567 | 1.54 |
| `lululemon-01042025.lulu_sourcing_dev.dummy_table` | Test | 1 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.product_intermediate_tmp` | Temp build artifact | 1,839,012 | 0.93 |
| `lululemon-01042025.lulu_sourcing_dev.product_intermediate_ttt` | Test / scratch | 2,547,492 | 1.35 |
| `lululemon-01042025.lulu_sourcing_dev.product_master_intermediate` | Legacy intermediate name | 1,839,012 | 0.93 |
| `lululemon-01042025.lulu_sourcing_dev.product_master_intermediate_1` | Legacy intermediate name | 2,547,492 | 1.51 |
| `lululemon-01042025.lulu_sourcing_dev.product_master_intermediate_2` | Legacy intermediate name | 2,547,492 | 1.53 |
| `lululemon-01042025.lulu_sourcing_dev.store_intermediate_2` | Legacy / test | 1,750 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.store_intermediate_ttt` | Test / scratch | 1,750 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate` | Legacy intermediate name | 1,750 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate_1` | Legacy intermediate name | 1,750 | 0.00 |
| `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate_2` | Legacy intermediate name | 1,750 | 0.00 |


## Flat list (all 30 tables, alphabetical)

```
lululemon-01042025.lulu_sourcing_dev.ada_visual_driver_significance
lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy
lululemon-01042025.lulu_sourcing_dev.dummy_table
lululemon-01042025.lulu_sourcing_dev.fiscal_calendar_intermediate
lululemon-01042025.lulu_sourcing_dev.fiscal_date_mapping_intermediate
lululemon-01042025.lulu_sourcing_dev.inventory_intermediate
lululemon-01042025.lulu_sourcing_dev.inventory_snapshot
lululemon-01042025.lulu_sourcing_dev.inventory_snapshot_cleaned
lululemon-01042025.lulu_sourcing_dev.location_details
lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy
lululemon-01042025.lulu_sourcing_dev.mapping
lululemon-01042025.lulu_sourcing_dev.product_attribute_s
lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy
lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy_cleaned
lululemon-01042025.lulu_sourcing_dev.product_intermediate
lululemon-01042025.lulu_sourcing_dev.product_intermediate_tmp
lululemon-01042025.lulu_sourcing_dev.product_intermediate_ttt
lululemon-01042025.lulu_sourcing_dev.product_master_intermediate
lululemon-01042025.lulu_sourcing_dev.product_master_intermediate_1
lululemon-01042025.lulu_sourcing_dev.product_master_intermediate_2
lululemon-01042025.lulu_sourcing_dev.sales_transactions
lululemon-01042025.lulu_sourcing_dev.sku_details
lululemon-01042025.lulu_sourcing_dev.store_intermediate
lululemon-01042025.lulu_sourcing_dev.store_intermediate_2
lululemon-01042025.lulu_sourcing_dev.store_intermediate_ttt
lululemon-01042025.lulu_sourcing_dev.store_master_intermediate
lululemon-01042025.lulu_sourcing_dev.store_master_intermediate_1
lululemon-01042025.lulu_sourcing_dev.store_master_intermediate_2
lululemon-01042025.lulu_sourcing_dev.transaction_intermediate
lululemon-01042025.lulu_sourcing_dev.view_mapping_table
```


## GCS feeds not yet in `lulu_sourcing_dev`

See [`forecastsmart_data_requirements_coverage.md`](forecastsmart_data_requirements_coverage.md) for the full 15-requirement gap matrix.

**Returns join POC (2026-06-24):** [`raw_returns_transactions_eda.md`](raw_returns_transactions_eda.md): GCS consolidated + outbound BQ; joins to `sales_transactions` on `DATE|SKU|STORE` keys; not landed in sourcing dev yet.

Present in consolidated GCS but **not** landed via extraction DAG (28 feeds). Examples:

- `returns_transactions_*.csv`
- `price_book_*.csv`
- `promotional_events_*.csv`
- `transfer_orders_*.csv`, `purchase_orders_*.csv`
- `eligibility_*.csv`, seasonal product attributes
- Anaplan feeds (demand forecast, allocation calendar, etc.)


## Related docs

- [`master_ingestion_source_views.md`](master_ingestion_source_views.md)
- [`master_source_table_matrix.md`](master_source_table_matrix.md)
- [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md)
- [`reference_docs/Lululemon/ia_platform_mapping_table_lulu_dev.csv`](../reference_docs/Lululemon/ia_platform_mapping_table_lulu_dev.csv)
