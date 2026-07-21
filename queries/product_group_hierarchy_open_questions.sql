-- =============================================================================
-- product_group_hierarchy — client open questions (combined SQL)
--
-- Table: `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
-- GCS:   product_group_hierarchy_*.csv
--
-- Workshop bullets + related PM rechecks (PM-3, PM-5, PM-6 Q1, PM-10, PM-14).
-- Run one section at a time in BigQuery console.
-- Last updated: 2026-06-23
--
-- INDEX
--   Q1  ~2x EAV row duplication (expected 9 rows/SKU, seeing ~18)
--   Q2  SKUs lacking PLANNING_STYLE_SIZE
--   Q3  PGH SKU universe vs product_intermediate / product_master
--   Q4  PSS / forecast product grain (PGH levels + GSM l8_name)
--   Q5  Short article codes (<=3 chars)
--   Q6  Never-sold SKUs at PGH catalog grain (PM-6)
--   Q7  STYLE level vs product_attribute_s STYLE_ID (PM-10)
--   Q8  BRAND values — third brand expected? (PM-14)
--   Q9  Extraction sync batch (row count / SYNCSTARTDATETIME)
-- =============================================================================


-- =============================================================================
-- Q1: ~2x EAV duplication
-- Client ask: Why ~2x duplication? Append-only load without dedup?
-- Verified 2026-06-23: avg 18.46 rows/SKU; 662,081 SKUs with 18 rows; 0 with 9;
--   8,447,243 (SKU,LEVEL) pairs at 2x; 0 conflicting values (identical appends)
-- =============================================================================

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

-- Sample one 18-row SKU (inspect byte-identical dupes)
SELECT *
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE SKU_ID = (
  SELECT SKU_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID HAVING COUNT(*) = 18 LIMIT 1
)
ORDER BY LEVEL_NUMBER, LEVEL_NAME;

-- Dup pairs with conflicting values (expect 0)
SELECT COUNT(*) AS pairs_with_conflicting_values
FROM (
  SELECT SKU_ID, LEVEL_NAME, COUNT(DISTINCT CONCAT(VALUE_CODE, '|', VALUE_NAME)) AS distinct_values
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID, LEVEL_NAME
  HAVING COUNT(*) > 1
)
WHERE distinct_values > 1;


-- =============================================================================
-- Q2: SKUs lacking PLANNING_STYLE_SIZE
-- Client ask: Placeholders or unreleased SKUs? product_name gap in master?
-- Verified 2026-06-23: 0 SKUs missing PSS level row; check empty VALUE_NAME below
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

-- PSS VALUE_NAME empty/sentinel (drives product_name nulls in build)
SELECT COUNT(DISTINCT SKU_ID) AS skus_pss_empty_name
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE'
  AND (NULLIF(TRIM(VALUE_NAME), '') IS NULL OR VALUE_NAME IN ('\\N', '\\\\N'));


-- =============================================================================
-- Q3: PGH SKU universe vs product_intermediate / product_master
-- Client ask: Intentional filter or join loss? (historically ~33%; verify current)
-- Verified 2026-06-23: PI = PM = 1,977,528 (~989K SKUs x 2 channels); 0 PGH-only
-- =============================================================================

SELECT
  (SELECT COUNT(DISTINCT SKU_ID) FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`) AS pgh_distinct_skus,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`) AS product_intermediate_rows,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`) AS product_master_rows,
  (SELECT COUNT(DISTINCT product_code_original) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`) AS pm_distinct_skus;

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
-- Q4: PSS / forecast product grain
-- Client ask: Which PGH level is canonical for PSS x store x week forecast?
-- =============================================================================

-- PGH: cardinality by hierarchy level (EAV)
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

-- PGH: median SKUs per PLANNING_STYLE_SIZE name
SELECT APPROX_QUANTILES(sku_cnt, 4)[OFFSET(2)] AS median_skus_per_pss_name
FROM (
  SELECT VALUE_NAME, COUNT(DISTINCT SKU_ID) AS sku_cnt
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_SIZE'
  GROUP BY VALUE_NAME
);

-- GSM product_master: grains after PGH pivot + channel expand (PM-3)
SELECT
  COUNT(DISTINCT product_code) AS sku_x_channel_rows,
  COUNT(DISTINCT product_code_original) AS channel_agnostic_skus,
  COUNT(DISTINCT l8_name) AS distinct_planning_style_size_names,
  COUNT(DISTINCT CONCAT(l8_name, '|', l1_name)) AS planning_style_size_x_channel
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`;

SELECT APPROX_QUANTILES(sku_cnt, 4)[OFFSET(2)] AS median_skus_per_pss_channel
FROM (
  SELECT l8_name, l1_name AS channel, COUNT(DISTINCT product_code_original) AS sku_cnt
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
  GROUP BY l8_name, l1_name
);


-- =============================================================================
-- Q5: Short article codes (<=3 chars)
-- Client ask: What do HX, MV, NK etc. represent? Exclude from forecast?
-- =============================================================================

-- PGH source: PLANNING_STYLE_OPTION short base
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

-- GSM product_master: LENGTH(article_original) <= 3 (PM-5)
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

-- Placeholder SKUs with sales (do not auto-exclude)
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
-- Q6: Never-sold catalog at PGH SKU grain (PM-6 Q1)
-- Client ask: Forecast universe rule for zero-history SKUs (~26% at raw grain)
-- =============================================================================

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


-- =============================================================================
-- Q7: PGH STYLE.VALUE_CODE vs product_attribute_s.STYLE_ID (PM-10)
-- Client ask: Canonical style key; PA-only styles not in PGH?
-- =============================================================================

WITH pgh_style AS (
  SELECT DISTINCT VALUE_CODE AS style_code, VALUE_NAME AS style_name
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
pa AS (
  SELECT DISTINCT STYLE_ID
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
)
SELECT
  (SELECT COUNT(*) FROM pgh_style) AS pgh_distinct_style_codes,
  (SELECT COUNT(DISTINCT style_name) FROM pgh_style) AS pgh_distinct_style_names,
  (SELECT COUNT(*) FROM pa) AS pa_distinct_style_ids,
  (SELECT COUNT(*) FROM pgh_style p JOIN pa a ON p.style_code = a.STYLE_ID) AS codes_in_both,
  (SELECT COUNT(*) FROM pgh_style p LEFT JOIN pa a ON p.style_code = a.STYLE_ID WHERE a.STYLE_ID IS NULL) AS pgh_not_in_pa,
  (SELECT COUNT(*) FROM pa a LEFT JOIN pgh_style p ON a.STYLE_ID = p.style_code WHERE p.style_code IS NULL) AS pa_not_in_pgh;

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

SELECT COUNT(DISTINCT l7_id) AS pm_distinct_l7_ids
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`;

-- PA-only styles (not in PGH STYLE level)
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

-- STYLE code -> name cardinality (expect 1:1)
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


-- =============================================================================
-- Q8: BRAND values (PM-14)
-- Client ask: Third brand beyond lululemon / ivivva?
-- =============================================================================

SELECT VALUE_NAME, VALUE_CODE, COUNT(DISTINCT SKU_ID) AS distinct_skus
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
WHERE LEVEL_NAME = 'BRAND'
GROUP BY VALUE_NAME, VALUE_CODE
ORDER BY distinct_skus DESC;


-- =============================================================================
-- Q9: Extraction load fingerprint
-- =============================================================================

SELECT
  COUNT(*) AS row_count,
  MAX(SYNCSTARTDATETIME) AS max_sync,
  COUNT(DISTINCT SYNCSTARTDATETIME) AS distinct_sync_batches
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`;
