-- =============================================================================
-- Product Master EDA - Phase 1: Structural Checks
-- Table: lululemon-01042025.lululemon_souricng_outbound.product_master
-- Goal: Understand shape, nullability, duplicates, and grain of the table
-- Based on: Signet SOP (Global Checks + Product-specific checks)
--
-- Schema confirmed 2026-04-20 via INFORMATION_SCHEMA.
-- STRING columns: use (col IS NULL OR col = '' OR col = '\\N') for nulls
-- INT64 columns:  use (col IS NULL) only
-- INT64 columns in this table: product_bucket_code, active_flag, color_family,
--                              ordering, launch_date
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1: Row counts, distinct identifier counts, channel split
-- Purpose: Shape of the data. How many rows? How many unique products?
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*)                                                              AS total_rows,
  COUNT(DISTINCT article)                                               AS distinct_article,
  COUNT(DISTINCT article_original)                                      AS distinct_article_original,
  COUNT(DISTINCT product_code)                                          AS distinct_product_code,
  COUNT(DISTINCT product_code_original)                                 AS distinct_product_code_original,
  COUNT(DISTINCT l1_name)                                               AS distinct_l1_values,
  COUNTIF(l1_name = 'RETAIL')                                           AS retail_rows,
  COUNTIF(l1_name = 'ECOMM')                                            AS ecomm_rows,
  COUNTIF(l1_name NOT IN ('RETAIL', 'ECOMM'))                           AS other_channel_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`;


-- -----------------------------------------------------------------------------
-- Q2: Null / blank / '\N' counts per key column (type-aware)
-- Purpose: Find columns with missing data. '\N' is a literal string null marker
--         sometimes present in STRING columns - IS NULL alone won't catch it.
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*)                                                                                       AS total_rows,
  -- STRING columns (checks NULL + '' + '\N')
  COUNTIF(product_name IS NULL OR product_name = '' OR product_name = '\\N')                     AS null_product_name,
  COUNTIF(size IS NULL OR size = '' OR size = '\\N')                                             AS null_size,
  COUNTIF(product_code IS NULL OR product_code = '' OR product_code = '\\N')                     AS null_product_code,
  COUNTIF(article IS NULL OR article = '' OR article = '\\N')                                    AS null_article,
  COUNTIF(color_code IS NULL OR color_code = '' OR color_code = '\\N')                           AS null_color_code,
  COUNTIF(color_description IS NULL OR color_description = '' OR color_description = '\\N')     AS null_color_description,
  COUNTIF(season_code IS NULL OR season_code = '' OR season_code = '\\N')                        AS null_season_code,
  COUNTIF(silhouette IS NULL OR silhouette = '' OR silhouette = '\\N')                           AS null_silhouette,
  COUNTIF(gender IS NULL OR gender = '' OR gender = '\\N')                                       AS null_gender,
  COUNTIF(fit_classification IS NULL OR fit_classification = '' OR fit_classification = '\\N')   AS null_fit_classification,
  COUNTIF(planning_product_grouping IS NULL OR planning_product_grouping = '' OR planning_product_grouping = '\\N') AS null_planning_product_grouping,
  COUNTIF(article_status IS NULL OR article_status = '' OR article_status = '\\N')               AS null_article_status,
  COUNTIF(design_line IS NULL OR design_line = '' OR design_line = '\\N')                        AS null_design_line,
  COUNTIF(product_line IS NULL OR product_line = '' OR product_line = '\\N')                     AS null_product_line,
  COUNTIF(size_scale IS NULL OR size_scale = '' OR size_scale = '\\N')                           AS null_size_scale,
  COUNTIF(global_merch_team IS NULL OR global_merch_team = '' OR global_merch_team = '\\N')      AS null_global_merch_team,
  COUNTIF(designed_for_activity IS NULL OR designed_for_activity = '' OR designed_for_activity = '\\N') AS null_designed_for_activity,
  COUNTIF(l8_name IS NULL OR l8_name = '' OR l8_name = '\\N')                                    AS null_l8_name,
  -- INT64 columns (IS NULL only - can't compare INT64 to '' or '\N')
  COUNTIF(product_bucket_code IS NULL)                                                           AS null_product_bucket_code,
  COUNTIF(active_flag IS NULL)                                                                   AS null_active_flag,
  COUNTIF(color_family IS NULL)                                                                  AS null_color_family,
  COUNTIF(ordering IS NULL)                                                                      AS null_ordering,
  COUNTIF(launch_date IS NULL)                                                                   AS null_launch_date
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`;


-- -----------------------------------------------------------------------------
-- Q3: Row-level duplicates (Global SOP check)
-- Purpose: At the expected grain (article + channel), should be 0 duplicates.
-- -----------------------------------------------------------------------------
SELECT
  article,
  size,
  color_code,
  l1_name,
  COUNT(*) AS dup_count
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
GROUP BY article, size, color_code, l1_name
HAVING COUNT(*) > 1
ORDER BY dup_count DESC
LIMIT 50;


-- -----------------------------------------------------------------------------
-- Q4: Grain test - What's the primary key?
-- Purpose: Confirm the PK. Based on Q1 we expect article_original + l1_name
--         to give the same count as total_rows (i.e., duplicate_count = 0).
-- -----------------------------------------------------------------------------
SELECT
  'article only'                         AS grain_test,
  COUNT(*)                               AS total_rows,
  COUNT(DISTINCT article)                AS distinct_vals,
  COUNT(*) - COUNT(DISTINCT article)     AS duplicate_count
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`

UNION ALL

SELECT
  'article_original only',
  COUNT(*),
  COUNT(DISTINCT article_original),
  COUNT(*) - COUNT(DISTINCT article_original)
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`

UNION ALL

SELECT
  'article_original + l1_name (channel)',
  COUNT(*),
  COUNT(DISTINCT CONCAT(COALESCE(article_original, ''), '|', COALESCE(l1_name, ''))),
  COUNT(*) - COUNT(DISTINCT CONCAT(COALESCE(article_original, ''), '|', COALESCE(l1_name, '')))
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`

UNION ALL

SELECT
  'product_code_original + color_code + size + l1_name',
  COUNT(*),
  COUNT(DISTINCT CONCAT(COALESCE(product_code_original, ''), '|', COALESCE(color_code, ''), '|', COALESCE(size, ''), '|', COALESCE(l1_name, ''))),
  COUNT(*) - COUNT(DISTINCT CONCAT(COALESCE(product_code_original, ''), '|', COALESCE(color_code, ''), '|', COALESCE(size, ''), '|', COALESCE(l1_name, '')))
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`;


-- -----------------------------------------------------------------------------
-- Q5: article_status x active_flag cross-tab
-- Purpose: Decide which column to use as the "active product" filter
-- -----------------------------------------------------------------------------
SELECT
  article_status,
  active_flag,
  COUNT(*) AS row_count
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
GROUP BY article_status, active_flag
ORDER BY row_count DESC;


-- -----------------------------------------------------------------------------
-- Q6 (bonus): launch_date format sanity check (INT64)
-- Purpose: launch_date is stored as INT64. Is it YYYYMMDD?
--         Check min/max/sample to figure out the format.
-- -----------------------------------------------------------------------------
SELECT
  MIN(launch_date)                                   AS min_launch_date,
  MAX(launch_date)                                   AS max_launch_date,
  COUNT(DISTINCT launch_date)                        AS distinct_launch_dates,
  COUNTIF(launch_date IS NULL)                       AS null_launch_date_count,
  COUNTIF(launch_date = 0)                           AS zero_launch_date_count,
  COUNT(*)                                           AS total_rows,
  APPROX_QUANTILES(launch_date, 10)                  AS launch_date_deciles
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`;


-- -----------------------------------------------------------------------------
-- Q7 (bonus): color_family values (INT64 - suspicious, suggests family_id)
-- Purpose: color_family is INT64 not STRING. See top distinct values.
--         If only a handful of integer codes, there's probably a lookup table
--         or the names are in a different column (color_description?).
-- -----------------------------------------------------------------------------
SELECT
  color_family,
  COUNT(*) AS row_count
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
GROUP BY color_family
ORDER BY row_count DESC
LIMIT 30;
