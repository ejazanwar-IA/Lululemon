# Schema Inventory - Canonical Raw Tables

> **Master reference** for all 26 canonical tables. Contains: schemas, partitioning/clustering, row counts, sample rows.
> Pulled 2026-04-20. Sourced from `queries/schema_dump_all_canonical.sql` + `queries/sample_rows_all_canonical.sql`.

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🟢 **Complete reference doc. Use this before writing any query.**

**TL;DR:**

1. **26 canonical tables fully documented** — schemas, sizes, partition/cluster info, sample rows, quirks.
2. **Critical for cost:** `inventory_master` and `transaction_master` are partitioned by `date`. **Always filter by date.**
3. **3 tables use SKU_ID clustering** — filter/join on SKU_ID for pruning: `anaplan_allocation_calendar_cleaned`, `anaplan_fdod_alloc_cleaned`, `assortment_plan_cleaned`.
4. **Several tables have typos / quirks baked into schema** — `souricng` dataset name, `calender` (not calendar), `fullfilment` (not fulfillment), columns with spaces. Don't "fix" — use as-is.
5. **5 tables are CLONEs** (zero-copy pointers): `product_master`, `store_master`, `sku_details_cleaned`, `transaction_master`, `price_book`. Data can change if source does.

**What this doc unblocks:**

- Any analyst can pick up work without re-querying metadata
- Cross-table join logic (we have the identifier format map here)
- Cost-aware query writing (partition/cluster info)

---

## 💡 My Recommendations (as analyst)

1. **Before writing ANY BQ query**, spend 30 seconds checking this doc for:
   - Is the table partitioned/clustered? Add filters accordingly.
   - What's the grain / PK?
   - Are there any known sentinel values to watch?

2. **Bookmark the "Common Join Keys & Patterns" section below** — resolves 80% of "which column joins to which" confusion.

3. **Never blindly trust column types.** Several money columns are STRING (`price_book`), date columns are STRING (`transfer_orders_cleaned_20251119.DATE_SHIPPED`), lat/long are STRING. Cast before use.

4. **Three columns have spaces in their names** — require backticks: `` `Planning Style Option` ``, `` `Final FDOD` ``, `` `Min Pres` ``.

---

## Quick Reference — Tables by Size

| Table | Rows | Size (GB) | Partition | Cluster | Type |
|-------|-----:|---------:|-----------|---------|------|
| `inventory_master` | 7,214,258,665 | 650.48 | **`date`** | `store_code` | BASE TABLE |
| `eligibility_cleaned_20251119` | 2,302,517,438 | 254.79 | — | — | BASE TABLE |
| `returns_transactions_20251119` | 733,682,768 | 78.76 | — | — | BASE TABLE |
| `transfer_orders_cleaned_20251119` | 710,271,174 | 68.92 | — | — | BASE TABLE |
| `price_book` | 440,496,318 | 32.42 | — | — | **CLONE** |
| `transaction_master` | 389,872,378 | 73.53 | **`date`** | `channel` | **CLONE** |
| `eligibility_20251119` | 241,782,410 | 14.14 | — | — | BASE TABLE |
| `transfer_orders_new_cleaned` | 75,893,552 | 8.12 | — | `sku_id` | BASE TABLE |
| `anaplan_transit_calender_cleaned` | 51,276,624 | 3.93 | `Datestring` | — | BASE TABLE |
| `assortment_plan_cleaned` | 42,594,160 | 7.70 | — | `SKU_ID` | BASE TABLE |
| `anaplan_allocation_calendar_cleaned` | 39,230,138 | 7.22 | — | `SKU_ID` | BASE TABLE |
| `anaplan_fdod_replen_cleaned` | 30,918,903 | 1.41 | — | — | BASE TABLE |
| `purchase_orders_cleaned_20251119` | 20,803,006 | 2.92 | — | — | BASE TABLE |
| `anaplan_fdod_alloc_cleaned` | 16,032,486 | 1.44 | — | `SKU_ID` | BASE TABLE |
| `product_group_hierarchy` | 11,460,436 | 0.61 | — | — | BASE TABLE |
| `anaplan_min_pres_cleaned` | 8,839,533 | 1.36 | — | — | BASE TABLE |
| `product_master` | 1,977,528 | 1.05 | — | — | **CLONE** |
| `sku_details_cleaned` | 1,977,528 | 0.61 | — | — | **CLONE** |
| `dc_store_mapping_cleaned_20251119` | 1,110,005 | 0.07 | — | — | BASE TABLE |
| `style_option_20251119` | 469,512 | 0.05 | — | — | BASE TABLE |
| `promotional_events_cleaned_20251119` | 448,134 | 0.03 | — | — | BASE TABLE |
| `spatial_ai_cleaned` | 22,798 | 0.01 | — | — | BASE TABLE |
| `anaplan_store_priority_cleaned` | 8,828 | 0 | — | — | BASE TABLE |
| `calendar_hierarchy` | 4,746 | 0 | — | — | BASE TABLE |
| `store_master` | 1,853 | 0 | — | — | **CLONE** |
| `min_pres_eol` | 99 | 0 | — | — | BASE TABLE |

**🎯 Always use these filters for cost efficiency:**
- `inventory_master` → `WHERE date BETWEEN ...`
- `transaction_master` → `WHERE date BETWEEN ...`
- `anaplan_transit_calender_cleaned` → `WHERE Datestring BETWEEN ...`

---

## Common Join Keys & Patterns

### Product / SKU identifiers

| Column | Type | Format | Used in |
|--------|------|--------|---------|
| `product_code` | STRING | `145328501_ECOMM` (numeric + `_RETAIL`/`_ECOMM`) | `product_master`, `transaction_master`, `inventory_master`, `eligibility_cleaned_20251119` |
| `SKU_ID` / `sku_id` / `ID` | INT64 or STRING | Numeric, e.g., `145328501` | Many tables — raw form |
| `sku_id_channel` / `sku_id_code` | STRING | `145328501_ECOMM` | Bridge column in cleaned Anaplan / order tables |
| `product_code_original` | STRING | `145328501` (no suffix) | `product_master` — channel-agnostic |
| `article` | STRING | `LU9ADVS-036716_ECOMM` | `product_master`, `eligibility_cleaned_20251119` |
| `article_original` | STRING | `LU9ADVS-036716` | `product_master` |
| `ITEM_ID` | STRING | `LW3AYRS-8395` | `sku_details_cleaned` (= article without channel) |
| `STYLE_OPTION_ID` / `style_option_id` | STRING | `LW1CHQS-012826` | `price_book`, `assortment_plan_cleaned`, `style_option_20251119`, `min_pres_eol` |
| `STYLE_ID` / `style_code` | STRING | `LW1CHQS` | `style_option_20251119`, `sku_details_cleaned` |
| `planning_style_option` | STRING | `PHPSO\|LW1CHQS-012826` (with `PHPSO\|` prefix) | Anaplan tables |
| `planning_style_option_v1` | STRING | `LW1CHQS-012826` (no prefix) | Anaplan tables — cleaned version |

### Store / Location identifiers

| Column | Type | Format | Used in |
|--------|------|--------|---------|
| `store_code` / `STORE_ID` / `store_id` | STRING or INT64 | `0000011043` (10-digit zero-padded) or `11043` (int) | `store_master`, `transaction_master`, `inventory_master`, all Anaplan tables |
| `store` (alt name) | STRING | Same format | Some Anaplan tables use `store` instead of `store_code` |
| `LOC_ID` / `LOCATION_ID` / `LOCATION_ID_*` | STRING or INT64 | Integer or zero-padded | `price_book`, `transfer_orders_*`, `purchase_orders_*` |
| `channel_code` | STRING | `LLL_USA_RTL` | `store_master`, `transaction_master` |

### Date / Time identifiers

| Column | Type | Format | Used in |
|--------|------|--------|---------|
| `date` / `DAY_ID` | DATE | `2023-05-14` | `inventory_master`, `transaction_master`, `calendar_hierarchy` |
| `DATE_CREATED`, `DATE_SHIPPED`, etc. | DATE or STRING | `2023-06-12` | order tables |
| `Datestring` | DATE | Standard DATE | `anaplan_fdod_replen_cleaned`, `anaplan_transit_calender_cleaned` |
| `WEEK_ID` / `week_id` | INT64 | `202718` (YYYYWW) | `calendar_hierarchy`, `eligibility_*` |
| `QUARTER_ID` / `quarter_id` | INT64 or STRING | `20254` (YYYYQ) | Many tables |
| `SEASON_CODE` / `season_code` | STRING | `25-4WI` | `calendar_hierarchy`, `product_master`, `sku_details_cleaned` |

### Sentinel values to watch for

- **`\N`** (literal 2-char string) — sometimes used for "null" in string columns. Especially in `gender` in `product_master` and `PLANNING_STYLE_OPTION` in `assortment_plan_cleaned`.
- **`9999-12-31`** — "no end date" sentinel, e.g., `price_book.EFFECTIVE_TO_DAY_ID`
- **`1999-12-31`** and **`1999-01-11`** — old placeholder dates in `store_master.open_date` and similar
- **`0` in INT64 columns** — sometimes means "missing", sometimes means "zero" (be careful with `transaction_master.cost`, `msrp`, `qty`)

---

## Per-Table Details

### `product_master` — 1,977,528 rows, 1.05 GB, CLONE

**Purpose:** Product catalog / SKU attributes (~2M SKU × channel combinations). EDA complete. PK: `product_code`.

**Partition:** none. **Cluster:** none.

**Schema (46 columns):**

| # | Column | Type |
|---|--------|------|
| 1 | `l0_name` | STRING |
| 2 | `l1_name` | STRING |
| 3 | `l2_name` | STRING |
| 4 | `l3_name` | STRING |
| 5 | `l4_name` | STRING |
| 6 | `l5_name` | STRING |
| 7 | `l6_name` | STRING |
| 8 | `l7_name` | STRING |
| 9 | `l8_name` | STRING |
| 10 | `article_status` | STRING |
| 11 | `product_bucket_code` | INT64 |
| 12 | `l0_id` | STRING |
| 13 | `l2_id` | STRING |
| 14-19 | `l3_id`...`l8_id` | STRING |
| 20 | `product_name` | STRING |
| 21 | `size` | STRING |
| 22 | `product_code` | STRING |
| 23 | `product_description` | STRING |
| 24 | `article` | STRING |
| 25 | `active_flag` | INT64 |
| 26 | `color_code` | STRING |
| 27 | `color_description` | STRING |
| 28 | `color_family` | INT64 *(100% NULL)* |
| 29 | `ordering` | INT64 *(100% NULL)* |
| 30 | `launch_date` | INT64 *(100% NULL)* |
| 31 | `season_code` | STRING |
| 32 | `silhouette` | STRING |
| 33 | `planning_product_grouping` | STRING |
| 34 | `gender` | STRING *(73% NULL/`\N`, derive from l5_name)* |
| 35 | `flex_status` | STRING |
| 36 | `global_merch_team` | STRING |
| 37 | `fit_classification` | STRING |
| 38 | `design_line` | STRING |
| 39 | `designed_for_activity` | STRING |
| 40 | `product_line` | STRING |
| 41 | `size_scale` | STRING |
| 42 | `product_development_pod` | STRING |
| 43 | `product_size_definition` | STRING |
| 44 | `global_line_segment_style_category` | STRING |
| 45 | `product_code_original` | STRING |
| 46 | `article_original` | STRING |

**Sample:** Womens Shorts "BeCalm Mid-Rise Bermuda Short" XXS, RETAIL, color_code=1179 (Steel Blue), season_code=25-4WI, gender=`\N` but l5_name="Womens Shorts".

---

### `transaction_master` — 389,872,378 rows, 73.53 GB, **PARTITION BY `date`**, **CLUSTER BY `channel`**, CLONE

**Purpose:** Sales transactions (4 years, 2021-11 → 2025-11). EDA complete. PK: `transaction_code`.

**🎯 Always filter by `date` AND/OR `channel` for partition/cluster pruning.**

**Schema (32 columns):**

| # | Column | Type | Notes |
|---|--------|------|-------|
| 1 | `channel` | STRING | ECOMM / RETAIL |
| 2 | `line_id` | INT64 | 100% NULL |
| 3 | `brand` | STRING | 99.9999% "lululemon" |
| 4 | `launch_price` | INT64 | 100% NULL |
| 5 | `clearance` | INT64 | 100% 0 |
| 6 | `unit_discount_amount` | INT64 | 100% 0 |
| 7 | `total_discount_amount` | INT64 | 100% 0 |
| 8 | `qty` | INT64 | 27% = 0 |
| 9 | `transaction_type` | INT64 | 100% NULL |
| 10 | `store_code` | STRING | |
| 11 | `fullfilment_location_customer` | INT64 | 100% NULL (note typo) |
| 12 | `flagged_rows` | INT64 | 100% 0 |
| 13 | `transaction_code` | STRING | PK: `date\|product\|store` |
| 14 | `channel_code` | STRING | 12 values (USA_RTL, etc.) |
| 15 | `date` | DATE | partition key |
| 16 | `product_code` | STRING | |
| 17 | `revenue_before_tax` | INT64 | 100% NULL |
| 18 | `ship_to_country` | INT64 | 100% NULL |
| 19 | `freight_cost` | INT64 | 100% NULL |
| 20 | `ws_channel` | STRING | ECOM / RETAIL (dupes of `channel`) |
| 21 | `geography` | STRING | NA / CHINA / APAC / EMEA |
| 22 | `clearance_price` | INT64 | 100% 0 |
| 23 | `store_contribution` | INT64 | 100% NULL |
| 24 | `workstream` | INT64 | 100% NULL |
| 25 | `ecomm_country` | STRING | 23 countries |
| 26 | `revenue` | FLOAT64 | |
| 27 | `cost` | FLOAT64 | 100% 0.0 |
| 28 | `currency_exchange_rate` | INT64 | 100% NULL |
| 29 | `order_type` | INT64 | 100% NULL |
| 30 | `transaction_category` | INT64 | 100% NULL |
| 31 | `msrp` | FLOAT64 | 100% 0.0 |
| 32 | `price` | FLOAT64 | |

---

### `inventory_master` — 7,214,258,665 rows, 650.48 GB, **PARTITION BY `date`**, **CLUSTER BY `store_code`**

**Purpose:** Daily inventory snapshot per SKU per store. **7.2 BILLION rows.**

**🎯 CRITICAL: Always filter by `date` AND/OR `store_code`. A single unfiltered scan = 650 GB.**

**Schema (10 columns):**

| # | Column | Type | Notes |
|---|--------|------|-------|
| 1 | `brand` | STRING | |
| 2 | `date` | DATE | **partition key** |
| 3 | `oh` | INT64 | on-hand (can be negative per sample) |
| 4 | `it` | INT64 | in-transit |
| 5 | `oo` | INT64 | on-order |
| 6 | `wip` | INT64 | work-in-progress |
| 7 | `initial_oh_quantity` | INT64 | |
| 8 | `total_units` | INT64 | likely oh+it+oo+wip |
| 9 | `store_code` | STRING | **cluster key** |
| 10 | `product_code` | STRING | joins to product_master, transaction_master |

**Sample:** SKU `139603134_RETAIL` at store `0000010355` on 2023-05-14, oh=-1, it=0, oo=0, wip=0, total_units=-1. **Negative on-hand!**

---

### `store_master` — 1,853 rows, CLONE

**Purpose:** Store/location master. EDA complete. PK: `store_code`.

**Schema (34 columns):** `s3_name`, `s4_name`, `s2_name`, `s1_name`, `channel`, `s0_name`, `store_name`, `longitude` (STRING), `latitude` (STRING), `location_attrib_squareft` (INT64), `store_format_code`, `loc_type_code`, `ws_channel`, `location_num_store_name`, `zipcode`, `store_code`, `s3_id`, `location_hierarchy_region_code`, `company_name`, `channel_code`, `open_date` (STRING), `close_date` (STRING), `store_type`, `company_code`, `active` (STRING `"1"`/`"0"`), `geography`, `dc_flag` (INT64), `special_classification` (INT64, 100% NULL), `district_name`, `region`, `like_store_id`, `is_deleted` (BOOL), `city`, `state`.

**Key filters:**
- Physical retail: `dc_flag=0 AND store_format_code NOT IN ('E-COMMERCE','VIRTUAL') AND ws_channel NOT IN ('OUT_OF_SCOPE','VIRTUAL_DC')`
- DCs: `dc_flag=1` OR `store_type='DC'` OR `loc_type_code='W'`
- ECOM virtual: `store_format_code='E-COMMERCE'`

---

### `calendar_hierarchy` — 4,746 rows

**Purpose:** Fiscal calendar (2015-02-02 → 2028-01-30, 13 FY years). EDA complete. PK: `DAY_ID`.

**Schema (37 columns):** day/week/month/quarter/year IDs + descriptions + keys, plus `SEASON_CODE`, `BUYING_PERIOD`, `ADJUSTED_LY_WEEK_ID`/`_SID`, `ADJUSTED_2LY_WEEK_ID`/`_SID`.

---

### `sku_details_cleaned` — 1,977,528 rows, 0.61 GB, CLONE

**Purpose:** SKU-level details (parallel to product_master — same row count!). Provides style name, color name, size name, season name, brand, segment, image URL.

**Schema (23 columns):** `ID` (INT64), `ITEM_ID` (= article without channel, e.g., `LW3AYRS-8395`), `DESCRIPTION`, `PRICE_CURRENCY` (all "DUMMY_CURRENCY"!), `COST_PRICE` (INT64), `SELLING_PRICE` (INT64), `STYLE_NAME`, `STYLE_CODE` (INT64), `COLOR_NAME`, `COLOR_CODE` (INT64), `SEASON_NAME`, `SEASON_YEAR` (INT64), `SEASON_CODE`, `SIZE_NAME`, `SIZE_CODE`, `SIZE_RANK` (INT64), `BRAND_NAME`, `BRAND_CODE` (INT64), `SEGMENT_NAME`, `SEGMENT_CODE` (INT64), `IMAGE_URL`, `channel`, `sku_id_code` (bridge = `ID_channel`).

**Relationship to product_master:** Same row count (1,977,528). Join on `sku_id_code = product_code` OR `ID = product_code_original` (type conversion needed).

**Quirk:** `PRICE_CURRENCY = "DUMMY_CURRENCY"`, `COST_PRICE = 0`, `SELLING_PRICE = 0` in samples — these fields appear not populated.

---

### `product_group_hierarchy` — 11,460,436 rows

**Purpose:** Long-format product hierarchy. Each row = 1 (SKU × level × value). Unpivoted version of what `product_master` stores wide.

**Schema (5 columns):** `SKU_ID`, `LEVEL_NUMBER`, `LEVEL_NAME` (e.g., `CLASS`, `SUBCLASS`, `STYLE`), `VALUE_NAME` (e.g., `"Womens Shorts/Skirts"`), `VALUE_CODE` (e.g., `100110102106`).

**Why this exists:** alternative way to query hierarchy level names. Width = 5.7 levels avg per SKU → 11.46M / 2M SKUs.

---

### `returns_transactions_20251119` — 733,682,768 rows, 78.76 GB

**Purpose:** Sales returns. Parallel to `transaction_master` but for returns only.

**Schema (8 columns):** `SKU_ID` (INT64), `LOCATION_ID_SALES` (INT64), `DATE_TRANSACTION` (DATE), `SALES_ORDER_ID` (STRING, format `DATE|SKU|STORE|RETURNS`), `SALES_ORDER_ITEM_ID` (STRING), `UNITS` (INT64), `CURRENCY_CODE` (STRING), `PRICE_SALES_TOTAL` (FLOAT64).

**🔴 Sample red flag:** All 3 sample rows show `UNITS=0` AND `PRICE_SALES_TOTAL=0`. Possibly same zero-event pattern as `transaction_master` (needs EDA verification).

**No channel column** — unlike `transaction_master`. Channel must be inferred from `LOCATION_ID_SALES` by joining to `store_master`.

---

### `transfer_orders_cleaned_20251119` — 710,271,174 rows, 68.92 GB

**Purpose:** DC-to-store transfers (and DC-to-DC). Receipts proxy.

**Schema (13 columns):** `TRANSFER_ORDER_ID` (INT64), `SKU_ID` (INT64), `LOCATION_ID_SENDING` (INT64), `LOCATION_ID_RECEIVING` (INT64), `UNITS_ORDERED/SHIPPED/RECEIVED` (INT64), `DATE_CREATED` (DATE), `DATE_SHIPPED` (**STRING, not DATE!**), `DATE_RECEIVED` (DATE), `TYPE_NAME` (`INTRCO`/`ALLOC`/`REPLEN`), `channel`, `sku_id_code`.

**Quirk:** `DATE_SHIPPED` is STRING (inconsistent with other date columns).

---

### `transfer_orders_new_cleaned` — 75,893,552 rows, 8.12 GB, **CLUSTER BY `sku_id`**

**Purpose:** Newer / separate transfer orders feed.

**Schema (11 columns):** `transfer_order_id` (STRING), `sku_id` (STRING), `location_id_sending`/`receiving` (STRING), `UNITS_ORDERED/SHIPPED/RECEIVED` (INT64), `DATE_CREATED/SHIPPED/RECEIVED` (DATE), `TYPE_NAME`, `sku_id_channel`.

**Quirk:** Column position 12 is missing (skipped in schema). Probably a deleted column. Only 11 columns present.

---

### `price_book` — 440,496,318 rows, 32.42 GB, CLONE

**Purpose:** Price history per style-option × location with validity windows.

**Schema (8 columns, ALL STRING — including prices!):**

| # | Column | Type |
|---|--------|------|
| 1 | `STYLE_OPTION_ID` | STRING (e.g., `LW1AKZS-8650`) |
| 2 | `LOC_ID` | STRING |
| 3 | `EFFECTIVE_FROM_DAY_ID` | STRING (actually a date) |
| 4 | `EFFECTIVE_TO_DAY_ID` | STRING (`9999-12-31` = open-ended) |
| 5 | `ORIGINAL_PRICE` | STRING (needs `CAST(... AS FLOAT64)`) |
| 6 | `REGULAR_PRICE` | STRING |
| 7 | `CLEARANCE_PRICE` | STRING (often `\\N`) |
| 8 | `DELETE_IND` | STRING (`"true"`/`"false"`) |

**To use:** cast prices to FLOAT64, dates to DATE. Handle `\N` and `9999-12-31` sentinels.

---

### `purchase_orders_cleaned_20251119` — 20,803,006 rows, 2.92 GB

**Schema (17 columns):** `PURCHASE_ORDER_ID`, `SKU_ID`, `LOCATION_ID_RECEIVING` (all INT64), `UNITS_ORDERED/SHIPPED/RECEIVED/ALLOCATED/AVAILABLE` (INT64), `DATE_CREATED/SCHEDULED/SHIPPED/EXPECTED_DELIVERY/RECEIVED` (DATE), `PO_LINE_STATUS` (CANCELLED/CLOSED/etc.), `TYPE_NAME` (always `"PURCHASE_ORDER"`?), `channel`, `sku_id_code`.

---

### `eligibility_20251119` — 241,782,410 rows, 14.14 GB

**Purpose:** SKU-store week-level eligibility. "Which SKU can be sold at which store in which week."

**Schema (7 columns):** `PLANNING_STYLE_OPTION_ID` (STRING), `STORE_ID` (INT64), `WEEK_ID` (INT64), `QUARTER_NAME` (STRING), `WP_FIRST_SELLING_WEEK_ID` (INT64), `WP_FIRST_SELLING_DAY_ID` (DATE), `WP_WEEKS_AT_REG_PRICE` (INT64).

---

### `eligibility_cleaned_20251119` — 2,302,517,438 rows, 254.79 GB

**Purpose:** 10× larger than `eligibility_20251119`. Cleaned + expanded (SKU-level instead of style-option-level).

**Schema (11 columns):** Same as above PLUS `week_id_int` (INT64, redundant?), `channel`, `SKU_ID`, `product_code`, `article`.

**🔴 10× size difference from `eligibility_20251119`** needs investigation — is it expanded per SKU (Style×Sizes×Channels)?

---

### `assortment_plan_cleaned` — 42,594,160 rows, 7.70 GB, **CLUSTER BY `SKU_ID`**

**Purpose:** Quarterly assortment plan per SKU × store. "Is this SKU planned to be at this store this quarter."

**Schema (23 columns):** `quarter_id`, `style_option_id`, `store_id`, `ASSORT_TO_STORE` (BOOL), `AP_WKS_AT_REGULAR_PRICE`, `AP_FIRST_SELLING_WEEK_ID`, `AP_RETAIL_PRICE_USD/LOCAL` (FLOAT64), `COMP_SO`, `CURRENCY_ID`, `AP_SEGMENTATION`, `GENDER`, `AP_ACTIVE_VS_DROP`, `AP_STATUS`, `PLANNING_STYLE_OPTION` (with `\N` sentinels), `PLACEHOLDER_COLOUR_LONG_DESC`, `ACTIVITY_DETAILS_FTW`, `FLEX_SIZE_VALUE` (CSV-encoded list, e.g., `"XXXS,XXS,XS,S,M,L,XL"`), `planning_style_option_v1`, `SKU_ID`, `ap_first_selling_week_id_int`, `channel`, `sku_id_channel`.

**Quirk:** `FLEX_SIZE_VALUE` is a comma-separated list in a single string — will need `SPLIT()` if used.

---

### `anaplan_allocation_calendar_cleaned` — 39,230,138 rows, **CLUSTER BY `SKU_ID`**

**Purpose:** Allocation calendar per SKU × store. When to allocate, effective dates.

**Schema (17 columns):** `custom_quarter`, `c1_store_planning_style_option`, `store`, `planning_style_option`, `planning_style_option_v1`, `custom_quarter_code` (INT64), `wp_first_selling_date`, `wp_last_selling_date`, `allocation_deadline`, `allocation_in_store_date`, `allocation_effective_available_date` (all DATE), `allocation_dc_override` (INT64), `sub_market_alloc_override`, `primary_fulfillment_logic`, `future_quarter` (all BOOL), `SKU_ID`, `sku_id_channel`.

---

### `anaplan_fdod_alloc_cleaned` — 16,032,486 rows, **CLUSTER BY `SKU_ID`**

**Purpose:** FDOD (Forward Days of Demand) + WOS (Weeks of Supply) config per SKU × store. Used for allocation logic.

**Schema (8 columns):** `planning_style_option`, `planning_style_option_v1`, `store`, `final_fdod` (INT64), `final_WOS` (INT64), `SKU_ID`, `channel`, `sku_id_channel`.

---

### `anaplan_fdod_replen_cleaned` — 30,918,903 rows

**Purpose:** Daily FDOD config for replenishment per style × store.

**Schema (4 columns):** `Datestring` (DATE), `Planning Style Option` (STRING — note the space in column name!), `store`, `Final FDOD` (INT64 — also has space).

**Quirk:** Column names have spaces — always quote with backticks.

---

### `anaplan_min_pres_cleaned` — 8,839,533 rows

**Purpose:** Minimum presentation quantity per style × store × size.

**Schema (11 columns):** `c2_store_planning_size`, `planning_size_code`, `store_code`, `min_pres_qty_final` (INT64), `override_min_pres_weeks` (INT64, can be -1), `max_str_u_qty_final` (INT64), `max_pres_weeks` (INT64), `min_pres_additive_final`, `max_as_zero_user_ip`, `oo_maintained_stores` (BOOL), `min_pres_weeks` (INT64, can be -1).

**Note:** `planning_size_code` has `PHPSZ|` prefix (different from `PHPSO|` for style option).

---

### `anaplan_transit_calender_cleaned` — 51,276,624 rows, **PARTITION BY `Datestring`**

**Purpose:** Transit time per DC × store × subclass × date.

**Schema (8 columns):** `distribution_center_code`, `transit_calendar_eligible_order_types` (e.g., `"REPLEN"`), `Period` (STRING, e.g., `"31 Oct 25"`), `l5_store_code`, `m5_sub_class_code` (`PHSBC|` prefix), `Datestring` (**partition key**), `total_lead_processing_time` (INT64), `effective_store_processing_time` (INT64).

**Filter for cost:** `WHERE Datestring BETWEEN ...`.

---

### `dc_store_mapping_cleaned_20251119` — 1,110,005 rows

**Purpose:** Primary/secondary DC assignment per store × subclass × quarter.

**Schema (14 columns):** `QUARTER_ID` (INT64), `STORE_ID`, `SUBCLASS_ID` (INT64), `PRIMARY_DC_ID` (INT64), `PRIMARY_DC_ALLOC_LEAD_TIME`/`REPLEN`/`SPECIAL_LEAD_TIME` (INT64), `SECONDARY_DC_ID` (**STRING, not INT64** — inconsistent), `SECONDARY_DC_ALLOC/REPLEN/SPECIAL_LEAD_TIME` (**STRING**), `OOZ_FLAG` (STRING `"false"`), `PRIMARY_FULFILLMENT_LOGIC` (STRING), `MAPPING_TYPE` (`"PO"`/`"ALLOC"`).

**🔴 Type inconsistency:** Primary DC columns are INT64 but Secondary are STRING.

---

### `anaplan_store_priority_cleaned` — 8,828 rows

**Schema (3 columns):** `store_code`, `division_code` (with `PHDIV|` prefix), `is_selected` (BOOL).

---

### `spatial_ai_cleaned` — 22,798 rows

**Purpose:** Consumer demography scores per location × quarter. 48 behavioral segments (Sweet Treats, Coffee Connoisseur, Wine Lovers, Yoga Advocates, LGBTQ Culture, etc.).

**Schema (51 columns):** `QUARTER_ID` (STRING), `LOCATION_ID` (STRING), then 48 `ED0x_*`, `EE0x_*`, `EF0x_*`, `EG0x_*`, `EH0x_*`, `EI0x_*`, `EJ0x_*`, `EK0x_*`, `EB03_LGBTQ_CULTURE` (all FLOAT64).

**🔴 Type inconsistency:** `EF03_AWESTRUCK` and `EF04_HAPPY_PLACE` are STRING (all others are FLOAT64). Need cast if used numerically.

---

### `style_option_20251119` — 469,512 rows

**Schema (9 columns, all STRING):** `STYLE_OPTION_ID`, `STYLE_ID`, `COLOURWAY_ID`, `PLANNING_STYLE_OPTION_ID`, `STYLE_OPTION_NAME`, `IS_PRIMARY_STYLE_OPTION` (`"true"`/`"false"`), `DELETE_IND`, `PLACEHOLDER_FLAG`, `ORIGINAL_STYLE_ID`.

---

### `promotional_events_cleaned_20251119` — 448,134 rows

**Schema (7 columns):** `LOC_ID`, `TYPE` (STRING, e.g., `"Holiday"`), `NAME` (e.g., `"VALDAY"`, `"IDAY"`, `"TMBSWP"`), `START_DATE` (DATE), `END_DATE` (DATE), `DESCRIPTION` (e.g., `"Valentines Day"`), `LOCATION_CLOSED_FLAG` (BOOL).

---

### `min_pres_eol` — 99 rows

**Purpose:** Reference table (very small). Min presentation and EOL (end-of-life) per style-option × store × size.

**Schema (7 columns):** `plan_quarter_id` (INT64), `style_option_id`, `store_id` (INT64), `Size` (STRING — has spaces), `Min Pres` (INT64 — has space), `EOL` (INT64), `string_field_6` (appears unused).

**Note:** Column names have spaces — quote with backticks.

---

## Noteworthy Schema Patterns

### Columns with typos (don't "fix" in queries)
- `transaction_master.fullfilment_location_customer` (should be "fulfillment")
- `anaplan_transit_calender_cleaned` table name (should be "calendar")
- `calender_hierarchy` ref in Dataset Inventory (calendar_hierarchy is correct)

### Columns with spaces (quote with backticks)
- `anaplan_fdod_replen_cleaned.Planning Style Option`
- `anaplan_fdod_replen_cleaned.Final FDOD`
- `min_pres_eol.Min Pres`

### Prefix conventions in Anaplan / planning tables
- `PHPSO|` → planning style option
- `PHPSZ|` → planning size
- `PHSBC|` → planning subclass
- `PHDIV|` → planning division

### Bridge columns for channel-aware joins
- `sku_id_channel` and `sku_id_code` — both formats seen, both = `<SKU_ID>_<CHANNEL>` (e.g., `145328501_ECOMM`)

---

## References

- Full dataset inventory: [`findings/dataset_inventory.md`](dataset_inventory.md)
- Project context: [`PROJECT_CONTEXT.md`](../PROJECT_CONTEXT.md)
- Query files: `queries/schema_dump_all_canonical.sql`, `queries/sample_rows_all_canonical.sql`
