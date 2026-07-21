-- ForecastSmart Req 11 / 13 / 14 EDA (read-only)
-- Billing project: lululemon-data-scan
-- Tables: planned_sales, product_attribute_s_seasonal, product_attribute_so_seasonal, eligibility
-- Run sections independently in BigQuery Console.

-- =============================================================================
-- 0) Foundation: row counts, sync batches, schema
-- =============================================================================
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / 1e9, 3) AS size_gb
FROM `lululemon-01042025.lulu_sourcing_dev.__TABLES__`
WHERE table_id IN (
  'planned_sales',
  'product_attribute_s_seasonal',
  'product_attribute_so_seasonal',
  'eligibility'
)
ORDER BY table_id;

SELECT table_name, column_name, data_type, ordinal_position
FROM `lululemon-01042025.lulu_sourcing_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN (
  'planned_sales',
  'product_attribute_s_seasonal',
  'product_attribute_so_seasonal',
  'eligibility'
)
ORDER BY table_name, ordinal_position;

SELECT 'planned_sales' AS tbl, COUNT(*) AS row_count,
  COUNT(DISTINCT SYNCSTARTDATETIME) AS sync_batches,
  CAST(MAX(SYNCSTARTDATETIME) AS STRING) AS max_sync
FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`
UNION ALL
SELECT 'product_attribute_s_seasonal', COUNT(*), COUNT(DISTINCT SYNCSTARTDATETIME), CAST(MAX(SYNCSTARTDATETIME) AS STRING)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
UNION ALL
SELECT 'product_attribute_so_seasonal', COUNT(*), COUNT(DISTINCT SYNCSTARTDATETIME), CAST(MAX(SYNCSTARTDATETIME) AS STRING)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so_seasonal`
UNION ALL
SELECT 'eligibility', COUNT(*), COUNT(DISTINCT SYNCSTARTDATETIME), CAST(MAX(SYNCSTARTDATETIME) AS STRING)
FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`;

-- =============================================================================
-- 1) planned_sales (Req 11)
-- =============================================================================
-- Grain
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT CONCAT(STYLE_OPTION_ID, '|', STORE_ID, '|', WEEK_ID)) AS distinct_so_store_week,
  COUNT(*) - COUNT(DISTINCT CONCAT(STYLE_OPTION_ID, '|', STORE_ID, '|', WEEK_ID)) AS duplicate_rows,
  COUNT(DISTINCT STYLE_OPTION_ID) AS distinct_style_options,
  COUNT(DISTINCT STORE_ID) AS distinct_stores,
  COUNT(DISTINCT WEEK_ID) AS distinct_weeks,
  MIN(WEEK_ID) AS min_week,
  MAX(WEEK_ID) AS max_week,
  MIN(PLAN_QUARTER_ID) AS min_quarter,
  MAX(PLAN_QUARTER_ID) AS max_quarter
FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`;

-- Numerical: WP_TOT_REG_SLS_U, WP_BOP_U
SELECT
  COUNTIF(SAFE_CAST(WP_TOT_REG_SLS_U AS FLOAT64) = 0) AS units_zero,
  COUNTIF(SAFE_CAST(WP_TOT_REG_SLS_U AS FLOAT64) > 0) AS units_positive,
  COUNTIF(SAFE_CAST(WP_TOT_REG_SLS_U AS FLOAT64) < 0) AS units_negative,
  ROUND(AVG(SAFE_CAST(WP_TOT_REG_SLS_U AS FLOAT64)), 4) AS units_avg,
  APPROX_QUANTILES(SAFE_CAST(WP_TOT_REG_SLS_U AS FLOAT64), 100)[OFFSET(50)] AS units_p50,
  APPROX_QUANTILES(SAFE_CAST(WP_TOT_REG_SLS_U AS FLOAT64), 100)[OFFSET(95)] AS units_p95,
  MAX(SAFE_CAST(WP_TOT_REG_SLS_U AS FLOAT64)) AS units_max,
  COUNTIF(SAFE_CAST(WP_BOP_U AS FLOAT64) = 0) AS bop_zero,
  COUNTIF(SAFE_CAST(WP_BOP_U AS FLOAT64) > 0) AS bop_positive,
  ROUND(AVG(SAFE_CAST(WP_BOP_U AS FLOAT64)), 4) AS bop_avg
FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`;

-- Completeness
SELECT
  'SIZE_RANGE' AS col,
  COUNTIF(SIZE_RANGE IS NULL OR TRIM(SIZE_RANGE) IN ('', '\\N')) AS missing,
  COUNT(*) AS total
FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`;

-- Categorical top values
SELECT SUB_MARKET_CHANNEL_ID, COUNT(*) AS n
FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`
GROUP BY 1 ORDER BY n DESC LIMIT 10;

SELECT SIZE_RANGE, COUNT(*) AS n
FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`
GROUP BY 1 ORDER BY n DESC LIMIT 10;

-- Future horizon (adjust week threshold to current fiscal week)
SELECT
  COUNTIF(CAST(WEEK_ID AS INT64) > 202626) AS rows_after_wk202626,
  ROUND(100 * COUNTIF(CAST(WEEK_ID AS INT64) > 202626) / COUNT(*), 2) AS pct_after_wk202626
FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`;

-- Join coverage
WITH ps AS (SELECT DISTINCT STYLE_OPTION_ID FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`),
so AS (SELECT DISTINCT STYLE_OPTION_ID FROM `lululemon-01042025.lulu_sourcing_dev.style_option`),
stores AS (SELECT DISTINCT CAST(ID AS STRING) AS store_id FROM `lululemon-01042025.lulu_sourcing_dev.location_details`)
SELECT
  (SELECT COUNT(*) FROM ps) AS ps_style_options,
  (SELECT COUNT(*) FROM ps p JOIN so s USING (STYLE_OPTION_ID)) AS ps_in_style_option,
  (SELECT COUNT(DISTINCT p.STORE_ID) FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales` p
   JOIN stores s ON p.STORE_ID = s.store_id) AS ps_stores_matched,
  (SELECT COUNT(DISTINCT STORE_ID) FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`) AS ps_stores_total;

-- =============================================================================
-- 2) product_attribute_s_seasonal + product_attribute_so_seasonal (Req 13)
-- =============================================================================
SELECT 's_seasonal' AS tbl, COUNT(*) AS total_rows,
  COUNT(DISTINCT CONCAT(STYLE_ID, '|', QUARTER_ID)) AS distinct_grain,
  COUNT(DISTINCT STYLE_ID) AS distinct_keys,
  MIN(QUARTER_ID) AS min_quarter, MAX(QUARTER_ID) AS max_quarter
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
UNION ALL
SELECT 'so_seasonal', COUNT(*),
  COUNT(DISTINCT CONCAT(STYLE_OPTION_ID, '|', QUARTER_ID)),
  COUNT(DISTINCT STYLE_OPTION_ID),
  MIN(QUARTER_ID), MAX(QUARTER_ID)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so_seasonal`;

-- Completeness (key attrs)
SELECT 's_seasonal' AS tbl, 'FLEX_STATUS' AS col,
  COUNTIF(FLEX_STATUS IS NULL OR TRIM(FLEX_STATUS) IN ('', '\\N')) AS missing, COUNT(*) AS total
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
UNION ALL
SELECT 's_seasonal', 'SEASONAL_STYLE_TYPE',
  COUNTIF(SEASONAL_STYLE_TYPE IS NULL OR TRIM(SEASONAL_STYLE_TYPE) IN ('', '\\N')), COUNT(*)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
UNION ALL
SELECT 'so_seasonal', 'FLEX_STATUS',
  COUNTIF(FLEX_STATUS IS NULL OR TRIM(FLEX_STATUS) IN ('', '\\N')), COUNT(*)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so_seasonal`
UNION ALL
SELECT 'so_seasonal', 'SEASONAL_COLOURWAY_TYPE',
  COUNTIF(SEASONAL_COLOURWAY_TYPE IS NULL OR TRIM(SEASONAL_COLOURWAY_TYPE) IN ('', '\\N')), COUNT(*)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so_seasonal`;

-- Categorical distributions
SELECT FLEX_STATUS, COUNT(*) AS n
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
GROUP BY 1 ORDER BY n DESC LIMIT 10;

SELECT FLEX_STATUS, COUNT(*) AS n
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so_seasonal`
GROUP BY 1 ORDER BY n DESC LIMIT 10;

-- Calendar quarter coverage
WITH cal AS (
  SELECT DISTINCT CAST(QUARTER_ID AS STRING) AS QUARTER_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
)
SELECT
  (SELECT COUNT(DISTINCT QUARTER_ID) FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`) AS s_quarters,
  (SELECT COUNT(DISTINCT a.QUARTER_ID) FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal` a
   JOIN cal c USING (QUARTER_ID)) AS s_quarters_in_calendar;

-- Style / style-option join paths
WITH s AS (SELECT DISTINCT STYLE_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`),
so AS (SELECT DISTINCT STYLE_ID FROM `lululemon-01042025.lulu_sourcing_dev.style_option`)
SELECT
  (SELECT COUNT(*) FROM s) AS seasonal_styles,
  (SELECT COUNT(*) FROM s JOIN so USING (STYLE_ID)) AS styles_in_style_option;

WITH so_feed AS (
  SELECT DISTINCT STYLE_OPTION_ID FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so_seasonal`
)
SELECT COUNT(*) AS so_distinct,
  (SELECT COUNT(*) FROM so_feed f JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` m USING (STYLE_OPTION_ID)) AS so_in_style_option
FROM so_feed;

-- =============================================================================
-- 3) eligibility (Req 14)
-- =============================================================================
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT CONCAT(PLANNING_STYLE_OPTION_ID, '|', STORE_ID, '|', WEEK_ID)) AS distinct_grain,
  COUNT(*) - COUNT(DISTINCT CONCAT(PLANNING_STYLE_OPTION_ID, '|', STORE_ID, '|', WEEK_ID)) AS duplicate_rows,
  APPROX_COUNT_DISTINCT(PLANNING_STYLE_OPTION_ID) AS distinct_pso,
  APPROX_COUNT_DISTINCT(STORE_ID) AS distinct_stores,
  APPROX_COUNT_DISTINCT(WEEK_ID) AS distinct_weeks,
  MIN(WEEK_ID) AS min_week, MAX(WEEK_ID) AS max_week,
  MIN(WP_FIRST_SELLING_DAY_ID) AS min_first_sell_day,
  MAX(WP_FIRST_SELLING_DAY_ID) AS max_first_sell_day,
  COUNTIF(PARSE_DATE('%Y-%m-%d', WP_FIRST_SELLING_DAY_ID) > CURRENT_DATE()) AS future_first_sell_rows
FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`;

-- Duplicate groups with conflicting attributes
WITH g AS (
  SELECT
    PLANNING_STYLE_OPTION_ID, STORE_ID, WEEK_ID,
    COUNT(*) AS c,
    COUNT(DISTINCT WP_WEEKS_AT_REG_PRICE) AS distinct_reg_weeks,
    COUNT(DISTINCT WP_FIRST_SELLING_DAY_ID) AS distinct_first_days
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  GROUP BY 1, 2, 3
)
SELECT
  SUM(c - 1) AS extra_rows,
  ROUND(100 * SUM(c - 1) / SUM(c), 2) AS extra_row_pct,
  COUNTIF(c > 1 AND distinct_reg_weeks > 1) AS groups_conflicting_reg_weeks,
  COUNTIF(c > 1 AND distinct_first_days > 1) AS groups_conflicting_first_days
FROM g;

SELECT WP_WEEKS_AT_REG_PRICE, COUNT(*) AS n
FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
GROUP BY 1 ORDER BY n DESC LIMIT 10;

-- style_option + store join coverage
SELECT
  COUNT(*) AS elig_rows_matched_style_option,
  ROUND(100 * COUNT(*) / 241782410, 2) AS pct_of_total
FROM `lululemon-01042025.lulu_sourcing_dev.eligibility` e
WHERE EXISTS (
  SELECT 1 FROM `lululemon-01042025.lulu_sourcing_dev.style_option` so
  WHERE so.PLANNING_STYLE_OPTION_ID = e.PLANNING_STYLE_OPTION_ID
);

WITH stores AS (SELECT DISTINCT CAST(ID AS STRING) AS store_id FROM `lululemon-01042025.lulu_sourcing_dev.location_details`)
SELECT
  COUNT(DISTINCT e.STORE_ID) AS elig_stores,
  COUNT(DISTINCT s.store_id) AS elig_stores_matched
FROM `lululemon-01042025.lulu_sourcing_dev.eligibility` e
JOIN stores s ON e.STORE_ID = s.store_id;

-- -----------------------------------------------------------------------------
-- PSO + store coverage summary (bidirectional distinct counts)
-- Verified 2026-07-02 on sync batch 2026-06-25
-- Sources: lulu_sourcing_dev.* (or outbound *_20251119 if raw tables empty)
--
-- | Comparison                      | Left    | Right   | Overlap | % left in right | % right in left |
-- |---------------------------------|---------|---------|---------|-----------------|-----------------|
-- | PGH → style_option              | 149,089 | 466,026 | 149,089 | 100%            | 31.99%          |
-- | PGH → eligibility               | 149,089 |  67,712 |  66,128 | 44.35%          | 97.66%          |
-- | style_option → eligibility      | 466,026 |  67,712 |  66,140 | 14.19%          | 97.68%          |
-- | eligibility → location_details  |   1,194 |   1,853 |   1,084 | 90.79%          | 58.50%          |
-- | planned_sales → eligibility     |   1,045 |   1,194 |     943 | 90.24%          | 78.98%          |
-- | planned_sales → location_details|   1,045 |   1,853 |   1,045 | 100%            | 56.40%          |
--
-- Store master stack (location_details, location_group_hierarchy, store_intermediate,
-- outbound store_master) is 1:1 on 1,853 IDs; eligibility → any of them = same row.
-- Join: TRIM(CAST(STORE_ID AS STRING)) = TRIM(location_details.ID)
-- -----------------------------------------------------------------------------

-- PSO coverage: PGH (original raw) + style_option vs eligibility

-- A) PGH PSO codes -> eligibility (catalog PSO universe from original raw stack)
WITH pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS planning_style_option_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND VALUE_CODE IS NOT NULL
    AND TRIM(VALUE_CODE) != ''
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE PLANNING_STYLE_OPTION_ID IS NOT NULL
    AND TRIM(PLANNING_STYLE_OPTION_ID) != ''
),
matched AS (
  SELECT p.planning_style_option_id
  FROM pgh_pso p
  INNER JOIN elig_pso e USING (PLANNING_STYLE_OPTION_ID)
)
SELECT
  (SELECT COUNT(*) FROM pgh_pso) AS pgh_distinct_pso,
  (SELECT COUNT(*) FROM elig_pso) AS eligibility_distinct_pso,
  (SELECT COUNT(*) FROM matched) AS pso_in_both,
  ROUND(100 * (SELECT COUNT(*) FROM matched) / (SELECT COUNT(*) FROM pgh_pso), 2)
    AS pct_pgh_pso_in_eligibility,
  ROUND(100 * (
    (SELECT COUNT(*) FROM pgh_pso) - (SELECT COUNT(*) FROM matched)
  ) / (SELECT COUNT(*) FROM pgh_pso), 2) AS pct_pgh_pso_not_in_eligibility;

-- B) PGH SKU-level: share of catalog SKUs whose PSO appears in eligibility
WITH pgh_sku_pso AS (
  SELECT DISTINCT SKU_ID, VALUE_CODE AS planning_style_option_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND VALUE_CODE IS NOT NULL
    AND TRIM(VALUE_CODE) != ''
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
),
matched_skus AS (
  SELECT DISTINCT p.SKU_ID
  FROM pgh_sku_pso p
  INNER JOIN elig_pso e
    ON p.planning_style_option_id = e.PLANNING_STYLE_OPTION_ID
)
SELECT
  (SELECT COUNT(DISTINCT SKU_ID) FROM pgh_sku_pso) AS pgh_distinct_skus,
  (SELECT COUNT(*) FROM matched_skus) AS skus_with_eligible_pso,
  ROUND(100 * (SELECT COUNT(*) FROM matched_skus)
    / (SELECT COUNT(DISTINCT SKU_ID) FROM pgh_sku_pso), 2)
    AS pct_skus_with_eligible_pso,
  (SELECT COUNT(DISTINCT SKU_ID) FROM pgh_sku_pso) -
  (SELECT COUNT(*) FROM matched_skus) AS skus_without_eligible_pso;

-- C) Three-way PSO alignment: PGH vs style_option vs eligibility
WITH pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS planning_style_option_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND VALUE_CODE IS NOT NULL AND TRIM(VALUE_CODE) != ''
),
style_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE PLANNING_STYLE_OPTION_ID IS NOT NULL AND TRIM(PLANNING_STYLE_OPTION_ID) != ''
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE PLANNING_STYLE_OPTION_ID IS NOT NULL AND TRIM(PLANNING_STYLE_OPTION_ID) != ''
)
SELECT
  'pgh_vs_style_option' AS comparison,
  (SELECT COUNT(*) FROM pgh_pso) AS left_distinct,
  (SELECT COUNT(*) FROM style_pso) AS right_distinct,
  (SELECT COUNT(*) FROM pgh_pso p INNER JOIN style_pso s USING (planning_style_option_id)) AS in_both,
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN style_pso s USING (planning_style_option_id))
    / (SELECT COUNT(*) FROM pgh_pso), 2) AS pct_left_in_right,
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN style_pso s USING (planning_style_option_id))
    / (SELECT COUNT(*) FROM style_pso), 2) AS pct_right_in_left
UNION ALL
SELECT
  'style_option_vs_eligibility',
  (SELECT COUNT(*) FROM style_pso),
  (SELECT COUNT(*) FROM elig_pso),
  (SELECT COUNT(*) FROM style_pso s INNER JOIN elig_pso e USING (PLANNING_STYLE_OPTION_ID)),
  ROUND(100 * (SELECT COUNT(*) FROM style_pso s INNER JOIN elig_pso e USING (PLANNING_STYLE_OPTION_ID))
    / (SELECT COUNT(*) FROM style_pso), 2),
  ROUND(100 * (SELECT COUNT(*) FROM style_pso s INNER JOIN elig_pso e USING (PLANNING_STYLE_OPTION_ID))
    / (SELECT COUNT(*) FROM elig_pso), 2)
UNION ALL
SELECT
  'pgh_vs_eligibility',
  (SELECT COUNT(*) FROM pgh_pso),
  (SELECT COUNT(*) FROM elig_pso),
  (SELECT COUNT(*) FROM pgh_pso p INNER JOIN elig_pso e ON p.planning_style_option_id = e.PLANNING_STYLE_OPTION_ID),
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN elig_pso e ON p.planning_style_option_id = e.PLANNING_STYLE_OPTION_ID)
    / (SELECT COUNT(*) FROM pgh_pso), 2),
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN elig_pso e ON p.planning_style_option_id = e.PLANNING_STYLE_OPTION_ID)
    / (SELECT COUNT(*) FROM elig_pso), 2);

-- D) Unmatched PSO counts (reverse directions)
WITH pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION' AND TRIM(VALUE_CODE) != ''
),
style_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) != ''
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) != ''
)
SELECT
  (SELECT COUNT(*) FROM elig_pso e LEFT JOIN pgh_pso p ON e.pso = p.pso WHERE p.pso IS NULL) AS elig_pso_not_in_pgh,
  (SELECT COUNT(*) FROM elig_pso e LEFT JOIN style_pso s ON e.pso = s.pso WHERE s.pso IS NULL) AS elig_pso_not_in_style_option,
  (SELECT COUNT(*) FROM style_pso s LEFT JOIN pgh_pso p ON s.pso = p.pso WHERE p.pso IS NULL) AS style_pso_not_in_pgh,
  (SELECT COUNT(*) FROM pgh_pso p LEFT JOIN elig_pso e ON p.pso = e.pso WHERE e.pso IS NULL) AS pgh_pso_not_in_eligibility;

-- -----------------------------------------------------------------------------
-- Store coverage: eligibility vs location / store master stack (bidirectional)
-- Verified 2026-07-02 on sync batch 2026-06-25 (241,782,410 rows)
-- Join key: TRIM(CAST(STORE_ID AS STRING)) = TRIM(location_details.ID) — no LPAD needed
-- Note: if lulu_sourcing_dev.eligibility is empty, swap to
--   lululemon_souricng_outbound.eligibility_20251119 (same row count as Jun 25 GCS drop)
-- -----------------------------------------------------------------------------

-- E) Bidirectional store coverage across all store master tables (same 1,853 spine)
WITH elig_stores AS (
  SELECT DISTINCT TRIM(CAST(STORE_ID AS STRING)) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE STORE_ID IS NOT NULL
),
loc_details AS (
  SELECT DISTINCT TRIM(ID) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
),
loc_hier AS (
  SELECT DISTINCT TRIM(LOC_ID) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
),
store_int AS (
  SELECT DISTINCT TRIM(LTRIM(store_code, '0')) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.store_intermediate`
  WHERE TRIM(LTRIM(store_code, '0')) != ''
),
outbound_sm AS (
  SELECT DISTINCT TRIM(LTRIM(store_code, '0')) AS store_id
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  WHERE TRIM(LTRIM(store_code, '0')) != ''
)
SELECT
  'eligibility -> location_details' AS comparison,
  (SELECT COUNT(*) FROM elig_stores) AS elig_distinct,
  (SELECT COUNT(*) FROM loc_details) AS master_distinct,
  (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_details l ON e.store_id = l.store_id) AS in_both,
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_details l ON e.store_id = l.store_id)
    / (SELECT COUNT(*) FROM elig_stores), 2) AS pct_elig_in_master,
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_details l ON e.store_id = l.store_id)
    / (SELECT COUNT(*) FROM loc_details), 2) AS pct_master_in_elig
UNION ALL
SELECT
  'eligibility -> location_group_hierarchy',
  (SELECT COUNT(*) FROM elig_stores),
  (SELECT COUNT(*) FROM loc_hier),
  (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_hier l ON e.store_id = l.store_id),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_hier l ON e.store_id = l.store_id)
    / (SELECT COUNT(*) FROM elig_stores), 2),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_hier l ON e.store_id = l.store_id)
    / (SELECT COUNT(*) FROM loc_hier), 2)
UNION ALL
SELECT
  'eligibility -> store_intermediate',
  (SELECT COUNT(*) FROM elig_stores),
  (SELECT COUNT(*) FROM store_int),
  (SELECT COUNT(*) FROM elig_stores e INNER JOIN store_int s ON e.store_id = s.store_id),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN store_int s ON e.store_id = s.store_id)
    / (SELECT COUNT(*) FROM elig_stores), 2),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN store_int s ON e.store_id = s.store_id)
    / (SELECT COUNT(*) FROM store_int), 2)
UNION ALL
SELECT
  'eligibility -> outbound store_master',
  (SELECT COUNT(*) FROM elig_stores),
  (SELECT COUNT(*) FROM outbound_sm),
  (SELECT COUNT(*) FROM elig_stores e INNER JOIN outbound_sm s ON e.store_id = s.store_id),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN outbound_sm s ON e.store_id = s.store_id)
    / (SELECT COUNT(*) FROM elig_stores), 2),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN outbound_sm s ON e.store_id = s.store_id)
    / (SELECT COUNT(*) FROM outbound_sm), 2);

-- F) Eligibility stores that match master: TYPE_CODE breakdown
WITH elig_stores AS (
  SELECT DISTINCT TRIM(CAST(STORE_ID AS STRING)) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE STORE_ID IS NOT NULL
),
loc AS (
  SELECT TRIM(ID) AS store_id, TYPE_CODE, CHANNEL_CODE
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
),
matched AS (
  SELECT e.store_id, l.TYPE_CODE
  FROM elig_stores e
  INNER JOIN loc l ON e.store_id = l.store_id
)
SELECT
  TYPE_CODE,
  COUNT(*) AS n_stores,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_matched
FROM matched
GROUP BY TYPE_CODE
ORDER BY n_stores DESC;

-- F2) Master stores NOT in eligibility: TYPE_CODE breakdown
WITH elig_stores AS (
  SELECT DISTINCT TRIM(CAST(STORE_ID AS STRING)) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE STORE_ID IS NOT NULL
),
loc AS (
  SELECT TRIM(ID) AS store_id, TYPE_CODE
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
),
loc_only AS (
  SELECT l.store_id, l.TYPE_CODE
  FROM loc l
  LEFT JOIN elig_stores e ON l.store_id = e.store_id
  WHERE e.store_id IS NULL
)
SELECT
  TYPE_CODE,
  COUNT(*) AS n_stores,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_location_only
FROM loc_only
GROUP BY TYPE_CODE
ORDER BY n_stores DESC;

-- G) Cross-feed: planned_sales vs eligibility (both Jun 25 sync batch)
WITH elig AS (
  SELECT DISTINCT TRIM(CAST(STORE_ID AS STRING)) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
),
planned AS (
  SELECT DISTINCT TRIM(CAST(STORE_ID AS STRING)) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`
)
SELECT
  (SELECT COUNT(*) FROM planned) AS planned_distinct_stores,
  (SELECT COUNT(*) FROM elig) AS eligibility_distinct_stores,
  (SELECT COUNT(*) FROM planned p INNER JOIN elig e ON p.store_id = e.store_id) AS in_both,
  ROUND(100 * (SELECT COUNT(*) FROM planned p INNER JOIN elig e ON p.store_id = e.store_id)
    / (SELECT COUNT(*) FROM planned), 2) AS pct_planned_in_eligibility,
  ROUND(100 * (SELECT COUNT(*) FROM planned p INNER JOIN elig e ON p.store_id = e.store_id)
    / (SELECT COUNT(*) FROM elig), 2) AS pct_eligibility_in_planned;

-- H) Combined PSO + store coverage table (same layout as summary comment above)
WITH pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS planning_style_option_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND VALUE_CODE IS NOT NULL AND TRIM(VALUE_CODE) != ''
),
style_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE PLANNING_STYLE_OPTION_ID IS NOT NULL AND TRIM(PLANNING_STYLE_OPTION_ID) != ''
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE PLANNING_STYLE_OPTION_ID IS NOT NULL AND TRIM(PLANNING_STYLE_OPTION_ID) != ''
),
elig_stores AS (
  SELECT DISTINCT TRIM(CAST(STORE_ID AS STRING)) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE STORE_ID IS NOT NULL
),
loc_details AS (
  SELECT DISTINCT TRIM(ID) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
),
planned_stores AS (
  SELECT DISTINCT TRIM(CAST(STORE_ID AS STRING)) AS store_id
  FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales`
  WHERE STORE_ID IS NOT NULL
)
SELECT 'PGH → style_option' AS comparison,
  (SELECT COUNT(*) FROM pgh_pso) AS left_distinct,
  (SELECT COUNT(*) FROM style_pso) AS right_distinct,
  (SELECT COUNT(*) FROM pgh_pso p INNER JOIN style_pso s USING (planning_style_option_id)) AS in_both,
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN style_pso s USING (planning_style_option_id))
    / (SELECT COUNT(*) FROM pgh_pso), 2) AS pct_left_in_right,
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN style_pso s USING (planning_style_option_id))
    / (SELECT COUNT(*) FROM style_pso), 2) AS pct_right_in_left
UNION ALL
SELECT 'PGH → eligibility',
  (SELECT COUNT(*) FROM pgh_pso),
  (SELECT COUNT(*) FROM elig_pso),
  (SELECT COUNT(*) FROM pgh_pso p INNER JOIN elig_pso e USING (planning_style_option_id)),
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN elig_pso e USING (planning_style_option_id))
    / (SELECT COUNT(*) FROM pgh_pso), 2),
  ROUND(100 * (SELECT COUNT(*) FROM pgh_pso p INNER JOIN elig_pso e USING (planning_style_option_id))
    / (SELECT COUNT(*) FROM elig_pso), 2)
UNION ALL
SELECT 'style_option → eligibility',
  (SELECT COUNT(*) FROM style_pso),
  (SELECT COUNT(*) FROM elig_pso),
  (SELECT COUNT(*) FROM style_pso s INNER JOIN elig_pso e USING (PLANNING_STYLE_OPTION_ID)),
  ROUND(100 * (SELECT COUNT(*) FROM style_pso s INNER JOIN elig_pso e USING (PLANNING_STYLE_OPTION_ID))
    / (SELECT COUNT(*) FROM style_pso), 2),
  ROUND(100 * (SELECT COUNT(*) FROM style_pso s INNER JOIN elig_pso e USING (PLANNING_STYLE_OPTION_ID))
    / (SELECT COUNT(*) FROM elig_pso), 2)
UNION ALL
SELECT 'eligibility → location_details',
  (SELECT COUNT(*) FROM elig_stores),
  (SELECT COUNT(*) FROM loc_details),
  (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_details l ON e.store_id = l.store_id),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_details l ON e.store_id = l.store_id)
    / (SELECT COUNT(*) FROM elig_stores), 2),
  ROUND(100 * (SELECT COUNT(*) FROM elig_stores e INNER JOIN loc_details l ON e.store_id = l.store_id)
    / (SELECT COUNT(*) FROM loc_details), 2)
UNION ALL
SELECT 'planned_sales → eligibility',
  (SELECT COUNT(*) FROM planned_stores),
  (SELECT COUNT(*) FROM elig_stores),
  (SELECT COUNT(*) FROM planned_stores p INNER JOIN elig_stores e ON p.store_id = e.store_id),
  ROUND(100 * (SELECT COUNT(*) FROM planned_stores p INNER JOIN elig_stores e ON p.store_id = e.store_id)
    / (SELECT COUNT(*) FROM planned_stores), 2),
  ROUND(100 * (SELECT COUNT(*) FROM planned_stores p INNER JOIN elig_stores e ON p.store_id = e.store_id)
    / (SELECT COUNT(*) FROM elig_stores), 2)
UNION ALL
SELECT 'planned_sales → location_details',
  (SELECT COUNT(*) FROM planned_stores),
  (SELECT COUNT(*) FROM loc_details),
  (SELECT COUNT(*) FROM planned_stores p INNER JOIN loc_details l ON p.store_id = l.store_id),
  ROUND(100 * (SELECT COUNT(*) FROM planned_stores p INNER JOIN loc_details l ON p.store_id = l.store_id)
    / (SELECT COUNT(*) FROM planned_stores), 2),
  ROUND(100 * (SELECT COUNT(*) FROM planned_stores p INNER JOIN loc_details l ON p.store_id = l.store_id)
    / (SELECT COUNT(*) FROM loc_details), 2)
ORDER BY comparison;

-- -----------------------------------------------------------------------------
-- I) PSO mismatch: retail vs e-commerce distribution (PGH + style_option)
-- Channel proxy: planned_sales.SUB_MARKET_CHANNEL_ID (_RTL = retail, _ECOM = e-commerce)
-- Join path: planned_sales -> style_option.STYLE_OPTION_ID -> PLANNING_STYLE_OPTION_ID
-- Product_master l8_id has both _RETAIL and _ECOMM SKUs for every PGH PSO (not discriminative)
-- Verified 2026-07-02
-- -----------------------------------------------------------------------------

-- I1) PGH PSOs: simplified retail/ecom channel presence vs eligibility status
WITH pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) != ''
),
planned_pso AS (
  SELECT
    so.PLANNING_STYLE_OPTION_ID AS pso,
    MAX(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_RTL'), 1, 0)) AS has_retail,
    MAX(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_ECOM'), 1, 0)) AS has_ecom
  FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales` ps
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON ps.STYLE_OPTION_ID = so.STYLE_OPTION_ID
  WHERE so.PLANNING_STYLE_OPTION_ID IS NOT NULL
  GROUP BY 1
),
labeled AS (
  SELECT
    p.pso,
    IF(e.pso IS NOT NULL, 'in_eligibility', 'not_in_eligibility') AS elig_status,
    CASE
      WHEN pp.pso IS NULL THEN 'no_planned_sales'
      WHEN pp.has_retail = 1 AND pp.has_ecom = 0 THEN 'retail_only'
      WHEN pp.has_ecom = 1 AND pp.has_retail = 0 THEN 'ecom_only'
      WHEN pp.has_retail = 1 AND pp.has_ecom = 1 THEN 'both_retail_and_ecom'
      ELSE 'other'
    END AS channel_presence
  FROM pgh_pso p
  LEFT JOIN elig_pso e ON p.pso = e.pso
  LEFT JOIN planned_pso pp ON p.pso = pp.pso
)
SELECT elig_status, channel_presence, COUNT(*) AS n_pso,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY elig_status), 2) AS pct_within_status
FROM labeled
GROUP BY 1, 2
ORDER BY elig_status, n_pso DESC;

-- I2) PGH PSOs: detailed planned-units channel profile vs eligibility
WITH pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
),
planned_pso AS (
  SELECT
    so.PLANNING_STYLE_OPTION_ID AS pso,
    MAX(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_RTL'), 1, 0)) AS has_retail_planned,
    MAX(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_ECOM'), 1, 0)) AS has_ecom_planned,
    SUM(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_RTL'), SAFE_CAST(ps.WP_TOT_REG_SLS_U AS FLOAT64), 0)) AS retail_units,
    SUM(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_ECOM'), SAFE_CAST(ps.WP_TOT_REG_SLS_U AS FLOAT64), 0)) AS ecom_units
  FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales` ps
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON ps.STYLE_OPTION_ID = so.STYLE_OPTION_ID
  GROUP BY 1
),
pso_planned_profile AS (
  SELECT pso,
    CASE
      WHEN has_retail_planned = 1 AND has_ecom_planned = 0 THEN 'retail_planned_only'
      WHEN has_ecom_planned = 1 AND has_retail_planned = 0 THEN 'ecom_planned_only'
      WHEN has_retail_planned = 1 AND has_ecom_planned = 1 AND retail_units >= ecom_units * 3 THEN 'retail_dominant_planned'
      WHEN has_retail_planned = 1 AND has_ecom_planned = 1 AND ecom_units >= retail_units * 3 THEN 'ecom_dominant_planned'
      WHEN has_retail_planned = 1 AND has_ecom_planned = 1 THEN 'both_channels_planned'
      ELSE 'no_planned_sales'
    END AS planned_channel_profile
  FROM planned_pso
),
pgh_labeled AS (
  SELECT
    p.pso,
    IF(e.pso IS NOT NULL, 'in_eligibility', 'not_in_eligibility') AS elig_status,
    COALESCE(pp.planned_channel_profile, 'no_planned_sales') AS planned_channel_profile
  FROM pgh_pso p
  LEFT JOIN elig_pso e ON p.pso = e.pso
  LEFT JOIN pso_planned_profile pp ON p.pso = pp.pso
)
SELECT elig_status, planned_channel_profile, COUNT(*) AS n_pso,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY elig_status), 2) AS pct_within_status
FROM pgh_labeled
GROUP BY 1, 2
ORDER BY elig_status, n_pso DESC;

-- I3) style_option PSOs NOT in eligibility: PGH presence x channel presence
WITH style_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) != ''
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
),
pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
),
planned_pso AS (
  SELECT
    so.PLANNING_STYLE_OPTION_ID AS pso,
    MAX(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_RTL'), 1, 0)) AS has_retail,
    MAX(IF(ENDS_WITH(ps.SUB_MARKET_CHANNEL_ID, '_ECOM'), 1, 0)) AS has_ecom
  FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales` ps
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON ps.STYLE_OPTION_ID = so.STYLE_OPTION_ID
  GROUP BY 1
),
missing AS (
  SELECT
    s.pso,
    IF(p.pso IS NOT NULL, 'in_pgh', 'not_in_pgh') AS pgh_status,
    CASE
      WHEN pp.pso IS NULL THEN 'no_planned_sales'
      WHEN pp.has_retail = 1 AND pp.has_ecom = 0 THEN 'retail_only'
      WHEN pp.has_ecom = 1 AND pp.has_retail = 0 THEN 'ecom_only'
      WHEN pp.has_retail = 1 AND pp.has_ecom = 1 THEN 'both_retail_and_ecom'
      ELSE 'other'
    END AS channel_presence
  FROM style_pso s
  LEFT JOIN elig_pso e ON s.pso = e.pso
  LEFT JOIN pgh_pso p ON s.pso = p.pso
  LEFT JOIN planned_pso pp ON s.pso = pp.pso
  WHERE e.pso IS NULL
)
SELECT pgh_status, channel_presence, COUNT(*) AS n_pso,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_missing_style_pso
FROM missing
GROUP BY 1, 2
ORDER BY n_pso DESC;

-- I4) PGH PSOs NOT in eligibility: style_option status (deleted / placeholder)
WITH pgh_pso AS (
  SELECT DISTINCT VALUE_CODE AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
),
elig_pso AS (
  SELECT DISTINCT PLANNING_STYLE_OPTION_ID AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
),
style_flags AS (
  SELECT
    PLANNING_STYLE_OPTION_ID AS pso,
    MAX(IF(UPPER(COALESCE(DELETE_IND, '')) IN ('TRUE', '1', 'Y'), 1, 0)) AS is_deleted,
    MAX(IF(UPPER(COALESCE(PLACEHOLDER_FLAG, '')) IN ('TRUE', '1', 'Y'), 1, 0)) AS is_placeholder
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  GROUP BY 1
),
missing AS (
  SELECT p.pso FROM pgh_pso p
  LEFT JOIN elig_pso e ON p.pso = e.pso
  WHERE e.pso IS NULL
)
SELECT
  CASE
    WHEN sf.pso IS NULL THEN 'no_style_option_row'
    WHEN sf.is_deleted = 1 THEN 'deleted_in_style_option'
    WHEN sf.is_placeholder = 1 THEN 'placeholder_in_style_option'
    ELSE 'active_in_style_option'
  END AS style_option_status,
  COUNT(*) AS n_pso,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM missing m
LEFT JOIN style_flags sf ON m.pso = sf.pso
GROUP BY 1
ORDER BY n_pso DESC;

-- I5) Eligibility rows on matched stores: RETAIL vs ECOM store TYPE mix
SELECT
  l.TYPE_CODE,
  COUNT(*) AS elig_rows,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_matched_elig_rows
FROM `lululemon-01042025.lulu_sourcing_dev.eligibility` el
INNER JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` l
  ON TRIM(CAST(el.STORE_ID AS STRING)) = TRIM(l.ID)
GROUP BY 1
ORDER BY elig_rows DESC;

-- =============================================================================
-- J) Eligibility coverage summary: PSO and PSO x store
-- Product: style_option (exact PSO), style_option (STYLE_ID prefix), PGH
-- Transaction: all-time and 2025-only (transaction_master, qty > 0, revenue > 0)
-- Txn bridge: eligibility PSO -> PGH SKU -> product_master -> transaction_master
-- Store join for PSO x store: TRIM(LTRIM(..., '0')) on eligibility STORE_ID and txn store_code
-- Adjust txn_year_start / txn_year_end for a different sales window.
-- Verified pattern: 2026-07-02
-- =============================================================================

-- J1) PSO-level coverage summary
WITH params AS (
  SELECT
    DATE '2025-01-01' AS txn_year_start,
    DATE '2025-12-31' AS txn_year_end
),
elig_pso AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    SPLIT(TRIM(PLANNING_STYLE_OPTION_ID), '-')[OFFSET(0)] AS style_prefix,
    COUNT(*) AS elig_rows
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
  GROUP BY 1, 2
),
style_pso AS (
  SELECT DISTINCT TRIM(PLANNING_STYLE_OPTION_ID) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
),
style_prefix AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_prefix
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(STYLE_ID) NOT IN ('', '\\N')
),
pgh_pso AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
pm AS (
  SELECT DISTINCT TRIM(product_code) AS product_code, TRIM(product_code_original) AS sku_id
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
  WHERE TRIM(product_code_original) NOT IN ('', '\\N')
),
txn_all AS (
  SELECT DISTINCT TRIM(product_code) AS product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0 AND revenue > 0
),
txn_2025 AS (
  SELECT DISTINCT TRIM(product_code) AS product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0
    AND revenue > 0
    AND date BETWEEN txn_year_start AND txn_year_end
),
pso_txn AS (
  SELECT DISTINCT s.pso
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_all t ON pm.product_code = t.product_code
),
pso_txn_2025 AS (
  SELECT DISTINCT s.pso
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_2025 t ON pm.product_code = t.product_code
),
pso_flags AS (
  SELECT
    e.pso,
    e.style_prefix,
    e.elig_rows,
    sp.pso IS NOT NULL AS in_style_option_exact,
    pp.style_prefix IS NOT NULL AS in_style_option_prefix,
    pg.pso IS NOT NULL AS in_pgh,
    ta.pso IS NOT NULL AS in_txn_all,
    t25.pso IS NOT NULL AS in_txn_2025
  FROM elig_pso e
  LEFT JOIN style_pso sp ON e.pso = sp.pso
  LEFT JOIN style_prefix pp ON e.style_prefix = pp.style_prefix
  LEFT JOIN pgh_pso pg ON e.pso = pg.pso
  LEFT JOIN pso_txn ta ON e.pso = ta.pso
  LEFT JOIN pso_txn_2025 t25 ON e.pso = t25.pso
)
SELECT
  'pso' AS grain,
  COUNT(*) AS distinct_keys,
  SUM(elig_rows) AS elig_rows,
  COUNTIF(in_style_option_exact) AS keys_in_style_option_exact,
  ROUND(100 * COUNTIF(in_style_option_exact) / COUNT(*), 2) AS pct_style_option_exact,
  COUNTIF(in_style_option_prefix) AS keys_in_style_option_prefix,
  ROUND(100 * COUNTIF(in_style_option_prefix) / COUNT(*), 2) AS pct_style_option_prefix,
  COUNTIF(in_pgh) AS keys_in_pgh,
  ROUND(100 * COUNTIF(in_pgh) / COUNT(*), 2) AS pct_pgh,
  COUNTIF(in_txn_all) AS keys_in_txn_all,
  ROUND(100 * COUNTIF(in_txn_all) / COUNT(*), 2) AS pct_txn_all,
  COUNTIF(in_txn_2025) AS keys_in_txn_2025,
  ROUND(100 * COUNTIF(in_txn_2025) / COUNT(*), 2) AS pct_txn_2025
FROM pso_flags;

-- J2) PSO x store coverage summary
WITH params AS (
  SELECT
    DATE '2025-01-01' AS txn_year_start,
    DATE '2025-12-31' AS txn_year_end
),
elig_pso_store AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    SPLIT(TRIM(PLANNING_STYLE_OPTION_ID), '-')[OFFSET(0)] AS style_prefix,
    COUNT(*) AS elig_rows
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
  GROUP BY 1, 2, 3
),
style_pso AS (
  SELECT DISTINCT TRIM(PLANNING_STYLE_OPTION_ID) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
),
style_prefix AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_prefix
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(STYLE_ID) NOT IN ('', '\\N')
),
pgh_pso AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
pm AS (
  SELECT DISTINCT TRIM(product_code) AS product_code, TRIM(product_code_original) AS sku_id
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
  WHERE TRIM(product_code_original) NOT IN ('', '\\N')
),
txn_all AS (
  SELECT DISTINCT
    TRIM(product_code) AS product_code,
    TRIM(LTRIM(store_code, '0')) AS store_id
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0 AND revenue > 0
),
txn_2025 AS (
  SELECT DISTINCT
    TRIM(product_code) AS product_code,
    TRIM(LTRIM(store_code, '0')) AS store_id
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0
    AND revenue > 0
    AND date BETWEEN txn_year_start AND txn_year_end
),
pso_store_txn AS (
  SELECT DISTINCT s.pso, t.store_id
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_all t ON pm.product_code = t.product_code
),
pso_store_txn_2025 AS (
  SELECT DISTINCT s.pso, t.store_id
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_2025 t ON pm.product_code = t.product_code
),
pso_store_flags AS (
  SELECT
    e.pso,
    e.store_id,
    e.elig_rows,
    sp.pso IS NOT NULL AS in_style_option_exact,
    pp.style_prefix IS NOT NULL AS in_style_option_prefix,
    pg.pso IS NOT NULL AS in_pgh,
    pst.pso IS NOT NULL AS in_txn_all,
    ps25.pso IS NOT NULL AS in_txn_2025
  FROM elig_pso_store e
  LEFT JOIN style_pso sp ON e.pso = sp.pso
  LEFT JOIN style_prefix pp ON e.style_prefix = pp.style_prefix
  LEFT JOIN pgh_pso pg ON e.pso = pg.pso
  LEFT JOIN pso_store_txn pst
    ON e.pso = pst.pso AND e.store_id = pst.store_id
  LEFT JOIN pso_store_txn_2025 ps25
    ON e.pso = ps25.pso AND e.store_id = ps25.store_id
)
SELECT
  'pso_x_store' AS grain,
  COUNT(*) AS distinct_keys,
  SUM(elig_rows) AS elig_rows,
  COUNTIF(in_style_option_exact) AS keys_in_style_option_exact,
  ROUND(100 * COUNTIF(in_style_option_exact) / COUNT(*), 2) AS pct_style_option_exact,
  COUNTIF(in_style_option_prefix) AS keys_in_style_option_prefix,
  ROUND(100 * COUNTIF(in_style_option_prefix) / COUNT(*), 2) AS pct_style_option_prefix,
  COUNTIF(in_pgh) AS keys_in_pgh,
  ROUND(100 * COUNTIF(in_pgh) / COUNT(*), 2) AS pct_pgh,
  COUNTIF(in_txn_all) AS keys_in_txn_all,
  ROUND(100 * COUNTIF(in_txn_all) / COUNT(*), 2) AS pct_txn_all,
  COUNTIF(in_txn_2025) AS keys_in_txn_2025,
  ROUND(100 * COUNTIF(in_txn_2025) / COUNT(*), 2) AS pct_txn_2025
FROM pso_store_flags;

-- J3) Combined one-page summary (PSO + PSO x store)
WITH params AS (
  SELECT DATE '2025-01-01' AS txn_year_start, DATE '2025-12-31' AS txn_year_end
),
elig_pso AS (
  SELECT TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    SPLIT(TRIM(PLANNING_STYLE_OPTION_ID), '-')[OFFSET(0)] AS style_prefix,
    COUNT(*) AS elig_rows
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
  GROUP BY 1, 2
),
elig_pso_store AS (
  SELECT TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    SPLIT(TRIM(PLANNING_STYLE_OPTION_ID), '-')[OFFSET(0)] AS style_prefix,
    COUNT(*) AS elig_rows
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
  GROUP BY 1, 2, 3
),
style_pso AS (
  SELECT DISTINCT TRIM(PLANNING_STYLE_OPTION_ID) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
),
style_prefix AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_prefix
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(STYLE_ID) NOT IN ('', '\\N')
),
pgh_pso AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
pm AS (
  SELECT DISTINCT TRIM(product_code) AS product_code, TRIM(product_code_original) AS sku_id
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
  WHERE TRIM(product_code_original) NOT IN ('', '\\N')
),
txn_all AS (
  SELECT DISTINCT
    TRIM(product_code) AS product_code,
    TRIM(LTRIM(store_code, '0')) AS store_id
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0 AND revenue > 0
),
txn_2025 AS (
  SELECT DISTINCT
    TRIM(product_code) AS product_code,
    TRIM(LTRIM(store_code, '0')) AS store_id
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0 AND revenue > 0
    AND date BETWEEN txn_year_start AND txn_year_end
),
pso_txn AS (
  SELECT DISTINCT s.pso
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_all t ON pm.product_code = t.product_code
),
pso_txn_2025 AS (
  SELECT DISTINCT s.pso
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_2025 t ON pm.product_code = t.product_code
),
pso_store_txn AS (
  SELECT DISTINCT s.pso, t.store_id
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_all t ON pm.product_code = t.product_code
),
pso_store_txn_2025 AS (
  SELECT DISTINCT s.pso, t.store_id
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_2025 t ON pm.product_code = t.product_code
),
pso_summary AS (
  SELECT
    'pso' AS grain,
    COUNT(*) AS distinct_keys,
    SUM(e.elig_rows) AS elig_rows,
    ROUND(100 * COUNTIF(sp.pso IS NOT NULL) / COUNT(*), 2) AS pct_style_option_exact,
    ROUND(100 * COUNTIF(pp.style_prefix IS NOT NULL) / COUNT(*), 2) AS pct_style_option_prefix,
    ROUND(100 * COUNTIF(pg.pso IS NOT NULL) / COUNT(*), 2) AS pct_pgh,
    ROUND(100 * COUNTIF(ta.pso IS NOT NULL) / COUNT(*), 2) AS pct_txn_all,
    ROUND(100 * COUNTIF(t25.pso IS NOT NULL) / COUNT(*), 2) AS pct_txn_2025
  FROM elig_pso e
  LEFT JOIN style_pso sp ON e.pso = sp.pso
  LEFT JOIN style_prefix pp ON e.style_prefix = pp.style_prefix
  LEFT JOIN pgh_pso pg ON e.pso = pg.pso
  LEFT JOIN pso_txn ta ON e.pso = ta.pso
  LEFT JOIN pso_txn_2025 t25 ON e.pso = t25.pso
),
pso_store_summary AS (
  SELECT
    'pso_x_store' AS grain,
    COUNT(*) AS distinct_keys,
    SUM(e.elig_rows) AS elig_rows,
    ROUND(100 * COUNTIF(sp.pso IS NOT NULL) / COUNT(*), 2) AS pct_style_option_exact,
    ROUND(100 * COUNTIF(pp.style_prefix IS NOT NULL) / COUNT(*), 2) AS pct_style_option_prefix,
    ROUND(100 * COUNTIF(pg.pso IS NOT NULL) / COUNT(*), 2) AS pct_pgh,
    ROUND(100 * COUNTIF(pst.pso IS NOT NULL) / COUNT(*), 2) AS pct_txn_all,
    ROUND(100 * COUNTIF(ps25.pso IS NOT NULL) / COUNT(*), 2) AS pct_txn_2025
  FROM elig_pso_store e
  LEFT JOIN style_pso sp ON e.pso = sp.pso
  LEFT JOIN style_prefix pp ON e.style_prefix = pp.style_prefix
  LEFT JOIN pgh_pso pg ON e.pso = pg.pso
  LEFT JOIN pso_store_txn pst ON e.pso = pst.pso AND e.store_id = pst.store_id
  LEFT JOIN pso_store_txn_2025 ps25 ON e.pso = ps25.pso AND e.store_id = ps25.store_id
)
SELECT * FROM pso_summary
UNION ALL
SELECT * FROM pso_store_summary
ORDER BY grain;

-- J4) PSO-level tier breakdown (exact / prefix / orphan x product + txn flags)
WITH params AS (
  SELECT DATE '2025-01-01' AS txn_year_start, DATE '2025-12-31' AS txn_year_end
),
elig_pso AS (
  SELECT TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    SPLIT(TRIM(PLANNING_STYLE_OPTION_ID), '-')[OFFSET(0)] AS style_prefix
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
  GROUP BY 1, 2
),
style_pso AS (
  SELECT DISTINCT TRIM(PLANNING_STYLE_OPTION_ID) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
),
style_prefix AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_prefix
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
),
pgh_pso AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
),
pm AS (
  SELECT DISTINCT TRIM(product_code) AS product_code, TRIM(product_code_original) AS sku_id
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
),
txn_all AS (
  SELECT DISTINCT TRIM(product_code) AS product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0 AND revenue > 0
),
txn_2025 AS (
  SELECT DISTINCT TRIM(product_code) AS product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`, params
  WHERE qty > 0 AND revenue > 0
    AND date BETWEEN txn_year_start AND txn_year_end
),
pso_txn AS (
  SELECT DISTINCT s.pso
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_all t ON pm.product_code = t.product_code
),
pso_txn_2025 AS (
  SELECT DISTINCT s.pso
  FROM pso_sku s
  INNER JOIN pm ON s.sku_id = pm.sku_id
  INNER JOIN txn_2025 t ON pm.product_code = t.product_code
),
tagged AS (
  SELECT
    e.pso,
    CASE
      WHEN sp.pso IS NOT NULL THEN '1_exact_pso_in_style_option'
      WHEN pp.style_prefix IS NOT NULL THEN '2_prefix_only_in_style_option'
      ELSE '3_no_style_option_match'
    END AS style_option_tier,
    pg.pso IS NOT NULL AS in_pgh,
    ta.pso IS NOT NULL AS in_txn_all,
    t25.pso IS NOT NULL AS in_txn_2025
  FROM elig_pso e
  LEFT JOIN style_pso sp ON e.pso = sp.pso
  LEFT JOIN style_prefix pp ON e.style_prefix = pp.style_prefix
  LEFT JOIN pgh_pso pg ON e.pso = pg.pso
  LEFT JOIN pso_txn ta ON e.pso = ta.pso
  LEFT JOIN pso_txn_2025 t25 ON e.pso = t25.pso
)
SELECT
  style_option_tier,
  COUNT(*) AS distinct_pso,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_pso,
  COUNTIF(in_pgh) AS pso_in_pgh,
  ROUND(100 * COUNTIF(in_pgh) / COUNT(*), 2) AS pct_in_pgh,
  COUNTIF(in_txn_all) AS pso_in_txn_all,
  ROUND(100 * COUNTIF(in_txn_all) / COUNT(*), 2) AS pct_in_txn_all,
  COUNTIF(in_txn_2025) AS pso_in_txn_2025,
  ROUND(100 * COUNTIF(in_txn_2025) / COUNT(*), 2) AS pct_in_txn_2025
FROM tagged
GROUP BY 1
ORDER BY 1;
