# GCS bucket EDA: `gs://client_data_lululemon/`

`Scan date: 2026-06-22. Project: lululemon-01042025.`

Thorough inventory of the four active folders in the live bucket. The root-level `2026-05-08/`
folder was removed (June 2026); sample data now lives under `Historic/s3_to_gcs/2026-05-08/`.

Method: streaming-first per the project rules. No full files loaded; listings via `gcloud storage ls -l`,
headers via `gsutil cat -r 0-2500` (byte-range, only header bytes fetched), one sample shard per feed.

## TL;DR

| Folder | Size | Files | What it is | State |
|---|---|---|---|---|
| `FOUNDATION_DATA/exports/` | **8.49 GiB** | 45 | 3 planning-grain feeds: `CH` (week calendar), `LH` (location hierarchy), `SLS_INV` (weekly sales+inventory fact) | **Newest active drop** |
| `Clustering_Latest/` | 297 KiB | 1 | Store clustering output (US + Canada retail) | Single latest file |
| `Historic/s3_to_gcs/` | **4.42 TB** | 3,342 | Raw IA sourcing backfill, 47 feeds across **8** dated batches | Historic archive |
| `test/` | 0 B | 0 | Empty placeholder | Empty |

Artifacts in this folder:
- `batch_folder_report.md` - per-batch feed inventory, overlap analysis, ingestion guidance
- `consolidated_validation.md` / `feed_sources.csv` / `consolidated_manifest.csv` - feed-centric copy under `Historic/s3_to_gcs/consolidated/` (35 feeds, ~1.32 TB)
- `batch_inventory_detail.csv` / `batch_feed_matrix.csv` - machine-readable batch x feed catalog
- `catalog_historic.csv` - every (batch, feed): file count, size, timestamps, sample URI
- `catalog_foundation.csv` - FOUNDATION_DATA feeds
- `headers_historic.txt` - header + column count for all 45 historic feeds
- `schema_foundation.csv` - FOUNDATION_DATA + Clustering schemas with sample values

---

## 1. FOUNDATION_DATA/exports (newest, recommended focus)

Three feeds, all delivered 2025-04-04. Filenames use `<name>.csv_<a>_<b>_0.csv` shard pattern (no date in name).

| Feed | Folder | Files | Size | Grain | Cols |
|---|---|---|---|---|---|
| `week` | `CH/` | 1 | <1 MB | one row per fiscal week | 8 |
| `location_hierarchy` | `LH/` | 4 | ~30 MB | one row per location (store/DC) | 44 |
| `sales_inventory` | `SLS_INV/` | 40 | **8.49 GB** | PLANNING_STYLE_OPTION × LOC × WEEK | 15 |

### CH / week (8 cols)
`WEEK_ID, WEEK_START_DAY_ID, WEEK_END_DAY_ID, MONTH_ID, QUARTER_ID, SEASON_CODE, BUYING_PERIOD, DELETE_IND`
- Slim fiscal calendar (a subset of the historic `calendar_hierarchy`, which has 37 cols).
- Sample: `WEEK_ID=202719, 2027-06-07 to 2027-06-13, SEASON_CODE="27-2SU", BUYING_PERIOD="BP58"`.

### LH / location_hierarchy (44 cols)
`BRAND_ID, BRAND_NAME, MARKET_ID, MARKET_NAME, PLANNING_MARKET_CURRENCY, MARKET_CHANNEL_ID/NAME, SUB_MARKET_CHANNEL_ID/NAME, LOC_ID, LOC_NAME, LOC_TYPE, LOC_FORMAT, PRIMARY_DC_ID, PLACEHOLDER_FLAG, MFP_PLANNING_TYPE, DC_DIRECT_DEMAND, COUNTRY_ID/NAME, CURRENCY_ID, OPERATIONAL_OPEN/CLOSE_DAY_ID, MPA_OPEN/CLOSE_DAY_ID, REGION_ID/NAME, AREA_ID/NAME, PHYSICAL_COUNTRY_ID, SERVICE_COUNTRY_ID, EXTERNAL_ID, GEO_REGION_ID/NAME, GEO_REGION_CHANNEL_ID/NAME, PHYSICAL_DC_ID, CITY, STATE, POSTAL_CODE, LONGITUDE, LATITUDE, ADDRESS_LINE_1/2, LOC_CLOSED_IND`
- Near-twin of historic `location_group_hierarchy` (43 cols), but FOUNDATION adds `ADDRESS_LINE_1/2` and reorders. This is the richer store-master source.
- Sample row is a LULULEMON NAM US retail store (`10770:FAYETTEVILLE LOCAL`).

### SLS_INV / sales_inventory (15 cols) - the heavy feed
`PLANNING_STYLE_OPTION_ID, LOC_ID, WEEK_ID, FIXED_FX_TOT_NET_SLS_RTL, TOT_NET_SLS_U, FIXED_FX_TOT_SLS_C, FIXED_FX_CURRENT_PRICE, FIXED_FX_REGULAR_PRICE, FIXED_FX_CLEARANCE_PRICE, FIXED_FX_RETURN_RTL, FIXED_FX_AV_COST, RETURN_U, TOT_BOP_U, TOT_EOP_U, TOT_IT_U`
- **Pre-aggregated planning fact** at PSS × Store × Week, not raw transactions. Metrics are FX-normalized (`FIXED_FX_*`): net sales retail/cost, units, prices, returns, BOP/EOP/in-transit units.
- This is the SOW forecasting grain (PSS × Store × Week). Distinct from the raw `sales_transactions` (9 cols, SKU-line grain) in Historic.
- 40 shards × ~227 MB each = 8.49 GB. Use BQ external table on the wildcard for any row-level aggregation; do not download.

---

## 2. Clustering_Latest

Single file `Clustering_Latest.csv`, 2,236 rows, 8 cols:
`workstream, l2_name, aur, quantity_sold, revenue, cluster_name, labels, store_code`

| Dimension | Distinct | Notes |
|---|---|---|
| workstream | 2 | `lululemon_United States_RETAIL` (1,916 rows), `lululemon_Canada_RETAIL` (320) |
| cluster_name | 47 | e.g. `lululemon_Canada_RETAIL-lulu Accessories-1` |
| store_code | 551 | zero-padded 10-digit (e.g. `0000000240`) |
| l2_name | 5 | lulu Accessories, lulu Mens, lulu Womens, lulu Footwear, Others |

Grain ~ workstream × l2_name × store. Output of a store-clustering model (AUR / qty / revenue per store-category, assigned to a cluster).

---

## 3. Historic/s3_to_gcs (raw IA sourcing backfill)

**8 dated batches**, ~4.42 TB, 47 distinct feeds. See [`batch_folder_report.md`](batch_folder_report.md) for full per-batch analysis.

Standard structure (7 batches):
`s3_to_gcs/<batch>/outbound/<feed>/[new|processed]/<shards>` (anaplan nests deeper:
`outbound/anaplan/<subfeed>/new/pod_id=N/TE2.0_EA_*.csv`).

**2026-05-08** uses a **flat layout**: CSVs at batch root (no `outbound/` tree). Sample subset copied from the 2025-11-18 drop (~185 files, ~107 GB).

### Per-batch size

| Batch | Size | Files | Headline feeds |
|---|---|---|---|
| 2025-08-28 | 1.65 TB | 1,262 | full feed set: inventory_snapshot (939 GB), sku_details (330 GB), TE2.0 demand forecast, sales/returns |
| 2025-09-18 | 0.03 TB | 64 | price_book only |
| 2025-10-06 | <0.01 TB | 8 | class_location_attribute_seasonal only |
| 2025-10-08 | 1.61 TB | 837 | inventory_snapshot (1.60 TB), eligibility, cc_target |
| 2025-11-18 | 0.35 TB | 664 | refreshed full set: sales/returns transactions, transfer_orders, price_book, forecasts |
| 2025-12-03 | 0.18 TB | 97 | TE2.0 demand forecast (pod/pov), inventory_snapshot |
| 2025-12-05 | 0.47 TB | 225 | inventory_snapshot |
| 2026-05-08 | 0.11 TB | 185 | flat sample: sales_transactions, inventory_snapshot, sku_details, masters (Nov 20251118 snaps) |

### Largest feeds by total size

| Feed | Cols | Notes |
|---|---|---|
| inventory_snapshot | 7 | by far the largest (SKU × Location × Date stock); spans multiple batches |
| sku_details | 21 | product master detail (item/style/color/season/size); cost+selling price |
| TE2.0_EA_Demand_Forecast (+ _pod/_pov) | 6 | Anaplan demand forecast, daily, per pod |
| sales_transactions | 9 | SKU-line sales (SKU_ID, LOCATION_ID_SALES, DATE, order ids, units, price) |
| returns_transactions | 8 | mirror of sales without unit price |
| price_book | 8 | PSS × LOC effective-dated prices |

### Feed families (46 feeds, headers in `headers_historic.txt`)

- **Transactions:** sales_transactions, returns_transactions, transfer_orders, purchase_orders
- **Inventory:** inventory_snapshot
- **Product:** sku_details, style_option, preseason_product_hierarchy, product_group_hierarchy,
  product_attribute_s / s_seasonal / so / so_seasonal (date-suffixed; `product_attribute_s` has **102 cols**)
- **Location:** location_details, location_group_hierarchy (43 cols), dc_store_mapping, class_location_attribute_seasonal
- **Calendar/pricing:** calendar_hierarchy (37 cols), price_book, delivery_week_logic
- **Planning/eligibility:** assortment_plan, planned_sales, eligibility (3 date variants), cc_target,
  min_pres_eol, inseason_demand_forecast, promotional_events
- **Anaplan TE2.0 (pod-partitioned):** Demand_Forecast (+pod/pov), Assortment_Parameters, Transit_Calendar,
  FDOD_Alloc, FDOD_Replen, Minimum_Presentation, Inventory_Parameters_Store_Priority
- **Other:** spatial_ai (75 cols, demographic affinity scores per location), nohup.out (stray log, ignore)

---

## 4. Data-quality flags to verify before ingesting

1. **BOM + trailing comma** in a few anaplan/hand-built feeds: `min_pres_eol` header is
   `﻿plan_quarter_id,...,EOL,` (UTF-8 BOM prefix and an empty trailing column);
   `delivery_week_logic` and `Inventory_Parameters_Store_Priority` also carry a BOM.
2. **Spaces and `#` in column names** for all Anaplan `TE2.0_EA_*` feeds (e.g. `#C2 Store/Planning Size`,
   `Reg Demand Daily Forecast`) - must be backtick-quoted / sanitized on load.
3. **Date-suffixed feed names** (`eligibility20250818`, `product_attribute_s20250813`, `..._20251118`) encode
   the snapshot date in the feed name; same logical feed, different drop date.
4. **`SLS_INV` is planning-grain, not raw** - do not confuse with raw `sales_transactions`. Metrics are
   FX-normalized (`FIXED_FX_*`).
5. Stray `nohup.out` under 2025-12-05 and root-level files under 2025-12-03 - housekeeping (2026-05-08 now populated under Historic).
6. Per the BQ context rules: `sku_details` `COST_PRICE`/`SELLING_PRICE` and `price_book` prices are
   string-typed and have historically arrived as `0` in some batches - confirm pricing populated before use.

## Reproduce

```bash
# Per-batch historic inventory (refreshes catalog + matrix + detail CSV)
python3 scripts/historic_batch_inventory.py --all-batches

# Inventory (raw listings)
gcloud storage ls -l "gs://client_data_lululemon/Historic/**"     --project=lululemon-01042025
gcloud storage ls -l "gs://client_data_lululemon/FOUNDATION_DATA/**" --project=lululemon-01042025
# Cheap header (byte range, no full download)
gsutil cat -r 0-2500 "gs://client_data_lululemon/<path>.csv" | head -1
```
