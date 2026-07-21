-- Inventory raw distribution EDA
-- Source: lululemon-01042025.lulu_sourcing_dev.inventory_snapshot
-- Billing project: lululemon-data-scan
-- Rules: read-only SELECT statements only. No DDL, DML, temp tables, or writes.
--
-- Run one section at a time with:
--   bq query --project_id=lululemon-data-scan --use_legacy_sql=false <section_sql>

-- INV_DIST_01_BEGIN
-- Castability, keys, sign buckets, sentinels, and high-level shape.
WITH typed AS (
  SELECT
    SKU_ID,
    LOCATION_ID,
    SAFE_CAST(`DATE` AS DATE) AS snap_date,
    SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) AS snapshot_ts,
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS inb,
    `DATE` AS raw_date,
    SNAPSHOT_TIME AS raw_snapshot_time,
    UNITS_ON_HAND AS raw_oh,
    UNITS_AVAILABLE AS raw_av,
    UNITS_INBOUND AS raw_inb
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
)
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT snap_date) AS distinct_dates,
  MIN(snap_date) AS min_date,
  MAX(snap_date) AS max_date,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNTIF(SKU_ID IS NULL OR SKU_ID = '' OR SKU_ID = '\\N') AS sku_missing,
  COUNTIF(LOCATION_ID IS NULL OR LOCATION_ID = '' OR LOCATION_ID = '\\N') AS location_missing,
  COUNTIF(snap_date IS NULL) AS date_bad_cast,
  COUNTIF(snapshot_ts IS NULL) AS snapshot_time_bad_cast,
  COUNTIF(oh IS NULL) AS oh_bad_cast,
  COUNTIF(av IS NULL) AS av_bad_cast,
  COUNTIF(inb IS NULL) AS inb_bad_cast,
  COUNTIF(oh = -1) AS oh_sentinel_neg_one,
  COUNTIF(oh < -1) AS oh_real_negative,
  COUNTIF(oh = 0) AS oh_zero,
  COUNTIF(oh > 0) AS oh_positive,
  COUNTIF(av = -1) AS av_sentinel_neg_one,
  COUNTIF(av < -1) AS av_real_negative,
  COUNTIF(av = 0) AS av_zero,
  COUNTIF(av > 0) AS av_positive,
  COUNTIF(inb < 0) AS inb_negative,
  COUNTIF(inb = 0) AS inb_zero,
  COUNTIF(inb > 0) AS inb_positive,
  MIN(oh) AS oh_min,
  MAX(oh) AS oh_max,
  MIN(av) AS av_min,
  MAX(av) AS av_max,
  MIN(inb) AS inb_min,
  MAX(inb) AS inb_max
FROM typed;
-- INV_DIST_01_END

-- INV_DIST_02_BEGIN
-- Full-table distributions, including sentinel and negative values.
WITH typed AS (
  SELECT
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS inb
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
),
q AS (
  SELECT
    COUNT(*) AS total_rows,
    AVG(oh) AS oh_avg,
    STDDEV(oh) AS oh_stddev,
    MIN(oh) AS oh_min,
    MAX(oh) AS oh_max,
    APPROX_QUANTILES(oh, 1000) AS oh_q,
    AVG(av) AS av_avg,
    STDDEV(av) AS av_stddev,
    MIN(av) AS av_min,
    MAX(av) AS av_max,
    APPROX_QUANTILES(av, 1000) AS av_q,
    AVG(inb) AS inb_avg,
    STDDEV(inb) AS inb_stddev,
    MIN(inb) AS inb_min,
    MAX(inb) AS inb_max,
    APPROX_QUANTILES(inb, 1000) AS inb_q
  FROM typed
)
SELECT
  metric,
  total_rows,
  avg_value,
  stddev_value,
  min_value,
  p01,
  p05,
  p10,
  p25,
  p50,
  p75,
  p90,
  p95,
  p99,
  p999,
  p1000,
  max_value
FROM q,
UNNEST([
  STRUCT('UNITS_ON_HAND' AS metric, oh_avg AS avg_value, oh_stddev AS stddev_value, oh_min AS min_value,
    oh_q[OFFSET(10)] AS p01, oh_q[OFFSET(50)] AS p05, oh_q[OFFSET(100)] AS p10,
    oh_q[OFFSET(250)] AS p25, oh_q[OFFSET(500)] AS p50, oh_q[OFFSET(750)] AS p75,
    oh_q[OFFSET(900)] AS p90, oh_q[OFFSET(950)] AS p95, oh_q[OFFSET(990)] AS p99,
    oh_q[OFFSET(999)] AS p999, oh_q[OFFSET(1000)] AS p1000, oh_max AS max_value),
  STRUCT('UNITS_AVAILABLE' AS metric, av_avg AS avg_value, av_stddev AS stddev_value, av_min AS min_value,
    av_q[OFFSET(10)] AS p01, av_q[OFFSET(50)] AS p05, av_q[OFFSET(100)] AS p10,
    av_q[OFFSET(250)] AS p25, av_q[OFFSET(500)] AS p50, av_q[OFFSET(750)] AS p75,
    av_q[OFFSET(900)] AS p90, av_q[OFFSET(950)] AS p95, av_q[OFFSET(990)] AS p99,
    av_q[OFFSET(999)] AS p999, av_q[OFFSET(1000)] AS p1000, av_max AS max_value),
  STRUCT('UNITS_INBOUND' AS metric, inb_avg AS avg_value, inb_stddev AS stddev_value, inb_min AS min_value,
    inb_q[OFFSET(10)] AS p01, inb_q[OFFSET(50)] AS p05, inb_q[OFFSET(100)] AS p10,
    inb_q[OFFSET(250)] AS p25, inb_q[OFFSET(500)] AS p50, inb_q[OFFSET(750)] AS p75,
    inb_q[OFFSET(900)] AS p90, inb_q[OFFSET(950)] AS p95, inb_q[OFFSET(990)] AS p99,
    inb_q[OFFSET(999)] AS p999, inb_q[OFFSET(1000)] AS p1000, inb_max AS max_value)
])
ORDER BY metric;
-- INV_DIST_02_END

-- INV_DIST_03_BEGIN
-- Distributions after excluding the known -1 sentinel from OH and AV.
WITH values_long AS (
  SELECT 'UNITS_ON_HAND_EXCL_SENTINEL' AS metric, SAFE_CAST(UNITS_ON_HAND AS INT64) AS value
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(UNITS_ON_HAND AS INT64) != -1
  UNION ALL
  SELECT 'UNITS_AVAILABLE_EXCL_SENTINEL' AS metric, SAFE_CAST(UNITS_AVAILABLE AS INT64) AS value
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(UNITS_AVAILABLE AS INT64) != -1
  UNION ALL
  SELECT 'UNITS_INBOUND' AS metric, SAFE_CAST(UNITS_INBOUND AS INT64) AS value
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
),
q AS (
  SELECT
    metric,
    COUNT(*) AS row_count,
    AVG(value) AS avg_value,
    STDDEV(value) AS stddev_value,
    MIN(value) AS min_value,
    MAX(value) AS max_value,
    APPROX_QUANTILES(value, 1000) AS qs
  FROM values_long
  GROUP BY metric
)
SELECT
  metric,
  row_count,
  avg_value,
  stddev_value,
  min_value,
  qs[OFFSET(10)] AS p01,
  qs[OFFSET(50)] AS p05,
  qs[OFFSET(100)] AS p10,
  qs[OFFSET(250)] AS p25,
  qs[OFFSET(500)] AS p50,
  qs[OFFSET(750)] AS p75,
  qs[OFFSET(900)] AS p90,
  qs[OFFSET(950)] AS p95,
  qs[OFFSET(990)] AS p99,
  qs[OFFSET(999)] AS p999,
  qs[OFFSET(1000)] AS p1000,
  max_value
FROM q
ORDER BY metric;
-- INV_DIST_03_END

-- INV_DIST_04_BEGIN
-- Positive-only distributions for meaningful stock levels.
WITH values_long AS (
  SELECT 'UNITS_ON_HAND_POSITIVE' AS metric, SAFE_CAST(UNITS_ON_HAND AS INT64) AS value
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(UNITS_ON_HAND AS INT64) > 0
  UNION ALL
  SELECT 'UNITS_AVAILABLE_POSITIVE' AS metric, SAFE_CAST(UNITS_AVAILABLE AS INT64) AS value
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(UNITS_AVAILABLE AS INT64) > 0
  UNION ALL
  SELECT 'UNITS_INBOUND_POSITIVE' AS metric, SAFE_CAST(UNITS_INBOUND AS INT64) AS value
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(UNITS_INBOUND AS INT64) > 0
),
q AS (
  SELECT
    metric,
    COUNT(*) AS row_count,
    AVG(value) AS avg_value,
    STDDEV(value) AS stddev_value,
    MIN(value) AS min_value,
    MAX(value) AS max_value,
    APPROX_QUANTILES(value, 1000) AS qs
  FROM values_long
  GROUP BY metric
)
SELECT
  metric,
  row_count,
  avg_value,
  stddev_value,
  min_value,
  qs[OFFSET(10)] AS p01,
  qs[OFFSET(50)] AS p05,
  qs[OFFSET(100)] AS p10,
  qs[OFFSET(250)] AS p25,
  qs[OFFSET(500)] AS p50,
  qs[OFFSET(750)] AS p75,
  qs[OFFSET(900)] AS p90,
  qs[OFFSET(950)] AS p95,
  qs[OFFSET(990)] AS p99,
  qs[OFFSET(999)] AS p999,
  qs[OFFSET(1000)] AS p1000,
  max_value
FROM q
ORDER BY metric;
-- INV_DIST_04_END

-- INV_DIST_05_BEGIN
-- Relationship checks and gap distributions.
WITH typed AS (
  SELECT
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS inb
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
),
base AS (
  SELECT
    *,
    av - oh AS av_minus_oh,
    ABS(av - oh) AS abs_av_oh_gap,
    SAFE_DIVIDE(inb, NULLIF(oh, 0)) AS inb_to_oh_ratio
  FROM typed
),
q AS (
  SELECT
    COUNT(*) AS total_rows,
    COUNTIF(av > oh) AS av_gt_oh,
    COUNTIF(av < oh) AS av_lt_oh,
    COUNTIF(av = oh) AS av_eq_oh,
    COUNTIF(oh > 0 AND av = 0) AS oh_pos_av_zero,
    COUNTIF(inb > 0 AND oh = 0) AS inb_pos_oh_zero,
    COUNTIF(oh < -1 OR av < -1 OR inb < 0) AS any_real_negative,
    COUNTIF(abs_av_oh_gap >= 100) AS abs_gap_ge_100,
    COUNTIF(abs_av_oh_gap >= 1000) AS abs_gap_ge_1000,
    COUNTIF(inb_to_oh_ratio > 10) AS inb_ratio_gt_10,
    APPROX_QUANTILES(abs_av_oh_gap, 1000) AS gap_q,
    APPROX_QUANTILES(IF(inb_to_oh_ratio IS NULL, NULL, inb_to_oh_ratio), 1000 IGNORE NULLS) AS ratio_q,
    MAX(abs_av_oh_gap) AS max_abs_gap,
    MAX(inb_to_oh_ratio) AS max_inb_to_oh_ratio
  FROM base
)
SELECT
  total_rows,
  av_gt_oh,
  av_lt_oh,
  av_eq_oh,
  oh_pos_av_zero,
  inb_pos_oh_zero,
  any_real_negative,
  abs_gap_ge_100,
  abs_gap_ge_1000,
  inb_ratio_gt_10,
  gap_q[OFFSET(500)] AS abs_gap_p50,
  gap_q[OFFSET(950)] AS abs_gap_p95,
  gap_q[OFFSET(990)] AS abs_gap_p99,
  gap_q[OFFSET(999)] AS abs_gap_p999,
  gap_q[OFFSET(1000)] AS abs_gap_p1000,
  max_abs_gap,
  ratio_q[OFFSET(500)] AS inb_to_oh_ratio_p50,
  ratio_q[OFFSET(950)] AS inb_to_oh_ratio_p95,
  ratio_q[OFFSET(990)] AS inb_to_oh_ratio_p99,
  ratio_q[OFFSET(999)] AS inb_to_oh_ratio_p999,
  ratio_q[OFFSET(1000)] AS inb_to_oh_ratio_p1000,
  max_inb_to_oh_ratio
FROM q;
-- INV_DIST_05_END

-- INV_DIST_06_BEGIN
-- Segment distributions by year, month, derived channel, and location type.
WITH typed AS (
  SELECT
    SAFE_CAST(i.`DATE` AS DATE) AS snap_date,
    SAFE_CAST(i.UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(i.UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(i.UNITS_INBOUND AS INT64) AS inb,
    COALESCE(ld.TYPE_CODE, 'UNKNOWN') AS location_type,
    CASE
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL' THEN 'RETAIL'
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
        OR UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOM'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
      ELSE 'NON_CORE'
    END AS derived_channel
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot` i
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON LPAD(CAST(i.LOCATION_ID AS STRING), 10, '0') = LPAD(CAST(ld.ID AS STRING), 10, '0')
),
grouped AS (
  SELECT
    EXTRACT(YEAR FROM snap_date) AS snap_year,
    DATE_TRUNC(snap_date, MONTH) AS snap_month,
    derived_channel,
    location_type,
    COUNT(*) AS row_count,
    COUNTIF(oh = -1) AS oh_sentinel,
    COUNTIF(oh < -1) AS oh_real_negative,
    COUNTIF(oh = 0) AS oh_zero,
    COUNTIF(oh > 0) AS oh_positive,
    COUNTIF(inb > 0) AS inb_positive,
    AVG(oh) AS oh_avg,
    AVG(av) AS av_avg,
    AVG(inb) AS inb_avg,
    APPROX_QUANTILES(oh, 100)[OFFSET(50)] AS oh_p50,
    APPROX_QUANTILES(oh, 100)[OFFSET(99)] AS oh_p99,
    APPROX_QUANTILES(av, 100)[OFFSET(50)] AS av_p50,
    APPROX_QUANTILES(av, 100)[OFFSET(99)] AS av_p99,
    APPROX_QUANTILES(inb, 100)[OFFSET(50)] AS inb_p50,
    APPROX_QUANTILES(inb, 100)[OFFSET(99)] AS inb_p99
  FROM typed
  GROUP BY 1, 2, 3, 4
)
SELECT *
FROM grouped
ORDER BY snap_month, derived_channel, location_type;
-- INV_DIST_06_END

-- INV_DIST_07_BEGIN
-- Top numeric outlier rows by metric.
WITH typed AS (
  SELECT
    SKU_ID,
    LOCATION_ID,
    SAFE_CAST(`DATE` AS DATE) AS snap_date,
    SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) AS snapshot_ts,
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS inb
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
),
ranked AS (
  SELECT 'UNITS_ON_HAND' AS metric, SKU_ID, LOCATION_ID, snap_date, snapshot_ts, oh AS metric_value, oh, av, inb
  FROM typed
  ORDER BY oh DESC
  LIMIT 50
),
ranked_av AS (
  SELECT 'UNITS_AVAILABLE' AS metric, SKU_ID, LOCATION_ID, snap_date, snapshot_ts, av AS metric_value, oh, av, inb
  FROM typed
  ORDER BY av DESC
  LIMIT 50
),
ranked_inb AS (
  SELECT 'UNITS_INBOUND' AS metric, SKU_ID, LOCATION_ID, snap_date, snapshot_ts, inb AS metric_value, oh, av, inb
  FROM typed
  ORDER BY inb DESC
  LIMIT 50
)
SELECT * FROM ranked
UNION ALL
SELECT * FROM ranked_av
UNION ALL
SELECT * FROM ranked_inb
ORDER BY metric, metric_value DESC;
-- INV_DIST_07_END

-- INV_DIST_08_BEGIN
-- Full raw vs active date scope vs active core-channel scope.
WITH typed AS (
  SELECT
    SAFE_CAST(i.`DATE` AS DATE) AS snap_date,
    SAFE_CAST(i.UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(i.UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(i.UNITS_INBOUND AS INT64) AS inb,
    CASE
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL' THEN 'RETAIL'
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
        OR UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOM'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
      ELSE 'NON_CORE'
    END AS derived_channel
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot` i
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON LPAD(CAST(i.LOCATION_ID AS STRING), 10, '0') = LPAD(CAST(ld.ID AS STRING), 10, '0')
),
scoped AS (
  SELECT 'full_raw' AS scope_name, * FROM typed
  UNION ALL
  SELECT 'active_date_scope' AS scope_name, * FROM typed
  WHERE snap_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
  UNION ALL
  SELECT 'active_core_scope' AS scope_name, * FROM typed
  WHERE snap_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
    AND derived_channel IN ('RETAIL', 'ECOMM')
),
q AS (
  SELECT
    scope_name,
    COUNT(*) AS row_count,
    MIN(snap_date) AS min_date,
    MAX(snap_date) AS max_date,
    COUNT(DISTINCT snap_date) AS distinct_dates,
    COUNTIF(derived_channel = 'RETAIL') AS retail_rows,
    COUNTIF(derived_channel = 'ECOMM') AS ecomm_rows,
    COUNTIF(derived_channel = 'NON_CORE') AS non_core_rows,
    COUNTIF(oh = -1) AS oh_sentinel,
    COUNTIF(oh < -1) AS oh_real_negative,
    COUNTIF(oh = 0) AS oh_zero,
    COUNTIF(oh > 0) AS oh_positive,
    COUNTIF(av > oh) AS av_gt_oh,
    COUNTIF(inb > 0 AND oh = 0) AS inb_pos_oh_zero,
    APPROX_QUANTILES(oh, 100)[OFFSET(50)] AS oh_p50,
    APPROX_QUANTILES(oh, 100)[OFFSET(99)] AS oh_p99,
    APPROX_QUANTILES(av, 100)[OFFSET(50)] AS av_p50,
    APPROX_QUANTILES(av, 100)[OFFSET(99)] AS av_p99,
    APPROX_QUANTILES(inb, 100)[OFFSET(50)] AS inb_p50,
    APPROX_QUANTILES(inb, 100)[OFFSET(99)] AS inb_p99
  FROM scoped
  GROUP BY scope_name
)
SELECT *
FROM q
ORDER BY scope_name;
-- INV_DIST_08_END
