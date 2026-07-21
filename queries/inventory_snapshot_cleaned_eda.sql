-- =============================================================================
-- Inventory Snapshot Cleaned EDA
-- =============================================================================
-- Table:
--   `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
--
-- Purpose:
--   EDA the raw inventory snapshot feed that builds `inventory_master` and the
--   new sourcing inventory intermediate.
--
-- How to run:
--   1. Run Sections 0-2 first. They are metadata or narrow-window checks.
--   2. Run Sections 3-7 only after confirming the date windows you want.
--   3. Run Section 8 for raw-to-master reconciliation.
--
-- Cost posture:
--   This raw table is very large and is not documented as DATE-partitioned.
--   Avoid broad scans until the narrow checks tell you exactly what to inspect.
-- =============================================================================

DECLARE sample_start_date DATE DEFAULT DATE '2025-08-28';
DECLARE sample_end_date   DATE DEFAULT DATE '2025-08-28';

DECLARE recent_start_date DATE DEFAULT DATE '2024-01-01';
DECLARE recent_end_date   DATE DEFAULT DATE '2024-12-31';

-- Full available business-date range. These scan the raw table once each, so
-- use `start_date` / `end_date` only for intentional all-history checks.
DECLARE start_date DATE;
DECLARE end_date DATE;

SET start_date = (
  SELECT MIN(`DATE`)
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
);

SET end_date = (
  SELECT MAX(`DATE`)
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
);

-- =============================================================================
-- Section 0 - Metadata and schema
-- =============================================================================

-- 0A. Real column names/types.
SELECT
  ordinal_position,
  column_name,
  data_type,
  is_nullable
FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'inventory_snapshot_cleaned'
ORDER BY ordinal_position;

-- 0B. Table storage/row-count metadata. Metadata-only.
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 4), 2) AS size_tb,
  TIMESTAMP_MILLIS(creation_time) AS created_at,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified_at
FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
WHERE table_id IN ('inventory_snapshot', 'inventory_snapshot_cleaned');

-- 0C. Partitioning/clustering metadata.
SELECT
  table_name,
  column_name,
  data_type,
  is_partitioning_column,
  clustering_ordinal_position
FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'inventory_snapshot_cleaned'
ORDER BY ordinal_position;

-- =============================================================================
-- Section 1 - Business date availability and load behavior
-- =============================================================================

-- 1A. Fixed candidate business-date probe.
-- Observed during inventory sourcing workbench: only 2025-08-28 returned rows
-- among this initial set.
SELECT
  `DATE` AS inventory_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CHANNEL) AS distinct_channels,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_sku_id_channel,
  MIN(SNAPSHOT_TIME) AS min_snapshot_time,
  MAX(SNAPSHOT_TIME) AS max_snapshot_time
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` IN (
  DATE '2025-08-28',
  DATE '2025-09-18',
  DATE '2025-10-08',
  DATE '2025-11-12',
  DATE '2025-11-18',
  DATE '2025-12-03',
  DATE '2025-12-05'
)
GROUP BY inventory_date
ORDER BY inventory_date;

-- 1B. Business-date profile for a chosen narrow window.
SELECT
  `DATE` AS inventory_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CHANNEL) AS distinct_channels,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_sku_id_channel,
  MIN(SNAPSHOT_TIME) AS min_snapshot_time,
  MAX(SNAPSHOT_TIME) AS max_snapshot_time,
  DATE_DIFF(DATE(MIN(SNAPSHOT_TIME)), `DATE`, DAY) AS min_load_lag_days,
  DATE_DIFF(DATE(MAX(SNAPSHOT_TIME)), `DATE`, DAY) AS max_load_lag_days
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date
GROUP BY inventory_date
ORDER BY inventory_date;

-- 1C. Snapshot/load date distribution for a chosen narrow business-date window.
SELECT
  DATE(SNAPSHOT_TIME) AS snapshot_load_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT `DATE`) AS distinct_business_dates,
  MIN(`DATE`) AS min_business_date,
  MAX(`DATE`) AS max_business_date
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date
GROUP BY snapshot_load_date
ORDER BY row_count DESC
LIMIT 100;

-- 1D. Backfill probe for old business dates visible in random sample.
SELECT
  EXTRACT(YEAR FROM `DATE`) AS business_year,
  DATE(SNAPSHOT_TIME) AS snapshot_load_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT `DATE`) AS distinct_business_dates,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_sku_id_channel
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN DATE '2016-01-01' AND DATE '2022-12-31'
  AND DATE(SNAPSHOT_TIME) IN (DATE '2022-08-02', DATE '2019-09-24')
GROUP BY business_year, snapshot_load_date
ORDER BY business_year, snapshot_load_date;

-- 1E. Optional full-table one-pass summary.
-- This is intentionally broad and can scan the full raw table. Run only when
-- you need all-history headline counts.
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  start_date AS min_date_from_variable,
  end_date AS max_date_from_variable,
  MIN(`DATE`) AS min_date,
  MAX(`DATE`) AS max_date,
  COUNTIF(UNITS_ON_HAND < 0) AS negative_oh_rows,
  COUNTIF(UNITS_AVAILABLE < 0) AS negative_available_rows,
  COUNTIF(UNITS_INBOUND < 0) AS negative_inbound_rows,
  MIN(SNAPSHOT_TIME) AS min_snapshot_time,
  MAX(SNAPSHOT_TIME) AS max_snapshot_time,
  COUNT(DISTINCT CHANNEL) AS distinct_channels,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_sku_id_channel
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN start_date AND end_date;

-- =============================================================================
-- Section 2 - Narrow-window raw profile
-- =============================================================================

-- 2A. Overall profile for selected business-date window.
-- Observed for 2025-08-28 in sourcing workbench:
--   row_count = 5,539,053
--   null SKU_ID/LOCATION_ID/DATE/SNAPSHOT_TIME = 0
--   null SKU_ID_CHANNEL and CHANNEL = 120,222
--   negative OH = 33,774; negative inbound = 712; negative available = 42,444
SELECT
  sample_start_date AS sample_start_date,
  sample_end_date AS sample_end_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT `DATE`) AS distinct_inventory_dates,
  COUNT(DISTINCT CHANNEL) AS distinct_channels,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_sku_id_channel,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  MIN(`DATE`) AS min_inventory_date,
  MAX(`DATE`) AS max_inventory_date,
  MIN(SNAPSHOT_TIME) AS min_snapshot_time,
  MAX(SNAPSHOT_TIME) AS max_snapshot_time,
  COUNTIF(SKU_ID IS NULL) AS null_sku_id,
  COUNTIF(SKU_ID_CHANNEL IS NULL OR SKU_ID_CHANNEL = '') AS null_sku_id_channel,
  COUNTIF(LOCATION_ID IS NULL OR LOCATION_ID = '') AS null_location_id,
  COUNTIF(`DATE` IS NULL) AS null_date,
  COUNTIF(CHANNEL IS NULL OR CHANNEL = '') AS null_channel,
  COUNTIF(SNAPSHOT_TIME IS NULL) AS null_snapshot_time,
  COUNTIF(UNITS_ON_HAND < 0) AS negative_oh_rows,
  COUNTIF(UNITS_ON_HAND = 0) AS zero_oh_rows,
  COUNTIF(UNITS_ON_HAND > 0) AS positive_oh_rows,
  COUNTIF(UNITS_INBOUND < 0) AS negative_inbound_rows,
  COUNTIF(UNITS_AVAILABLE < 0) AS negative_available_rows,
  COUNTIF(UNITS_AVAILABLE > UNITS_ON_HAND) AS available_gt_oh_rows,
  COUNTIF(UNITS_ON_HAND > 0 AND UNITS_AVAILABLE = 0) AS positive_oh_zero_available_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date;

-- 2B. Profile by raw channel for selected business-date window.
SELECT
  COALESCE(NULLIF(CHANNEL, ''), '<missing>') AS channel,
  COUNT(*) AS row_count,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_sku_id_channel,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNTIF(SKU_ID_CHANNEL IS NULL OR SKU_ID_CHANNEL = '') AS null_sku_id_channel,
  COUNTIF(UNITS_ON_HAND < 0) AS negative_oh_rows,
  COUNTIF(UNITS_ON_HAND = 0) AS zero_oh_rows,
  COUNTIF(UNITS_ON_HAND > 0) AS positive_oh_rows,
  COUNTIF(UNITS_AVAILABLE > UNITS_ON_HAND) AS available_gt_oh_rows,
  COUNTIF(UNITS_ON_HAND > 0 AND UNITS_AVAILABLE = 0) AS positive_oh_zero_available_rows,
  SUM(COALESCE(UNITS_ON_HAND, 0)) AS total_oh,
  SUM(COALESCE(UNITS_AVAILABLE, 0)) AS total_available_units,
  SUM(COALESCE(UNITS_INBOUND, 0)) AS total_inbound_units,
  MIN(SNAPSHOT_TIME) AS min_snapshot_time,
  MAX(SNAPSHOT_TIME) AS max_snapshot_time
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date
GROUP BY channel
ORDER BY row_count DESC;

-- 2C. Small row sample for anomalies in selected business-date window.
SELECT *
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date
  AND (
    UNITS_ON_HAND < 0
    OR UNITS_AVAILABLE < 0
    OR UNITS_INBOUND < 0
    OR UNITS_AVAILABLE > UNITS_ON_HAND
    OR SKU_ID_CHANNEL IS NULL
    OR SKU_ID_CHANNEL = ''
    OR CHANNEL IS NULL
    OR CHANNEL = ''
  )
LIMIT 100;

-- =============================================================================
-- Section 3 - Grain and duplicate checks
-- =============================================================================

-- 3A. Duplicate summary by effective raw grain.
WITH grain_counts AS (
  SELECT
    COALESCE(SKU_ID_CHANNEL, CONCAT(CAST(SKU_ID AS STRING), '_', CHANNEL)) AS effective_product_code,
    LOCATION_ID,
    `DATE`,
    CHANNEL,
    COUNT(*) AS rows_at_grain,
    COUNT(DISTINCT SNAPSHOT_TIME) AS distinct_snapshot_times,
    MIN(SNAPSHOT_TIME) AS min_snapshot_time,
    MAX(SNAPSHOT_TIME) AS max_snapshot_time
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
  WHERE `DATE` BETWEEN sample_start_date AND sample_end_date
  GROUP BY
    effective_product_code,
    LOCATION_ID,
    `DATE`,
    CHANNEL
)
SELECT
  COUNT(*) AS total_grain_groups,
  COUNTIF(rows_at_grain > 1) AS duplicate_grain_groups,
  MAX(rows_at_grain) AS max_rows_at_one_grain,
  SUM(rows_at_grain) AS source_rows,
  SUM(CASE WHEN rows_at_grain > 1 THEN rows_at_grain ELSE 0 END) AS rows_in_duplicate_groups
FROM grain_counts;

-- 3B. Top duplicate examples, if any.
WITH grain_counts AS (
  SELECT
    COALESCE(SKU_ID_CHANNEL, CONCAT(CAST(SKU_ID AS STRING), '_', CHANNEL)) AS effective_product_code,
    LOCATION_ID,
    `DATE`,
    CHANNEL,
    COUNT(*) AS rows_at_grain,
    COUNT(DISTINCT SNAPSHOT_TIME) AS distinct_snapshot_times,
    MIN(SNAPSHOT_TIME) AS min_snapshot_time,
    MAX(SNAPSHOT_TIME) AS max_snapshot_time,
    ARRAY_AGG(STRUCT(UNITS_ON_HAND, UNITS_AVAILABLE, UNITS_INBOUND, SNAPSHOT_TIME) ORDER BY SNAPSHOT_TIME DESC LIMIT 5) AS sample_versions
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
  WHERE `DATE` BETWEEN sample_start_date AND sample_end_date
  GROUP BY
    effective_product_code,
    LOCATION_ID,
    `DATE`,
    CHANNEL
)
SELECT *
FROM grain_counts
WHERE rows_at_grain > 1
ORDER BY rows_at_grain DESC, distinct_snapshot_times DESC
LIMIT 100;

-- =============================================================================
-- Section 4 - Key consistency and derivation checks
-- =============================================================================

-- 4A. Does SKU_ID_CHANNEL match SKU_ID + CHANNEL?
SELECT
  COUNT(*) AS row_count,
  COUNTIF(SKU_ID_CHANNEL = CONCAT(CAST(SKU_ID AS STRING), '_', CHANNEL)) AS exact_sku_channel_matches,
  COUNTIF(SKU_ID_CHANNEL IS NOT NULL AND SKU_ID_CHANNEL != '' AND CHANNEL IS NOT NULL AND CHANNEL != ''
    AND SKU_ID_CHANNEL != CONCAT(CAST(SKU_ID AS STRING), '_', CHANNEL)) AS sku_channel_mismatches,
  COUNTIF(SKU_ID_CHANNEL IS NULL OR SKU_ID_CHANNEL = '') AS missing_sku_id_channel,
  COUNTIF(CHANNEL IS NULL OR CHANNEL = '') AS missing_channel
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date;

-- 4B. Missing channel/product key derivation via location tables.
WITH missing_channel_inventory AS (
  SELECT i.*
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned` i
  WHERE i.`DATE` BETWEEN sample_start_date AND sample_end_date
    AND (
      i.SKU_ID_CHANNEL IS NULL
      OR i.SKU_ID_CHANNEL = ''
      OR i.CHANNEL IS NULL
      OR i.CHANNEL = ''
    )
),
classified AS (
  SELECT
    i.*,
    lgh.LOC_TYPE,
    lgh.LOC_FORMAT,
    lgh.SUB_MARKET_CHANNEL_NAME,
    lgh.MARKET_CHANNEL_NAME,
    ld.TYPE_CODE AS location_details_type_code,
    ld.CHANNEL_CODE AS location_details_channel_code,
    CASE
      WHEN UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%STRAT%'
        OR UPPER(COALESCE(lgh.SUB_MARKET_CHANNEL_NAME, '')) LIKE '%STRAT%'
        OR UPPER(COALESCE(lgh.MARKET_CHANNEL_NAME, '')) LIKE '%STRAT%' THEN 'STRAT'
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL'
        OR UPPER(COALESCE(lgh.SUB_MARKET_CHANNEL_NAME, '')) LIKE '%RETAIL%'
        OR UPPER(COALESCE(lgh.MARKET_CHANNEL_NAME, '')) LIKE '%RETAIL%' THEN 'RETAIL'
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
      ELSE NULL
    END AS derived_channel
  FROM missing_channel_inventory i
  LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119` lgh
    ON i.LOCATION_ID = lgh.LOC_ID
  LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.location_details_cleaned_20251119` ld
    ON i.LOCATION_ID = ld.ID
)
SELECT
  COALESCE(derived_channel, '<unclassified>') AS derived_channel,
  location_details_type_code,
  location_details_channel_code,
  LOC_TYPE,
  LOC_FORMAT,
  COUNT(*) AS row_count,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  SUM(COALESCE(UNITS_ON_HAND, 0)) AS total_oh,
  SUM(COALESCE(UNITS_AVAILABLE, 0)) AS total_available_units,
  SUM(COALESCE(UNITS_INBOUND, 0)) AS total_inbound_units
FROM classified
GROUP BY
  derived_channel,
  location_details_type_code,
  location_details_channel_code,
  LOC_TYPE,
  LOC_FORMAT
ORDER BY row_count DESC;

-- =============================================================================
-- Section 5 - Quantity quality over a selected recent window
-- =============================================================================

-- 5A. Quantity profile by year/channel for a selected window.
SELECT
  EXTRACT(YEAR FROM `DATE`) AS inventory_year,
  COALESCE(NULLIF(CHANNEL, ''), '<missing>') AS channel,
  COUNT(*) AS row_count,
  COUNTIF(UNITS_ON_HAND < 0) AS negative_oh_rows,
  ROUND(COUNTIF(UNITS_ON_HAND < 0) * 100.0 / COUNT(*), 4) AS pct_negative_oh,
  COUNTIF(UNITS_ON_HAND = 0) AS zero_oh_rows,
  COUNTIF(UNITS_ON_HAND > 0) AS positive_oh_rows,
  COUNTIF(UNITS_AVAILABLE < 0) AS negative_available_rows,
  COUNTIF(UNITS_AVAILABLE > UNITS_ON_HAND) AS available_gt_oh_rows,
  COUNTIF(UNITS_ON_HAND > 0 AND UNITS_AVAILABLE = 0) AS positive_oh_zero_available_rows,
  COUNTIF(UNITS_INBOUND < 0) AS negative_inbound_rows,
  APPROX_QUANTILES(UNITS_ON_HAND, 101)[OFFSET(50)] AS p50_oh,
  APPROX_QUANTILES(UNITS_ON_HAND, 101)[OFFSET(90)] AS p90_oh,
  APPROX_QUANTILES(UNITS_ON_HAND, 101)[OFFSET(99)] AS p99_oh,
  MIN(UNITS_ON_HAND) AS min_oh,
  MAX(UNITS_ON_HAND) AS max_oh
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN recent_start_date AND recent_end_date
GROUP BY inventory_year, channel
ORDER BY inventory_year, row_count DESC;

-- 5B. Top outlier rows for selected recent window.
SELECT
  SKU_ID,
  LOCATION_ID,
  `DATE`,
  CHANNEL,
  SKU_ID_CHANNEL,
  UNITS_ON_HAND,
  UNITS_AVAILABLE,
  UNITS_INBOUND,
  SNAPSHOT_TIME
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN recent_start_date AND recent_end_date
ORDER BY ABS(UNITS_ON_HAND) DESC
LIMIT 100;

-- =============================================================================
-- Section 6 - Location and product coverage
-- =============================================================================

-- 6A. Location/country/channel interpretation for selected window.
SELECT
  CASE
    WHEN UPPER(lgh.COUNTRY_NAME) IN ('USA', 'UNITED STATES') THEN 'United States'
    WHEN UPPER(lgh.COUNTRY_NAME) = 'CANADA' THEN 'Canada'
    ELSE COALESCE(lgh.COUNTRY_NAME, '<missing>')
  END AS country,
  COALESCE(NULLIF(i.CHANNEL, ''), '<missing>') AS raw_channel,
  lgh.LOC_TYPE,
  lgh.LOC_FORMAT,
  ld.TYPE_CODE AS location_details_type_code,
  COUNT(*) AS row_count,
  COUNT(DISTINCT i.LOCATION_ID) AS distinct_locations,
  COUNT(DISTINCT i.SKU_ID) AS distinct_skus,
  SUM(COALESCE(i.UNITS_ON_HAND, 0)) AS total_oh,
  SUM(COALESCE(i.UNITS_AVAILABLE, 0)) AS total_available_units,
  SUM(COALESCE(i.UNITS_INBOUND, 0)) AS total_inbound_units
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned` i
LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119` lgh
  ON i.LOCATION_ID = lgh.LOC_ID
LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.location_details_cleaned_20251119` ld
  ON i.LOCATION_ID = ld.ID
WHERE i.`DATE` BETWEEN sample_start_date AND sample_end_date
GROUP BY
  country,
  raw_channel,
  lgh.LOC_TYPE,
  lgh.LOC_FORMAT,
  location_details_type_code
ORDER BY row_count DESC;

-- 6B. Product hierarchy coverage by raw channel for selected window.
SELECT
  COALESCE(NULLIF(i.CHANNEL, ''), '<missing>') AS raw_channel,
  COUNT(*) AS inventory_rows,
  COUNT(DISTINCT i.SKU_ID_CHANNEL) AS distinct_sku_id_channel,
  COUNTIF(pgh.sku_id_code IS NOT NULL) AS matched_rows,
  COUNTIF(pgh.sku_id_code IS NULL) AS unmatched_rows,
  ROUND(COUNTIF(pgh.sku_id_code IS NULL) * 100.0 / COUNT(*), 4) AS unmatched_pct
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned` i
LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned` pgh
  ON i.SKU_ID_CHANNEL = pgh.sku_id_code
WHERE i.`DATE` BETWEEN sample_start_date AND sample_end_date
GROUP BY raw_channel
ORDER BY unmatched_rows DESC;

-- =============================================================================
-- Section 7 - Raw-to-master reconciliation
-- =============================================================================

-- 7A. Raw vs master row counts for selected window.
SELECT
  'raw_inventory_snapshot_cleaned' AS layer,
  COUNT(*) AS row_count,
  COUNT(DISTINCT `DATE`) AS distinct_dates,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_product_codes,
  SUM(COALESCE(UNITS_ON_HAND, 0)) AS total_oh,
  SUM(COALESCE(UNITS_INBOUND, 0)) AS total_it
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date

UNION ALL

SELECT
  'inventory_master' AS layer,
  COUNT(*) AS row_count,
  COUNT(DISTINCT date) AS distinct_dates,
  COUNT(DISTINCT store_code) AS distinct_locations,
  COUNT(DISTINCT product_code) AS distinct_product_codes,
  SUM(COALESCE(oh, 0)) AS total_oh,
  SUM(COALESCE(it, 0)) AS total_it
FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master`
WHERE date BETWEEN sample_start_date AND sample_end_date;

-- 7B. Raw rows dropped by inventory_master product-hierarchy inner join.
SELECT
  COUNT(*) AS raw_rows,
  COUNTIF(pgh.sku_id_code IS NOT NULL) AS rows_with_pgh_match,
  COUNTIF(pgh.sku_id_code IS NULL) AS rows_without_pgh_match,
  ROUND(COUNTIF(pgh.sku_id_code IS NULL) * 100.0 / COUNT(*), 4) AS pct_without_pgh_match
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned` i
LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned` pgh
  ON i.SKU_ID_CHANNEL = pgh.sku_id_code
WHERE i.`DATE` BETWEEN sample_start_date AND sample_end_date;

-- 7C. Pre-2023 raw rows that cannot appear in the documented inventory_master.
-- This scan can be large. Run only when validating the known history gap.
SELECT
  MIN(`DATE`) AS min_pre2023_date,
  MAX(`DATE`) AS max_pre2023_date,
  COUNT(*) AS pre2023_rows,
  COUNT(DISTINCT `DATE`) AS pre2023_distinct_dates,
  COUNT(DISTINCT LOCATION_ID) AS pre2023_distinct_locations,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS pre2023_distinct_sku_id_channel,
  SUM(COALESCE(UNITS_ON_HAND, 0)) AS pre2023_total_oh
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` < DATE '2023-01-01';

-- =============================================================================
-- Section 8 - Final sample extracts for documentation
-- =============================================================================

-- 8A. Representative rows by channel for selected window.
SELECT
  SKU_ID,
  LOCATION_ID,
  `DATE`,
  UNITS_ON_HAND,
  UNITS_AVAILABLE,
  UNITS_INBOUND,
  SNAPSHOT_TIME,
  CHANNEL,
  SKU_ID_CHANNEL
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` BETWEEN sample_start_date AND sample_end_date
QUALIFY ROW_NUMBER() OVER (PARTITION BY CHANNEL ORDER BY FARM_FINGERPRINT(TO_JSON_STRING(STRUCT(SKU_ID, LOCATION_ID, `DATE`, SKU_ID_CHANNEL)))) <= 20
ORDER BY CHANNEL, SKU_ID_CHANNEL, LOCATION_ID
LIMIT 100;
