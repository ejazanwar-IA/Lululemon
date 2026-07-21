-- =============================================================================
-- Sales vs Eligibility Reconciliation (PSO x store x week) — RAW SOURCES
-- Sources:
--   lulu_sourcing_dev.sales_transactions (SKU x store x date)
--   lulu_sourcing_dev.product_group_hierarchy (SKU -> PSO)
--   lulu_sourcing_dev.calendar_hierarchy (date -> WEEK_ID)
--   lulu_sourcing_dev.eligibility (PLANNING_STYLE_OPTION_ID x STORE_ID x WEEK_ID)
-- Default window: 2025-01-01 to 2025-12-31 (adjust params CTE)
-- Real-sales filter: SAFE_CAST(UNITS) > 0 AND SAFE_CAST(PRICE_SALES_TOTAL) > 0
-- Dedup: eligibility GROUP BY (pso, store_id, week_id) only
-- Verified pattern: 2026-07-06 (raw tables)
-- =============================================================================

-- K0) Sanity: sample sales keys with calendar week + eligibility match flag
WITH params AS (
  SELECT DATE '2025-01-01' AS start_date, DATE '2025-12-31' AS end_date
),
cal AS (
  SELECT DAY_ID AS txn_date, CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
sales AS (
  SELECT
    ps.pso,
    TRIM(LTRIM(CAST(t.LOCATION_ID_SALES AS STRING), '0')) AS store_id,
    c.week_id,
    MIN(SAFE_CAST(t.DATE_TRANSACTION AS DATE)) AS sample_txn_date,
    SUM(SAFE_CAST(t.UNITS AS FLOAT64)) AS units,
    SUM(SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64)) AS revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions` t, params p
  INNER JOIN cal c ON SAFE_CAST(t.DATE_TRANSACTION AS DATE) = c.txn_date
  INNER JOIN pso_sku ps ON TRIM(t.SKU_ID) = ps.sku_id
  WHERE SAFE_CAST(t.DATE_TRANSACTION AS DATE) BETWEEN p.start_date AND p.end_date
    AND SAFE_CAST(t.UNITS AS FLOAT64) > 0
    AND SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64) > 0
  GROUP BY 1, 2, 3
),
elig AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
  GROUP BY 1, 2, 3
),
top_sales AS (
  SELECT *
  FROM sales
  ORDER BY units DESC
  LIMIT 5
)
SELECT
  s.pso,
  s.store_id,
  s.week_id,
  s.sample_txn_date,
  cal_check.week_id AS calendar_week_from_date,
  s.units,
  s.revenue,
  e.pso IS NOT NULL AS has_eligibility_row
FROM top_sales s
LEFT JOIN cal cal_check ON s.sample_txn_date = cal_check.txn_date
LEFT JOIN elig e
  ON s.pso = e.pso
  AND s.store_id = e.store_id
  AND s.week_id = e.week_id
ORDER BY s.units DESC;


-- K1) Summary: sales keys / units / revenue with vs without eligibility match
WITH params AS (
  SELECT DATE '2025-01-01' AS start_date, DATE '2025-12-31' AS end_date
),
cal AS (
  SELECT DAY_ID AS txn_date, CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
sales AS (
  SELECT
    ps.pso,
    TRIM(LTRIM(CAST(t.LOCATION_ID_SALES AS STRING), '0')) AS store_id,
    c.week_id,
    SUM(SAFE_CAST(t.UNITS AS FLOAT64)) AS units,
    SUM(SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64)) AS revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions` t, params p
  INNER JOIN cal c ON SAFE_CAST(t.DATE_TRANSACTION AS DATE) = c.txn_date
  INNER JOIN pso_sku ps ON TRIM(t.SKU_ID) = ps.sku_id
  WHERE SAFE_CAST(t.DATE_TRANSACTION AS DATE) BETWEEN p.start_date AND p.end_date
    AND SAFE_CAST(t.UNITS AS FLOAT64) > 0
    AND SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64) > 0
  GROUP BY 1, 2, 3
),
elig AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
  GROUP BY 1, 2, 3
),
joined AS (
  SELECT
    s.*,
    e.pso IS NOT NULL AS is_eligible
  FROM sales s
  LEFT JOIN elig e
    ON s.pso = e.pso
    AND s.store_id = e.store_id
    AND s.week_id = e.week_id
)
SELECT
  COUNT(*) AS distinct_sales_keys,
  COUNTIF(is_eligible) AS eligible_keys,
  COUNTIF(NOT is_eligible) AS ineligible_keys,
  ROUND(100 * COUNTIF(is_eligible) / COUNT(*), 2) AS pct_keys_eligible,
  ROUND(100 * COUNTIF(NOT is_eligible) / COUNT(*), 2) AS pct_keys_ineligible,
  SUM(units) AS total_units,
  SUM(IF(is_eligible, units, 0)) AS eligible_units,
  SUM(IF(NOT is_eligible, units, 0)) AS ineligible_units,
  ROUND(100 * SUM(IF(is_eligible, units, 0)) / SUM(units), 2) AS pct_units_eligible,
  ROUND(100 * SUM(IF(NOT is_eligible, units, 0)) / SUM(units), 2) AS pct_units_ineligible,
  SUM(revenue) AS total_revenue,
  SUM(IF(is_eligible, revenue, 0)) AS eligible_revenue,
  SUM(IF(NOT is_eligible, revenue, 0)) AS ineligible_revenue,
  ROUND(100 * SUM(IF(is_eligible, revenue, 0)) / SUM(revenue), 2) AS pct_revenue_eligible,
  ROUND(100 * SUM(IF(NOT is_eligible, revenue, 0)) / SUM(revenue), 2) AS pct_revenue_ineligible
FROM joined;


-- K2) Violations sample: top ineligible sales keys by units
WITH params AS (
  SELECT DATE '2025-01-01' AS start_date, DATE '2025-12-31' AS end_date
),
cal AS (
  SELECT DAY_ID AS txn_date, CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
sales AS (
  SELECT
    ps.pso,
    TRIM(LTRIM(CAST(t.LOCATION_ID_SALES AS STRING), '0')) AS store_id,
    c.week_id,
    SUM(SAFE_CAST(t.UNITS AS FLOAT64)) AS units,
    SUM(SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64)) AS revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions` t, params p
  INNER JOIN cal c ON SAFE_CAST(t.DATE_TRANSACTION AS DATE) = c.txn_date
  INNER JOIN pso_sku ps ON TRIM(t.SKU_ID) = ps.sku_id
  WHERE SAFE_CAST(t.DATE_TRANSACTION AS DATE) BETWEEN p.start_date AND p.end_date
    AND SAFE_CAST(t.UNITS AS FLOAT64) > 0
    AND SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64) > 0
  GROUP BY 1, 2, 3
),
elig AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
  GROUP BY 1, 2, 3
),
violations AS (
  SELECT s.*
  FROM sales s
  LEFT JOIN elig e
    ON s.pso = e.pso
    AND s.store_id = e.store_id
    AND s.week_id = e.week_id
  WHERE e.pso IS NULL
)
SELECT
  pso,
  store_id,
  week_id,
  units,
  revenue
FROM violations
ORDER BY units DESC
LIMIT 25;


-- K3) Reverse coverage: eligibility keys in 2025 weeks with zero sales
WITH params AS (
  SELECT DATE '2025-01-01' AS start_date, DATE '2025-12-31' AS end_date
),
cal AS (
  SELECT DAY_ID AS txn_date, CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
  WHERE DAY_ID BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
),
weeks_2025 AS (
  SELECT DISTINCT week_id FROM cal
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
sales AS (
  SELECT
    ps.pso,
    TRIM(LTRIM(CAST(t.LOCATION_ID_SALES AS STRING), '0')) AS store_id,
    c.week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions` t, params p
  INNER JOIN cal c ON SAFE_CAST(t.DATE_TRANSACTION AS DATE) = c.txn_date
  INNER JOIN pso_sku ps ON TRIM(t.SKU_ID) = ps.sku_id
  WHERE SAFE_CAST(t.DATE_TRANSACTION AS DATE) BETWEEN p.start_date AND p.end_date
    AND SAFE_CAST(t.UNITS AS FLOAT64) > 0
    AND SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64) > 0
  GROUP BY 1, 2, 3
),
elig AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
    AND CAST(WEEK_ID AS INT64) IN (SELECT week_id FROM weeks_2025)
  GROUP BY 1, 2, 3
),
joined AS (
  SELECT
    e.*,
    s.pso IS NOT NULL AS has_sales
  FROM elig e
  LEFT JOIN sales s
    ON e.pso = s.pso
    AND e.store_id = s.store_id
    AND e.week_id = s.week_id
)
SELECT
  COUNT(*) AS distinct_elig_keys_2025_weeks,
  COUNTIF(has_sales) AS elig_keys_with_sales,
  COUNTIF(NOT has_sales) AS elig_keys_without_sales,
  ROUND(100 * COUNTIF(has_sales) / COUNT(*), 2) AS pct_elig_with_sales,
  ROUND(100 * COUNTIF(NOT has_sales) / COUNT(*), 2) AS pct_elig_without_sales
FROM joined;


-- K4) Match rate by fiscal week (2025)
WITH params AS (
  SELECT DATE '2025-01-01' AS start_date, DATE '2025-12-31' AS end_date
),
cal AS (
  SELECT DAY_ID AS txn_date, CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
sales AS (
  SELECT
    ps.pso,
    TRIM(LTRIM(CAST(t.LOCATION_ID_SALES AS STRING), '0')) AS store_id,
    c.week_id,
    SUM(SAFE_CAST(t.UNITS AS FLOAT64)) AS units,
    SUM(SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64)) AS revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions` t, params p
  INNER JOIN cal c ON SAFE_CAST(t.DATE_TRANSACTION AS DATE) = c.txn_date
  INNER JOIN pso_sku ps ON TRIM(t.SKU_ID) = ps.sku_id
  WHERE SAFE_CAST(t.DATE_TRANSACTION AS DATE) BETWEEN p.start_date AND p.end_date
    AND SAFE_CAST(t.UNITS AS FLOAT64) > 0
    AND SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64) > 0
  GROUP BY 1, 2, 3
),
elig AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
  GROUP BY 1, 2, 3
),
joined AS (
  SELECT
    s.*,
    e.pso IS NOT NULL AS is_eligible
  FROM sales s
  LEFT JOIN elig e
    ON s.pso = e.pso
    AND s.store_id = e.store_id
    AND s.week_id = e.week_id
)
SELECT
  week_id,
  COUNT(*) AS sales_keys,
  COUNTIF(is_eligible) AS eligible_keys,
  ROUND(100 * COUNTIF(is_eligible) / COUNT(*), 2) AS pct_keys_eligible,
  SUM(units) AS units,
  ROUND(100 * SUM(IF(is_eligible, units, 0)) / SUM(units), 2) AS pct_units_eligible
FROM joined
GROUP BY 1
ORDER BY 1;


-- K5) Ineligible sales by store TYPE_CODE (location_details)
WITH params AS (
  SELECT DATE '2025-01-01' AS start_date, DATE '2025-12-31' AS end_date
),
cal AS (
  SELECT DAY_ID AS txn_date, CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
    AND TRIM(VALUE_CODE) NOT IN ('', '\\N')
    AND TRIM(SKU_ID) NOT IN ('', '\\N')
),
sales AS (
  SELECT
    ps.pso,
    TRIM(LTRIM(CAST(t.LOCATION_ID_SALES AS STRING), '0')) AS store_id,
    c.week_id,
    SUM(SAFE_CAST(t.UNITS AS FLOAT64)) AS units,
    SUM(SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64)) AS revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions` t, params p
  INNER JOIN cal c ON SAFE_CAST(t.DATE_TRANSACTION AS DATE) = c.txn_date
  INNER JOIN pso_sku ps ON TRIM(t.SKU_ID) = ps.sku_id
  WHERE SAFE_CAST(t.DATE_TRANSACTION AS DATE) BETWEEN p.start_date AND p.end_date
    AND SAFE_CAST(t.UNITS AS FLOAT64) > 0
    AND SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64) > 0
  GROUP BY 1, 2, 3
),
elig AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE TRIM(PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(STORE_ID AS STRING)) NOT IN ('', '\\N')
  GROUP BY 1, 2, 3
),
violations AS (
  SELECT s.*
  FROM sales s
  LEFT JOIN elig e
    ON s.pso = e.pso
    AND s.store_id = e.store_id
    AND s.week_id = e.week_id
  WHERE e.pso IS NULL
),
loc AS (
  SELECT TRIM(ID) AS store_id, TYPE_CODE
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
)
SELECT
  COALESCE(l.TYPE_CODE, '<no_location_match>') AS type_code,
  COUNT(*) AS ineligible_keys,
  SUM(v.units) AS ineligible_units,
  SUM(v.revenue) AS ineligible_revenue,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_ineligible_keys,
  ROUND(100 * SUM(v.units) / SUM(SUM(v.units)) OVER (), 2) AS pct_of_ineligible_units
FROM violations v
LEFT JOIN loc l ON v.store_id = l.store_id
GROUP BY 1
ORDER BY ineligible_units DESC;


-- K6) Ad-hoc spot check: parameterize (pso, store_id, week_id)
-- Example: uncomment and set values before running.
/*
WITH params AS (
  SELECT
    'LU9ADVS-036716' AS pso,
    '10110' AS store_id,
    202526 AS week_id
),
cal AS (
  SELECT DAY_ID AS txn_date, CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
),
pso_sku AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS pso, TRIM(SKU_ID) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'PLANNING_STYLE_OPTION'
),
sales AS (
  SELECT
    ps.pso,
    TRIM(LTRIM(CAST(t.LOCATION_ID_SALES AS STRING), '0')) AS store_id,
    c.week_id,
    SUM(SAFE_CAST(t.UNITS AS FLOAT64)) AS units,
    SUM(SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64)) AS revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions` t
  INNER JOIN cal c ON SAFE_CAST(t.DATE_TRANSACTION AS DATE) = c.txn_date
  INNER JOIN pso_sku ps ON TRIM(t.SKU_ID) = ps.sku_id
  WHERE SAFE_CAST(t.UNITS AS FLOAT64) > 0
    AND SAFE_CAST(t.PRICE_SALES_TOTAL AS FLOAT64) > 0
  GROUP BY 1, 2, 3
),
elig AS (
  SELECT
    TRIM(PLANNING_STYLE_OPTION_ID) AS pso,
    TRIM(LTRIM(CAST(STORE_ID AS STRING), '0')) AS store_id,
    CAST(WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  GROUP BY 1, 2, 3
)
SELECT
  p.pso,
  p.store_id,
  p.week_id,
  s.units AS sales_units,
  s.revenue AS sales_revenue,
  e.pso IS NOT NULL AS has_eligibility_row
FROM params p
LEFT JOIN sales s
  ON p.pso = s.pso AND p.store_id = s.store_id AND p.week_id = s.week_id
LEFT JOIN elig e
  ON p.pso = e.pso AND p.store_id = e.store_id AND p.week_id = e.week_id;
*/
