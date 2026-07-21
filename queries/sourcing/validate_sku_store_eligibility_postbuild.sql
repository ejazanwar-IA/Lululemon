-- =============================================================================
-- Post-build validation for sku_store_eligibility (read-only)
-- Run after create_sku_store_eligibility_weekly.sql
-- Billing: lululemon-data-scan
-- =============================================================================

-- V3) Output grain and volume
SELECT
  COUNT(*) AS rows,
  COUNT(DISTINCT product_code) AS distinct_skus,
  COUNT(DISTINCT store_code) AS distinct_stores,
  COUNT(DISTINCT week_id) AS distinct_weeks,
  COUNT(DISTINCT CONCAT(product_code, '|', store_code)) AS sku_store_pairs,
  COUNT(DISTINCT CONCAT(product_code, '|', store_code, '|', CAST(week_id AS STRING))) AS grain_groups,
  COUNT(*) - COUNT(DISTINCT CONCAT(product_code, '|', store_code, '|', CAST(week_id AS STRING))) AS duplicate_grain_rows
FROM `lululemon-01042025.lulu_sourcing_dev.sku_store_eligibility`;


-- V4) Week-level output density
SELECT
  week_id,
  COUNT(*) AS rows,
  COUNT(DISTINCT CONCAT(product_code, '|', store_code)) AS sku_store_pairs
FROM `lululemon-01042025.lulu_sourcing_dev.sku_store_eligibility`
GROUP BY 1
ORDER BY 1;


-- V5) Intersect shrinkage: eligibility-only vs final (current week snapshot)
WITH current_ctx AS (
  SELECT CAST(WEEK_ID AS INT64) AS current_week
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
  WHERE DAY_ID = CURRENT_DATE()
  LIMIT 1
),
elig_current AS (
  SELECT COUNT(DISTINCT CONCAT(pso, '|', store_code)) AS pairs
  FROM (
    SELECT
      TRIM(e.PLANNING_STYLE_OPTION_ID) AS pso,
      LPAD(TRIM(CAST(e.STORE_ID AS STRING)), 10, '0') AS store_code
    FROM `lululemon-01042025.lulu_sourcing_dev.eligibility` e
    CROSS JOIN current_ctx c
    WHERE CAST(e.WEEK_ID AS INT64) = c.current_week
      AND TRIM(e.PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
  )
),
built_current AS (
  SELECT COUNT(DISTINCT CONCAT(product_code, '|', store_code)) AS pairs
  FROM `lululemon-01042025.lulu_sourcing_dev.sku_store_eligibility` s
  CROSS JOIN current_ctx c
  WHERE s.week_id = c.current_week
)
SELECT
  e.pairs AS elig_pso_store_current_week,
  b.pairs AS built_sku_store_current_week,
  ROUND(100 * b.pairs / NULLIF(e.pairs, 0), 2) AS built_pct_of_elig_pso_store
FROM elig_current e
CROSS JOIN built_current b;
