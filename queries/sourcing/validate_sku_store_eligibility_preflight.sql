-- =============================================================================
-- Preflight validation for sku_store_eligibility build (read-only)
-- Run before create_sku_store_eligibility_weekly.sql
-- Billing: lululemon-data-scan
-- =============================================================================

-- V0) Prerequisites: input tables landed
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 2) AS size_gb
FROM `lululemon-01042025.lulu_sourcing_dev.__TABLES__`
WHERE table_id IN (
  'eligibility',
  'assortment_plan',
  'style_option',
  'product_group_hierarchy_cleaned',
  'product_intermediate',
  'store_intermediate',
  'calendar_hierarchy'
)
ORDER BY table_id;


-- V1) 26-week horizon: eligibility week coverage
WITH current_ctx AS (
  SELECT CAST(WEEK_ID AS INT64) AS current_week
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
  WHERE DAY_ID = CURRENT_DATE()
  LIMIT 1
),
horizon_weeks AS (
  SELECT DISTINCT CAST(ch.WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy` ch
  CROSS JOIN current_ctx c
  WHERE CAST(ch.WEEK_ID AS INT64) >= c.current_week
    AND ch.DAY_ID BETWEEN CURRENT_DATE()
                      AND DATE_ADD(CURRENT_DATE(), INTERVAL 26 WEEK)
),
elig_by_week AS (
  SELECT
    CAST(e.WEEK_ID AS INT64) AS week_id,
    COUNT(DISTINCT CONCAT(
      TRIM(e.PLANNING_STYLE_OPTION_ID), '|',
      LPAD(TRIM(CAST(e.STORE_ID AS STRING)), 10, '0')
    )) AS pso_store_pairs
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility` e
  INNER JOIN horizon_weeks hw
    ON CAST(e.WEEK_ID AS INT64) = hw.week_id
  WHERE TRIM(e.PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
  GROUP BY 1
)
SELECT
  (SELECT current_week FROM current_ctx) AS current_week,
  (SELECT COUNT(*) FROM horizon_weeks) AS weeks_in_horizon,
  COUNTIF(e.pso_store_pairs > 0) AS horizon_weeks_with_eligibility,
  COUNTIF(e.pso_store_pairs IS NULL OR e.pso_store_pairs = 0) AS horizon_weeks_missing,
  ROUND(AVG(e.pso_store_pairs), 0) AS avg_pso_store_pairs,
  MIN(e.pso_store_pairs) AS min_pso_store_pairs,
  MAX(e.pso_store_pairs) AS max_pso_store_pairs
FROM horizon_weeks h
LEFT JOIN elig_by_week e ON h.week_id = e.week_id;


-- V2) Assortment gate health (requires assortment_plan loaded)
WITH ap AS (
  SELECT
    COUNT(*) AS rows,
    COUNTIF(ASSORT_TO_STORE) AS assort_true_rows,
    COUNT(DISTINCT CONCAT(TRIM(STYLE_OPTION_ID), '|', CAST(STORE_ID AS STRING))) AS style_store_pairs
  FROM `lululemon-01042025.lulu_sourcing_dev.assortment_plan`
),
expanded AS (
  SELECT
    COALESCE(
      NULLIF(TRIM(so.PLANNING_STYLE_OPTION_ID), ''),
      TRIM(ap.STYLE_OPTION_ID)
    ) AS pso,
    TRIM(size_token) AS size_name
  FROM `lululemon-01042025.lulu_sourcing_dev.assortment_plan` ap
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON TRIM(ap.STYLE_OPTION_ID) = TRIM(so.STYLE_OPTION_ID)
  CROSS JOIN UNNEST(SPLIT(ap.FLEX_SIZE_VALUE, ',')) AS size_token
  WHERE ap.ASSORT_TO_STORE
    AND TRIM(size_token) NOT IN ('', '\\N')
),
pgh_match AS (
  SELECT
    COUNT(*) AS ap_pso_size_rows,
    COUNTIF(pgh.SKU_ID IS NOT NULL) AS matched_to_pgh
  FROM expanded e
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy_cleaned` pgh
    ON e.pso = TRIM(pgh.PLANNING_STYLE_OPTION_CODE)
   AND e.size_name = TRIM(pgh.PLANNING_STYLE_SIZE_NAME)
)
SELECT
  ap.rows,
  ap.assort_true_rows,
  ap.style_store_pairs,
  pm.ap_pso_size_rows,
  pm.matched_to_pgh,
  ROUND(100 * pm.matched_to_pgh / NULLIF(pm.ap_pso_size_rows, 0), 2) AS pgh_match_pct
FROM ap
CROSS JOIN pgh_match pm;
