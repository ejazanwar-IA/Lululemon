# Lululemon intermediate builds v2 (canonical reference)

`Locked: 2026-07-17.` · Validated via pre/post `_tmp_20260717` tables in `lulu_sourcing_dev`.

**Authority:** the four `queries/Intermediate_table_builds/create_*_intermediate_historic_v2.sql` files are the source of truth for historic rebuild logic. This doc is the human-readable index; when in doubt, read the SQL.

**Scope:** `product_intermediate`, `store_intermediate`, `inventory_intermediate`, `transaction_intermediate` in `lululemon-01042025.lulu_sourcing_dev`. These feed platform `*_master` tables via Generic Schema Mapping (GSM), not directly.

---

## Agent / developer rule

When editing intermediate build SQL, explaining lineage, or comparing to old workbench scripts:

1. Start from the **v2 historic SQL** linked below.
2. Do **not** treat `queries/store_master_intermediate_build.sql`, `queries/transaction_intermediate_build.sql`, or v1 `create_*_historic.sql` as current unless explicitly doing a historical diff.
3. Periodic scripts (`create_*_intermediate_periodic.sql`) may still lag v2 until promoted; flag the gap if they diverge.

Cursor rule: [`.cursor/rules/lululemon-intermediate-builds-v2.mdc`](../.cursor/rules/lululemon-intermediate-builds-v2.mdc)

---

## Build order (dependencies)

| Order | Intermediate | Depends on |
|---:|---|---|
| 1 | `store_intermediate` | `location_group_hierarchy`, `location_details` |
| 2 | `product_intermediate` | `product_group_hierarchy`, `sku_details`, `product_attribute_s`, `eligibility` |
| 3 | `inventory_intermediate` | `inventory_snapshot`, `location_details` |
| 4 | `transaction_intermediate` | `sales_transactions`, **`product_intermediate`**, **`store_intermediate`**, `sku_details`, `price_book` |

Inventory does not join product/store intermediates in the build itself. Transaction **must** run after product and store.

---

## Shared conventions

| Topic | Rule |
|---|---|
| Project / dataset | `lululemon-01042025.lulu_sourcing_dev` |
| `product_code` grain | `{SKU_ID}_{channel}` where `channel` is `ECOMM` or `RETAIL` (product build expands both; txn/store derive channel from store or suffix) |
| `store_code` | `LPAD(LOC_ID, 10, '0')` |
| Time-series date window | `>= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)` (2 full prior calendar years + YTD). **Not** rolling 730 days. |
| Sentinel cleaning | `NULLIF(TRIM(col), '\\N')`; store v2 also strips `'\\\\N'` on `AREA_ID`/`REGION_ID` and `'N/A'` on `LOC_FORMAT` |
| Live promotion | Use dated `_tmp_YYYYMMDD` tables for pre/post comparison before `CREATE OR REPLACE` on live intermediates |
| BQ job project | `--project_id=lululemon-data-scan` for DDL |

---

## Quick index

Schema: `lulu_sourcing_dev`

| Intermediate | Historic v2 SQL | v1 baseline | Grain | Rows (Jul 2026) |
|---|---|---|---:|---:|
| `store_intermediate` | [`create_store_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_store_intermediate_historic_v2.sql) | [`create_store_intermediate_historic.sql`](../queries/Intermediate_table_builds/create_store_intermediate_historic.sql) | 1 row / `store_code` | 1,853 |
| `product_intermediate` | [`create_product_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql) | [`create_product_intermediate_historic.sql`](../queries/Intermediate_table_builds/create_product_intermediate_historic.sql) | 1 row / `product_code` | 1,977,528 |
| `inventory_intermediate` | [`create_inventory_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_inventory_intermediate_historic_v2.sql) | [`create_inventory_intermediate_historic.sql`](../queries/Intermediate_table_builds/create_inventory_intermediate_historic.sql) | 1 row / `product_code`, `store_code`, `date`, `channel` | ~4.4B (windowed) |
| `transaction_intermediate` | [`create_transaction_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_transaction_intermediate_historic_v2.sql) | [`create_transaction_intermediate_historic.sql`](../queries/Intermediate_table_builds/create_transaction_intermediate_historic.sql) | 1 row / txn grain | ~198M (windowed) |

---

## 1. Store intermediate

**Sources:** `location_group_hierarchy`, `location_details`

**CTE flow:**
- `lgh_cleaned` — LPAD + `\N` cleaning; v2 adds double-backslash and `N/A` handling on hierarchy IDs / format
- `ld_cleaned` — same recipe on location_details
- Final `LEFT JOIN` on `LOC_ID = ID` (no `SELECT DISTINCT`; grain is 1:1)

**Key derivations:**
- `channel` / `s1_name`: `SPLIT(SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]` (RETAIL, ECOMM, FO, STRAT, …)
- `store_type`: `LOC_TYPE` S→Store, else DC; `dc_flag`: W→1 else 0
- `active`: passthrough `LOC_CLOSED_IND` (name is misleading; `'0'` ≈ closed store)
- `ws_channel`: `location_details.TYPE_CODE`

**v2 fixes (9 rows, 0.49%):** `s3_id` `\\N`→NULL (7 rows); `location_hierarchy_region_code` cleaned (7 rows); `store_format_code` `N/A`→NULL (2 rows)

**Still blocked:**

| Column | Value |
|---|---|
| `location_attrib_squareft` | hardcoded `0` |
| `special_classification` | `NULL` |

**Validated temp tables:** `store_intermediate_prechange_tmp_20260717`, `store_intermediate_postchange_v2_tmp_20260717`

---

## 2. Product intermediate

**Sources:** `product_group_hierarchy`, `sku_details`, `product_attribute_s`, `eligibility`

**CTE flow:**
- `pgh_pivot` — EAV pivot to wide hierarchy per `SKU_ID`
- `pgh_cleaned` — `CROSS JOIN UNNEST(['ECOMM','RETAIL'])` → `sku_id_code`
- `pso_launch_dates` — `MIN(WP_FIRST_SELLING_DAY_ID)` at PSO grain
- Join `sku_details` on `SKU_ID` only (no sku-side channel cross join)

**Key derivations:**
- `product_code`: `{SKU_ID}_{channel}`
- `article` / `l8_id`: `{PLANNING_STYLE_OPTION_CODE}_{channel}`
- `article_status` / `active_flag`: mapped from `product_attribute_s.FLEX_STATUS` (Active→ACTIVE/1; Drop/Inactive/Hold→mapped/0)
- `ordering`: `SAFE_CAST(sku_details.SIZE_RANK AS INT64)` (100% fill)
- `launch_date`: eligibility PSO min first-sell (~53.53% row fill)
- `gender`: **`PRODUCT_GENDER`** (not `GENDER`; intentional per sign-off)
- PA attrs (`flex_status`, `silhouette`, …): join `STYLE_CODE = STYLE_ID`

**Still blocked:**

| Column | Value |
|---|---|
| `color_family` | `NULL` (no integer lookup in feeds) |

**Post-rebuild fill highlights (1,977,528 rows):** `flex_status` 95.57%; `ordering` 100%; `launch_date` 53.53%; `gender` 26.57% (`PRODUCT_GENDER`); Drop styles 28.93% at SKU×channel

**Validated temp tables:** `product_intermediate_prechange_tmp_20260717`, `product_intermediate_postchange_v2_tmp_20260717`

---

## 3. Inventory intermediate

**Sources:** `inventory_snapshot`, `location_details`

**CTE flow:**
- `typed_inventory` — cast snapshot fields
- `location_channels` — map location→RETAIL/ECOMM via `TYPE_CODE`/`CHANNEL_CODE`; dedupe with `ROW_NUMBER()`
- `normalized_inventory` — join + date window filter
- Final `QUALIFY ROW_NUMBER()` — latest snapshot per `product_code`, `store_code`, `date`, `channel`

**Key derivations:**
- `product_code`: `CONCAT(sku_id, '_', channel)` from **location_details** channel map (not `store_intermediate`)
- Date window: calendar-year truncate (see shared conventions)
- `oo`: hardcoded `0`

**Known cross-feed gap:** inventory channel map yields **100% RETAIL** today (0 ECOMM rows); transactions use `store_intermediate.channel` (114 ECOMM locations). Same suffix convention, different channel source.

**Validated temp tables:** `inventory_intermediate_prechange_tmp_20260717`, `inventory_intermediate_postchange_v2_tmp_20260717`

---

## 4. Transaction intermediate

**Sources:** `sales_transactions`, `product_intermediate`, `store_intermediate`, `sku_details`, `price_book`

**CTE flow:**
- `typed_transactions` — cast + date window + null guards
- `txn_enriched` — single `INNER JOIN store_intermediate` for channel / geo
- `sku_cost` — avg `sku_details.COST_PRICE` by `product_code` (via base SKU split)
- `price_book_pricing` — MSRP / clearance by `article_original`, `store_code`, txn date
- `txn_projected` — final column projection

**Pricing / discount wiring (v2):**

| Column | Source |
|---|---|
| `msrp` | `price_book.ORIGINAL_PRICE` (~71.38% > 0) |
| `clearance_price` | `price_book.CLEARANCE_PRICE` (~15.74%) |
| `clearance` | derived: `price <= clearance_price` |
| `unit_discount_amount` | `GREATEST(msrp - price, 0)` |
| `total_discount_amount` | `GREATEST(msrp × qty - revenue, 0)` |
| `cost` | `sku_details.COST_PRICE` (**100% zero** until client feed) |
| `transaction_type` | `sales_transactions.TRANSACTION_TYPE` |
| `order_type` | `SALES_SERVICE_TYPE` |
| `ship_to_country` | `store_intermediate.s2_name` |

**Still blocked:** `line_id`, `launch_price`, `revenue_before_tax`, `fullfilment_location_customer`, `freight_cost`, `store_contribution`, `workstream`, `currency_exchange_rate`, `transaction_category`, `flagged_rows`

**Validated temp tables:** `transaction_intermediate_prechange_tmp_20260717`, `transaction_intermediate_postchange_v2_tmp_20260717` (+ pricebook/stubs variants from iteration)

---

## Promotion status (as of 2026-07-17)

| Artifact | v2 aligned? |
|---|---|
| Historic v2 SQL files | Yes (canonical) |
| Live `lulu_sourcing_dev.*_intermediate` tables | **Not yet rebuilt** from v2 (validated on `_tmp_` only) |
| `create_*_intermediate_periodic.sql` | **Not yet updated** to match v2 |
| Legacy workbench scripts (`store_master_intermediate_build.sql`, etc.) | Superseded by v2 historic paths |

---

## Validation workflow (repeat for future changes)

1. Clone live → `{table}_prechange_tmp_{YYYYMMDD}`
2. Run v2 SQL with target → `{table}_postchange_v2_tmp_{YYYYMMDD}`
3. Compare row counts, stable-column diffs, fill-rate deltas
4. Only then promote to live + update periodic script

---

## Related docs

- Build order / periodic MERGE keys: [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md)
- BQ gotchas / table names: [`.cursor/rules/lululemon-bq-context.mdc`](../.cursor/rules/lululemon-bq-context.mdc)
- Master EDA index: [`lulu_eda_inventory.md`](lulu_eda_inventory.md)
- Client open questions on stubs: [`lululemon_client_open_questions.md`](lululemon_client_open_questions.md)
