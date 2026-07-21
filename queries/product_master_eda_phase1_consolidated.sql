-- =============================================================================
-- Product Master EDA - Phase 1 CONSOLIDATED
-- Outputs all 7 query results in ONE result set (7 rows, JSON-encoded).
-- Run once, copy the whole output, paste back.
--
-- Output columns:
--   query_id        - 'Q1' .. 'Q7'
--   description     - what the query checks
--   results_json    - results serialized as JSON (array for multi-row queries)
--
-- Table: lululemon-01042025.lululemon_souricng_outbound.product_master
-- =============================================================================

WITH

-- ---- Q1: Row counts, distinct identifier counts, channel split ----
q1 AS (
  SELECT
    'Q1' AS query_id,
    'Row counts + channel split' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNT(DISTINCT article) AS distinct_article,
      COUNT(DISTINCT article_original) AS distinct_article_original,
      COUNT(DISTINCT product_code) AS distinct_product_code,
      COUNT(DISTINCT product_code_original) AS distinct_product_code_original,
      COUNT(DISTINCT l1_name) AS distinct_l1_values,
      COUNTIF(l1_name = 'RETAIL') AS retail_rows,
      COUNTIF(l1_name = 'ECOMM') AS ecomm_rows,
      COUNTIF(l1_name NOT IN ('RETAIL', 'ECOMM')) AS other_channel_rows
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
),

-- ---- Q2: Null / blank / '\N' counts per key column ----
q2 AS (
  SELECT
    'Q2' AS query_id,
    'Null/blank/\\N counts per column (type-aware)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(product_name IS NULL OR product_name = '' OR product_name = '\\N') AS null_product_name,
      COUNTIF(size IS NULL OR size = '' OR size = '\\N') AS null_size,
      COUNTIF(product_code IS NULL OR product_code = '' OR product_code = '\\N') AS null_product_code,
      COUNTIF(article IS NULL OR article = '' OR article = '\\N') AS null_article,
      COUNTIF(color_code IS NULL OR color_code = '' OR color_code = '\\N') AS null_color_code,
      COUNTIF(color_description IS NULL OR color_description = '' OR color_description = '\\N') AS null_color_description,
      COUNTIF(season_code IS NULL OR season_code = '' OR season_code = '\\N') AS null_season_code,
      COUNTIF(silhouette IS NULL OR silhouette = '' OR silhouette = '\\N') AS null_silhouette,
      COUNTIF(gender IS NULL OR gender = '' OR gender = '\\N') AS null_gender,
      COUNTIF(fit_classification IS NULL OR fit_classification = '' OR fit_classification = '\\N') AS null_fit_classification,
      COUNTIF(planning_product_grouping IS NULL OR planning_product_grouping = '' OR planning_product_grouping = '\\N') AS null_planning_product_grouping,
      COUNTIF(article_status IS NULL OR article_status = '' OR article_status = '\\N') AS null_article_status,
      COUNTIF(design_line IS NULL OR design_line = '' OR design_line = '\\N') AS null_design_line,
      COUNTIF(product_line IS NULL OR product_line = '' OR product_line = '\\N') AS null_product_line,
      COUNTIF(size_scale IS NULL OR size_scale = '' OR size_scale = '\\N') AS null_size_scale,
      COUNTIF(global_merch_team IS NULL OR global_merch_team = '' OR global_merch_team = '\\N') AS null_global_merch_team,
      COUNTIF(designed_for_activity IS NULL OR designed_for_activity = '' OR designed_for_activity = '\\N') AS null_designed_for_activity,
      COUNTIF(l8_name IS NULL OR l8_name = '' OR l8_name = '\\N') AS null_l8_name,
      COUNTIF(product_bucket_code IS NULL) AS null_product_bucket_code,
      COUNTIF(active_flag IS NULL) AS null_active_flag,
      COUNTIF(color_family IS NULL) AS null_color_family,
      COUNTIF(ordering IS NULL) AS null_ordering,
      COUNTIF(launch_date IS NULL) AS null_launch_date
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
),

-- ---- Q3: Row-level duplicates (top 50) ----
q3_rows AS (
  SELECT article, size, color_code, l1_name, COUNT(*) AS dup_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY article, size, color_code, l1_name
  HAVING COUNT(*) > 1
  ORDER BY dup_count DESC
  LIMIT 50
),
q3 AS (
  SELECT
    'Q3' AS query_id,
    'Row-level duplicates (top 50)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(article, size, color_code, l1_name, dup_count))) AS results_json
  FROM q3_rows
),

-- ---- Q4: Grain test ----
q4_rows AS (
  SELECT 'article only' AS grain_test,
         COUNT(*) AS total_rows,
         COUNT(DISTINCT article) AS distinct_vals,
         COUNT(*) - COUNT(DISTINCT article) AS duplicate_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  UNION ALL
  SELECT 'article_original only',
         COUNT(*),
         COUNT(DISTINCT article_original),
         COUNT(*) - COUNT(DISTINCT article_original)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  UNION ALL
  SELECT 'article_original + l1_name (channel)',
         COUNT(*),
         COUNT(DISTINCT CONCAT(COALESCE(article_original, ''), '|', COALESCE(l1_name, ''))),
         COUNT(*) - COUNT(DISTINCT CONCAT(COALESCE(article_original, ''), '|', COALESCE(l1_name, '')))
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  UNION ALL
  SELECT 'product_code_original + color_code + size + l1_name',
         COUNT(*),
         COUNT(DISTINCT CONCAT(COALESCE(product_code_original, ''), '|', COALESCE(color_code, ''), '|', COALESCE(size, ''), '|', COALESCE(l1_name, ''))),
         COUNT(*) - COUNT(DISTINCT CONCAT(COALESCE(product_code_original, ''), '|', COALESCE(color_code, ''), '|', COALESCE(size, ''), '|', COALESCE(l1_name, '')))
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
),
q4 AS (
  SELECT
    'Q4' AS query_id,
    'Grain test (PK candidate check)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(grain_test, total_rows, distinct_vals, duplicate_count))) AS results_json
  FROM q4_rows
),

-- ---- Q5: article_status x active_flag ----
q5_rows AS (
  SELECT article_status, active_flag, COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY article_status, active_flag
  ORDER BY row_count DESC
),
q5 AS (
  SELECT
    'Q5' AS query_id,
    'article_status x active_flag cross-tab' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(article_status, active_flag, row_count))) AS results_json
  FROM q5_rows
),

-- ---- Q6: launch_date format sanity ----
q6 AS (
  SELECT
    'Q6' AS query_id,
    'launch_date format sanity (INT64)' AS description,
    TO_JSON_STRING(STRUCT(
      MIN(launch_date) AS min_launch_date,
      MAX(launch_date) AS max_launch_date,
      COUNT(DISTINCT launch_date) AS distinct_launch_dates,
      COUNTIF(launch_date IS NULL) AS null_launch_date_count,
      COUNTIF(launch_date = 0) AS zero_launch_date_count,
      COUNT(*) AS total_rows,
      APPROX_QUANTILES(launch_date, 10) AS launch_date_deciles
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
),

-- ---- Q7: color_family distinct values (top 30) ----
q7_rows AS (
  SELECT color_family, COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY color_family
  ORDER BY row_count DESC
  LIMIT 30
),
q7 AS (
  SELECT
    'Q7' AS query_id,
    'color_family distinct values (top 30)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(color_family, row_count))) AS results_json
  FROM q7_rows
)

-- ---- Final: union all 7 results ----
SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
UNION ALL SELECT * FROM q5
UNION ALL SELECT * FROM q6
UNION ALL SELECT * FROM q7
ORDER BY query_id;
