# ForecastSmart data requirements: coverage tracker

`Last updated: 2026-06-24.`

Client **Must Have** list for Forecasting / ForecastSmart (15 data files). Tracks how far each requirement is covered by:

1. **GCS consolidated**: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/` (35 feeds, canonical picks)
2. **BQ raw extraction**: `lulu_sourcing_dev` tables landed via GCS extraction DAG
3. **BQ master / intermediate**: periodic build outputs in `lulu_sourcing_dev` / `lulu_ingestion_dev`

Related: [`lululemon_forecasting_table_refresh_guide.md`](lululemon_forecasting_table_refresh_guide.md), [`master_source_table_matrix.md`](master_source_table_matrix.md), [`raw_sourcing_dev_7_table_eda_summary.md`](raw_sourcing_dev_7_table_eda_summary.md), [`gcs_eda_2026/consolidated_validation.md`](gcs_eda_2026/consolidated_validation.md).


## Requirements (source list)

| # | Data file | Ideal grain | Time period |
|---:|---|---|---|
| 1 | Location Master | Location ID | Latest |
| 2 | Product Master | SKU ID | Latest |
| 3 | Fiscal Calendar | Day | 3 years historic + 5 years future |
| 4 | Inventory Data | SKU ID × Store ID × Day | 2 years + YTD |
| 5 | Transaction Data | SKU ID × Store ID × Day × Txn ID × Line ID | 2 years + YTD |
| 6 | Discount at Transaction | SKU ID × Store ID × Day × Txn ID × Line ID | 2 years + YTD |
| 7 | Holidays and Store Closure | Event ID × Store ID × Start Date × End Date | 2 years historic + 2 years future |
| 8 | Purchase Order | SKU ID × PO ID × PO Line ID | 2 years + YTD + Future |
| 9 | ASN | SKU ID × ASN ID × ASN Line ID | 2 years + YTD + Future |
| 10 | Receipts | SKU ID × Receipt ID × Receipt Date | 2 years + YTD + Future |
| 11 | Future Promotions Pricing | Hierarchy × Week | Future |
| 12 | Product attributes | SKU ID | Latest |
| 13 | Product Time dependent attributes | SKU ID × Start Date × End Date | 2 years historic + Future |
| 14 | SKU-Store Allocation Eligibility | SKU ID × Store ID × Start Date × End Date | Future feed |
| 15 | StyleColor-Store Eligibility | Style Color ID × Store ID × Start Date × End Date | Future |


## Coverage summary

| # | Data file | Overall | GCS consolidated | BQ raw landed | Master / target table | Main gap |
|---:|---|:---:|---|---|---|---|
| 1 | Location Master | **High (~85%)** | Yes | Yes | `store_master` | ~50% stores inactive in master filter; not repointed to consolidated |
| 2 | Product Master | **Medium (~70%)** | Yes | Yes | `product_master` | Only ~33% SKU universe in master; sku pricing zero in current load |
| 3 | Fiscal Calendar | **High (~80%)** | Yes | Yes (BQ bootstrap) | `fiscal_date_mapping` | ~2 yrs future vs 5 yrs required (need FY2030) |
| 4 | Inventory Data | **Medium (~55%)** | Yes (474 GB Dec snap) | Yes (May sample) | `inventory_master` | Raw extract sparse (33 snap dates, 2024 gap); master uses `inventory_snapshot_cleaned` |
| 5 | Transaction Data | **Medium (~70%)** | Yes (sales + returns) | Partial (sales only) | `transaction_master` | Returns in GCS; join validated (~14% net impact); not landed or merged: see [`raw_returns_transactions_eda.md`](raw_returns_transactions_eda.md) |
| 6 | Discount at Transaction | **Low (~15%)** | Partial (`price_book`) | No | Stubs in `transaction_master` | No line-level discount feed; discount cols hardcoded 0 |
| 7 | Holidays & Store Closure | **Low (~25%)** | Yes | No | `events_master` (not in pipeline) | Small promo feed; future horizon unverified; not extracted |
| 8 | Purchase Order | **Low (~20%)** | Yes | No | None | PO CSV exists; no BQ table or master |
| 9 | ASN | **None (0%)** | No | No | None | Confirmed: Lululemon has no ASN feed |
| 10 | Receipts | **Low (~15%)** | Partial (`transfer_orders`) | No | None | Transfer orders proxy only; no receipt_id grain |
| 11 | Future Promotions Pricing | **Low (~20%)** | Partial | No | None | `price_book`, `planned_sales`, Anaplan demand have price/promo signals; not landed |
| 12 | Product attributes | **Medium (~50%)** | Yes (4 attr feeds) | Partial (`product_attribute_s` only) | Joined in `product_master` | `_so`, seasonal variants not extracted; style-level attrs partial |
| 13 | Product Time dependent attributes | **Low (~25%)** | Yes (seasonal attrs) | No | None | Seasonal product_attribute_* in consolidated; not in BQ |
| 14 | SKU-Store Allocation Eligibility | **Low (~30%)** | Yes (`eligibility`, Anaplan) | No | POC `eligibility_cleaned_*` only | PSO × Store × Week grain; future feed; not in dev pipeline |
| 15 | StyleColor-Store Eligibility | **Low (~25%)** | Partial | No | None | Derivable from `eligibility` (PSO) + style_option map; not built |

**Legend:** Overall % = rough end-to-end readiness (source → BQ raw → master → grain/time spec). Not a row-count metric.

**Scorecard:** 0 fully done · 3 high · 3 medium · 8 low/none · **1 confirmed N/A (ASN)**


## Detail by requirement

### 1. Location Master: **High (~85%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `location_details/`, `location_group_hierarchy/` (Nov 20251118) |
| BQ raw | Yes | `lulu_sourcing_dev.location_details`, `location_group_hierarchy` |
| Master | Yes | `lulu_ingestion_dev.store_master` via `store_intermediate` |
| Grain | Match | 1,853 locations |
| Time | Match | Latest snapshot |
| EDA | Done | [`raw_location_*_eda.md`](raw_location_details_eda.md) |

**Gaps:** Connector still reads May sample path, not consolidated. Master `active` flag misleading (~912 operational stores).


### 2. Product Master: **Medium (~70%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `product_group_hierarchy/`, `sku_details/` (Aug priced), `product_attribute_s/` |
| BQ raw | Yes | All three extraction tables |
| Master | Yes | `product_master` via `product_intermediate` |
| Grain | Match | SKU / channel-suffixed `product_code` |
| Time | Partial | Latest snapshot; `FLEX_STATUS` lost in master (hardcoded ACTIVE) |

**Gaps:** ~33% of catalog SKUs reach master after filters. Current BQ `sku_details` load is zero-priced (Nov sample); consolidated has Aug priced shards.


### 3. Fiscal Calendar: **High (~80%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `calendar_hierarchy/` (1 file) |
| BQ raw | Yes | `calendar_hierarchy` (bootstrapped from outbound, not GCS DAG) |
| Master | Yes | `fiscal_date_mapping` |
| Grain | Match | Day (`DAY_ID`) |
| Time | Partial | 2015-02-02 → 2028-01-30 (~13 yrs hist, ~2 yrs future) |

**Gaps:** Spec wants 5 years future (FY2030). See [`fiscal_calendar_eda.md`](fiscal_calendar_eda.md).


### 4. Inventory Data: **Medium (~55%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `inventory_snapshot/` (224 files, snap 20251204, ~474 GB) |
| BQ raw | Yes | `inventory_snapshot` (May sample: 403M rows, **33 snapshot dates**) |
| Master | Yes | `inventory_master` built from **`inventory_snapshot_cleaned`** (16.4B rows), not raw extract |
| Grain | Match | SKU × Location × Day |
| Time | Partial | Raw extract: 2023 + Nov 2025, **2024 gap**. Cleaned table has deeper history |

**Gaps:** Raw extraction not refreshed from consolidated Dec batch. Time coverage vs "2 years + YTD" needs validation on cleaned path.


### 5. Transaction Data: **Medium (~65%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `sales_transactions/` (64 files, Nov 20251118) |
| BQ raw | Yes | `sales_transactions` (683.6M rows, 2015 to 2025) |
| Master | Yes | `transaction_master` (352M rows after filters) |
| Grain | Partial | Raw has `SALES_ORDER_ID` + `SALES_ORDER_ITEM_ID`; **master rolls up** to date × store × product |
| Time | Match | Exceeds 2-year requirement |

**Gaps:** `returns_transactions` in consolidated GCS; join to sales validated (see [`raw_returns_transactions_eda.md`](raw_returns_transactions_eda.md)) but not landed in BQ or merged into master. Master drops zero-qty rows. No txn/line grain in master.


### 6. Discount at Transaction: **Low (~15%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Partial | `price_book/` (style-option × loc × effective dates); not line-level discount |
| BQ raw | No | n/a |
| Master | Stubs | `unit_discount_amount`, `total_discount_amount`, `clearance` = 0 |

**Gaps:** No dedicated discount-at-transaction feed. `price_book` may support derived discount logic (join by style-option, store, date). See [`lululemon_client_open_questions.md`](lululemon_client_open_questions.md) #11.


### 7. Holidays and Store Closure: **Low (~25%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `promotional_events/` (5 files, `LOC_ID`, `START_DATE`, `END_DATE`, `LOCATION_CLOSED_FLAG`) |
| BQ raw | No | n/a |
| Master | POC only | `events_master` from outbound `promotional_events_cleaned`; **not in active pipeline** |
| Time | Unknown | Need EDA on future 2-year span |

**Gaps:** Not extracted to `lulu_sourcing_dev`. No dedicated holiday calendar (promo events may include closures).


### 8. Purchase Order: **Low (~20%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `purchase_orders/` (16 files; `PURCHASE_ORDER_ID`, `SKU_ID`, dates, units) |
| BQ raw | No | n/a |
| Master | No | n/a |
| Grain | Partial | PO × SKU (no explicit PO line ID column in header) |
| Time | Unknown | Needs EDA vs 2yr + YTD + future |

**Gaps:** Full pipeline not built. Confluence stub: "Delta Feed for DC or PO or ASN" still TODO.


### 9. ASN: None (0%), confirmed N/A

| Layer | Status | Notes |
|---|---|---|
| GCS consolidated | No | No ASN view in historic catalog |
| Client | Confirmed | [`PROJECT_CONTEXT.md`](../PROJECT_CONTEXT.md): "Lululemon doesn't have ASN" |

InventorySmart references ASN for allocation UI; data must come from PO/transfer paths or client clarification.


### 10. Receipts: **Low (~15%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Partial | `transfer_orders/` (`UNITS_RECEIVED`, `DATE_RECEIVED`; transfer_id not receipt_id) |
| BQ raw | No | POC `transfer_orders_cleaned_20251119` in outbound only |
| Master | No | n/a |

**Gaps:** No true receipt_id grain. PO feed has `DATE_RECEIVED` / `UNITS_RECEIVED` as alternative receipt signal.


### 11. Future Promotions Pricing: **Low (~20%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Partial | `price_book/`, `planned_sales/`, `promotional_events/`, Anaplan demand (reg + discount forecast cols) |
| BQ raw | No | n/a |
| Grain | Partial | `price_book` = style-option × loc × week window; not full hierarchy × week promo calendar |

**Gaps:** No landed table. May combine `price_book` + `planned_sales` + Anaplan for future price/promo features.


### 12. Product attributes: **Medium (~50%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `product_attribute_s/`, `_s_seasonal/`, `_so/`, `_so_seasonal/`, `style_option/` |
| BQ raw | Partial | **`product_attribute_s` only** (258K rows) |
| Master | Partial | Style-level attrs joined into `product_master`; 102 cols truncated in build |

**Gaps:** Style-option and seasonal attribute feeds not extracted. `FLEX_STATUS` exists in source but stubbed in master.


### 13. Product Time dependent attributes: **Low (~25%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `product_attribute_s_seasonal/`, `product_attribute_so_seasonal/` (`QUARTER_ID`, `FLEX_SEASON_CODE`, `FLEX_STATUS`) |
| BQ raw | No | n/a |
| Master | No | n/a |
| Grain | Partial | Quarter-bounded, not explicit start/end dates on every row |

**Gaps:** Must-have for ForecastSmart per client list; not productionalized. Map quarter → date range via fiscal calendar.


### 14. SKU-Store Allocation Eligibility: **Low (~30%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Yes | `eligibility/` (PSO × Store × Week), Anaplan assortment/allocation calendars |
| BQ raw | No | POC `eligibility_cleaned_20251119` in outbound |
| Grain | Partial | Feed is **Planning Style Option × Store × Week**, not SKU × Store × date range |
| Time | Future | `WP_FIRST_SELLING_WEEK_ID`, `WP_WEEKS_AT_REG_PRICE` |

**Gaps:** Not in dev extraction DAG. Need SKU roll-up from PSO + size curve or client grain confirmation.


### 15. StyleColor-Store Eligibility: **Low (~25%)**

| Layer | Status | Source |
|---|---|---|
| GCS consolidated | Partial | Same `eligibility/` feed (PSO-level) + `style_option/` for style-color mapping |
| BQ raw | No | n/a |
| Master | No | Size Smart "StyleColor-Store Buy Eligibility" in broader IA requirements |

**Gaps:** No dedicated style-color × store feed. Likely derived: `eligibility` joined to `style_option` on `PLANNING_STYLE_OPTION_ID`.


## What we have productionalized today (7 raw + 5 masters)

**GCS extraction DAG → `lulu_sourcing_dev` (7 tables):**

`product_group_hierarchy`, `sku_details`, `product_attribute_s`, `location_group_hierarchy`, `location_details`, `sales_transactions`, `inventory_snapshot`

**Masters in active pipeline (5):**

`product_master`, `store_master`, `transaction_master`, `inventory_master`, `fiscal_date_mapping`

**Maps to requirements:** #1, #2, #3, #4 (partial), #5 (partial), #12 (partial): **6 of 15** with any BQ raw landing; **5 of 15** with masters.


## Consolidated GCS not yet in BQ (28 feeds)

Highest priority for ForecastSmart gaps:

| Priority | Consolidated feed | Unblocks req # |
|---|---|---|
| P0 | `returns_transactions` | #5 (returns in txn) |
| P0 | `price_book` | #6, #11 |
| P0 | `eligibility` | #14, #15 |
| P0 | `product_attribute_s_seasonal`, `_so`, `_so_seasonal` | #12, #13 |
| P1 | `promotional_events` | #7 |
| P1 | `purchase_orders` | #8, #10 (partial) |
| P1 | `transfer_orders` | #10 (proxy) |
| P2 | `planned_sales`, Anaplan demand | #11, forecast drivers |
| P2 | `inseason_demand_forecast` | external benchmark |

Full list: [`gcs_eda_2026/feed_sources.csv`](gcs_eda_2026/feed_sources.csv)


## Next steps (suggested)

1. Repoint 7 existing extractions to `consolidated/` after era-mix sign-off (especially Aug `sku_details`, Dec `inventory_snapshot`).
2. Add extraction + EDA for **returns_transactions**, **price_book**, **eligibility**, **promotional_events**, **purchase_orders**.
3. Build **product time-dependent** and **events** masters (or extend product_master / add events_master to pipeline).
4. Request **FY2030 calendar** extension from client (#3).
5. Confirm with client: ASN N/A (#9), receipt vs transfer_orders (#10), eligibility grain PSO vs SKU (#14).
