# Master Table Build Logic (20251119)

> **Source:** `reference_docs/Lululemon/Master Table Build Logic/master_table_build_queries_20251119.csv` — the actual DDL/SELECT statements the PC team used to construct each master table from raw tables.
> **Date added:** 2026-04-21 | **Last updated:** 2026-04-22 | **Owner:** Ejaz Anwar
> **Why this matters:** ~70% of the "anomalies" we flagged in Phase 1 EDA are not data quality issues — they are **hardcoded NULL/0 defaults** or **intentional column duplications** inside these build scripts. This doc reclassifies every master-table column by its actual origin.
>
> Each section below includes the **verbatim SQL from the source CSV** in a collapsible "Full build SQL" block — click to expand.

---

## TL;DR

| Finding type | Count | Action |
|---|---:|---|
| **Hardcoded NULL / 0 in build** (by design, not a feed gap) | ~24 columns | Decide: keep stub, drop, or populate from raw |
| **Derived by duplication** (e.g., `total_units` = `oh`) | 3 columns | Drop redundant cols |
| **Genuine source-data issue** (raw table itself is empty/zero) | 3 items | Escalate to Ritik/DE |
| **Potential logic bug** (CTE alias mismatch, inverted polarity) | 2 items | Needs code review |
| **Genuine data anomaly** (outliers, negative OH, etc.) | ~8 items | Client/business discussion |

---

## 1. `product_master` — Build Logic

**Source tables:**
- `product_group_hierarchy_cleaned_20251119` (alias `a`) — primary
- `sku_details_cleaned_20251119` (alias `b`) — LEFT JOIN on `sku_id_code`
- `product_attribute_s_20251119` (alias `c`) — LEFT JOIN on `STYLE_CODE = STYLE_ID`

**Filter:** `WHERE a.sku_id_code IS NOT NULL`

??? example "Full build SQL"
    ```sql
    INSERT INTO `lululemon-01042025.lululemon_souricng_outbound.product_master_20251119`
    SELECT DISTINCT
      a.BRAND_NAME                                       AS l0_name,
      SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]          AS l1_name,
      a.DIVISION_NAME                                    AS l2_name,
      a.DEPARTMENT_NAME                                  AS l3_name,
      a.CLASS_NAME                                       AS l4_name,
      a.SUBCLASS_NAME                                    AS l5_name,
      a.MASTER_STYLE_NAME                                AS l6_name,
      a.STYLE_NAME                                       AS l7_name,
      a.PLANNING_STYLE_SIZE_NAME                         AS l8_name,
      'ACTIVE'                                           AS article_status,
      CAST(CONCAT(
        (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.BRAND_CODE,'',a.BRAND_NAME)       AS STRING), '')) c),
        (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(DIVISION_CODE,'',DIVISION_NAME)     AS STRING), '')) c),
        (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(DEPARTMENT_CODE,'',DEPARTMENT_NAME) AS STRING), '')) c),
        (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(CLASS_CODE,'',CLASS_NAME)           AS STRING), '')) c)
      ) AS BIGINT)                                       AS product_bucket_code,
      a.BRAND_CODE                                       AS l0_id,
      a.DIVISION_CODE                                    AS l2_id,
      a.DEPARTMENT_CODE                                  AS l3_id,
      a.CLASS_CODE                                       AS l4_id,
      a.SUBCLASS_CODE                                    AS l5_id,
      a.MASTER_STYLE_CODE                                AS l6_id,
      a.STYLE_CODE                                       AS l7_id,
      CONCAT(a.PLANNING_STYLE_OPTION_CODE,'_', SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]) AS l8_id,
      a.PLANNING_STYLE_SIZE_NAME                         AS product_name,
      b.SIZE_NAME                                        AS size,
      a.sku_id_code                                      AS product_code,
      b.DESCRIPTION                                      AS product_description,
      CONCAT(a.PLANNING_STYLE_OPTION_CODE,'_', SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]) AS article,
      1                                                  AS active_flag,
      CAST(b.COLOR_CODE AS STRING)                       AS color_code,
      b.COLOR_NAME                                       AS color_description,
      NULL                                               AS color_family,
      NULL                                               AS ordering,
      NULL                                               AS launch_date,
      b.SEASON_CODE                                      AS season_code,
      c.silhouette                                       AS silhouette,
      c.planning_product_grouping                        AS planning_product_grouping,
      c.product_gender                                   AS gender,
      c.flex_status                                      AS flex_status,
      c.global_merch_team                                AS global_merch_team,
      c.fit_classification                               AS fit_classification,
      c.design_line                                      AS design_line,
      c.designed_for_activity                            AS designed_for_activity,
      c.product_line                                     AS product_line,
      c.size_scale                                       AS size_scale,
      c.product_development_pod                          AS product_development_pod,
      c.product_size_definition                          AS product_size_definition,
      c.global_line_segment_style_category               AS global_line_segment_style_category,
      SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(0)]          AS product_code_original,
      a.PLANNING_STYLE_OPTION_CODE                       AS article_original
    FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119` a
    LEFT JOIN (
      SELECT DISTINCT * EXCEPT(COST_PRICE, SELLING_PRICE)
      FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned_20251119`
    ) b
      ON a.sku_id_code = b.sku_id_code
    LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119` c
      ON a.STYLE_CODE = c.STYLE_ID
    WHERE a.sku_id_code IS NOT NULL;
    ```

**Column origin classification:**

| Column | Origin | Notes |
|---|---|---|
| `l0_name` | `a.BRAND_NAME` | |
| `l1_name` | `SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]` | **Derived channel suffix — hence only "RETAIL"/"ECOMM" (2 values)** |
| `l2_name`–`l8_name` | `a.DIVISION_NAME`, `DEPARTMENT_NAME`, `CLASS_NAME`, `SUBCLASS_NAME`, `MASTER_STYLE_NAME`, `STYLE_NAME`, `PLANNING_STYLE_SIZE_NAME` | |
| `article_status` | `'ACTIVE'` **hardcoded** | ✅ Explains 100% ACTIVE — use `flex_status` instead |
| `product_bucket_code` | ASCII sum of concatenated `BRAND_CODE + BRAND_NAME`, DIVISION, DEPT, CLASS — cast to BIGINT | Synthetic hash-like bucket |
| `l0_id`–`l8_id` | Raw code columns from `a` | `l8_id = CONCAT(PLANNING_STYLE_OPTION_CODE, '_', channel)` |
| `product_name` | `a.PLANNING_STYLE_SIZE_NAME` | |
| `size` | `b.SIZE_NAME` | |
| `product_code` | `a.sku_id_code` | Primary key of master |
| `product_description` | `b.DESCRIPTION` | |
| `article` | `CONCAT(PLANNING_STYLE_OPTION_CODE, '_', channel)` | |
| `active_flag` | `1` **hardcoded** | ✅ Explains 100% =1 |
| `color_code` | `CAST(b.COLOR_CODE AS STRING)` | |
| `color_description` | `b.COLOR_NAME` | |
| `color_family` | `NULL` **hardcoded** | ✅ Explains 100% NULL — our derivation from `color_description` is the correct path |
| `ordering` | `NULL` **hardcoded** | ✅ Explains 100% NULL |
| `launch_date` | `NULL` **hardcoded** | ✅ **This is the actual answer to P0 `launch_date` issue** — not missing from source, just not populated in the build. Ask: is `launch_date` available in any raw table? |
| `season_code` | `b.SEASON_CODE` | Current snapshot only ("25-4WI"); this is why there's no history |
| `silhouette`, `planning_product_grouping`, `gender`, `flex_status`, `global_merch_team`, `fit_classification`, `design_line`, `designed_for_activity`, `product_line`, `size_scale`, `product_development_pod`, `product_size_definition`, `global_line_segment_style_category` | All from `c.*` (product_attribute_s) | Note: `c.product_gender AS gender` — raw has `product_gender`; explains why 73% NULL if the attribute table is sparse |
| `product_code_original` | `SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(0)]` | SKU without channel suffix |
| `article_original` | `a.PLANNING_STYLE_OPTION_CODE` | |

**Hardcoded NULL/0 columns (6):** `article_status` (='ACTIVE'), `active_flag` (=1), `color_family`, `ordering`, `launch_date`, (and `l1_name` is a derived channel split, not a hierarchy level).

**Open questions (for Ritik / DE):**
1. Can `launch_date` be sourced from `product_group_hierarchy.FIRST_SELLING_DATE` or similar?
2. Why is `color_family` stubbed — is there a lookup table or should we keep our parsed derivation?
3. `gender` pulled from `product_attribute_s.product_gender` — can we verify source coverage?

---

## 2. `transaction_master_20251119` — Build Logic

**Source tables:**
- `sales_transactions_4y_cleaned_20251119` (alias `txn`) — primary
- `product_group_hierarchy_cleaned_20251119` (alias `pgh`) — JOIN on `sku_id_code = sku_id_channel`
- CTE `all_skus` (from `product_group_hierarchy` LEFT JOIN `sku_details`) — AVG of cost/selling per SKU — JOINed as `sd`
- `store_master_20251119` (alias `lm`) — JOIN on `store_code = location_id_sales`

??? example "Full build SQL"
    ```sql
    WITH all_skus AS (
      SELECT
        a.sku_id_code                          AS sku_id_channel,
        AVG(b.COST_PRICE)                      AS cost_price,
        AVG(CAST(selling_price AS INT))        AS selling_price
      FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119` AS a
      LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned_20251119` AS b
        ON a.sku_id_code = b.sku_id_code
      GROUP BY 1
    )
    SELECT DISTINCT
      lm.s1_name                               AS channel,
      NULL                                     AS line_id,
      pgh.brand_name                           AS brand,
      NULL                                     AS launch_price,
      0                                        AS clearance,
      0                                        AS unit_discount_amount,
      0                                        AS total_discount_amount,
      txn.units                                AS qty,
      NULL                                     AS transaction_type,
      txn.location_id_sales                    AS store_code,
      NULL                                     AS fullfilment_location_customer,
      0                                        AS flagged_rows,
      txn.SALES_ORDER_ID                       AS transaction_code,
      lm.channel_code                          AS channel_code,
      txn.DATE_TRANSACTION                     AS date,
      txn.sku_id_channel                       AS product_code,
      NULL                                     AS revenue_before_tax,
      NULL                                     AS ship_to_country,
      NULL                                     AS freight_cost,
      lm.ws_channel,
      lm.geography,
      0                                        AS clearance_price,
      NULL                                     AS store_contribution,
      NULL                                     AS workstream,
      lm.s2_name                               AS ecomm_country,
      txn.PRICE_SALES_TOTAL                    AS revenue,
      sd.COST_PRICE                            AS cost,
      NULL                                     AS currency_exchange_rate,
      NULL                                     AS order_type,
      NULL                                     AS transaction_category,
      sd.SELLING_PRICE                         AS msrp,
      txn.PRICE_SALES_UNIT                     AS price
    FROM      `lululemon-01042025.lululemon_souricng_outbound.sales_transactions_4y_cleaned_20251119` AS txn
    JOIN      `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119` AS pgh ON pgh.sku_id_code = txn.sku_id_channel
    JOIN      all_skus                                                                                AS sd  ON sd.sku_id_channel = txn.sku_id_channel
    JOIN      `lululemon-01042025.lululemon_souricng_outbound.store_master_20251119`                  AS lm  ON lm.store_code = txn.location_id_sales;
    ```

**⚠️ Alias note:** The CTE outputs `cost_price`/`selling_price`, but the SELECT references `COST_PRICE`/`SELLING_PRICE`. BigQuery is case-insensitive, so this resolves. Cost/msrp = 0 therefore means **`sku_details_cleaned_20251119.COST_PRICE` and `SELLING_PRICE` are themselves 0/NULL**. This is a **real source data issue**, not a master-build bug.

**Column origin classification:**

| Column | Origin | Notes |
|---|---|---|
| `channel` | `lm.s1_name` | from store_master |
| `line_id` | `NULL` **hardcoded** | ✅ Stub |
| `brand` | `pgh.brand_name` | |
| `launch_price` | `NULL` **hardcoded** | ✅ Stub |
| `clearance` | `0` **hardcoded** | ✅ Stub |
| `unit_discount_amount` | `0` **hardcoded** | ✅ Stub |
| `total_discount_amount` | `0` **hardcoded** | ✅ Stub |
| `qty` | `txn.units` | Real |
| `transaction_type` | `NULL` **hardcoded** | ✅ Stub |
| `store_code` | `txn.location_id_sales` | Real |
| `fullfilment_location_customer` | `NULL` **hardcoded** | ✅ Stub (typo preserved: `fullfilment`) |
| `flagged_rows` | `0` **hardcoded** | ✅ Stub |
| `transaction_code` | `txn.SALES_ORDER_ID` | Real |
| `channel_code` | `lm.channel_code` | |
| `date` | `txn.DATE_TRANSACTION` | Real |
| `product_code` | `txn.sku_id_channel` | |
| `revenue_before_tax` | `NULL` **hardcoded** | ✅ Stub |
| `ship_to_country` | `NULL` **hardcoded** | ✅ Stub |
| `freight_cost` | `NULL` **hardcoded** | ✅ Stub |
| `ws_channel` | `lm.ws_channel` | |
| `geography` | `lm.geography` | |
| `clearance_price` | `0` **hardcoded** | ✅ Stub |
| `store_contribution` | `NULL` **hardcoded** | ✅ Stub |
| `workstream` | `NULL` **hardcoded** | ✅ Stub |
| `ecomm_country` | `lm.s2_name` | |
| `revenue` | `txn.PRICE_SALES_TOTAL` | Real |
| `cost` | `sd.COST_PRICE` (CTE AVG from sku_details) | **Source issue — sku_details has 0s** |
| `currency_exchange_rate` | `NULL` **hardcoded** | ✅ Stub |
| `order_type` | `NULL` **hardcoded** | ✅ Stub |
| `transaction_category` | `NULL` **hardcoded** | ✅ Stub |
| `msrp` | `sd.SELLING_PRICE` (CTE AVG from sku_details) | **Source issue — sku_details has 0s** |
| `price` | `txn.PRICE_SALES_UNIT` | Real |

**Hardcoded NULL/0 columns (17):** `line_id`, `launch_price`, `clearance`, `unit_discount_amount`, `total_discount_amount`, `transaction_type`, `fullfilment_location_customer`, `flagged_rows`, `revenue_before_tax`, `ship_to_country`, `freight_cost`, `clearance_price`, `store_contribution`, `workstream`, `currency_exchange_rate`, `order_type`, `transaction_category`.

**Real source-data issues (2):** `cost` and `msrp` (trace to `sku_details_cleaned_20251119.COST_PRICE` / `SELLING_PRICE`).

**DISTINCT note:** The master build uses `SELECT DISTINCT` — deduping on *all* columns. This means legitimately duplicated transaction rows (same SKU/store/date with different order_ids) would survive. But it also explains the ~660K row gap between `distinct_transaction_code` (390.5M) and `total_rows` (389.9M) — some transaction codes have different payloads that DISTINCT keeps separate.

**Open questions (for Ritik / DE):**
1. Is `sku_details_cleaned_20251119.COST_PRICE` / `SELLING_PRICE` genuinely empty in raw, or lost in cleaning?
2. Is discount supposed to come via a downstream JOIN to `price_book`? (17 discount/promo columns stubbed = suspicious pattern.)
3. Why `SELECT DISTINCT` on `sales_transactions`? Is the raw source itself duplicated?

---

## 3. `inventory_master` — Build Logic

**Source tables:**
- `inventory_snapshot_cleaned` (alias `A`) — primary (63.4B rows)
- `product_group_hierarchy_cleaned` (alias `B`) — JOIN on `A.sku_id_channel = B.sku_id_code`

**Raw-source EDA:** See [`inventory_snapshot_cleaned_eda.md`](inventory_snapshot_cleaned_eda.md) for the upstream raw table profile, including pre-2023 history, `SNAPSHOT_TIME` backfill behavior, `UNITS_AVAILABLE`, and raw channel/key anomalies.

**Join key correction (2026-04-17):** An earlier version of this doc (and the reference CSV) showed the join as `A.sku_id_channel = B.sku_id_channel`. The corrected build — supplied directly by Ejaz on 2026-04-17 — uses `A.sku_id_channel = B.sku_id_code`. This is consistent with `product_group_hierarchy_cleaned_20251119.sku_id_code` being the canonical SKU key in PGH (same key the product_master and transaction_master builds use). See cursor rule G9 for why the older DDL couldn't be trusted.

??? example "Full build SQL (corrected)"
    ```sql
    DROP TABLE IF EXISTS `lululemon-01042025.lululemon_souricng_outbound.inventory_master`;

    CREATE TABLE `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
    PARTITION BY DATE(date)
    CLUSTER BY store_code AS
    SELECT
      B.BRAND_NAME                   AS brand,
      A.DATE                         AS date,
      A.UNITS_ON_HAND                AS oh,
      A.UNITS_INBOUND                AS it,
      0                              AS oo,
      0                              AS wip,
      0                              AS initial_oh_quantity,
      A.UNITS_ON_HAND                AS total_units,
      A.LOCATION_ID                  AS store_code,
      A.sku_id_channel               AS product_code
    FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`           AS A
    JOIN `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned`      AS B
      ON A.sku_id_channel = B.sku_id_code;
    ```

**Note on the PGH variant:** `inventory_master` joins to `product_group_hierarchy_cleaned` (no `_20251119` suffix). The other masters use `product_group_hierarchy_cleaned_20251119`. Since both variants have identical row counts (1,977,528) and were built 3 days apart, they're almost certainly the same underlying data — see Q4a/Q4b of `queries/de_review_stage1_verification.sql` for confirmation.

**Column origin classification:**

| Column | Origin | Notes |
|---|---|---|
| `brand` | `B.BRAND_NAME` | |
| `date` | `A.DATE` | |
| `oh` | `A.UNITS_ON_HAND` | Real |
| `it` | `A.UNITS_INBOUND` | Real |
| `oo` | `0` **hardcoded** | ✅ Stub |
| `wip` | `0` **hardcoded** | ✅ Stub |
| `initial_oh_quantity` | `0` **hardcoded** | ✅ Stub |
| `total_units` | `A.UNITS_ON_HAND` (**same as `oh`**) | ✅ Redundant by construction |
| `store_code` | `A.LOCATION_ID` | |
| `product_code` | `A.sku_id_channel` | |

**Hardcoded / redundant columns (4):** `oo`, `wip`, `initial_oh_quantity`, `total_units`.

**Grain:** one row per (SKU × store × date) — confirmed by EDA.

**Open questions (for Ritik / DE):**
1. Is on-order (`oo`) and WIP available anywhere in raw? (If yes, populate; if no, drop.)
2. `total_units` is literally `= oh` — was this intended to include `it` or other components? Drop or fix definition.
3. The feed joins on `sku_id_channel` → only SKUs in `product_group_hierarchy` will have inventory rows. Explains 23,782 SKUs in `product_master` that never appear in inventory.

---

## 4. `store_master_20251119` — Build Logic

**Source tables:**
- `location_group_hierarchy_cleaned_20251119` (alias `a`) — primary
- `location_details_cleaned_20251119` (alias `b`) — LEFT JOIN on `a.loc_id = b.id`

??? example "Full build SQL"
    ```sql
    INSERT INTO `lululemon-01042025.lululemon_souricng_outbound.store_master_20251119`
    SELECT DISTINCT
      a.AREA_NAME                                        AS s3_name,
      a.REGION_NAME                                      AS s4_name,
      a.COUNTRY_NAME                                     AS s2_name,
      SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]   AS s1_name,
      SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]   AS channel,
      a.BRAND_NAME                                       AS s0_name,
      a.LOC_NAME                                         AS store_name,
      a.LONGITUDE                                        AS longitude,
      a.LATITUDE                                         AS latitude,
      0                                                  AS location_attrib_squareft,
      a.LOC_FORMAT                                       AS store_format_code,
      a.LOC_TYPE                                         AS loc_type_code,
      b.TYPE_CODE                                        AS ws_channel,
      CONCAT(loc_id, '_', LOC_NAME)                      AS location_num_store_name,
      a.POSTAL_CODE                                      AS zipcode,
      a.loc_id                                           AS store_code,
      a.AREA_ID                                          AS s3_id,
      CONCAT(REGION_ID, '_', COALESCE(REGION_NAME,''))   AS location_hierarchy_region_code,
      a.BRAND_NAME                                       AS company_name,
      a.SUB_MARKET_CHANNEL_ID                            AS channel_code,
      a.OPERATIONAL_OPEN_DAY_ID                          AS open_date,
      a.OPERATIONAL_CLOSE_DAY_ID                         AS close_date,
      CASE WHEN UPPER(a.LOC_TYPE) = 'S' THEN 'Store' ELSE 'DC' END AS store_type,
      a.BRAND_ID                                         AS company_code,
      a.LOC_CLOSED_IND                                   AS active,
      a.GEO_REGION_NAME                                  AS geography,
      CASE WHEN UPPER(a.LOC_TYPE) = 'W' THEN 1 ELSE 0 END AS dc_flag,
      NULL                                               AS special_classification,
      a.AREA_NAME                                        AS district_name,
      a.REGION_NAME                                      AS region,
      a.loc_id                                           AS like_store_id,
      a.DELETE_IND                                       AS is_deleted,
      a.city,
      a.state
    FROM      `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119` a
    LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.location_details_cleaned_20251119`        b
      ON a.loc_id = b.id;
    ```

**Column origin classification:**

| Column | Origin | Notes |
|---|---|---|
| `s3_name` | `a.AREA_NAME` | |
| `s4_name` | `a.REGION_NAME` | |
| `s2_name` | `a.COUNTRY_NAME` | |
| `s1_name` | `SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]` | Parsed token #2 |
| `channel` | `SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]` | **Same expression as s1_name → duplicated** |
| `s0_name` | `a.BRAND_NAME` | |
| `store_name` | `a.LOC_NAME` | |
| `longitude`, `latitude` | `a.LONGITUDE`, `a.LATITUDE` | STRING in master → source is STRING too |
| `location_attrib_squareft` | `0` **hardcoded** | ✅ Stub |
| `store_format_code` | `a.LOC_FORMAT` | |
| `loc_type_code` | `a.LOC_TYPE` | |
| `ws_channel` | `b.TYPE_CODE` | from location_details |
| `location_num_store_name` | `CONCAT(loc_id, '_', LOC_NAME)` | |
| `zipcode` | `a.POSTAL_CODE` | |
| `store_code` | `a.loc_id` | |
| `s3_id` | `a.AREA_ID` | |
| `location_hierarchy_region_code` | `CONCAT(REGION_ID, '_', COALESCE(REGION_NAME, ''))` | |
| `company_name` | `a.BRAND_NAME` | Same as `s0_name` |
| `company_code` | `a.BRAND_ID` | |
| `channel_code` | `a.SUB_MARKET_CHANNEL_ID` | |
| `open_date` | `a.OPERATIONAL_OPEN_DAY_ID` | |
| `close_date` | `a.OPERATIONAL_CLOSE_DAY_ID` | |
| `store_type` | `CASE WHEN UPPER(LOC_TYPE)='S' THEN 'Store' ELSE 'DC' END` | |
| **`active`** | `a.LOC_CLOSED_IND` | **⚠️ SEMANTIC FLAG — column named "active" but sourced from a "closed indicator." Polarity may be inverted. Needs verification.** |
| `geography` | `a.GEO_REGION_NAME` | |
| `dc_flag` | `CASE WHEN UPPER(LOC_TYPE)='W' THEN 1 ELSE 0 END` | |
| `special_classification` | `NULL` **hardcoded** | ✅ Stub |
| `district_name` | `a.AREA_NAME` | Same as `s3_name` |
| `region` | `a.REGION_NAME` | Same as `s4_name` |
| `like_store_id` | `a.loc_id` | **Same as `store_code`** — not a "like store" reference |
| `is_deleted` | `a.DELETE_IND` | |
| `city`, `state` | `a.city`, `a.state` | |

**Hardcoded / duplicated columns (4):** `location_attrib_squareft` (=0), `special_classification` (=NULL), `company_name`/`district_name`/`region` (duplicates of s0/s3/s4), `like_store_id` (= store_code).

**⚠️ Suspected logic bug:** `active = LOC_CLOSED_IND`. If `LOC_CLOSED_IND` is a flag where 1=closed, 0=open, then `active=1` means "closed" and `active=0` means "open" — **inverted from the column name**. Must verify with DE team before using.

**Open questions (for Ritik / DE):**
1. What is `LOC_CLOSED_IND` polarity? (1=closed or 1=active?)
2. `like_store_id = loc_id` is useless (self-reference). Should it be an actual like-store lookup?
3. `s1_name` and `channel` are the same parsed value — is channel supposed to be the full `SUB_MARKET_CHANNEL_NAME`?

---

## 5. `events_master` — Build Logic

Simple 1:1 projection from `promotional_events_cleaned`.

**Source tables:**
- `promotional_events_cleaned` — only source

??? example "Full build SQL"
    ```sql
    SELECT
      loc_id                  AS store_code,
      type,
      name,
      start_date,
      end_date,
      description,
      location_closed_flag
    FROM `lululemon-01042025.lululemon_souricng_outbound.promotional_events_cleaned`;
    ```

No hardcoded values. Grain = one row per (store × event).

---

## 6. `fiscal_date_mapping` — Build Logic

Derived from `calendar_hierarchy` using ~30 window functions (`ROW_NUMBER`, `DENSE_RANK`, `MIN/MAX OVER`) to explode each day into fiscal dimensions (week, month, quarter, year in various formats).

**Source tables:**
- `calendar_hierarchy` — only source

??? example "Full build SQL"
    ```sql
    CREATE OR REPLACE TABLE `lululemon-01042025.lululemon_souricng_outbound.fiscal_date_mapping` AS
    SELECT
      quarter_desc                                                                         AS fiscal_quarter_name,
      QUARTER_KEY                                                                          AS fiscal_quarter_name_abb,
      YEAR_ID*100 + QUARTER_NUMBER                                                         AS fiscal_year_quarter,
      REGEXP_REPLACE(CAST(DAY_ID AS STRING), '[^0-9]', '')                                 AS date_id,
      UPPER(FORMAT_DATE('%A', DAY_ID))                                                     AS fiscal_day_name,
      ROW_NUMBER()  OVER (PARTITION BY YEAR_ID*100 + QUARTER_NUMBER ORDER BY DAY_ID)       AS fiscal_day_in_quarter,
      DENSE_RANK()  OVER (PARTITION BY YEAR_ID*100 + QUARTER_NUMBER ORDER BY YEAR_ID*100 + MONTH_NUMBER) AS fiscal_month_in_quarter,
      YEAR_ID*100 + DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID) - 100        AS fiscal_prior_year_comp_week,
      DAY_ID                                                                               AS calendar_date,
      RANK()        OVER (PARTITION BY YEAR_ID ORDER BY DAY_ID)                            AS fiscal_day_in_year,
      FORMAT_DATE('%B', PARSE_DATE('%b', SPLIT(MONTH_DESC, ' ')[1]))                       AS fiscal_month_name,
      SPLIT(MONTH_DESC, ' ')[1]                                                            AS fiscal_month_name_abb,
      YEAR_ID*100 + MONTH_NUMBER                                                           AS fiscal_year_period,
      DAY_NUMBER                                                                           AS fiscal_day_in_week,
      YEAR_ID*100 + MONTH_NUMBER                                                           AS fiscal_year_month,
      DENSE_RANK()  OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID)                           AS fiscal_week_in_year,
      MONTH_NUMBER                                                                         AS fiscal_month,
      WEEK_NUMBER                                                                          AS fiscal_week,
      YEAR_ID                                                                              AS fiscal_year,
      WEEK_ID                                                                              AS fiscal_year_week,
      MIN(DAY_ID)  OVER (PARTITION BY WEEK_ID)                                             AS fiscal_week_begin_date,
      MAX(DAY_ID)  OVER (PARTITION BY WEEK_ID)                                             AS fiscal_week_end_date,
      MIN(DAY_ID)  OVER (PARTITION BY YEAR_ID*100 + MONTH_NUMBER)                          AS fiscal_month_begin_date,
      MIN(DAY_ID)  OVER (PARTITION BY YEAR_ID*100 + QUARTER_NUMBER)                        AS fiscal_quarter_begin_date,
      MAX(DAY_ID)  OVER (PARTITION BY YEAR_ID*100 + QUARTER_NUMBER)                        AS fiscal_quarter_end_date,
      MIN(DAY_ID)  OVER (PARTITION BY YEAR_ID)                                             AS fiscal_year_begin_date,
      MAX(DAY_ID)  OVER (PARTITION BY YEAR_ID)                                             AS fiscal_year_end_date,
      QUARTER_NUMBER                                                                       AS fiscal_quarter,
      ROW_NUMBER()  OVER (PARTITION BY YEAR_ID ORDER BY DAY_ID)                            AS fiscal_day,
      DENSE_RANK()  OVER (PARTITION BY YEAR_ID*100 + MONTH_NUMBER ORDER BY WEEK_ID)        AS fiscal_week_in_month,
      DENSE_RANK()  OVER (PARTITION BY YEAR_ID*100 + QUARTER_NUMBER ORDER BY WEEK_ID)      AS fiscal_week_in_quarter,
      LEFT(UPPER(FORMAT_DATE('%A', DAY_ID)), 3)                                            AS fiscal_day_name_abb,
      DENSE_RANK()  OVER (PARTITION BY YEAR_ID ORDER BY YEAR_ID*100 + MONTH_NUMBER)        AS fiscal_month_in_year,
      DENSE_RANK()  OVER (PARTITION BY YEAR_ID ORDER BY YEAR_ID*100 + QUARTER_NUMBER)      AS fiscal_quarter_in_year,
      CASE WHEN UPPER(FORMAT_DATE('%A', DAY_ID)) IN ('SATURDAY', 'SUNDAY') THEN 'N' ELSE 'Y' END AS weekday_indicator,
      ROW_NUMBER()  OVER (PARTITION BY YEAR_ID*100 + MONTH_NUMBER ORDER BY DAY_ID)         AS fiscal_day_in_month,
      DAY_ID                                                                               AS date,
      LAG(WEEK_ID, 7) OVER (ORDER BY WEEK_ID)                                              AS fiscal_year_week_prior,
      NULL                                                                                 AS fiscal_month_in_season,
      CASE WHEN ROUND((DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID) / 2), 0) > 26
           THEN 26
           ELSE   ROUND((DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID) / 2), 0)
      END                                                                                  AS fiscal_bi_week,
      ROW_NUMBER()  OVER (PARTITION BY WEEK_ID ORDER BY DAY_ID)                            AS day_of_week,
      NULL                                                                                 AS fiscal_year_quarter_prior,
      SEASON_CODE                                                                          AS fiscal_year_season,
      NULL                                                                                 AS fiscal_year_season_prior,
      NULL                                                                                 AS fiscal_quarter_in_season,
      NULL                                                                                 AS fiscal_week_in_season,
      MAX(DAY_ID)  OVER (PARTITION BY YEAR_ID*100 + MONTH_NUMBER)                          AS fiscal_month_end_date,
      NULL                                                                                 AS fiscal_year_week_2wa,
      MIN(DAY_ID)  OVER (PARTITION BY SEASON_CODE)                                         AS fiscal_season_begin_date,
      NULL                                                                                 AS fiscal_season_in_year,
      MAX(DAY_ID)  OVER (PARTITION BY SEASON_CODE)                                         AS fiscal_season_end_date,
      RANK()        OVER (PARTITION BY SEASON_CODE ORDER BY DAY_ID ASC)                    AS fiscal_day_in_season,
      NULL                                                                                 AS fiscal_year_month_prior,
      NULL                                                                                 AS fiscal_season_name,
      NULL                                                                                 AS fiscal_season_name_abb,
      NULL                                                                                 AS fiscal_year_week_3wa,
      NULL                                                                                 AS holiday,
      NULL                                                                                 AS fiscal_year_qtr,
      NULL                                                                                 AS trend
    FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`;
    ```

**Hardcoded NULL columns (~13):** `fiscal_month_in_season`, `fiscal_year_quarter_prior`, `fiscal_year_season_prior`, `fiscal_quarter_in_season`, `fiscal_week_in_season`, `fiscal_year_week_2wa`/`3wa`, `fiscal_season_in_year`, `fiscal_year_month_prior`, `fiscal_season_name`/`_abb`, `holiday`, `fiscal_year_qtr`, `trend`.

These are all **seasonal/prior-period helper columns** that were stubbed out. If Forecast Smart needs any of them (e.g., `holiday`), they'll need to be populated.

---

## Column Classification Summary (all 5 main masters)

| Bucket | Count | Examples |
|---|---:|---|
| **Real data from source** | ~60 | qty, revenue, oh, date, store_code, etc. |
| **Hardcoded NULL stub** | ~22 | launch_date, color_family, line_id, transaction_type, workstream, special_classification, … |
| **Hardcoded 0 stub** | ~12 | active_flag, clearance, discount cols, oo, wip, initial_oh_quantity, location_attrib_squareft, … |
| **Hardcoded string stub** | 1 | article_status='ACTIVE' |
| **Derived / duplicated column** | ~8 | total_units=oh, like_store_id=store_code, company_name=s0_name, channel=s1_name, district_name=s3_name, region=s4_name, l1_name (channel suffix), … |
| **Real source-data issue** | 2 | cost / msrp (trace to sku_details) |
| **Suspected logic bug** | 1 | store_master.active = LOC_CLOSED_IND (polarity?) |

---

## Implications for Client Escalation

The 5 P0 items previously bundled together now split into three distinct conversations:

### Conversation 1 — "Can we populate these stubs?" (to Ritik / DE, not client)

These columns were stubbed during PC build. Ask: is the data available in raw, and if so, cheap to populate?

- `product_master.launch_date`, `color_family`, `ordering`
- `transaction_master` discount suite (`unit_discount_amount`, `total_discount_amount`, `clearance_price`, `clearance`, `launch_price`) — likely comes from `price_book`
- `transaction_master` metadata (`transaction_type`, `order_type`, `transaction_category`, `workstream`) — likely stripped from `sales_transactions`
- `inventory_master.oo`, `wip`, `initial_oh_quantity` — likely from inventory_snapshot or a transfer/PO join
- `store_master.special_classification`, `location_attrib_squareft`

### Conversation 2 — "Source data itself is empty/wrong" (escalate to client)

- `sku_details_cleaned_20251119.COST_PRICE` / `SELLING_PRICE` are 0 → blocks cost & msrp
- `inventory_snapshot` history starts 2023-01 (14 months missing for txn backtest)
- Only current season in `product_group_hierarchy` (no historical product_master)

### Conversation 3 — "Logic to verify in the build script" (internal code review)

- `store_master.active = LOC_CLOSED_IND` — polarity?
- `transaction_master` CTE uses `AVG(cost_price)` per SKU — is an average the right semantics for per-row cost?
- `SELECT DISTINCT` on transaction data — is there duplication upstream?

---

## References

- **Source CSV:** `reference_docs/Lululemon/Master Table Build Logic/master_table_build_queries_20251119.csv`
- **Related:** `consolidated_p0_p1_issues.md` (recategorized), `schema_inventory.md` (canonical tables)
