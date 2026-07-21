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
