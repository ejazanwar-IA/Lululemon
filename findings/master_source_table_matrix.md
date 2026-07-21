# Master Source Table Matrix

**As of:** 2026-06-22
**Owner:** Ejaz Anwar
**Purpose:** One row per master table showing where its source lives across the three build efforts (live ingestion pipeline, Self-Help tool builds, POC outbound), whether the outbound artifact was simply cloned, the raw GCS files associated, and the date range the data covers.

Companion to [`raw_to_master_lineage.md`](raw_to_master_lineage.md) (column-level lineage) and [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md) (periodic build config).

---

## Column legend

- **Master Table** - the IA master.
- **Source Table (Ingestion Pipeline)** - the live periodic source/intermediate in `lulu_sourcing_dev` feeding `lulu_ingestion_dev`.
- **Self-Help tool (Ejaz)** - what was built or synced via the Self-Help tool in `lulu_sourcing_dev` (extraction tables + intermediates + the `inventory_snapshot_cleaned` CTAS copy).
- **Outbound version (POC Phase)** - the `lululemon_souricng_outbound` table from the Nov 2025 PC-team build.
- **Was simply cloned (Yes/No)** - whether the outbound master/table is a straight BQ CLONE / CTAS copy vs a transform.
- **Raw data files associated** - GCS `client_data_lululemon` view files feeding it.
- **Timeline coverage** - date range the data spans.

---

## Matrix

| Master Table | Source Table (Ingestion Pipeline) | Self-Help tool (Ejaz) | Outbound version (POC Phase) | Was simply cloned | Raw data files associated | Timeline coverage |
|---|---|---|---|---|---|---|
| **product_master** | `lulu_sourcing_dev.product_intermediate` | `product_group_hierarchy`, `sku_details`, `product_attribute_s` extraction + `product_intermediate` periodic SQL | `product_master_20251119` (and `product_master` CLONE) | Yes - outbound `product_master` is BQ CLONE of `_20251119` | `product_group_hierarchy_*.csv`, `sku_details_*.csv`, `product_attribute_s_*.csv` | SKU catalog snapshot, no date series; current season `25-4WI` (Nov 3 2025 to Feb 1 2026) |
| **transaction_master** | `lulu_sourcing_dev.transaction_intermediate` | `sales_transactions` extraction + `transaction_intermediate` periodic SQL | `transaction_master` from `sales_transactions_4y_cleaned_20251119` | Yes - outbound `transaction_master` is BQ CLONE of `_20251119` | `sales_transactions_*.csv` | 2022-05-15 to 2025-11-18 (~3.5 years, 1,284 dates) |
| **inventory_master** | `lulu_sourcing_dev.inventory_intermediate` | **`inventory_snapshot_cleaned`** CTAS copy (Ejaz, 2026-05-07) + `inventory_intermediate` periodic SQL | `inventory_master` from `inventory_snapshot_cleaned` + `product_group_hierarchy_cleaned` | No - CTAS full copy (~1.4 TB), not a zero-byte CLONE | `inventory_snapshot_*.csv` | Master 2023+ (build drops pre-2023); raw `inventory_snapshot_cleaned` holds pre-2023 history; POC master sample = single date 2025-08-28 |
| **store_master** | `lulu_sourcing_dev.store_intermediate` | `location_group_hierarchy`, `location_details` extraction + `store_intermediate` periodic SQL | `store_master_20251119` (and `store_master` CLONE) | Yes - outbound `store_master` is BQ CLONE of `_20251119` | `location_group_hierarchy_*.csv`, `location_details_*.csv` | Store dimension snapshot, no time series; per-store open/close dates |
| **events_master** | Not in active extraction mapping (`promotional_events` not registered) | n/a - no periodic intermediate authored yet | `events_master` from `promotional_events_cleaned` | No - simple projection | `promotional_events_*.csv` | Event start/end dates (per promotional event) |
| **fiscal_date_mapping** | `lulu_sourcing_dev.fiscal_calendar_intermediate` | `fiscal_calendar_intermediate` via `create_fiscal_calendar_intermediate_*.sql` wired in Self-Help; `calendar_hierarchy` bootstrapped from outbound | `fiscal_date_mapping` from `calendar_hierarchy` | No - window-function transform | None - `calendar_hierarchy` is BQ-only (no GCS view) | 2015-02-02 to 2028-01-30 (FY2015 to FY2027, 52 seasons) |

---

## Notes

- **"Was simply cloned" reflects the outbound POC artifact.** The masters cloned in outbound (`product_master`, `store_master`, `transaction_master`, plus `product_group_hierarchy_cleaned`) are zero-byte BQ CLONEs of their `_20251119` variants. `inventory_snapshot_cleaned` is a full CTAS copy into `lulu_sourcing_dev` (~1.4 TB), not a zero-byte clone.
- **Extraction table names differ from POC names.** The live pipeline lands GCS view names in `lulu_sourcing_dev` (`product_group_hierarchy`, `sku_details`, etc., no `_cleaned_20251119` suffix). The POC outbound path used `*_cleaned_20251119` snapshots.
- **Sources:** [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md), [`raw_to_master_lineage.md`](raw_to_master_lineage.md) Sections 5-7, and the master EDA files for date ranges.
