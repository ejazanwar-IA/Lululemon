-- DEC04 inventory_snapshot EDA (GCS batch 20251204 / drop 2025-12-05)
-- Billing project: lululemon-data-scan
-- Source: gs://client_data_lululemon/Historic/s3_to_gcs/2025-12-05/outbound/inventory_snapshot/new/inventory_snapshot*.csv
-- External table JSON: use explicit STRING schema (see findings/raw_inventory_snapshot_dec04_eda.md)
--
-- Example:
--   bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
--     --external_table_definition=t::/tmp/lulu_inv/dec04_eda.json \
--     "$(sed -n '/^-- PHASE1:/,/^-- END PHASE1/p' queries/inventory_snapshot_dec04_eda.sql | grep -v '^--')"

-- PHASE1: Foundation
WITH d AS (
  SELECT SAFE_CAST(DATE AS DATE) AS snap_date FROM t
),
bounds AS (
  SELECT MIN(snap_date) AS min_d, MAX(snap_date) AS max_d, COUNT(DISTINCT snap_date) AS distinct_dates
  FROM d
)
SELECT
  COUNT(*) AS row_cnt,
  COUNT(DISTINCT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE)) AS distinct_grains,
  ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE)), 0), 4) AS dup_ratio,
  COUNT(DISTINCT SKU_ID) AS distinct_sku,
  COUNT(DISTINCT LOCATION_ID) AS distinct_loc,
  b.min_d, b.max_d, b.distinct_dates,
  DATE_DIFF(b.max_d, b.min_d, DAY) + 1 AS calendar_days,
  DATE_DIFF(b.max_d, b.min_d, DAY) + 1 = b.distinct_dates AS full_daily_continuity
FROM t, bounds b
GROUP BY b.min_d, b.max_d, b.distinct_dates;
-- END PHASE1

-- PHASE2YEAR: Year rollup
SELECT
  EXTRACT(YEAR FROM SAFE_CAST(DATE AS DATE)) AS yr,
  COUNT(*) AS row_cnt,
  COUNT(DISTINCT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE)) AS distinct_grains,
  COUNT(DISTINCT SAFE_CAST(DATE AS DATE)) AS distinct_dates,
  COUNT(DISTINCT SKU_ID) AS distinct_sku,
  COUNT(DISTINCT LOCATION_ID) AS distinct_loc,
  MIN(SAFE_CAST(DATE AS DATE)) AS min_date,
  MAX(SAFE_CAST(DATE AS DATE)) AS max_date
FROM t
GROUP BY 1
ORDER BY 1;

-- PHASE2DAILY: Per-date row count summary
WITH daily AS (
  SELECT SAFE_CAST(DATE AS DATE) AS snap_date, COUNT(*) AS row_cnt
  FROM t GROUP BY 1
)
SELECT
  COUNT(*) AS distinct_dates,
  MIN(row_cnt) AS min_rows_per_date,
  MAX(row_cnt) AS max_rows_per_date,
  CAST(AVG(row_cnt) AS INT64) AS avg_rows_per_date,
  APPROX_QUANTILES(row_cnt, 100)[OFFSET(50)] AS median_rows_per_date
FROM daily;

-- PHASE2OUTLIERS: Dates >3 stdev from mean daily row count
WITH daily AS (
  SELECT SAFE_CAST(DATE AS DATE) AS snap_date, COUNT(*) AS row_cnt
  FROM t GROUP BY 1
),
stats AS (
  SELECT AVG(row_cnt) AS avg_rows, STDDEV(row_cnt) AS std_rows FROM daily
)
SELECT snap_date, row_cnt, ROUND(row_cnt / s.avg_rows, 2) AS ratio_to_avg
FROM daily, stats s
WHERE row_cnt > s.avg_rows + 3 * s.std_rows OR row_cnt < s.avg_rows - 3 * s.std_rows
ORDER BY row_cnt DESC;

-- PHASE345: Completeness, sentinels, business logic (single pass)
SELECT
  COUNTIF(SKU_ID IS NULL OR SKU_ID = "" OR SKU_ID = "\\N") AS sku_null,
  COUNTIF(LOCATION_ID IS NULL OR LOCATION_ID = "" OR LOCATION_ID = "\\N") AS loc_null,
  COUNTIF(DATE IS NULL OR DATE = "" OR DATE = "\\N") AS date_null,
  COUNTIF(SNAPSHOT_TIME IS NULL OR SNAPSHOT_TIME = "" OR SNAPSHOT_TIME = "\\N") AS snap_null,
  COUNTIF(UNITS_ON_HAND = "-1") AS oh_sentinel,
  COUNTIF(UNITS_ON_HAND != "-1" AND SAFE_CAST(UNITS_ON_HAND AS INT64) < 0) AS oh_real_neg,
  COUNTIF(UNITS_ON_HAND = "0") AS oh_zero,
  COUNTIF(SAFE_CAST(UNITS_ON_HAND AS INT64) > 0) AS oh_pos,
  COUNTIF(UNITS_AVAILABLE = "-1") AS av_sentinel,
  COUNTIF(UNITS_AVAILABLE != "-1" AND SAFE_CAST(UNITS_AVAILABLE AS INT64) < 0) AS av_real_neg,
  COUNTIF(UNITS_INBOUND = "0") AS inb_zero,
  COUNTIF(SAFE_CAST(UNITS_INBOUND AS INT64) < 0) AS inb_neg,
  COUNTIF(SAFE_CAST(UNITS_INBOUND AS INT64) > 0) AS inb_pos,
  COUNTIF(SAFE_CAST(UNITS_AVAILABLE AS INT64) > SAFE_CAST(UNITS_ON_HAND AS INT64)) AS av_gt_oh,
  COUNTIF(SAFE_CAST(UNITS_ON_HAND AS INT64) > 0 AND SAFE_CAST(UNITS_AVAILABLE AS INT64) = 0) AS oh_pos_av_zero,
  COUNTIF(SAFE_CAST(UNITS_INBOUND AS INT64) > 0 AND SAFE_CAST(UNITS_ON_HAND AS INT64) = 0) AS inb_pos_oh_zero,
  MIN(SAFE_CAST(UNITS_ON_HAND AS INT64)) AS oh_min,
  MAX(SAFE_CAST(UNITS_ON_HAND AS INT64)) AS oh_max,
  MIN(SAFE.PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%E*SZ", SNAPSHOT_TIME)) AS snap_min,
  MAX(SAFE.PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%E*SZ", SNAPSHOT_TIME)) AS snap_max
FROM t;

-- PHASE4: Unit quartiles
SELECT
  APPROX_QUANTILES(SAFE_CAST(UNITS_ON_HAND AS INT64), 100)[OFFSET(25)] AS oh_p25,
  APPROX_QUANTILES(SAFE_CAST(UNITS_ON_HAND AS INT64), 100)[OFFSET(50)] AS oh_p50,
  APPROX_QUANTILES(SAFE_CAST(UNITS_ON_HAND AS INT64), 100)[OFFSET(75)] AS oh_p75,
  APPROX_QUANTILES(SAFE_CAST(UNITS_ON_HAND AS INT64), 100)[OFFSET(99)] AS oh_p99,
  APPROX_QUANTILES(SAFE_CAST(UNITS_AVAILABLE AS INT64), 100)[OFFSET(50)] AS av_p50,
  APPROX_QUANTILES(SAFE_CAST(UNITS_INBOUND AS INT64), 100)[OFFSET(50)] AS inb_p50
FROM t;

-- PHASE5: SNAPSHOT_TIME lag vs business DATE
WITH l AS (
  SELECT DATE_DIFF(
    DATE(SAFE.PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%E*SZ", SNAPSHOT_TIME)),
    SAFE_CAST(DATE AS DATE), DAY) AS lag_days
  FROM t
)
SELECT
  COUNTIF(lag_days = 1) AS lag_1_day,
  COUNTIF(lag_days = 0) AS lag_0_day,
  COUNTIF(lag_days BETWEEN 2 AND 3) AS lag_2_3_day,
  COUNTIF(lag_days < 0) AS lag_negative,
  COUNTIF(lag_days > 3) AS lag_gt_3,
  COUNT(*) AS total
FROM l;

-- PHASE6: Join orphans on latest snapshot date (2025-12-04)
WITH sample AS (
  SELECT DISTINCT SKU_ID, LOCATION_ID
  FROM t WHERE SAFE_CAST(DATE AS DATE) = DATE "2025-12-04"
),
pm_bare AS (
  SELECT DISTINCT SPLIT(product_code, "_")[OFFSET(0)] AS bare_sku
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
),
sku_check AS (
  SELECT COUNT(*) AS distinct_sku_loc_pairs,
         COUNTIF(pm.bare_sku IS NULL) AS sku_orphan_pairs,
         COUNT(DISTINCT s.SKU_ID) AS distinct_sku,
         COUNT(DISTINCT IF(pm.bare_sku IS NULL, s.SKU_ID, NULL)) AS orphan_sku_ids
  FROM sample s
  LEFT JOIN pm_bare pm ON s.SKU_ID = pm.bare_sku
),
loc_store AS (
  SELECT COUNT(DISTINCT s.LOCATION_ID) AS distinct_loc,
         COUNT(DISTINCT IF(sm.store_code IS NULL, s.LOCATION_ID, NULL)) AS store_orphan_locs
  FROM sample s
  LEFT JOIN `lululemon-01042025.lulu_ingestion_dev.store_master` sm
    ON s.LOCATION_ID = sm.store_code
),
loc_det AS (
  SELECT COUNT(DISTINCT IF(ld.id IS NULL, s.LOCATION_ID, NULL)) AS loc_details_orphan_locs
  FROM sample s
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON s.LOCATION_ID = ld.id
)
SELECT *,
  ROUND(100 * sku_orphan_pairs / distinct_sku_loc_pairs, 2) AS sku_orphan_pct,
  ROUND(100 * store_orphan_locs / NULLIF(distinct_loc, 0), 2) AS store_orphan_pct,
  ROUND(100 * loc_details_orphan_locs / NULLIF(distinct_loc, 0), 2) AS loc_det_orphan_pct
FROM sku_check, loc_store, loc_det;
