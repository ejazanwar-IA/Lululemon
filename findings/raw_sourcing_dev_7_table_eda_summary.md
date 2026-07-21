# Raw GCS extraction EDAs: consolidated findings

`Last updated: 2026-06-23.`

One-page summary of all seven `lulu_sourcing_dev` raw-table EDAs (May 2026). Full detail lives in the per-table files linked below.

**Dataset:** `lululemon-01042025.lulu_sourcing_dev`  
**Sync batch:** single snapshot (`2026-05-08T00:00:00`) on every table  
**Canonical per-table docs:** see [`lulu_eda_inventory.md`](lulu_eda_inventory.md)

| Table | Rows | Size | Full EDA |
|-------|-----:|-----:|----------|
| `product_group_hierarchy` | 18.2M | 1.11 GB | [`raw_product_group_hierarchy_eda.md`](raw_product_group_hierarchy_eda.md) |
| `sku_details` | 4.0M | 1.09 GB | [`raw_sku_details_eda.md`](raw_sku_details_eda.md) |
| `product_attribute_s` | 258K | 0.16 GB | [`raw_product_attribute_s_eda.md`](raw_product_attribute_s_eda.md) |
| `location_group_hierarchy` | 1,853 | 0.71 MB | [`raw_location_group_hierarchy_eda.md`](raw_location_group_hierarchy_eda.md) |
| `location_details` | 1,853 | 0.26 MB | [`raw_location_details_eda.md`](raw_location_details_eda.md) |
| `sales_transactions` | 683.6M | 90.83 GB | [`raw_sales_transactions_eda.md`](raw_sales_transactions_eda.md) |
| `inventory_snapshot` | 403.6M | 25.87 GB | [`raw_inventory_snapshot_eda.md`](raw_inventory_snapshot_eda.md) |


## Executive summary

| Theme | Finding |
|-------|---------|
| **Load duplication** | PGH ~2x EAV dupes; sku_details 4x identical rows per SKU; product_attribute_s 3x per STYLE_ID; inventory_snapshot ~2.1x on (SKU, LOC, DATE) |
| **Pricing broken** | sku_details: 100% zero `COST_PRICE` / `SELLING_PRICE`, `DUMMY_CURRENCY` (GCS batch scan shows Aug 2025 priced, Sep/Nov zero: see [`sku_details_gcs_batch_pricing_scan.md`](sku_details_gcs_batch_pricing_scan.md)) |
| **Lifecycle signal lost** | `FLEX_STATUS` in product_attribute_s is real (47% Drop / 43% Active); `article_status` in master is hardcoded `ACTIVE` |
| **SKU universe** | 988,764 SKUs in PGH and sku_details (perfect match); only ~33% reach product_master after build filters |
| **Store universe** | 1,853 locations in both location tables; only ~912 (~50%) are operationally active today |
| **Transactions** | 683,582,361 rows, 2015 to 2025; 25.7% zero-qty; synthetic order IDs; USD only; returns in separate feed (see [`raw_returns_transactions_eda.md`](raw_returns_transactions_eda.md)) |
| **Inventory** | 33 snapshot dates (2023 + Nov 2025 only; **2024 gap**); live master built from `inventory_snapshot_cleaned`, not this table |


## 1. `product_group_hierarchy`

**Role:** Primary spine for product master. Long-format EAV (6 cols) pivoted to 9 hierarchy levels, then channel-expanded (`ECOMM` / `RETAIL`).

### Headline metrics

| Metric | Value |
|--------|-------|
| Rows | 18,249,385 |
| Distinct `SKU_ID` | 988,764 (~18.5 rows/SKU; expected 9) |
| Hierarchy levels | 9 (BRAND → PLANNING_STYLE_SIZE) |
| Brands | 2 (`lululemon`, `ivivva`) |
| Completeness | 0% nulls/sentinels: cleanest product raw source |

### Key findings

- **~2x EAV duplication:** almost every `(SKU_ID, LEVEL_NAME)` pair appears twice (451K triplicated). Build uses `MAX(CASE WHEN ...)` so values resolve, but storage is 2x bloat.
- **STYLE level:** 21,741 names vs 43,642 codes (~2x: aligns with channel doubling).
- **~13K SKUs lack PLANNING_STYLE_SIZE**: affects `product_name` population in master.
- **Only 33% of SKU universe reaches master** (653K of ~1.98M expected after pivot × 2 channels). Drop at `WHERE sku_id_code IS NOT NULL` + join survivorship.

### Reliable / broken

| Reliable | Use with caution | Action |
|----------|------------------|--------|
| `SKU_ID` (never null) | 2x source bloat | Ask client if PGH load should dedup |
| Clean 9-level hierarchy | Some SKUs missing deep levels | Document filter rules |
| No sentinels | Single sync batch (no history) | n/a |

### Client questions

- Why ~2x EAV row duplication?
- Why ~13K SKUs lack PLANNING_STYLE_SIZE?
- Why does master ingest only 33% of SKUs?


## 2. `sku_details`

**Role:** LEFT JOIN for size, color, season, description on product master. Join key: `ID` = PGH `SKU_ID` + channel suffix.

### Headline metrics

| Metric | Value |
|--------|-------|
| Rows | 3,955,056 |
| Distinct `ID` | 988,764 (bijection with PGH) |
| Rows per `ID` | Exactly 4 (byte-identical) |
| Season | 100% `25-4WI` (2025 Winter) |
| Pricing | 100% zero cost/sell; `DUMMY_CURRENCY` |

### Key findings

- **4x identical row duplication** per SKU: build relies on `SELECT DISTINCT` to collapse.
- **Pricing completely missing** in BQ: blocks transaction_master cost/msrp lineage.
- **33% empty `IMAGE_URL`** (empty string, not NULL: `IS NULL` misses them).
- **11 segment values** (e.g. `lulu Womens`, `lulu Mens`): finer than gender alone.

### Reliable / broken

| Reliable | Broken |
|----------|--------|
| `ID`, `STYLE_CODE`, `COLOR_CODE`, `SIZE_CODE`, `DESCRIPTION` | `COST_PRICE`, `SELLING_PRICE` (100% zero) |
| `SIZE_NAME`, `SEASON_CODE`, `BRAND_NAME` | `PRICE_CURRENCY` (`DUMMY_CURRENCY`) |

### Client questions

- Why are prices 100% zero? Separate pricing feed?
- Why 4 identical rows per `ID`?
- Single season only: need historical seasons?


## 3. `product_attribute_s`

**Role:** Style-level wide table (100 cols). LEFT JOIN on `STYLE_ID` = PGH `STYLE_CODE`.

### Headline metrics

| Metric | Value |
|--------|-------|
| Rows | 258,405 |
| Distinct `STYLE_ID` | 86,135 |
| Rows per `STYLE_ID` | Exactly 3 |
| Build uses | 14 of 100 columns |
| `GENDER` populated | 96.3% |
| `PRODUCT_GENDER` populated | 16.6% (not used: correct) |

### Key findings

- **3x row duplication** per `STYLE_ID`: may multiply product_intermediate rows if not deduped (later confirmed internal DE ingest issue; GCS/outbound = 1 row/style).
- **`FLEX_STATUS`:** Drop 47.3%, Active 43.2%, `\N` 9.4%: real lifecycle field; master hardcodes `article_status = 'ACTIVE'`.
- **Sparse optional attrs:** `FIT_CLASSIFICATION` 65% missing, `PLANNING_PRODUCT_GROUPING` 54% missing, `SILHOUETTE` 47% missing.
- **86 unused columns** (apparel taxonomy: `FABRIC_FAMILY`, `INSEAM`, `RISE`, etc.): potential for modeling if enabled.

### Reliable / avoid

| Reliable | Avoid |
|----------|-------|
| `STYLE_ID`, `GENDER`, `FLEX_STATUS` | `PRODUCT_GENDER` (83% missing) |

### Client questions

- Wire `FLEX_STATUS` into `article_status`?
- Are 3 rows per `STYLE_ID` identical or encode a dimension?
- Which of 86 unused columns matter for forecasting?


## 4. `location_group_hierarchy`

**Role:** Store master spine. 44 cols of brand/market/channel/geo hierarchy → `s0_name`..`s5_name`.

### Headline metrics

| Metric | Value |
|--------|-------|
| Rows | 1,853 |
| `LOC_ID` uniqueness | Perfect (1:1 with location_details) |
| Brands | 100% LULULEMON (constant) |
| Markets | 4 (NAM 60%, China 17%, APAC 15%, EMEA 9%) |
| `LOC_TYPE` | S (store) 93%, W (warehouse) 7% |

### Key findings

- **Double-backslash sentinel `\\N`** on `PHYSICAL_DC_ID` (93%), `AREA_ID`, `REGION_ID`: canonical cleaning only strips `\N`, so `\\N` passes through as literal string.
- **`LOC_CLOSED_IND` naming trap:** `'1'` = 1,339 rows (mostly no close date); `'0'` = 315 rows (all have close date). Field name suggests opposite of data: verify with business.
- **`MARKET_CHANNEL_ID` = `location_details.CHANNEL_CODE`**: same identifier, different column names.
- **CMNTY vs COMMUNITY** naming split by region: use IDs not names for filters.
- **1 orphan `PRIMARY_DC_ID`**: points to non-existent location.

### Reliable / avoid

| Reliable | Avoid until confirmed |
|----------|----------------------|
| Market/channel/geo hierarchy (100% populated) | `LOC_CLOSED_IND` semantics |
| `LOC_ID` as join key | `PLANNING_MARKET_CURRENCY` (always USD: constant) |


## 5. `location_details`

**Role:** Second store master input. 15 cols: identity, type, channel, geo, dates.

### Headline metrics

| Metric | Value |
|--------|-------|
| Rows | 1,853 |
| `ID` uniqueness | Perfect |
| `TYPE_CODE` | RETAIL 81%, OUT_OF_SCOPE 11%, ECOM 3.5%, DC_ECOM 2.7%, VIRTUAL_DC 1.6% |
| Active stores today | **912 / 1,853 (49%)** |
| `DELETE_IND` | 100% `'false'` |

### Key findings

- **Zero actual NULLs**: sentinels only (`\N` or empty string `''`).
- **Cleaning gap:** `LATITUDE`/`LONGITUDE` use empty string (343 rows): `NULLIF(..., '\\N')` does not catch them.
- **Typo preserved:** `PERMANANENT_CLOSE_DATE` (double N).
- **30 future-dated opens** (`FIRST_OPEN_DATE > today`).
- **OUT_OF_SCOPE correlates with channel suffix** `_FO`, `_CMNTY`, `_STRAT`: 100% of those channels are out of scope.
- **Perfect 1:1 pass-through** to store_master (1,853 = 1,853).

### Active-store funnel

| Filter | Count | % |
|--------|------:|--:|
| Total | 1,853 | 100% |
| In-scope (`TYPE_CODE != OUT_OF_SCOPE`) | 1,645 | 89% |
| In-scope + not closed | 1,262 | 68% |
| **Active today** | **912** | **49%** |


## 6. `sales_transactions`

**Role:** Primary raw source for transaction master. ~11 years of history.

### Headline metrics

| Metric | Value |
|--------|-------|
| Rows | 683,582,361 |
| Date range | 2015-02-02 → 2025-11-18 (3,943 distinct dates) |
| Distinct SKUs | 765,813 (77% of PGH catalog) |
| Distinct locations | 1,217 (66% of stores) |
| Zero-qty rows | 25.7% |
| Currency | 100% USD |

### Key findings

- **Synthetic order IDs:** `SALES_ORDER_ID = DATE|SKU|LOCATION` for all 683.6M rows: no real basket/order grouping.
- **`TRANSACTION_TYPE` = `GROSS SALE` only**: no returns/exchanges/voids classified (351 negative-qty rows exist but unflagged).
- **`SALES_SERVICE_TYPE`:** BNM 83%, ECOM 17%.
- **Volume ~4x growth** 2015 → 2024; 2025 partial (Jan to Nov).
- **Zero nulls/sentinels**: cleanest raw source overall.

### Reliable / stub

| Reliable | Stub / filter |
|----------|---------------|
| SKU, location, date (100% populated) | Filter `UNITS > 0` for real sales |
| 11 years near-daily coverage | `TRANSACTION_TYPE` useless (single value) |
| USD prices after `SAFE_CAST` | Synthetic order IDs |


## 7. `inventory_snapshot`

**Role:** Intended raw source for inventory master. Daily grain: SKU × location × date.

### Headline metrics

| Metric | Value |
|--------|-------|
| Rows | 403,567,770 |
| Distinct (SKU, LOC, DATE) | 191,998,292 (~2.1x duplication) |
| Distinct dates | **33** (sparse; **2024 has zero data**) |
| Date range | 2023-02-23 → 2025-11-17 |
| Distinct locations | 1,568 (285 stores never appear) |

### Key findings

- **Live inventory_master was NOT built from this table**: built from `inventory_snapshot_cleaned` (16.4B rows). Master's only date (2025-08-28) is absent here.
- **2.1x duplication** concentrated on spike dates 2025-11-09 (50.7M) and 2025-11-16 (54.2M): multi-load same DATE.
- **`-1` sentinel** on `UNITS_ON_HAND` / `UNITS_AVAILABLE` (0.3 to 0.5%) = "unknown"; real negatives also exist (max -6,508).
- **93% of rows have `UNITS_INBOUND = 0`**: sparse inbound signal.
- **Median OH = 1**: half of rows have ≤1 unit on hand.

### Reliable / broken

| Reliable | Broken / missing |
|----------|------------------|
| SKU, location, date keys (100%) | 2024 date gap |
| 33 snapshot dates | 2025-08-28 not in table |
| | 2x duplication on spike dates |


## Cross-table integrity

| Relationship | Result |
|--------------|--------|
| PGH `SKU_ID` ↔ sku_details `ID` | Perfect bijection (988,764) |
| PGH SKUs ↔ sales_transactions SKUs | 77% overlap (223K never sold) |
| location_details `ID` ↔ LGH `LOC_ID` | Perfect bijection (1,853) |
| location_details ↔ store_master | Perfect bijection (1,853) |
| sales_transactions locations ↔ stores | 1,217 of 1,853 (66%) |
| inventory_snapshot locations ↔ stores | 1,568 of 1,853 (85%) |
| product_attribute_s `STYLE_ID` vs PGH STYLE | 86,135 PA styles vs 43,642 PGH STYLE codes (format/cardinality mismatch: join verified in open questions PM #10) |


## Top P0 / P1 flags (all tables)

| # | Table | Issue | Impact |
|---|-------|-------|--------|
| 1 | sku_details | 100% zero pricing | transaction_master cost/msrp broken |
| 2 | product_attribute_s | `article_status` hardcoded vs `FLEX_STATUS` | 47% Drop styles show as Active |
| 3 | product_group_hierarchy | ~2x EAV duplication | Storage bloat; dedup risk in builds |
| 4 | sku_details | 4x row duplication | Build depends on DISTINCT |
| 5 | product_attribute_s | 3x row duplication | Internal DE ingest (not client) |
| 6 | inventory_snapshot | Live master uses cleaned table, not this | Pipeline mismatch |
| 7 | inventory_snapshot | 2024 zero dates; 2x dupes on Nov spikes | Grain integrity |
| 8 | location_group_hierarchy | `LOC_CLOSED_IND` inverted semantics? | Wrong active-store filters |
| 9 | location_details / LGH | `\\N` vs `\N` sentinel split | Literal `\\N` in master cols |
| 10 | sales_transactions | 25.7% zero-qty; synthetic order IDs | Real-sales filter required; no basket analysis |
| 11 | product_group_hierarchy | Only 33% SKUs reach master | Assortment universe question |


## Related docs

- **Deduplicated index:** [`lulu_eda_inventory.md`](lulu_eda_inventory.md)
- **Table list:** [`lulu_sourcing_dev_tables.md`](lulu_sourcing_dev_tables.md)
- **Client open questions:** [`lululemon_client_open_questions.md`](lululemon_client_open_questions.md)
- **P0/P1 rollup:** [`consolidated_p0_p1_issues.md`](consolidated_p0_p1_issues.md)
- **GCS batch pricing:** [`sku_details_gcs_batch_pricing_scan.md`](sku_details_gcs_batch_pricing_scan.md)
- **Inventory cleaned (what master actually uses):** [`inventory_snapshot_cleaned_eda.md`](inventory_snapshot_cleaned_eda.md)
