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
