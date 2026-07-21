# EDA Findings - Lululemon

This folder holds EDA findings per table, structured to be **pasted into Confluence**. Each file is a standalone page.

**Start here:** [`lulu_eda_inventory.md`](lulu_eda_inventory.md) — deduplicated index of all EDAs (canonical artifact per table, duplicate map, gaps).

**Intermediate build logic (locked v2):** [`lululemon_intermediate_builds_v2_reference.md`](lululemon_intermediate_builds_v2_reference.md) — canonical product / store / inventory / transaction intermediate SQL and lineage.

## Workflow

1. I write SQL queries in `queries/<table>_eda_<phase>.sql`
2. You run them in **BigQuery Console**
3. You paste results back here (or share in chat)
4. I update the matching `findings/<table>_eda.md` with results + interpretation
5. When a section is "done," you copy-paste the markdown into a Confluence page

## Canonical EDAs (use these, not superseded copies)

### Raw GCS extraction (`lulu_sourcing_dev`) — May 2026

**Consolidated summary:** [`raw_sourcing_dev_7_table_eda_summary.md`](raw_sourcing_dev_7_table_eda_summary.md) (all 7 tables in one doc) · **Word:** [`Lululemon_Raw_GCS_Extraction_EDA_Summary.docx`](Lululemon_Raw_GCS_Extraction_EDA_Summary.docx)

| File | Table |
|------|-------|
| [`raw_product_group_hierarchy_eda.md`](raw_product_group_hierarchy_eda.md) | `product_group_hierarchy` |
| [`raw_sku_details_eda.md`](raw_sku_details_eda.md) | `sku_details` |
| [`raw_product_attribute_s_eda.md`](raw_product_attribute_s_eda.md) | `product_attribute_s` |
| [`raw_location_group_hierarchy_eda.md`](raw_location_group_hierarchy_eda.md) | `location_group_hierarchy` |
| [`raw_location_details_eda.md`](raw_location_details_eda.md) | `location_details` |
| [`raw_sales_transactions_eda.md`](raw_sales_transactions_eda.md) | `sales_transactions` |
| [`raw_returns_transactions_eda.md`](raw_returns_transactions_eda.md) | `returns_transactions` (join vs sales) |

### GCS file layer — Jun 2026

| File | Scope |
|------|-------|
| [`gcs_eda_2026/README.md`](gcs_eda_2026/README.md) | Full bucket inventory (all 7 feeds + 40 others) |
| [`forecastsmart_data_requirements_coverage.md`](forecastsmart_data_requirements_coverage.md) | 15 ForecastSmart Must-Haves vs GCS / BQ / master coverage |
| [`sku_details_gcs_batch_pricing_scan.md`](sku_details_gcs_batch_pricing_scan.md) | sku_details batch pricing root cause |
| [`inventory_snapshot_batch_compare.md`](inventory_snapshot_batch_compare.md) | inventory_snapshot 6-batch comparison vs BQ load |
| [`raw_inventory_snapshot_dec04_eda.md`](raw_inventory_snapshot_dec04_eda.md) | DEC04 latest batch full EDA (7.93B rows, GCS) |
| [`inbound_drop_agent/briefs/inventory_snapshot_20251204.md`](inbound_drop_agent/briefs/inventory_snapshot_20251204.md) | DEC04 drop sign-off brief (GREEN) |
| [`inventory_schema_alignment_lululemon.md`](inventory_schema_alignment_lululemon.md) | IA inventory schema alignment table (raw + master mapping) |

### Synced / supporting tables

| File | Table |
|------|-------|
| [`inventory_snapshot_cleaned_eda.md`](inventory_snapshot_cleaned_eda.md) | `inventory_snapshot_cleaned` |
| [`fiscal_calendar_eda.md`](fiscal_calendar_eda.md) | `calendar_hierarchy` |

### Ingestion masters (`lulu_ingestion_dev`) — May 2026

| File | Table |
|------|-------|
| [`master_product_master_eda.md`](master_product_master_eda.md) | `product_master` |
| [`master_store_master_eda.md`](master_store_master_eda.md) | `store_master` |
| [`master_inventory_master_eda.md`](master_inventory_master_eda.md) | `inventory_master` |
| [`master_transaction_master_eda.md`](master_transaction_master_eda.md) | `transaction_master` |
| [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) | All 4 masters (delta) |

### Inbound drop briefs

| File | Table |
|------|-------|
| [`inbound_drop_agent/briefs/inventory_snapshot_20260528.md`](inbound_drop_agent/briefs/inventory_snapshot_20260528.md) | `inventory_snapshot_cleaned` (live drop) |

## Historical (superseded — reference only)

Apr 2026 outbound POC: `product_master_eda.md`, `store_master_eda.md`, `transaction_master_eda.md`, `inventory_master_eda.md`. See [`lulu_eda_inventory.md`](lulu_eda_inventory.md) §6 for the full duplicate map.

## Notes

- Each file is self-contained (can be pasted into Confluence as one page)
- Tables, code blocks, and headings render cleanly in Confluence when using the paste-as-markdown option
- Intermediate tables (`*_intermediate`) have no standalone EDA — see master EDAs above
