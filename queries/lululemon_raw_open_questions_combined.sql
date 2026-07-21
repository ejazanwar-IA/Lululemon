-- =============================================================================
-- Lululemon — RAW GCS open questions (COMBINED SQL reference)
--
-- Project:  lululemon-01042025
-- Sourcing: lulu_sourcing_dev.*  (7 GCS extraction tables)
-- GSM:      lulu_ingestion_dev.* (downstream masters / joins)
-- Outbound: lululemon_souricng_outbound.* (client feed cross-checks)
--
-- Companion docs:
--   findings/raw_sourcing_dev_7_table_eda_summary.md
--   findings/lululemon_client_open_questions.md
--
-- PGH-only workshop SQL (product + hierarchy bullets combined):
--   queries/product_group_hierarchy_open_questions.sql
--
-- Run one section at a time in BigQuery console.
-- Last updated: 2026-06-23
--
-- STRUCTURE
--   PART A — Workshop bullets (PGH / SKU / PA / LGH / LD / TXN / INV)
--   PART B — Supplemental rechecks (PM-1..PM-10, cross-layer / outbound)
--   PART C — Post-extraction DAG diagnostics
-- =============================================================================
--
-- MASTER INDEX (Part A bullets)
--   PGH.1–5   product_group_hierarchy
--   SKU.1–6   sku_details
--   PA.1–6    product_attribute_s
--   LGH.1–5   location_group_hierarchy
--   LD.1–7    location_details (+ LGH joins)
--   TXN.1–8   sales_transactions
--   INV.1–6   inventory_snapshot (+ cleaned)
--
-- MASTER INDEX (Part B — maps to client open questions workbook)
--   PM-1  pricing cross-layer + price_book
--   PM-2  season GSM vs outbound
--   PM-3  PSS grain on GSM product_master
--   PM-5  placeholder codes on GSM + sales overlap
--   PM-6  never-sold SKUs (multi-grain)
--   PM-7  PA triplicate fingerprint + dedup pattern
--   PM-8  FLEX_STATUS outbound vs GSM stub
--   PM-9  explainability attribute tiers (outbound PA)
--   PM-10 STYLE_ID alignment + PA-only styles


-- #############################################################################
-- PART A — WORKSHOP BULLETS (7 raw GCS tables)
-- #############################################################################

-- INDEX (table.bullet)
--   PGH.1  ~2x EAV row duplication
--   PGH.2  SKUs lacking PLANNING_STYLE_SIZE
--   PGH.3  PGH SKU universe vs product_intermediate / product_master
--   PGH.4  PSS / forecast product grain (PGH levels)
--   PGH.5  Short article codes (<=3 chars)
--   SKU.1  Zero pricing / dummy currency
--   SKU.2  PRICE_CURRENCY = DUMMY_CURRENCY
--   SKU.3  4 identical rows per SKU
--   SKU.4  Single season 25-4WI
--   SKU.5  Missing IMAGE_URL
--   SKU.6  Join rules PGH <-> sku_details
--   PA.1   FLEX_STATUS distribution
--   PA.2   article_status stub vs FLEX_STATUS
--   PA.3   Attribute population tiers (forecast / explainability)
--   PA.4   STYLE_ID vs PGH STYLE; PA-only styles
--   PA.5   GENDER vs PRODUCT_GENDER
--   PA.6   [Internal DE] 3x load dedup
--   LGH.1  Store/DC universe (TYPE_CODE x channel)
--   LGH.2  LOC_CLOSED_IND vs close dates
--   LGH.3  \\N vs \N sentinels
--   LGH.4  CMNTY vs COMMUNITY naming
--   LGH.5  Orphan PRIMARY_DC_ID
--   LD.1   Active-store funnel
--   LD.2   OUT_OF_SCOPE vs channel suffix
--   LD.3   PERMANANENT_CLOSE_DATE populated rate (typo in source name)
--   LD.4   Missing LOC_CLOSED_IND (via LGH join)
--   LD.5   Missing LOC_FORMAT (LGH)
--   LD.6   Future-dated FIRST_OPEN_DATE
--   LD.7   China ecomm store IDs
--   TXN.1  Returns feed vs gross sales
--   TXN.2  TRANSACTION_TYPE single value
--   TXN.3  Sales history date range
--   TXN.4  Zero-qty rows
--   TXN.5  Negative qty rows
--   TXN.6  Synthetic order IDs
--   TXN.7  Locations never in transactions
--   TXN.8  Outliers (qty / revenue)
--   INV.1  Sparse snapshot dates / 2024 gap
--   INV.2  Inventory vs sales history start
--   INV.3  -1 sentinel on units
--   INV.4  Nov 2025 spike dates
--   INV.5  Negative on-hand / inbound
--   INV.6  raw inventory_snapshot vs inventory_snapshot_cleaned


-- =============================================================================
-- PGH.1: ~2x EAV duplication (expected 9 rows/SKU, seeing ~18)
-- Verified 2026-06-23: avg 18.46 rows/SKU; 662,081 SKUs with exactly 18 rows;
--   0 SKUs with 9 rows; 8.4M (SKU,LEVEL) pairs duplicated 2x
-- =============================================================================

-- Summary metrics
WITH per_sku AS (
  SELECT SKU_ID, COUNT(*) AS row_cnt
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID
),
dup_pairs AS (
  SELECT SKU_ID, LEVEL_NAME, COUNT(*) AS pair_cnt
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID, LEVEL_NAME
)
SELECT
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`) AS total_rows,
  (SELECT COUNT(DISTINCT SKU_ID) FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`) AS distinct_skus,
  (SELECT ROUND(AVG(row_cnt), 2) FROM per_sku) AS avg_rows_per_sku,
  (SELECT COUNTIF(row_cnt = 9) FROM per_sku) AS skus_with_9_rows,
  (SELECT COUNTIF(row_cnt = 18) FROM per_sku) AS skus_with_18_rows,
  (SELECT COUNTIF(pair_cnt = 2) FROM dup_pairs) AS sku_level_pairs_dup_2x,
  (SELECT COUNTIF(pair_cnt = 3) FROM dup_pairs) AS sku_level_pairs_dup_3x;

-- Rows-per-SKU distribution
SELECT row_cnt AS rows_per_sku, COUNT(*) AS sku_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM (
  SELECT SKU_ID, COUNT(*) AS row_cnt
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID
)
GROUP BY row_cnt
ORDER BY row_cnt;

-- Are duplicate EAV rows byte-identical? (sample one SKU)
SELECT *
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE SKU_ID = (
  SELECT SKU_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID HAVING COUNT(*) = 18 LIMIT 1
)
ORDER BY LEVEL_NUMBER, LEVEL_NAME;

-- Duplicate pairs with differing VALUE_CODE (should be 0 if pure append dup)
SELECT COUNT(*) AS pairs_with_conflicting_values
FROM (
  SELECT SKU_ID, LEVEL_NAME, COUNT(DISTINCT CONCAT(VALUE_CODE, '|', VALUE_NAME)) AS distinct_values
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID, LEVEL_NAME
  HAVING COUNT(*) > 1
)
WHERE distinct_values > 1;


-- =============================================================================
-- PGH.2: SKUs lacking PLANNING_STYLE_SIZE
-- Verified 2026-06-23: 0 SKUs missing PSS level row; all 988,764 have nonempty code
-- (May differ if client redefines "missing" as null VALUE_NAME in master build)
-- =============================================================================

SELECT
  COUNT(DISTINCT SKU_ID) AS skus_with_pss_level_row,
  COUNT(DISTINCT CASE
    WHEN NULLIF(TRIM(VALUE_CODE), '') IS NOT NULL AND VALUE_CODE NOT IN ('\\N', '\\\\N')
    THEN SKU_ID END) AS skus_with_nonempty_pss_code
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE';

WITH all_skus AS (
  SELECT DISTINCT SKU_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
),
has_pss AS (
  SELECT DISTINCT SKU_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE'
)
SELECT COUNT(*) AS skus_missing_pss_level_entirely
FROM all_skus a
LEFT JOIN has_pss h USING (SKU_ID)
WHERE h.SKU_ID IS NULL;

-- SKUs where PSS VALUE_NAME is empty/sentinel (product_name gap in master)
SELECT COUNT(DISTINCT SKU_ID) AS skus_pss_empty_name
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE'
  AND (NULLIF(TRIM(VALUE_NAME), '') IS NULL OR VALUE_NAME IN ('\\N', '\\\\N'));


-- =============================================================================
-- PGH.3: PGH SKU universe vs product_intermediate / product_master
-- Verified 2026-06-23: PI=1,977,528 = PM (channel-expanded); ~2x989K SKUs
-- =============================================================================

SELECT
  (SELECT COUNT(DISTINCT SKU_ID) FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`) AS pgh_distinct_skus,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`) AS product_intermediate_rows,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`) AS product_master_rows,
  (SELECT COUNT(DISTINCT product_code_original) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`) AS pm_distinct_skus;

-- SKUs in PGH not reaching product_intermediate (after pivot+channel build)
WITH pgh_skus AS (
  SELECT DISTINCT SKU_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
),
pi_skus AS (
  SELECT DISTINCT product_code_original AS SKU_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`
)
SELECT
  COUNT(*) AS pgh_skus,
  COUNTIF(pi.SKU_ID IS NOT NULL) AS in_product_intermediate,
  COUNTIF(pi.SKU_ID IS NULL) AS pgh_only
FROM pgh_skus p
LEFT JOIN pi_skus pi USING (SKU_ID);


-- =============================================================================
-- PGH.4: PSS / forecast product grain — PGH level cardinalities
-- =============================================================================

SELECT
  LEVEL_NUMBER,
  LEVEL_NAME,
  COUNT(*) AS rows,
  COUNT(DISTINCT VALUE_NAME) AS distinct_names,
  COUNT(DISTINCT VALUE_CODE) AS distinct_codes,
  COUNT(DISTINCT SKU_ID) AS distinct_skus
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
GROUP BY LEVEL_NUMBER, LEVEL_NAME
ORDER BY SAFE_CAST(LEVEL_NUMBER AS INT64);

-- Median SKUs per planning-style-size name (PSS proxy)
SELECT APPROX_QUANTILES(sku_cnt, 4)[OFFSET(2)] AS median_skus_per_pss_name
FROM (
  SELECT VALUE_NAME, COUNT(DISTINCT SKU_ID) AS sku_cnt
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE'
  GROUP BY VALUE_NAME
);


-- =============================================================================
-- PGH.5: Short article codes (<=3 chars) at PLANNING_STYLE_OPTION
-- =============================================================================

SELECT
  COUNT(*) AS pgh_pso_rows_short_base,
  COUNT(DISTINCT SPLIT(VALUE_CODE, '-')[SAFE_OFFSET(0)]) AS distinct_short_bases,
  COUNT(DISTINCT SKU_ID) AS distinct_skus
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
  AND LENGTH(SPLIT(VALUE_CODE, '-')[SAFE_OFFSET(0)]) <= 3;

SELECT SPLIT(VALUE_CODE, '-')[SAFE_OFFSET(0)] AS short_base,
  COUNT(DISTINCT SKU_ID) AS sku_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
  AND LENGTH(SPLIT(VALUE_CODE, '-')[SAFE_OFFSET(0)]) <= 3
GROUP BY short_base
ORDER BY sku_cnt DESC
LIMIT 20;


-- =============================================================================
-- SKU.1 + SKU.2: Zero pricing and DUMMY_CURRENCY
-- =============================================================================

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) = 0) AS cost_zero,
  COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) = 0) AS sell_zero,
  COUNTIF(PRICE_CURRENCY = 'DUMMY_CURRENCY') AS dummy_currency,
  COUNT(DISTINCT PRICE_CURRENCY) AS distinct_currencies
FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`;


-- =============================================================================
-- SKU.3: 4 identical rows per SKU
-- =============================================================================

SELECT rows_per_id, COUNT(*) AS id_count
FROM (
  SELECT ID, COUNT(*) AS rows_per_id
  FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
  GROUP BY ID
)
GROUP BY rows_per_id
ORDER BY rows_per_id;

-- Columns that vary within ID (expect 0 rows if all 4 are identical)
SELECT ID, COUNT(*) AS row_cnt, COUNT(DISTINCT TO_JSON_STRING(t)) AS distinct_row_shapes
FROM `lululemon-01042025.lulu_sourcing_dev.sku_details` t
GROUP BY ID
HAVING COUNT(DISTINCT TO_JSON_STRING(t)) > 1
LIMIT 20;


-- =============================================================================
-- SKU.4: Single season
-- =============================================================================

SELECT SEASON_YEAR, SEASON_CODE, COUNT(*) AS row_cnt, COUNT(DISTINCT ID) AS distinct_ids
FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
GROUP BY SEASON_YEAR, SEASON_CODE
ORDER BY row_cnt DESC;


-- =============================================================================
-- SKU.5: Missing IMAGE_URL (empty string, not NULL)
-- =============================================================================

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(NULLIF(TRIM(IMAGE_URL), '') IS NULL) AS missing_image_url,
  ROUND(100.0 * COUNTIF(NULLIF(TRIM(IMAGE_URL), '') IS NULL) / COUNT(*), 2) AS pct_missing
FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`;


-- =============================================================================
-- SKU.6: Join rules — PGH SKU_ID bijection with sku_details.ID
-- =============================================================================

WITH pgh AS (SELECT DISTINCT SKU_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`),
sku AS (SELECT DISTINCT ID FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`)
SELECT
  (SELECT COUNT(*) FROM pgh) AS pgh_skus,
  (SELECT COUNT(*) FROM sku) AS sku_ids,
  (SELECT COUNT(*) FROM pgh JOIN sku ON pgh.SKU_ID = sku.ID) AS matched,
  (SELECT COUNT(*) FROM pgh LEFT JOIN sku ON pgh.SKU_ID = sku.ID WHERE sku.ID IS NULL) AS pgh_only,
  (SELECT COUNT(*) FROM sku LEFT JOIN pgh ON sku.ID = pgh.SKU_ID WHERE pgh.SKU_ID IS NULL) AS sku_only;


-- =============================================================================
-- PA.1: FLEX_STATUS distribution
-- =============================================================================

SELECT FLEX_STATUS, COUNT(*) AS row_cnt, COUNT(DISTINCT STYLE_ID) AS distinct_styles,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
GROUP BY FLEX_STATUS
ORDER BY row_cnt DESC;


-- =============================================================================
-- PA.2: article_status stub vs FLEX_STATUS (GSM)
-- =============================================================================

SELECT article_status, COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
GROUP BY article_status;

SELECT flex_status, COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`
GROUP BY flex_status
ORDER BY row_cnt DESC;


-- =============================================================================
-- PA.3: Attribute population tiers (product_attribute_s)
-- =============================================================================

-- Replace column list with INFORMATION_SCHEMA or run per-column in script
SELECT
  'GENDER' AS col, COUNTIF(NULLIF(TRIM(GENDER), '') IS NULL OR GENDER IN ('\\N', '\\\\N')) AS missing, COUNT(*) AS total
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
UNION ALL SELECT 'SILHOUETTE', COUNTIF(NULLIF(TRIM(SILHOUETTE), '') IS NULL OR SILHOUETTE IN ('\\N', '\\\\N')), COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
UNION ALL SELECT 'FLEX_STATUS', COUNTIF(NULLIF(TRIM(FLEX_STATUS), '') IS NULL OR FLEX_STATUS IN ('\\N', '\\\\N')), COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
UNION ALL SELECT 'PRODUCT_GENDER', COUNTIF(NULLIF(TRIM(PRODUCT_GENDER), '') IS NULL OR PRODUCT_GENDER IN ('\\N', '\\\\N')), COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
UNION ALL SELECT 'FABRIC_FAMILY', COUNTIF(NULLIF(TRIM(FABRIC_FAMILY), '') IS NULL OR FABRIC_FAMILY IN ('\\N', '\\\\N')), COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`;


-- =============================================================================
-- PA.4: STYLE_ID vs PGH STYLE; PA-only styles
-- =============================================================================

WITH pgh_styles AS (
  SELECT DISTINCT VALUE_CODE AS style_code
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
pa_styles AS (
  SELECT DISTINCT STYLE_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
)
SELECT
  (SELECT COUNT(*) FROM pgh_styles) AS pgh_style_count,
  (SELECT COUNT(*) FROM pa_styles) AS pa_style_count,
  (SELECT COUNT(*) FROM pa_styles p LEFT JOIN pgh_styles g ON p.STYLE_ID = g.style_code WHERE g.style_code IS NULL) AS pa_only_styles,
  (SELECT COUNT(*) FROM pgh_styles g LEFT JOIN pa_styles p ON g.style_code = p.STYLE_ID WHERE p.STYLE_ID IS NULL) AS pgh_only_styles;


-- =============================================================================
-- PA.5: GENDER vs PRODUCT_GENDER
-- =============================================================================

SELECT 'GENDER' AS field, GENDER AS val, COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
GROUP BY GENDER
UNION ALL
SELECT 'PRODUCT_GENDER', PRODUCT_GENDER, COUNT(*)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
GROUP BY PRODUCT_GENDER
ORDER BY field, row_cnt DESC;


-- =============================================================================
-- PA.6: [Internal DE] 3x load — rows per STYLE_ID
-- =============================================================================

SELECT rows_per_style, COUNT(*) AS style_count
FROM (
  SELECT STYLE_ID, COUNT(*) AS rows_per_style
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  GROUP BY STYLE_ID
)
GROUP BY rows_per_style
ORDER BY rows_per_style;


-- =============================================================================
-- LGH.1 + LD.2: Store/DC universe and OUT_OF_SCOPE vs channel
-- =============================================================================

SELECT TYPE_CODE, COUNT(*) AS loc_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
GROUP BY TYPE_CODE
ORDER BY loc_cnt DESC;

SELECT
  REGEXP_EXTRACT(CHANNEL_CODE, r'_([A-Z]+)$') AS channel_suffix,
  TYPE_CODE,
  COUNT(*) AS loc_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
GROUP BY channel_suffix, TYPE_CODE
ORDER BY channel_suffix, TYPE_CODE;


-- =============================================================================
-- LGH.2: LOC_CLOSED_IND vs close dates
-- =============================================================================

SELECT
  lgh.LOC_CLOSED_IND,
  COUNT(*) AS loc_cnt,
  COUNTIF(NULLIF(TRIM(ld.PERMANANENT_CLOSE_DATE), '\\N') IS NOT NULL) AS has_close_date,
  COUNTIF(NULLIF(TRIM(ld.PERMANANENT_CLOSE_DATE), '\\N') IS NULL) AS no_close_date
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy` lgh
JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
  ON lgh.LOC_ID = ld.ID
GROUP BY lgh.LOC_CLOSED_IND
ORDER BY loc_cnt DESC;


-- =============================================================================
-- LGH.3: \\N vs \N sentinels
-- =============================================================================

SELECT
  'PHYSICAL_DC_ID' AS col,
  COUNTIF(PHYSICAL_DC_ID = '\\\\N') AS double_backslash,
  COUNTIF(PHYSICAL_DC_ID = '\\N') AS single_backslash
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
UNION ALL
SELECT 'AREA_ID', COUNTIF(AREA_ID = '\\\\N'), COUNTIF(AREA_ID = '\\N')
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
UNION ALL
SELECT 'REGION_ID', COUNTIF(REGION_ID = '\\\\N'), COUNTIF(REGION_ID = '\\N')
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`;


-- =============================================================================
-- LGH.4: CMNTY vs COMMUNITY naming
-- =============================================================================

SELECT MARKET_CHANNEL_NAME, COUNT(*) AS loc_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
WHERE MARKET_CHANNEL_NAME LIKE '%CMNTY%' OR MARKET_CHANNEL_NAME LIKE '%COMMUNITY%'
GROUP BY MARKET_CHANNEL_NAME
ORDER BY loc_cnt DESC;


-- =============================================================================
-- LGH.5: Orphan PRIMARY_DC_ID
-- =============================================================================

WITH dcs AS (SELECT DISTINCT LOC_ID FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`)
SELECT lgh.LOC_ID, lgh.LOC_NAME, lgh.PRIMARY_DC_ID
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy` lgh
LEFT JOIN dcs ON lgh.PRIMARY_DC_ID = dcs.LOC_ID
WHERE lgh.PRIMARY_DC_ID NOT IN ('\\N', '\\\\N', '')
  AND dcs.LOC_ID IS NULL;


-- =============================================================================
-- LD.1: Active-store funnel
-- =============================================================================

SELECT
  COUNT(*) AS total,
  COUNTIF(TYPE_CODE != 'OUT_OF_SCOPE') AS in_scope,
  COUNTIF(TYPE_CODE != 'OUT_OF_SCOPE'
    AND (NULLIF(TRIM(PERMANANENT_CLOSE_DATE), '\\N') IS NULL)) AS in_scope_not_closed,
  COUNTIF(TYPE_CODE != 'OUT_OF_SCOPE'
    AND (NULLIF(TRIM(PERMANANENT_CLOSE_DATE), '\\N') IS NULL)
    AND SAFE_CAST(FIRST_OPEN_DATE AS DATE) <= CURRENT_DATE()) AS active_today
FROM `lululemon-01042025.lulu_sourcing_dev.location_details`;


-- =============================================================================
-- LD.5: Missing LOC_FORMAT (LGH)
-- =============================================================================

SELECT LOC_FORMAT, COUNT(*) AS loc_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
GROUP BY LOC_FORMAT
ORDER BY loc_cnt DESC;


-- =============================================================================
-- LD.6: Future-dated opens
-- =============================================================================

SELECT ID, DISPLAY_NAME, FIRST_OPEN_DATE
FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
WHERE SAFE_CAST(FIRST_OPEN_DATE AS DATE) > CURRENT_DATE()
ORDER BY FIRST_OPEN_DATE
LIMIT 50;


-- =============================================================================
-- LD.7: China ecomm stores (sample IDs from store master open questions)
-- =============================================================================

SELECT ID, DISPLAY_NAME, CHANNEL_CODE, TYPE_CODE
FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
WHERE ID IN ('45189', '45187', '45186')
   OR DISPLAY_NAME LIKE '%Tmall%' OR DISPLAY_NAME LIKE '%WeChat%' OR DISPLAY_NAME LIKE '%JD%';


-- =============================================================================
-- TXN.1: Returns feed exists (row count only)
-- =============================================================================

-- SELECT COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.returns_transactions`;
-- (not landed in sourcing_dev — check outbound/GCS if needed)


-- =============================================================================
-- TXN.2: TRANSACTION_TYPE single value
-- =============================================================================

SELECT TRANSACTION_TYPE, COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
GROUP BY TRANSACTION_TYPE;


-- =============================================================================
-- TXN.3: Sales history date range
-- =============================================================================

SELECT
  MIN(SAFE_CAST(DATE_TRANSACTION AS DATE)) AS min_date,
  MAX(SAFE_CAST(DATE_TRANSACTION AS DATE)) AS max_date,
  COUNT(DISTINCT SAFE_CAST(DATE_TRANSACTION AS DATE)) AS distinct_dates,
  COUNT(*) AS total_rows
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`;


-- =============================================================================
-- TXN.4: Zero-qty rows
-- =============================================================================

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(SAFE_CAST(UNITS AS FLOAT64) = 0) AS zero_qty,
  ROUND(100.0 * COUNTIF(SAFE_CAST(UNITS AS FLOAT64) = 0) / COUNT(*), 2) AS pct_zero_qty
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`;


-- =============================================================================
-- TXN.5: Negative qty rows
-- =============================================================================

SELECT COUNT(*) AS negative_qty_rows
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
WHERE SAFE_CAST(UNITS AS FLOAT64) < 0;


-- =============================================================================
-- TXN.6: Synthetic order IDs
-- =============================================================================

SELECT COUNT(*) AS total_rows,
  COUNTIF(SALES_ORDER_ID = CONCAT(DATE_TRANSACTION, '|', SKU_ID, '|', LOCATION_ID_SALES)) AS synthetic_match,
  COUNTIF(SALES_ORDER_ID != CONCAT(DATE_TRANSACTION, '|', SKU_ID, '|', LOCATION_ID_SALES)) AS non_match
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`;


-- =============================================================================
-- TXN.7: Locations never in transactions
-- =============================================================================

WITH stores AS (
  SELECT DISTINCT LPAD(ID, 10, '0') AS store_code FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
),
txn_locs AS (
  SELECT DISTINCT LPAD(LOCATION_ID_SALES, 10, '0') AS store_code
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
)
SELECT
  COUNT(*) AS total_stores,
  COUNTIF(t.store_code IS NULL) AS stores_never_in_txn
FROM stores s
LEFT JOIN txn_locs t USING (store_code);


-- =============================================================================
-- TXN.8: Outliers
-- =============================================================================

SELECT
  MAX(SAFE_CAST(UNITS AS FLOAT64)) AS max_qty,
  MAX(SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64)) AS max_revenue
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`;

SELECT DATE_TRANSACTION, SKU_ID, LOCATION_ID_SALES, UNITS, PRICE_SALES_TOTAL
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
ORDER BY SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64) DESC
LIMIT 10;


-- =============================================================================
-- INV.1: Sparse snapshot dates / 2024 gap
-- =============================================================================

SELECT EXTRACT(YEAR FROM SAFE_CAST(DATE AS DATE)) AS yr,
  COUNT(DISTINCT DATE) AS distinct_dates,
  COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
GROUP BY yr
ORDER BY yr;


-- =============================================================================
-- INV.2: Inventory vs sales history start
-- =============================================================================

SELECT 'inventory_snapshot' AS src, MIN(SAFE_CAST(DATE AS DATE)) AS min_date, MAX(SAFE_CAST(DATE AS DATE)) AS max_date
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
UNION ALL
SELECT 'sales_transactions', MIN(SAFE_CAST(DATE_TRANSACTION AS DATE)), MAX(SAFE_CAST(DATE_TRANSACTION AS DATE))
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`;


-- =============================================================================
-- INV.3: -1 sentinel
-- =============================================================================

SELECT
  COUNTIF(SAFE_CAST(UNITS_ON_HAND AS INT64) = -1) AS oh_minus_one,
  COUNTIF(SAFE_CAST(UNITS_ON_HAND AS INT64) < -1) AS oh_real_negative,
  COUNTIF(SAFE_CAST(UNITS_AVAILABLE AS INT64) = -1) AS avail_minus_one
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`;


-- =============================================================================
-- INV.4: Nov 2025 spike dates
-- =============================================================================

SELECT SAFE_CAST(DATE AS DATE) AS snap_date, COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
WHERE SAFE_CAST(DATE AS DATE) BETWEEN '2025-10-29' AND '2025-11-17'
GROUP BY snap_date
ORDER BY snap_date;


-- =============================================================================
-- INV.5: Negative on-hand / inbound
-- =============================================================================

SELECT
  COUNTIF(SAFE_CAST(UNITS_ON_HAND AS INT64) < 0) AS oh_negative,
  COUNTIF(SAFE_CAST(UNITS_INBOUND AS INT64) < 0) AS inbound_negative
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`;


-- =============================================================================
-- INV.6: raw vs cleaned inventory
-- =============================================================================

SELECT 'inventory_snapshot' AS tbl, COUNT(*) AS rows, COUNT(DISTINCT DATE) AS distinct_dates
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
UNION ALL
SELECT 'inventory_snapshot_cleaned', COUNT(*), COUNT(DISTINCT DATE)
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot_cleaned`;

-- #############################################################################
-- PART B — SUPPLEMENTAL RECHECKS (PM-1 .. PM-10, cross-layer)
-- #############################################################################

-- =============================================================================
-- PM-1: sku_details pricing — cost/sell zero, currency dummy
-- Open Q: confirm canonical pricing source (Aug 2025 GCS priced; Sep+ zero)
-- =============================================================================

-- Q1: Cross-table pricing population
SELECT layer,
  total_rows,
  rows_dummy_currency,
  ROUND(100 * rows_dummy_currency / total_rows, 2) AS pct_dummy_currency,
  rows_cost_zero,
  ROUND(100 * rows_cost_zero / total_rows, 2) AS pct_cost_zero,
  rows_sell_zero,
  rows_cost_positive,
  rows_sell_positive,
  distinct_currency
FROM (
  SELECT '1_lulu_sourcing_dev.sku_details' AS layer,
    COUNT(*) AS total_rows,
    COUNTIF(CAST(PRICE_CURRENCY AS STRING) = 'DUMMY_CURRENCY') AS rows_dummy_currency,
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) = 0) AS rows_cost_zero,
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) = 0) AS rows_sell_zero,
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) > 0) AS rows_cost_positive,
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) > 0) AS rows_sell_positive,
    COUNT(DISTINCT PRICE_CURRENCY) AS distinct_currency
  FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
  UNION ALL
  SELECT '2_outbound.sku_details_20251119',
    COUNT(*),
    COUNTIF(CAST(PRICE_CURRENCY AS STRING) = 'DUMMY_CURRENCY'),
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) = 0),
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) = 0),
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) > 0),
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) > 0),
    COUNT(DISTINCT PRICE_CURRENCY)
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
  UNION ALL
  SELECT '3_outbound.sku_details_cleaned',
    COUNT(*),
    COUNTIF(CAST(PRICE_CURRENCY AS STRING) = 'DUMMY_CURRENCY'),
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) = 0),
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) = 0),
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) > 0),
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) > 0),
    COUNT(DISTINCT PRICE_CURRENCY)
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned`
  UNION ALL
  SELECT '4_outbound.sku_details_raw',
    COUNT(*),
    COUNTIF(CAST(PRICE_CURRENCY AS STRING) = 'DUMMY_CURRENCY'),
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) = 0),
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) = 0),
    COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) > 0),
    COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) > 0),
    COUNT(DISTINCT PRICE_CURRENCY)
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details`
)
ORDER BY layer;

-- Q2: sku_details_cleaned snapshot fingerprint
SELECT
  COUNT(DISTINCT sku_id_code) AS cleaned_skus,
  COUNTIF(COST_PRICE = 0 AND SELLING_PRICE = 0) AS skus_both_zero,
  COUNT(DISTINCT SEASON_CODE) AS distinct_seasons,
  ARRAY_AGG(DISTINCT SEASON_CODE LIMIT 10) AS seasons,
  ARRAY_AGG(DISTINCT PRICE_CURRENCY LIMIT 10) AS currencies
FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned`;

-- Q3: Downstream transaction_master impact (1% sample)
SELECT
  COUNT(*) AS txn_rows,
  COUNTIF(cost = 0) AS cost_zero,
  COUNTIF(msrp = 0) AS msrp_zero,
  COUNTIF(cost > 0) AS cost_positive,
  COUNTIF(msrp > 0) AS msrp_positive
FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`
TABLESAMPLE SYSTEM (1 PERCENT);

-- Q4: Alternate pricing source — price_book
SELECT
  COUNT(*) AS price_book_rows,
  COUNTIF(SAFE_CAST(REGULAR_PRICE AS FLOAT64) > 0) AS regular_price_positive,
  COUNTIF(SAFE_CAST(ORIGINAL_PRICE AS FLOAT64) > 0) AS original_price_positive,
  COUNT(DISTINCT STYLE_OPTION_ID) AS distinct_style_options
FROM `lululemon-01042025.lululemon_souricng_outbound.price_book`;


-- =============================================================================
-- PM-2: season_code — single season on current load vs GCS drops
-- =============================================================================

-- Q1: GSM product_master (from loaded sku_details batch)
SELECT season_code, COUNT(*) AS pm_rows
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
GROUP BY season_code
ORDER BY pm_rows DESC;

-- Q2: Sourcing sku_details seasons
SELECT SEASON_CODE, COUNT(*) AS row_cnt, COUNT(DISTINCT ID) AS distinct_skus
FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
GROUP BY SEASON_CODE
ORDER BY row_cnt DESC;

-- Q3: Raw outbound sku_details (multi-batch history if present)
SELECT CAST(SEASON_CODE AS STRING) AS season_code,
  COUNT(*) AS row_cnt,
  COUNT(DISTINCT ID) AS distinct_ids
FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details`
GROUP BY season_code
ORDER BY row_cnt DESC;


-- =============================================================================
-- PM-3: PSS grain — Phase 1 forecast (PSS x store x week) vs SKU sales
-- =============================================================================

-- Q1: GSM grains on product_master
SELECT
  COUNT(DISTINCT product_code) AS sku_x_channel_rows,
  COUNT(DISTINCT product_code_original) AS channel_agnostic_skus,
  COUNT(DISTINCT l8_name) AS distinct_planning_style_size_names,
  COUNT(DISTINCT CONCAT(l8_name, '|', l1_name)) AS planning_style_size_x_channel
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`;

-- Q2: Median SKUs per planning-style-size x channel
SELECT APPROX_QUANTILES(sku_cnt, 4)[OFFSET(2)] AS median_skus_per_pss_channel
FROM (
  SELECT l8_name, l1_name AS channel, COUNT(DISTINCT product_code_original) AS sku_cnt
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
  GROUP BY l8_name, l1_name
);

-- Q3: PGH PLANNING_STYLE_SIZE level exists (EAV)
SELECT
  COUNT(DISTINCT SKU_ID) AS skus_with_pss_level,
  COUNT(DISTINCT VALUE_CODE) AS distinct_pss_codes,
  COUNT(DISTINCT VALUE_NAME) AS distinct_pss_names
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE';

-- Q4: SKUs lacking PLANNING_STYLE_SIZE in PGH (ties PM-12)
SELECT COUNT(DISTINCT SKU_ID) AS skus_missing_pss
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy` pgh
WHERE SKU_ID NOT IN (
  SELECT DISTINCT SKU_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE'
);


-- =============================================================================
-- PM-4: flex_status Drop — forecast universe
-- =============================================================================

-- Q1: SKU x channel on product_intermediate
SELECT
  flex_status,
  COUNT(*) AS row_cnt,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`
GROUP BY flex_status
ORDER BY row_cnt DESC;

-- Q2: Style-level from product_attribute_s (if FLEX_STATUS column present)
SELECT
  FLEX_STATUS,
  COUNT(*) AS row_cnt,
  COUNT(DISTINCT STYLE_ID) AS distinct_styles
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
GROUP BY FLEX_STATUS
ORDER BY row_cnt DESC;

-- Q3: GSM product_master has no flex_status; article_status stubbed
SELECT article_status, COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
GROUP BY article_status;


-- =============================================================================
-- PM-5: placeholder / short article codes (LENGTH(article_original) <= 3)
-- Canonical flag: product_master_clean_view.sql -> is_placeholder
-- =============================================================================

-- Q1: Row-level scope + top short codes
SELECT
  COUNT(*) AS placeholder_rows,
  COUNT(DISTINCT article_original) AS distinct_short_codes,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`), 2) AS pct_of_pm_rows
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
WHERE LENGTH(COALESCE(article_original, '')) <= 3;

SELECT article_original, COUNT(*) AS row_count
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
WHERE LENGTH(COALESCE(article_original, '')) <= 3
GROUP BY article_original
ORDER BY row_count DESC
LIMIT 20;

-- Q2: Trace to sourcing PGH (PLANNING_STYLE_OPTION)
SELECT
  COUNT(*) AS pgh_pso_rows_short_base,
  COUNT(DISTINCT SPLIT(VALUE_CODE, '-')[SAFE_OFFSET(0)]) AS distinct_short_bases
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
  AND LENGTH(SPLIT(VALUE_CODE, '-')[SAFE_OFFSET(0)]) <= 3;

-- Q3: Sales overlap — do not auto-exclude (row grain = SKU x channel)
SELECT
  COUNT(*) AS placeholder_rows,
  COUNTIF(t.product_code IS NOT NULL) AS rows_with_real_sales,
  ROUND(100.0 * COUNTIF(t.product_code IS NOT NULL) / COUNT(*), 1) AS pct_rows_with_sales
FROM `lululemon-01042025.lulu_ingestion_dev.product_master` p
LEFT JOIN (
  SELECT DISTINCT product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`
  WHERE qty > 0 AND revenue > 0
) t USING (product_code)
WHERE LENGTH(COALESCE(p.article_original, '')) <= 3;

-- Q4: Same at channel-agnostic SKU grain
WITH ph AS (
  SELECT DISTINCT product_code_original
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
  WHERE LENGTH(COALESCE(article_original, '')) <= 3
),
sold AS (
  SELECT DISTINCT p.product_code_original
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master` t
  JOIN `lululemon-01042025.lulu_ingestion_dev.product_master` p USING (product_code)
  WHERE t.qty > 0 AND t.revenue > 0
)
SELECT
  COUNT(*) AS placeholder_skus,
  COUNTIF(s.product_code_original IS NOT NULL) AS skus_with_sales,
  ROUND(100.0 * COUNTIF(s.product_code_original IS NOT NULL) / COUNT(*), 1) AS pct_skus_with_sales
FROM ph
LEFT JOIN sold s USING (product_code_original);


-- =============================================================================
-- PM-6: never-sold catalog SKUs
--
-- Grain matters:
--   ~26%  PGH SKU_ID never in raw sales_transactions (UNITS > 0)  [client ~23% EDA]
--   ~59%  distinct product_code_original in GSM PM never sold
--   ~63%  product_code rows (SKU x channel) in GSM PM never sold
-- Filter: qty > 0 AND revenue > 0 on transaction_master
-- =============================================================================

-- Q1: Raw sales vs PGH catalog (original EDA grain)
WITH pgh AS (
  SELECT COUNT(DISTINCT SKU_ID) AS catalog_skus
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
),
raw_sold AS (
  SELECT COUNT(DISTINCT SKU_ID) AS skus_in_raw_sales
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
  WHERE SKU_ID IS NOT NULL
    AND SAFE_CAST(UNITS AS FLOAT64) > 0
)
SELECT
  pgh.catalog_skus,
  raw_sold.skus_in_raw_sales,
  pgh.catalog_skus - raw_sold.skus_in_raw_sales AS never_in_raw_sales,
  ROUND(100.0 * (pgh.catalog_skus - raw_sold.skus_in_raw_sales) / pgh.catalog_skus, 2) AS pct_never_in_raw_sales
FROM pgh, raw_sold;

-- Q2: GSM SKU grain (channel-agnostic product_code_original)
WITH catalog AS (
  SELECT DISTINCT product_code_original
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
),
sold AS (
  SELECT DISTINCT p.product_code_original
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master` t
  JOIN `lululemon-01042025.lulu_ingestion_dev.product_master` p USING (product_code)
  WHERE t.qty > 0 AND t.revenue > 0
)
SELECT
  COUNT(*) AS catalog_skus,
  COUNTIF(s.product_code_original IS NULL) AS never_sold_skus,
  ROUND(100.0 * COUNTIF(s.product_code_original IS NULL) / COUNT(*), 2) AS pct_never_sold
FROM catalog c
LEFT JOIN sold s USING (product_code_original);

-- Q3: GSM SKU x channel grain (health check X5)
WITH txn_products AS (
  SELECT DISTINCT product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`
  WHERE product_code IS NOT NULL
    AND qty > 0
    AND revenue > 0
)
SELECT
  COUNT(*) AS pm_rows_never_sold,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`), 2) AS pct_of_pm
FROM `lululemon-01042025.lulu_ingestion_dev.product_master` p
LEFT JOIN txn_products t USING (product_code)
WHERE t.product_code IS NULL;

-- Q4: Characterize never-sold SKUs (flex_status, placeholder overlap)
WITH pm AS (
  SELECT product_code, product_code_original,
         LENGTH(COALESCE(article_original, '')) <= 3 AS is_placeholder
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
),
pi AS (
  SELECT product_code, flex_status
  FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`
),
sold_sku AS (
  SELECT DISTINCT p.product_code_original
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master` t
  JOIN pm p USING (product_code)
  WHERE t.qty > 0 AND t.revenue > 0
),
sku_status AS (
  SELECT
    p.product_code_original,
    MAX(IF(s.product_code_original IS NOT NULL, 1, 0)) AS has_sales,
    MAX(IF(pi.flex_status = 'Active', 1, 0)) AS any_active,
    MAX(IF(pi.flex_status = 'Drop', 1, 0)) AS any_drop,
    MAX(IF(p.is_placeholder, 1, 0)) AS any_placeholder
  FROM pm p
  LEFT JOIN sold_sku s USING (product_code_original)
  LEFT JOIN pi USING (product_code)
  GROUP BY product_code_original
)
SELECT
  COUNT(*) AS catalog_skus,
  COUNTIF(has_sales = 0) AS never_sold_skus,
  COUNTIF(has_sales = 0 AND any_active = 1) AS never_sold_but_some_channel_active,
  COUNTIF(has_sales = 0 AND any_drop = 1 AND any_active = 0) AS never_sold_drop_only,
  COUNTIF(has_sales = 0 AND any_placeholder = 1) AS never_sold_with_placeholder_row
FROM sku_status;

-- Q5: Never-sold SKUs by division (l2_name)
WITH catalog AS (
  SELECT DISTINCT product_code_original FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
),
sold AS (
  SELECT DISTINCT p.product_code_original
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master` t
  JOIN `lululemon-01042025.lulu_ingestion_dev.product_master` p USING (product_code)
  WHERE t.qty > 0 AND t.revenue > 0
),
never AS (
  SELECT c.product_code_original
  FROM catalog c
  LEFT JOIN sold s USING (product_code_original)
  WHERE s.product_code_original IS NULL
),
pm AS (
  SELECT product_code_original, ANY_VALUE(l2_name) AS l2_name
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
  GROUP BY product_code_original
)
SELECT pm.l2_name, COUNT(*) AS never_sold_skus
FROM never
JOIN pm USING (product_code_original)
GROUP BY l2_name
ORDER BY never_sold_skus DESC;


-- =============================================================================
-- PM-7: product_attribute_s — 3 rows per STYLE_ID
-- Revalidated 2026-06-16: identical triplicate load, not an extra dimension
-- =============================================================================

-- Q1: Grain summary
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT STYLE_ID) AS distinct_styles,
  ROUND(COUNT(*) / COUNT(DISTINCT STYLE_ID), 2) AS avg_rows_per_style,
  COUNT(DISTINCT SYNCSTARTDATETIME) AS distinct_sync_batches
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`;

-- Q2: Rows-per-style distribution (expect all styles = 3)
SELECT row_cnt, COUNT(*) AS style_count
FROM (
  SELECT STYLE_ID, COUNT(*) AS row_cnt
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  GROUP BY STYLE_ID
)
GROUP BY row_cnt
ORDER BY row_cnt;

-- Q3: Are the 3 rows identical or do they encode another dimension?
WITH per_style AS (
  SELECT
    STYLE_ID,
    COUNT(*) AS row_cnt,
    COUNT(DISTINCT FARM_FINGERPRINT(TO_JSON_STRING(t))) AS distinct_row_fingerprints
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` t
  GROUP BY STYLE_ID
)
SELECT
  COUNT(*) AS styles,
  COUNTIF(row_cnt = 3 AND distinct_row_fingerprints = 1) AS triple_fully_identical,
  COUNTIF(row_cnt = 3 AND distinct_row_fingerprints > 1) AS triple_with_differences,
  COUNTIF(row_cnt != 3) AS styles_not_exactly_3
FROM per_style;

-- Q4: Columns that vary within STYLE_ID (expect zero rows if fully identical)
-- Run only if Q3 shows differences; samples key build columns
SELECT
  STYLE_ID,
  COUNT(DISTINCT FLEX_STATUS) AS flex_status_variants,
  COUNT(DISTINCT GENDER) AS gender_variants,
  COUNT(DISTINCT SILHOUETTE) AS silhouette_variants
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
GROUP BY STYLE_ID
HAVING COUNT(*) > 1
  AND (
    COUNT(DISTINCT FLEX_STATUS) > 1
    OR COUNT(DISTINCT GENDER) > 1
    OR COUNT(DISTINCT SILHOUETTE) > 1
  )
LIMIT 20;

-- Q5: Recommended dedup for joins (use in build if DISTINCT removed)
SELECT * EXCEPT (rn)
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY STYLE_ID
      ORDER BY SYNCSTARTDATETIME DESC
    ) AS rn
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
)
WHERE rn = 1;


-- =============================================================================
-- PM-8: article_status stub vs FLEX_STATUS (lifecycle field)
-- Build hardcodes article_status='ACTIVE'; flex_status comes from product_attribute_s
-- =============================================================================

-- Q1: Client outbound feed (canonical source, 1 row per STYLE_ID)
SELECT
  FLEX_STATUS,
  COUNT(*) AS row_cnt,
  COUNT(DISTINCT STYLE_ID) AS distinct_styles,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
GROUP BY FLEX_STATUS
ORDER BY row_cnt DESC;

-- Q2: Sourcing product_intermediate (SKU x channel grain)
SELECT
  flex_status,
  article_status,
  COUNT(*) AS row_cnt,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`
GROUP BY flex_status, article_status
ORDER BY row_cnt DESC;

-- Q3: GSM product_master (flex_status column absent; article_status stubbed)
SELECT article_status, COUNT(*) AS row_cnt
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
GROUP BY article_status;

-- Q4: Drop styles incorrectly marked ACTIVE on GSM (join to sourcing)
SELECT
  pi.flex_status,
  pm.article_status,
  COUNT(*) AS gsm_rows
FROM `lululemon-01042025.lulu_ingestion_dev.product_master` pm
JOIN `lululemon-01042025.lulu_sourcing_dev.product_intermediate` pi
  USING (product_code)
GROUP BY pi.flex_status, pm.article_status
ORDER BY gsm_rows DESC;

-- Q5: Suggested build change (DE, after client sign-off on value mapping)
-- Replace hardcoded 'ACTIVE' with mapped FLEX_STATUS, e.g.:
--   CASE UPPER(c.FLEX_STATUS)
--     WHEN 'ACTIVE' THEN 'ACTIVE'
--     WHEN 'DROP' THEN 'DROP'
--     WHEN 'INACTIVE' THEN 'INACTIVE'
--     ELSE 'UNKNOWN'
--   END AS article_status


-- =============================================================================
-- PM-9: forecasting / explainability — which product_attribute_s columns?
-- Use outbound product_attribute_s_20251119 (1 row per STYLE_ID, clean client feed)
-- =============================================================================

-- Q1: Column inventory
SELECT COUNT(*) AS column_count
FROM `lululemon-01042025.lulu_sourcing_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'product_attribute_s';

-- Q2: Population tiers for candidate forecasting / explainability attributes
SELECT
  COUNT(*) AS total_styles,
  ROUND(100.0 * COUNTIF(GENDER IS NULL OR GENDER IN ('', '\\N')) / COUNT(*), 1) AS gender_missing_pct,
  ROUND(100.0 * COUNTIF(PRODUCT_LINE IS NULL OR PRODUCT_LINE IN ('', '\\N')) / COUNT(*), 1) AS product_line_missing_pct,
  ROUND(100.0 * COUNTIF(FLEX_STATUS IS NULL OR FLEX_STATUS IN ('', '\\N')) / COUNT(*), 1) AS flex_status_missing_pct,
  ROUND(100.0 * COUNTIF(DESIGN_LINE IS NULL OR DESIGN_LINE IN ('', '\\N')) / COUNT(*), 1) AS design_line_missing_pct,
  ROUND(100.0 * COUNTIF(DESIGNED_FOR_ACTIVITY IS NULL OR DESIGNED_FOR_ACTIVITY IN ('', '\\N')) / COUNT(*), 1) AS designed_for_activity_missing_pct,
  ROUND(100.0 * COUNTIF(GLOBAL_MERCH_TEAM IS NULL OR GLOBAL_MERCH_TEAM IN ('', '\\N')) / COUNT(*), 1) AS global_merch_team_missing_pct,
  ROUND(100.0 * COUNTIF(SILHOUETTE IS NULL OR SILHOUETTE IN ('', '\\N')) / COUNT(*), 1) AS silhouette_missing_pct,
  ROUND(100.0 * COUNTIF(PLANNING_PRODUCT_GROUPING IS NULL OR PLANNING_PRODUCT_GROUPING IN ('', '\\N')) / COUNT(*), 1) AS planning_product_grouping_missing_pct,
  ROUND(100.0 * COUNTIF(FABRIC_FAMILY IS NULL OR FABRIC_FAMILY IN ('', '\\N')) / COUNT(*), 1) AS fabric_family_missing_pct,
  ROUND(100.0 * COUNTIF(INSEAM IS NULL OR INSEAM IN ('', '\\N')) / COUNT(*), 1) AS inseam_missing_pct,
  ROUND(100.0 * COUNTIF(ACTIVITY IS NULL OR ACTIVITY IN ('', '\\N')) / COUNT(*), 1) AS activity_col_missing_pct,
  ROUND(100.0 * COUNTIF(FIT_CLASSIFICATION IS NULL OR FIT_CLASSIFICATION IN ('', '\\N')) / COUNT(*), 1) AS fit_classification_missing_pct
FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`;

-- Q3: What is on product_intermediate vs GSM product_master today?
SELECT 'product_intermediate' AS layer, column_name
FROM `lululemon-01042025.lulu_sourcing_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'product_intermediate'
  AND column_name IN (
    'gender','silhouette','flex_status','planning_product_grouping','global_merch_team',
    'fit_classification','design_line','designed_for_activity','product_line','size_scale',
    'product_development_pod','product_size_definition','global_line_segment_style_category'
  )
UNION ALL
SELECT 'gsm_product_master', column_name
FROM `lululemon-01042025.lulu_ingestion_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'product_master'
  AND column_name IN (
    'gender','silhouette','flex_status','planning_product_grouping','global_merch_team',
    'fit_classification','design_line','designed_for_activity','product_line','size_scale',
    'product_development_pod','product_size_definition','global_line_segment_style_category'
  )
ORDER BY layer, column_name;

-- Q4: Top values for well-populated explainability candidates
SELECT 'DESIGNED_FOR_ACTIVITY' AS attr, DESIGNED_FOR_ACTIVITY AS value, COUNT(*) AS style_cnt
FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
WHERE DESIGNED_FOR_ACTIVITY IS NOT NULL AND DESIGNED_FOR_ACTIVITY NOT IN ('', '\\N')
GROUP BY value ORDER BY style_cnt DESC LIMIT 10;

SELECT 'GLOBAL_MERCH_TEAM' AS attr, GLOBAL_MERCH_TEAM AS value, COUNT(*) AS style_cnt
FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
WHERE GLOBAL_MERCH_TEAM IS NOT NULL AND GLOBAL_MERCH_TEAM NOT IN ('', '\\N')
GROUP BY value ORDER BY style_cnt DESC LIMIT 10;


-- =============================================================================
-- PM-10: STYLE_ID (product_attribute_s) vs PGH STYLE.VALUE_CODE alignment
-- Build join: PGH STYLE_CODE = product_attribute_s.STYLE_ID (= GSM l7_id)
-- =============================================================================

-- Q1: Distinct counts
WITH pgh_style AS (
  SELECT DISTINCT VALUE_CODE AS style_code, VALUE_NAME AS style_name
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
pa AS (
  SELECT DISTINCT STYLE_ID FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
)
SELECT
  (SELECT COUNT(*) FROM pgh_style) AS pgh_distinct_style_codes,
  (SELECT COUNT(DISTINCT style_name) FROM pgh_style) AS pgh_distinct_style_names,
  (SELECT COUNT(*) FROM pa) AS pa_distinct_style_ids,
  (SELECT COUNT(*) FROM pgh_style p JOIN pa a ON p.style_code = a.STYLE_ID) AS codes_in_both,
  (SELECT COUNT(*) FROM pgh_style p LEFT JOIN pa a ON p.style_code = a.STYLE_ID WHERE a.STYLE_ID IS NULL) AS pgh_not_in_pa,
  (SELECT COUNT(*) FROM pa a LEFT JOIN pgh_style p ON a.STYLE_ID = p.style_code WHERE p.style_code IS NULL) AS pa_not_in_pgh;

-- Q2: SKU-level join coverage (PGH SKU -> STYLE code -> PA)
WITH sku_style AS (
  SELECT DISTINCT SKU_ID, VALUE_CODE AS style_code
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
pa AS (
  SELECT STYLE_ID FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
)
SELECT
  COUNT(DISTINCT s.SKU_ID) AS pgh_skus,
  COUNTIF(p.STYLE_ID IS NOT NULL) AS skus_with_pa_match,
  ROUND(100.0 * COUNTIF(p.STYLE_ID IS NOT NULL) / COUNT(DISTINCT s.SKU_ID), 2) AS pct_matched
FROM sku_style s
LEFT JOIN pa p ON s.style_code = p.STYLE_ID;

-- Q3: GSM l7_id should equal PGH STYLE code count
SELECT COUNT(DISTINCT l7_id) AS pm_distinct_l7_ids
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`;

-- Q4: PA-only styles (in product_attribute_s, not in current PGH STYLE level)
WITH pgh_codes AS (
  SELECT DISTINCT VALUE_CODE AS style_code
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
pa_only AS (
  SELECT pa.STYLE_ID, pa.FLEX_STATUS
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119` pa
  LEFT JOIN pgh_codes p ON pa.STYLE_ID = p.style_code
  WHERE p.style_code IS NULL
)
SELECT
  COUNT(*) AS pa_only_styles,
  COUNTIF(FLEX_STATUS = 'Drop') AS drop_styles,
  COUNTIF(FLEX_STATUS = 'Active') AS active_styles,
  COUNTIF(FLEX_STATUS IS NULL OR FLEX_STATUS IN ('', '\\N')) AS flex_null
FROM pa_only;

-- Q5: PGH style code -> name cardinality (expect 1:1)
SELECT
  COUNT(*) AS style_codes,
  COUNTIF(distinct_names = 1) AS one_name_per_code,
  COUNTIF(distinct_names > 1) AS multi_name_codes
FROM (
  SELECT VALUE_CODE, COUNT(DISTINCT VALUE_NAME) AS distinct_names
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
  GROUP BY VALUE_CODE
);


-- #############################################################################
-- PART C — POST-EXTRACTION DAG DIAGNOSTICS
-- #############################################################################

-- =============================================================================
-- 1) Checkpoint vs table metadata (quick gate)
-- =============================================================================
SELECT
  v.table,
  v.view,
  CAST(v.filter_param AS STRING) AS filter_param_after_run,
  CAST(v.extraction_sync_dt AS STRING) AS extraction_sync_dt,
  t.row_count,
  TIMESTAMP_MILLIS(t.last_modified_time) AS table_last_modified
FROM `lululemon-01042025.lulu_sourcing_dev.view_mapping_table` v
LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.__TABLES__` t
  ON v.view = t.table_id
WHERE v.is_deleted = FALSE
ORDER BY v.table, v.view;

-- =============================================================================
-- 2) Per-feed: total rows, max sync, distinct sync timestamps
--    (single sync value = one GCS drop loaded; no newer drop yet)
-- =============================================================================
SELECT
  'product_group_hierarchy' AS raw_table,
  COUNT(*) AS row_count,
  MAX(SYNCSTARTDATETIME) AS max_sync,
  COUNT(DISTINCT SYNCSTARTDATETIME) AS distinct_sync_ts
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
UNION ALL
SELECT 'sku_details', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
UNION ALL
SELECT 'product_attribute_s', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
UNION ALL
SELECT 'location_details', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
UNION ALL
SELECT 'location_group_hierarchy', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`;

-- Large tables — run separately with higher bytes cap if needed:
-- sales_transactions (~683M rows), inventory_snapshot (~404M rows)

-- =============================================================================
-- 3) Rows loaded AFTER a checkpoint (replace @checkpoint with pre-run filter_param)
-- =============================================================================
-- DECLARE checkpoint DATETIME DEFAULT DATETIME('2026-05-19 09:21:05');
-- SELECT COUNT(*) AS incremental_rows, MAX(SYNCSTARTDATETIME) AS max_sync
-- FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
-- WHERE SYNCSTARTDATETIME > checkpoint;

-- =============================================================================
-- 4) Append duplicate smell (same id + same sync timestamp twice)
-- =============================================================================
-- SELECT ID, SYNCSTARTDATETIME, COUNT(*) AS c
-- FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
-- GROUP BY 1, 2 HAVING COUNT(*) > 1
-- ORDER BY c DESC LIMIT 20;
