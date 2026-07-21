-- =============================================================================
-- Raw GCS open questions — reference SQL (one section per workshop bullet)
--
-- **PGH + product open questions (combined):**
--   product_group_hierarchy_open_questions.sql
--
-- **All 7 tables (full walkthrough):**
--   lululemon_raw_open_questions_combined.sql
--
-- Project: lululemon-01042025 | Dataset: lulu_sourcing_dev
-- Companion: findings/raw_sourcing_dev_7_table_eda_summary.md
-- Run sections individually in BigQuery console.
-- =============================================================================

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
