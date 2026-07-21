# Lululemon Forecasting Table Refresh Guide

`Last updated: 2026-06-15.`

## Purpose

Use this as the single quick-reference file for getting back up to speed on Lululemon forecasting data at IA. It summarizes what the important tables are, what they are made from, their grain, how they join, and the caveats that matter before handing data to the Forecast Smart / ADA team.

Primary sources condensed here:

- `raw_to_master_lineage.md`
- `schema_inventory.md`
- `master_bq_health_check_2026-05-20.md`
- `master_product_master_eda.md`
- `master_store_master_eda.md`
- `master_transaction_master_eda.md`
- `master_inventory_master_eda.md`
- `product_master_hierarchy_decoded.md`
- `fiscal_date_mapping_pipeline.md`
- `lululemon_ingestion_end_to_end.md`

## One-Minute Mental Model

Forecasting is driven by clean master tables, not by raw tables directly.

```text
Lululemon AWS S3
-> BigQuery raw: lululemon_souricng_outbound
-> Sourcing/intermediate: lulu_sourcing_dev
-> Ingestion masters: lulu_ingestion_dev
-> Injection datasets
-> PostgreSQL lulu_dev
-> Forecast Smart / ADA Visual
-> Offline 13-week forecast outputs
```

SOW forecast grain:

- Phase 1 primary: `PSS x Store/DC x Week`
- Phase 1 daily breakdown: `PSS x Store/DC x Day`
- Phase 2: unit-level forecasts with confidence intervals

Your role is mainly data/integration readiness: stable masters, known caveats, fiscal mapping, refreshability, and Postgres sync health.

## Main Tables At A Glance

| Table | Layer | Purpose | Grain | Forecast relevance |
|---|---|---|---|---|
| `product_master` | Master | Product hierarchy and SKU attributes | One row per `product_code` | Defines product/PSS universe and attributes |
| `store_master` | Master | Store/DC/location hierarchy | One row per `store_code` | Defines Store/DC geography and channel |
| `transaction_master` | Master fact | Historical sales demand | One row per `date x store_code x product_code` | Main demand history |
| `inventory_master` | Master fact | Inventory position | One row per `date x store_code x product_code` | Availability and current-week signal |
| `fiscal_date_mapping` | Master/calendar | Calendar to fiscal week/day | One row per calendar date | Required for week/day forecast grain |
| `events_master` | Master/event | Promo/store event calendar | One row per store-event/date span | Optional demand driver |
| `eligibility_cleaned_20251119` | Raw/cleaned | SKU-store-week eligibility | Likely `SKU x Store x Week` | Forecast/allocation eligibility |
| `assortment_plan_cleaned` | Raw/cleaned | SKU-store-quarter assortment plan | `SKU x Store x Quarter` | Future assortment/eligibility signal |
| `anaplan_allocation_calendar_cleaned` | Raw/cleaned | Allocation timing | `SKU x Store x allocation dates` | Launch/allocation timing |
| `price_book` | Raw/cleaned | Price history | Style-option x location x validity window | Could populate price/discount stubs |

## Core Master Lineage

| Master | Primary source | Joined sources | Join keys | Grain | Important filter/build note |
|---|---|---|---|---|---|
| `product_master` | `product_group_hierarchy_cleaned_20251119` | `sku_details_cleaned_20251119`, `product_attribute_s_20251119` | `sku_id_code`; `STYLE_CODE = STYLE_ID` | One row per channel-suffixed SKU | `product_code` is the key |
| `transaction_master` | `sales_transactions_4y_cleaned_20251119` | `product_group_hierarchy_cleaned_20251119`, `sku_details_cleaned_20251119`, `store_master` | `sku_id_channel = sku_id_code`; `location_id_sales = store_code` | `date x store x product` | Use real sales filter |
| `inventory_master` | `inventory_snapshot_cleaned` | `product_group_hierarchy_cleaned` | `sku_id_channel = sku_id_channel` | `date x store x product` | Current master is single-date POC in health check |
| `store_master` | `location_group_hierarchy_cleaned_20251119` | `location_details_cleaned_20251119` | `loc_id = id` | One row per location | `active` name is misleading |
| `events_master` | `promotional_events_cleaned` | none | `loc_id` | One row per store event | Not deeply used yet |
| `fiscal_date_mapping` | `calendar_hierarchy` | none | `DAY_ID` | One row per calendar date | Critical for week/day forecast |

Only around 10 raw tables feed the masters directly. Many other useful raw tables exist but are not folded into masters yet.

## Join Keys You Should Remember

### Product Keys

| Key | Format | Used in | Notes |
|---|---|---|---|
| `product_code` | `145328501_RETAIL` or `145328501_ECOMM` | `product_master`, `transaction_master`, `inventory_master`, eligibility | Main channel-suffixed SKU key |
| `product_code_original` | `145328501` | `product_master` | Bare SKU, useful for inventory channel mismatch |
| `sku_id_channel` / `sku_id_code` | `<SKU_ID>_<CHANNEL>` | raw and cleaned feeds | Bridge into `product_code` |
| `article` | style-color-channel | `product_master`, eligibility | Often maps to style option with channel |
| `article_original` | style-color without channel | `product_master` | Useful for PSO-style logic |
| `STYLE_OPTION_ID` | style-color | `price_book`, assortment, style option | Usually no SKU size |

### Store Keys

| Key | Format | Used in | Notes |
|---|---|---|---|
| `store_code` | often zero-padded 10-char string | masters and Anaplan tables | Main store join key |
| `LOCATION_ID` / `LOC_ID` / `STORE_ID` | int or string | raw feeds | Cast and pad carefully |
| `channel` | RETAIL, ECOMM, FO, STRAT, CMNTY, COMMUNITY | `store_master`, `inventory_master` | Location channel, not always same as product suffix |
| `channel_code` | e.g. `LLL_USA_RTL` | store/txn | Do not parse without a map |

### Date Keys

| Key | Format | Used in | Notes |
|---|---|---|---|
| `date` | DATE | `transaction_master`, `inventory_master`, fiscal joins | Partition key for large masters |
| `DAY_ID` | DATE | `calendar_hierarchy` | Calendar date |
| `WEEK_ID` | `YYYYWW` integer | fiscal, eligibility | Forecast week grain |
| `SEASON_CODE` | e.g. `25-4WI` | product/calendar | Product master is mostly current snapshot |

## Master Table Details

### `product_master`

Purpose: product catalog and hierarchy used to define forecast product universe.

Current health-check state:

- Rows: `1,977,528`
- Grain: `product_code` unique
- Channels: `RETAIL` and `ECOMM`, 50/50 split
- Primary key: `product_code`
- Important hierarchy: `l0_name` to `l8_name`, plus `l0_id`, `l2_id` to `l8_id`

How to think about hierarchy:

- `L0`: brand namespace, mainly `lululemon`, plus `ivivva`
- `L1`: channel, derived from SKU suffix
- `L2-L5`: business/category/planning hierarchy
- `L6`: planning concept/subclass
- `L7`: style
- `L8`: SKU/article-color-channel leaf

Important columns:

- `product_code`: channel-suffixed SKU, main join key
- `product_code_original`: bare SKU
- `article`: style-color-channel
- `article_original`: style-color without channel
- `product_name`, `size`, `color_code`, `color_description`, `season_code`
- `flex_status`: lifecycle signal; `Drop` should be excluded from forward-looking forecasts when available

Caveats:

- `active` or `active_flag` should not be blindly treated as real lifecycle.
- `article_status` was historically hardcoded as `ACTIVE`.
- `season_code` is current snapshot heavy, not full product time history.
- Gender can be unreliable or sparse; use `l2_name` / `l3_name` for gender-like filtering where possible.
- PM has only `_RETAIL` / `_ECOMM`; inventory can also have `_FO`, `_STRAT`, `_COMMUNITY`, `_CMNTY`.

### `store_master`

Purpose: store, DC, location, country, region, and channel dimension.

Current health-check state:

- Rows: `1,853`
- Grain: `store_code` unique
- Stores/DC split: around `1,724` stores and `129` DCs
- In-scope retail filter: usually `dc_flag = 0 AND channel = 'RETAIL'`

Important columns:

- `store_code`: main join key
- `store_name`
- `channel` / `s1_name`: RETAIL, ECOMM, FO, STRAT, CMNTY, COMMUNITY
- `channel_code`: full channel code
- `s2_name`: country
- `s3_name`: area
- `s4_name`: region
- `loc_type_code`: `S` store, `W` warehouse/DC
- `store_type`: Store or DC
- `dc_flag`: `0` store, `1` DC
- `active`: from `LOC_CLOSED_IND`, but name is misleading

Caveats:

- `channel = s1_name`, so those are effectively duplicates.
- `active` is a string and can be confusing. Do not assume the name means exactly what it says without checking definitions.
- Some intermediate columns like lat/long/open_date may not be in the ingested master depending on GSM mapping.
- FO, STRAT, CMNTY, COMMUNITY rows are mostly out-of-scope in raw `location_details`, but they still matter for inventory joins.

### `transaction_master`

Purpose: historical sales demand, the primary input to forecasting.

Current health-check state:

- Rows: `354,138,091`
- Date range: `2022-05-19` to `2025-11-18`
- Grain: `(date, store_code, product_code)` unique in health check
- Real sales: around `72.87%` where `qty > 0 AND revenue > 0`
- Partition: `date`
- Cluster: `channel`

Important columns:

- `date`: transaction date, partition key
- `store_code`: joins to `store_master`
- `product_code`: joins to `product_master`
- `qty`: units sold
- `revenue`: sales value
- `price`: derived/populated when quantity exists
- `channel`: RETAIL or ECOMM
- `geography`: NA, CHINA, APAC, EMEA
- `transaction_code`: synthetic-ish transaction key in the master

Use this filter for demand modeling/EDA:

```sql
WHERE qty > 0
  AND revenue > 0
```

Caveats:

- Around 27% of rows are zero qty/revenue/price style noise.
- `cost` and `msrp` are 100% zero in the checked load because source `sku_details` cost/selling price is zero.
- Many discount/clearance fields are hardcoded stubs: `clearance`, `unit_discount_amount`, `total_discount_amount`, `clearance_price`.
- Several descriptive columns are 100% NULL stubs, such as `line_id`, `transaction_type`, `freight_cost`, `order_type`, `transaction_category`.
- Transactions only use RETAIL/ECOMM; this aligns cleanly with `product_master`.

### `inventory_master`

Purpose: inventory position by product, store, and date. Needed for availability, in-stock logic, and current-week responsiveness.

Current health-check state:

- Rows in latest master health check: `5,539,053`
- Grain: `(date, store_code, product_code)` unique
- Distinct dates in checked master: `1`, date `2025-08-28`
- Distinct stores: `1,073`
- Distinct products: `487,587`

Schema shape in the ingested master:

- `display_product_code`: bare SKU
- `product_code`: channel-suffixed SKU
- `store_code`
- `date`
- `channel`
- `source_product_code`, `source_channel`
- `product_code_was_derived`, `channel_was_derived`
- `oh`: on-hand
- `it`: in-transit
- `oo`: on-order, 100% zero in checked master
- `oh_it_qty`
- timestamps

Caveats:

- Big blocker: the health-check master is still a single-date POC snapshot. Forecasting needs multi-date inventory history and current refreshes.
- Inventory has six channel suffixes: RETAIL, ECOMM, FO, STRAT, COMMUNITY, CMNTY.
- Product master only has RETAIL/ECOMM. Strict inventory-to-product join therefore shows apparent orphans for FO/STRAT/COMMUNITY/CMNTY.
- Bare SKU join resolves this: those "orphans" are channel suffix mismatch, not missing product.
- Negative `oh` exists in raw/master and likely represents corrections/oversell.
- `oo` is not really populated in current master; purchase/transfer feeds could populate it later.

### `fiscal_date_mapping`

Purpose: maps calendar date to fiscal week/day/month/quarter/year. Required because the SOW forecast grain is fiscal week and fiscal day.

Current state:

- Raw: `calendar_hierarchy`
- Intermediate: `fiscal_calendar_intermediate`
- Master: `fiscal_date_mapping`
- Rows: `4,746`
- Grain: one row per calendar date

Pipeline:

```text
calendar_hierarchy
-> fiscal_calendar_intermediate
-> fiscal_date_mapping
-> Dataflow validated table
-> Postgres global.fiscal_date_mapping
```

Caveats:

- Raw ends around `2028-01-30`, about two fiscal years forward. SOW wants 5-year future calendar.
- 53-week fiscal years exist, including FY2018 and FY2024, with FY2030 projected.
- Lululemon day numbering is `Mon=1` to `Sun=7`; IA OOTB examples may use `Sun=1`.
- `ADJUSTED_LY_WEEK_ID = 201401` is a sentinel and should be treated like NULL for YoY logic.

### `events_master` / `promotional_events_cleaned_20251119`

Purpose: promotional events and store closure/event calendar.

Source:

- `promotional_events_cleaned_20251119`

Likely grain:

- One row per location/event/date range.

Important fields:

- `LOC_ID`
- `TYPE`
- `NAME`
- `START_DATE`
- `END_DATE`
- `DESCRIPTION`
- `LOCATION_CLOSED_FLAG`

Caveats:

- Useful as a demand driver, but not currently one of the cleanly documented core forecast dependencies.
- Validate location join and date overlap before using in modeling.

## Forecast-Relevant Raw And Cleaned Tables

These are not all master tables, but they matter because they can explain missing fields, stubs, future eligibility, or allocation context.

### Product And Hierarchy Inputs

| Table | Purpose | Grain | Notes |
|---|---|---|---|
| `product_group_hierarchy_cleaned_20251119` | Main hierarchy source for PM and txn | long hierarchy rows by SKU/level | Most important product raw table |
| `product_group_hierarchy_cleaned` | Inventory brand lookup | SKU hierarchy | No `_20251119`; snapshot mismatch risk |
| `sku_details_cleaned_20251119` | Size, color, season, SKU detail | SKU-channel | Cost/selling price are zero |
| `product_attribute_s_20251119` | Product attributes | Style-level-ish | Source of fit, silhouette, gender, size scale |
| `style_option_20251119` | Style option reference | style option | All string columns |

### Sales, Returns, And Price

| Table | Purpose | Grain | Notes |
|---|---|---|---|
| `sales_transactions_4y_cleaned_20251119` | Raw sales feeding txn master | raw transaction/order rows | Main demand source |
| `returns_transactions_20251119` | Returns | return transaction rows | Not folded into txn master |
| `price_book` | Price history | style-option x location x validity window | Prices are STRING and need casting |

Forecasting note: `price_book` could help populate launch price, clearance price, and discounts, which are currently stubs in `transaction_master`.

### Inventory, Transfers, Purchase Orders

| Table | Purpose | Grain | Notes |
|---|---|---|---|
| `inventory_snapshot_cleaned` | Raw inventory snapshot | SKU x location x date | Primary source for inventory master |
| `transfer_orders_cleaned_20251119` | Transfers/receipts proxy | transfer order x SKU x sending/receiving location | `DATE_SHIPPED` is STRING |
| `transfer_orders_new_cleaned` | Newer transfer feed | transfer order x SKU x locations | Clustered by `sku_id` |
| `purchase_orders_cleaned_20251119` | PO / inbound supply | PO x SKU x receiving location | Candidate for `oo` and `wip` |

Forecasting note: these feeds are important if IA wants availability-aware forecasting or on-order/inbound signals. Current `inventory_master.oo` is not populated.

### Eligibility, Assortment, Allocation

| Table | Purpose | Grain | Notes |
|---|---|---|---|
| `eligibility_20251119` | SKU-store week eligibility at style-option level | style-option x store x week | Smaller base eligibility |
| `eligibility_cleaned_20251119` | Expanded eligibility | SKU x store x week | 10x larger; likely expanded by SKU/size/channel |
| `assortment_plan_cleaned` | Quarterly assortment plan | SKU x store x quarter | Clustered by `SKU_ID` |
| `anaplan_allocation_calendar_cleaned` | Allocation dates/windows | SKU x store x allocation dates | Clustered by `SKU_ID` |
| `anaplan_fdod_alloc_cleaned` | FDOD/WOS allocation config | SKU x store | Allocation planning context |
| `anaplan_fdod_replen_cleaned` | Daily replenishment FDOD | style option x store x date | Has column names with spaces |
| `anaplan_min_pres_cleaned` | Minimum presentation | style/size x store | Planning size code has `PHPSZ|` prefix |
| `anaplan_transit_calender_cleaned` | Transit lead time | DC x store x subclass x date | Table name is misspelled `calender`; partitioned by `Datestring` |
| `dc_store_mapping_cleaned_20251119` | DC-store assignment | store x subclass x quarter | Secondary DC columns are STRING |

Forecasting note: eligibility is a must-have forecasting feed. It tells which products are allowed or expected at which stores and weeks.

### Store/Spatial Inputs

| Table | Purpose | Grain | Notes |
|---|---|---|---|
| `location_group_hierarchy_cleaned_20251119` | Main location hierarchy | location | Feeds store master |
| `location_details_cleaned_20251119` | Location type and detail | location | Feeds store master |
| `spatial_ai_cleaned` | Demographic scores | location x quarter | Some score columns are STRING |
| `anaplan_store_priority_cleaned` | Store priority by division | store x division | Small table |

## Product Hierarchy Refresher

| Level | Meaning | Example |
|---|---|---|
| `L0` | Brand | lululemon, ivivva |
| `L1` | Channel | RETAIL, ECOMM |
| `L2` | Brand x business unit | lulu Womens, lulu Mens, lulu Footwear |
| `L3` | Division | Womens Tops, Mens Bottoms |
| `L4` | Department | Womens Pants, Mens SS-LS Tops |
| `L5` | Planning split/class | Womens Tights, Mens Pull On |
| `L6` | Subclass/planning concept | SP25 product concept |
| `L7` | Style | `LW9AWPS` |
| `L8` | SKU/article-color-channel | `LU9ADVS-036715_ECOMM` |

Rules of thumb:

- Use `product_code` for channel-specific SKU work.
- Use `product_code_original` for bare SKU reconciliation.
- Use `article_original` for style-color/PSO-style logic.
- Do not use `gender` blindly. Prefer `l2_name` / `l3_name`.
- Exclude `flex_status = 'Drop'` from forward-looking forecast universes when that column is available.

## Known Hardcoded Or Stubbed Columns

Around 44 master columns are hardcoded NULL, zero, or constants in the build logic. These are not necessarily client data-quality issues.

Important examples:

- `product_master.article_status = 'ACTIVE'`
- `product_master.active_flag = 1`
- `product_master.color_family = NULL`
- `product_master.launch_date = NULL`
- `transaction_master.line_id = NULL`
- `transaction_master.transaction_type = NULL`
- `transaction_master.clearance = 0`
- `transaction_master.unit_discount_amount = 0`
- `transaction_master.total_discount_amount = 0`
- `transaction_master.clearance_price = 0`
- `transaction_master.cost = 0`
- `transaction_master.msrp = 0`
- `inventory_master.oo = 0`
- `inventory_master.wip = 0`
- `inventory_master.initial_oh_quantity = 0`
- `fiscal_date_mapping.holiday = NULL`
- `fiscal_date_mapping.trend = NULL`

Do not raise every NULL/zero as a client data issue. First check whether it is a build stub.

## Biggest Open Issues

| Priority | Issue | Why it matters |
|---|---|---|
| P1 | Inventory channel suffix mismatch | Strict `inventory_master.product_code = product_master.product_code` fails for FO/STRAT/COMMUNITY/CMNTY |
| P2 | `inventory_master` single-date POC in health check | Forecasting needs multi-date/current inventory |
| P2 | Product Time Dependent Attributes missing | Forecasting must-have feed |
| P2 | Fiscal future horizon only to 2028 | SOW wants longer future calendar |
| P3 | Transaction discount/clearance fields are stubs | Limits promo/price explainability |
| P3 | Cost/MSRP are zero | Blocks margin/economics analysis |
| INFO | 63% of product master never sold | Expected due to assortment/channel universe, but know it |

## Query Safety And Cost Habits

Always filter large partitioned tables:

```sql
-- transaction_master
WHERE date BETWEEN DATE '2025-01-01' AND DATE '2025-01-31'

-- inventory_master
WHERE date = DATE '2025-08-28'

-- anaplan_transit_calender_cleaned
WHERE Datestring BETWEEN DATE '2025-01-01' AND DATE '2025-01-31'
```

For demand history, prefer:

```sql
WHERE qty > 0
  AND revenue > 0
```

For in-scope retail stores, usually start with:

```sql
WHERE dc_flag = 0
  AND channel = 'RETAIL'
```

For inventory-to-product when suffix mismatch matters:

```sql
ON SPLIT(inv.product_code, '_')[SAFE_OFFSET(0)] = pm.product_code_original
```

Then decide how to map FO/STRAT/COMMUNITY/CMNTY to RETAIL/ECOMM for attributes.

## Sentinel Values And Naming Traps

| Trap | Where | Meaning/action |
|---|---|---|
| `\N` | many string fields | Treat as null-like |
| `9999-12-31` | `price_book.EFFECTIVE_TO_DAY_ID` | Open-ended price validity |
| `201401` | fiscal adjusted LY week | Treat as null-like for YoY |
| `fullfilment_location_customer` | `transaction_master` | Typo is real; use as-is |
| `anaplan_transit_calender_cleaned` | table name | Misspelling is real; use as-is |
| columns with spaces | Anaplan/min_pres tables | Use backticks |
| money as STRING | `price_book` | Cast before numeric use |
| `DATE_SHIPPED` as STRING | transfer orders | Cast before date logic |

## What To Review Before A Forecasting/Data Session

1. Can we define forecast universe at `PSS x Store/DC x Week`?
2. Is `fiscal_date_mapping` synced and accepted by Postgres?
3. Are product/store/transaction/inventory masters current?
4. Is inventory multi-date and refreshable, or still single-date?
5. Are eligibility feeds ready for future weeks?
6. Are dropped products excluded?
7. Do we know the channel policy for FO/STRAT/COMMUNITY/CMNTY?
8. Are zero-sales rows filtered out?
9. Are stubs documented so they are not mistaken for client gaps?
10. Are missing product time-dependent attributes escalated?

## Fastest Reading Path If You Have 15 Minutes

Read this file in this order:

1. `One-Minute Mental Model`
2. `Main Tables At A Glance`
3. `Core Master Lineage`
4. `Master Table Details`
5. `Biggest Open Issues`
6. `Query Safety And Cost Habits`

If you need one deeper source after this, open `raw_to_master_lineage.md`.
