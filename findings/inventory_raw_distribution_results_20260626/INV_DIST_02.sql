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
