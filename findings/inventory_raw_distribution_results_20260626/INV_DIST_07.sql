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
