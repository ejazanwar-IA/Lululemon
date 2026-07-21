-- =============================================================================
-- Inventory Master EDA - Phase 1 CONSOLIDATED
--
-- Table: lululemon-01042025.lululemon_souricng_outbound.inventory_master
--        (7.2B rows, 650 GB) — partitioned by date, clustered by store_code
--
-- 9 queries, single consolidated output. ~650 GB scanned once across CTEs.
-- =============================================================================

WITH

-- ========== Q1: Date range + yearly distribution ==========
q1_summary AS (
  SELECT
    COUNT(*) AS total_rows,
    MIN(date) AS min_date,
    MAX(date) AS max_date,
    COUNT(DISTINCT date) AS distinct_dates,
    DATE_DIFF(MAX(date), MIN(date), DAY) + 1 AS span_days
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
),
q1_yearly AS (
  SELECT
    EXTRACT(YEAR FROM date) AS year,
    COUNT(*) AS rows_in_year,
    COUNT(DISTINCT date) AS distinct_dates,
    MIN(date) AS min_date_in_year,
    MAX(date) AS max_date_in_year
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
  GROUP BY year
  ORDER BY year
),
q1 AS (
  SELECT
    'Q1' AS query_id,
    'Date range + yearly row distribution' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT AS STRUCT * FROM q1_summary) AS summary,
      (SELECT ARRAY_AGG(STRUCT(year, rows_in_year, distinct_dates, min_date_in_year, max_date_in_year) ORDER BY year) FROM q1_yearly) AS by_year
    )) AS results_json
),

-- ========== Q2: Null counts per column ==========
q2 AS (
  SELECT
    'Q2' AS query_id,
    'Null counts per column' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      -- STRING (null / '' / '\N')
      COUNTIF(brand IS NULL OR brand = '' OR brand = '\\N') AS null_brand,
      COUNTIF(store_code IS NULL OR store_code = '' OR store_code = '\\N') AS null_store_code,
      COUNTIF(product_code IS NULL OR product_code = '' OR product_code = '\\N') AS null_product_code,
      -- DATE
      COUNTIF(date IS NULL) AS null_date,
      -- INT64
      COUNTIF(oh IS NULL) AS null_oh,
      COUNTIF(it IS NULL) AS null_it,
      COUNTIF(oo IS NULL) AS null_oo,
      COUNTIF(wip IS NULL) AS null_wip,
      COUNTIF(initial_oh_quantity IS NULL) AS null_initial_oh_quantity,
      COUNTIF(total_units IS NULL) AS null_total_units
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
),

-- ========== Q3: Distinct counts ==========
q3 AS (
  SELECT
    'Q3' AS query_id,
    'Distinct counts (store, product, brand)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      APPROX_COUNT_DISTINCT(store_code) AS distinct_store_code,
      APPROX_COUNT_DISTINCT(product_code) AS distinct_product_code,
      APPROX_COUNT_DISTINCT(brand) AS distinct_brand,
      APPROX_COUNT_DISTINCT(CONCAT(COALESCE(store_code, ''), '|', COALESCE(product_code, ''))) AS distinct_store_product_pairs
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
),

-- ========== Q4: Quantity distributions ==========
q4 AS (
  SELECT
    'Q4' AS query_id,
    'Quantity distributions (oh/it/oo/wip/total_units/initial_oh_quantity)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      -- oh
      COUNTIF(oh < 0) AS oh_negative,
      COUNTIF(oh = 0) AS oh_zero,
      COUNTIF(oh > 0) AS oh_positive,
      MIN(oh) AS oh_min,
      MAX(oh) AS oh_max,
      APPROX_QUANTILES(oh, 10) AS oh_deciles,
      -- it
      COUNTIF(it < 0) AS it_negative,
      COUNTIF(it = 0) AS it_zero,
      COUNTIF(it > 0) AS it_positive,
      MIN(it) AS it_min,
      MAX(it) AS it_max,
      -- oo
      COUNTIF(oo < 0) AS oo_negative,
      COUNTIF(oo = 0) AS oo_zero,
      COUNTIF(oo > 0) AS oo_positive,
      MIN(oo) AS oo_min,
      MAX(oo) AS oo_max,
      -- wip
      COUNTIF(wip < 0) AS wip_negative,
      COUNTIF(wip = 0) AS wip_zero,
      COUNTIF(wip > 0) AS wip_positive,
      MIN(wip) AS wip_min,
      MAX(wip) AS wip_max,
      -- total_units
      COUNTIF(total_units < 0) AS total_units_negative,
      COUNTIF(total_units = 0) AS total_units_zero,
      COUNTIF(total_units > 0) AS total_units_positive,
      MIN(total_units) AS total_units_min,
      MAX(total_units) AS total_units_max,
      APPROX_QUANTILES(total_units, 10) AS total_units_deciles,
      -- initial_oh_quantity
      COUNTIF(initial_oh_quantity < 0) AS init_oh_negative,
      COUNTIF(initial_oh_quantity = 0) AS init_oh_zero,
      COUNTIF(initial_oh_quantity > 0) AS init_oh_positive,
      MIN(initial_oh_quantity) AS init_oh_min,
      MAX(initial_oh_quantity) AS init_oh_max,
      -- All-zero rows
      COUNTIF(oh = 0 AND it = 0 AND oo = 0 AND wip = 0) AS all_four_zero,
      COUNTIF(oh = 0 AND it = 0 AND oo = 0 AND wip = 0 AND total_units = 0) AS all_five_zero
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
),

-- ========== Q5: Math validation — total_units = oh + it + oo + wip? ==========
q5 AS (
  SELECT
    'Q5' AS query_id,
    'Math validation: total_units = oh + it + oo + wip?' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(total_units = oh + it + oo + wip) AS rows_matching_sum,
      COUNTIF(total_units != oh + it + oo + wip) AS rows_mismatching_sum,
      COUNTIF(total_units = oh) AS rows_where_total_equals_oh_only,
      COUNTIF(total_units = oh + initial_oh_quantity) AS rows_where_total_equals_oh_plus_initial
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
  WHERE total_units IS NOT NULL
    AND oh IS NOT NULL AND it IS NOT NULL AND oo IS NOT NULL AND wip IS NOT NULL
),

-- ========== Q6: Grain test ==========
-- Is (date, store_code, product_code) the unique key?
q6 AS (
  SELECT
    'Q6' AS query_id,
    'Grain test: is (date, store_code, product_code) unique?' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      APPROX_COUNT_DISTINCT(CONCAT(CAST(date AS STRING), '|', COALESCE(store_code, ''), '|', COALESCE(product_code, ''))) AS distinct_triples_approx
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
),

-- ========== Q7: Cross-table orphans ==========
-- Build small distinct sets from inventory; check which are missing from masters.
inv_products AS (
  SELECT DISTINCT product_code
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
  WHERE product_code IS NOT NULL
),
inv_stores AS (
  SELECT DISTINCT store_code
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
  WHERE store_code IS NOT NULL
),
pm_products AS (
  SELECT DISTINCT product_code
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE product_code IS NOT NULL
),
sm_stores AS (
  SELECT DISTINCT store_code
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  WHERE store_code IS NOT NULL
),
q7 AS (
  SELECT
    'Q7' AS query_id,
    'Cross-table orphans vs product_master and store_master' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT COUNT(*) FROM inv_products) AS inv_distinct_products,
      (SELECT COUNT(*) FROM pm_products) AS pm_distinct_products,
      (SELECT COUNT(*) FROM inv_products i LEFT JOIN pm_products p ON i.product_code = p.product_code WHERE p.product_code IS NULL) AS orphan_products_in_inv,
      (SELECT COUNT(*) FROM pm_products p LEFT JOIN inv_products i ON p.product_code = i.product_code WHERE i.product_code IS NULL) AS pm_products_never_in_inv,
      (SELECT COUNT(*) FROM inv_stores) AS inv_distinct_stores,
      (SELECT COUNT(*) FROM sm_stores) AS sm_distinct_stores,
      (SELECT COUNT(*) FROM inv_stores i LEFT JOIN sm_stores s ON i.store_code = s.store_code WHERE s.store_code IS NULL) AS orphan_stores_in_inv,
      (SELECT COUNT(*) FROM sm_stores s LEFT JOIN inv_stores i ON s.store_code = i.store_code WHERE i.store_code IS NULL) AS sm_stores_never_in_inv
    )) AS results_json
),

-- ========== Q8: Brand distribution ==========
q8_rows AS (
  SELECT brand, COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
  GROUP BY brand
  ORDER BY row_count DESC
),
q8 AS (
  SELECT
    'Q8' AS query_id,
    'Brand distribution' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(brand, row_count))) AS results_json
  FROM q8_rows
),

-- ========== Q9: Sanity checks ==========
-- Combines five sanity checks off a single per-date aggregation:
--   (a) date continuity        — list dates in [min, max] with zero rows
--   (b) recency / freshness    — days_since_max_date + last 14 days of activity
--   (c) row-count anomalies    — dates >3 stddev from mean daily row_count
--   (d) channel-suffix coverage — % product_code ending in _ECOMM / _RETAIL / other / null
--   (e) store-coverage stability — dates where distinct_stores < median - 3*stddev
-- Multi-level aggregation is split into per_date → overall (per G4).
q9_per_date AS (
  SELECT
    date,
    COUNT(*) AS row_count,
    COUNT(DISTINCT store_code) AS distinct_stores,
    COUNTIF(ENDS_WITH(product_code, '_ECOMM')) AS rows_ecomm,
    COUNTIF(ENDS_WITH(product_code, '_RETAIL')) AS rows_retail,
    COUNTIF(product_code IS NOT NULL
            AND NOT ENDS_WITH(product_code, '_ECOMM')
            AND NOT ENDS_WITH(product_code, '_RETAIL')) AS rows_other_suffix,
    COUNTIF(product_code IS NULL) AS rows_null_pc
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
  GROUP BY date
),
q9_overall AS (
  SELECT
    MIN(date) AS min_date,
    MAX(date) AS max_date,
    COUNT(*) AS distinct_dates,
    DATE_DIFF(MAX(date), MIN(date), DAY) + 1 AS span_days,
    APPROX_QUANTILES(row_count, 100)[OFFSET(50)] AS median_row_count,
    AVG(row_count) AS mean_row_count,
    STDDEV(row_count) AS stddev_row_count,
    APPROX_QUANTILES(distinct_stores, 100)[OFFSET(50)] AS median_stores,
    STDDEV(distinct_stores) AS stddev_stores,
    SUM(row_count) AS total_rows,
    SUM(rows_ecomm) AS total_ecomm,
    SUM(rows_retail) AS total_retail,
    SUM(rows_other_suffix) AS total_other_suffix,
    SUM(rows_null_pc) AS total_null_pc
  FROM q9_per_date
),
q9_all_dates AS (
  SELECT d AS date_in_range
  FROM q9_overall, UNNEST(GENERATE_DATE_ARRAY(min_date, max_date)) AS d
),
q9_missing_dates AS (
  SELECT a.date_in_range AS missing_date
  FROM q9_all_dates a
  LEFT JOIN q9_per_date pd ON pd.date = a.date_in_range
  WHERE pd.date IS NULL
),
q9_recent AS (
  SELECT pd.date, pd.row_count, pd.distinct_stores
  FROM q9_per_date pd, q9_overall o
  WHERE pd.date >= DATE_SUB(o.max_date, INTERVAL 13 DAY)
),
q9_rowcount_anomalies AS (
  SELECT pd.date, pd.row_count
  FROM q9_per_date pd, q9_overall o
  WHERE o.stddev_row_count IS NOT NULL
    AND ABS(pd.row_count - o.mean_row_count) > 3 * o.stddev_row_count
),
q9_low_store_coverage AS (
  SELECT pd.date, pd.distinct_stores
  FROM q9_per_date pd, q9_overall o
  WHERE o.stddev_stores IS NOT NULL
    AND pd.distinct_stores < o.median_stores - 3 * o.stddev_stores
),
q9 AS (
  SELECT
    'Q9' AS query_id,
    'Sanity checks: date continuity / recency / row-count anomalies / suffix coverage / store coverage' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT AS STRUCT
        min_date,
        max_date,
        distinct_dates,
        span_days,
        span_days - distinct_dates AS missing_date_count,
        DATE_DIFF(CURRENT_DATE(), max_date, DAY) AS days_since_max_date,
        median_row_count,
        mean_row_count,
        stddev_row_count,
        median_stores,
        stddev_stores,
        total_rows,
        total_ecomm,
        total_retail,
        total_other_suffix,
        total_null_pc,
        SAFE_DIVIDE(total_ecomm, total_rows) AS pct_ecomm,
        SAFE_DIVIDE(total_retail, total_rows) AS pct_retail,
        SAFE_DIVIDE(total_other_suffix, total_rows) AS pct_other_suffix,
        SAFE_DIVIDE(total_null_pc, total_rows) AS pct_null_pc
       FROM q9_overall) AS summary,
      (SELECT COUNT(*) FROM q9_missing_dates) AS missing_dates_total,
      (SELECT ARRAY_AGG(missing_date ORDER BY missing_date LIMIT 50) FROM q9_missing_dates) AS missing_dates_first_50,
      (SELECT ARRAY_AGG(STRUCT(date, row_count, distinct_stores) ORDER BY date) FROM q9_recent) AS recent_14_days,
      (SELECT ARRAY_AGG(STRUCT(date, row_count) ORDER BY date) FROM q9_rowcount_anomalies) AS rowcount_anomalies,
      (SELECT ARRAY_AGG(STRUCT(date, distinct_stores) ORDER BY date) FROM q9_low_store_coverage) AS low_store_coverage_days
    )) AS results_json
)

SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
UNION ALL SELECT * FROM q5
UNION ALL SELECT * FROM q6
UNION ALL SELECT * FROM q7
UNION ALL SELECT * FROM q8
UNION ALL SELECT * FROM q9
ORDER BY query_id;
