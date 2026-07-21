-- =============================================================================
-- Lululemon Client Open Questions — SQL reference (single file)
--
-- **Combined file (Part A + this file + diagnostics):**
--   lululemon_raw_open_questions_combined.sql
--
-- Sections follow deliverable order: Product Master #1-18, then other masters
-- as rechecked. Run individual sections in BigQuery console.
--
-- Project: lululemon-01042025
-- GSM:     lulu_ingestion_dev.*
-- Sourcing: lulu_sourcing_dev.*
-- =============================================================================

-- INDEX
--   PM-1  sku_details pricing (cost / sell / currency)
--   PM-2  season_code single-season vs GCS drops
--   PM-3  PSS grain vs SKU-level sales
--   PM-4  flex_status Drop / Active universe
--   PM-5  placeholder short article codes
--   PM-6  never-sold catalog SKUs (grain-dependent)
--   PM-7  product_attribute_s 3 rows per STYLE_ID (dedup)
--   PM-8  article_status stub vs FLEX_STATUS source
--   PM-9  forecasting / explainability attribute shortlist
--   PM-10 style id vs PGH STYLE code alignment
--   (PM-11+ added as questions are rechecked in order)


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

