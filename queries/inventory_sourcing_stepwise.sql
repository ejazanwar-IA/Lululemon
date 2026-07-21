-- Lululemon inventory sourcing build - stepwise validation workbench
--
-- Purpose:
--   Build and validate `lulu_sourcing_dev.inventory_intermediate` from
--   `lulu_sourcing_dev.inventory_snapshot` (+ location_details in same dataset).
--
-- How to run safely:
--   1. Run Section 0 to confirm platform config state.
--   2. Run Section 1 for raw profile/anomaly checks.
--   3. Run Section 2 to create `inventory_intermediate_temp`.
--   4. Run Section 3 to validate temp output.
--   5. Run Section 4A once if the live table does not exist.
--   6. Run Section 4B for future steady-state upserts.
--
-- Validated date:
--   2025-08-28. Raw, temp, and live counts all matched at 5,539,053 rows.
--   Downstream channel policy updated 2026-06-25: emit only RETAIL / ECOMM
--   inventory rows because product_intermediate / product_master do not carry
--   FO, STRAT, COMMUNITY, or CMNTY product_code suffixes.
--
-- Cost note:
--   `inventory_snapshot` is large. Keep all validation windows tight and avoid
--   repeated broad date-discovery scans.

DECLARE run_start_date DATE DEFAULT DATE '2025-08-28';
DECLARE run_end_date   DATE DEFAULT DATE '2025-08-28';
DECLARE source_min_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR);

-- As of 2026-05-04, active mapping/view config exists only for product and store.
-- Inventory is not registered in `mapping` or `view_mapping_table`, so this
-- manual fallback keeps validation runnable until SelfPI config is added.
DECLARE manual_filter_param TIMESTAMP DEFAULT TIMESTAMP('1900-01-01 00:00:00 UTC');

DECLARE filter_param TIMESTAMP DEFAULT (
  SELECT COALESCE(
    MAX(COALESCE(filter_param, TIMESTAMP(dataingestion_filterparam))),
    manual_filter_param
  )
  FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
  WHERE is_deleted = FALSE
    AND (
      LOWER(COALESCE(`view`, '')) LIKE '%inventory%'
      OR LOWER(COALESCE(`table`, '')) LIKE '%inventory%'
      OR LOWER(COALESCE(intermediate_table, '')) LIKE '%inventory%'
    )
);

-- =============================================================================
-- Section 0 - Platform config discovery
-- =============================================================================
-- Active config observed 2026-05-04:
--   mapping             -> product_intermediate, store_intermediate only
--   view_mapping_table  -> product_streaming, store_streaming only
-- Inventory config was absent, so the script uses `manual_filter_param`.

-- 0A. Active mapping rows.
SELECT
  tenant,
  `view`,
  `table`,
  intermediate_table,
  connector,
  source_config,
  pull_type,
  schedule_interval,
  `filter`,
  inter_query_exec_order,
  dataingestion_filterparam,
  filter_param,
  COALESCE(filter_param, TIMESTAMP(dataingestion_filterparam)) AS active_checkpoint,
  is_deleted,
  created_at,
  updated_at
FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
WHERE is_deleted = FALSE
ORDER BY
  inter_query_exec_order,
  intermediate_table,
  `table`;

-- 0B. Inventory-specific mapping rows, including soft-deleted rows.
SELECT
  tenant,
  `view`,
  `table`,
  intermediate_table,
  connector,
  source_config,
  pull_type,
  schedule_interval,
  `filter`,
  inter_query_exec_order,
  dataingestion_filterparam,
  filter_param,
  COALESCE(filter_param, TIMESTAMP(dataingestion_filterparam)) AS active_checkpoint,
  is_deleted,
  created_at,
  updated_at,
  deleted_at
FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
WHERE LOWER(COALESCE(`view`, '')) LIKE '%inventory%'
   OR LOWER(COALESCE(`table`, '')) LIKE '%inventory%'
   OR LOWER(COALESCE(intermediate_table, '')) LIKE '%inventory%'
ORDER BY
  is_deleted,
  intermediate_table,
  `view`,
  `table`;

-- 0C. Active extraction/view config rows.
SELECT
  tenant,
  `view`,
  `table`,
  connector,
  source_config,
  pull_type,
  replace,
  schedule_interval,
  `filter`,
  extraction_sync_dt,
  source_format_regex,
  partition_column,
  clustering_columns,
  field_delimiter,
  filter_param,
  replace_special_characters,
  miscellaneous_attributes,
  is_deleted,
  created_at,
  updated_at
FROM `lululemon-01042025.lulu_sourcing_dev.view_mapping_table`
WHERE is_deleted = FALSE
ORDER BY
  `table`,
  `view`;

-- 0D. Inventory-specific extraction/view config rows, including soft-deleted rows.
SELECT
  tenant,
  `view`,
  `table`,
  connector,
  source_config,
  pull_type,
  replace,
  schedule_interval,
  `filter`,
  extraction_sync_dt,
  source_format_regex,
  partition_column,
  clustering_columns,
  field_delimiter,
  filter_param,
  replace_special_characters,
  miscellaneous_attributes,
  is_deleted,
  created_at,
  updated_at,
  deleted_at
FROM `lululemon-01042025.lulu_sourcing_dev.view_mapping_table`
WHERE LOWER(COALESCE(`view`, '')) LIKE '%inventory%'
   OR LOWER(COALESCE(`table`, '')) LIKE '%inventory%'
ORDER BY
  is_deleted,
  `table`,
  `view`;

-- 0E. Active joined extraction -> intermediate config.
-- Avoid `SELECT *` here because both tables share column names and BigQuery will
-- suffix duplicates (`table_1`, `filter_1`, etc.), making the result hard to read.
-- Observed 2026-05-04: active joined rows exist for product/store only.
SELECT
  v.`view` AS source_view,
  v.`table` AS source_table,
  m.intermediate_table,
  v.connector,
  v.source_config,
  v.pull_type,
  v.replace,
  v.schedule_interval,
  v.`filter` AS extraction_filter_column,
  m.dataingestion_filterparam,
  v.filter_param AS extraction_filter_param,
  m.filter_param AS mapping_filter_param,
  COALESCE(m.filter_param, TIMESTAMP(m.dataingestion_filterparam), TIMESTAMP(v.filter_param)) AS active_checkpoint,
  m.inter_query_exec_order,
  v.partition_column,
  v.clustering_columns,
  v.field_delimiter,
  v.replace_special_characters,
  v.miscellaneous_attributes
FROM `lululemon-01042025.lulu_sourcing_dev.view_mapping_table` v
JOIN `lululemon-01042025.lulu_sourcing_dev.mapping` m
  ON v.`table` = m.`table`
WHERE v.is_deleted = FALSE
  AND m.is_deleted = FALSE
ORDER BY
  m.inter_query_exec_order,
  m.intermediate_table,
  v.`view`;

-- 0F. Business-date availability probe.
-- Observed 2026-05-04: only 2025-08-28 returned rows among these candidate
-- dates. GCS landing dates like 2025-12-05 are not business inventory dates.
SELECT
  SAFE_CAST(`DATE` AS DATE) AS inventory_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  MIN(SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP)) AS min_snapshot_time,
  MAX(SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP)) AS max_snapshot_time
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
WHERE SAFE_CAST(`DATE` AS DATE) IN (
  DATE '2025-08-28',
  DATE '2025-09-18',
  DATE '2025-10-08',
  DATE '2025-11-12',
  DATE '2025-11-18',
  DATE '2025-12-03',
  DATE '2025-12-05'
)
  AND SAFE_CAST(`DATE` AS DATE) >= source_min_date
GROUP BY inventory_date
ORDER BY inventory_date;

-- =============================================================================
-- Section 1 - Raw profile and anomaly checks
-- =============================================================================

-- 1A. Raw source profile for the validated date window.
SELECT
  run_start_date AS run_start_date,
  run_end_date AS run_end_date,
  filter_param AS active_filter_param,
  source_min_date AS source_min_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT SAFE_CAST(`DATE` AS DATE)) AS distinct_inventory_dates,
  COUNT(DISTINCT LOCATION_ID) AS distinct_locations,
  MIN(SAFE_CAST(`DATE` AS DATE)) AS min_inventory_date,
  MAX(SAFE_CAST(`DATE` AS DATE)) AS max_inventory_date,
  MIN(SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP)) AS min_snapshot_time,
  MAX(SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP)) AS max_snapshot_time,
  COUNTIF(SAFE_CAST(SKU_ID AS INT64) IS NULL) AS bad_sku_id,
  COUNTIF(LOCATION_ID IS NULL OR LOCATION_ID = '') AS null_location_id,
  COUNTIF(SAFE_CAST(`DATE` AS DATE) IS NULL) AS bad_date,
  COUNTIF(SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) IS NULL) AS bad_snapshot_time,
  COUNTIF(SAFE_CAST(UNITS_ON_HAND AS INT64) < 0) AS negative_oh_rows,
  COUNTIF(SAFE_CAST(UNITS_INBOUND AS INT64) < 0) AS negative_inbound_rows,
  COUNTIF(SAFE_CAST(UNITS_AVAILABLE AS INT64) < 0) AS negative_available_rows
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
WHERE SAFE_CAST(`DATE` AS DATE) BETWEEN run_start_date AND run_end_date
  AND SAFE_CAST(`DATE` AS DATE) >= source_min_date
  AND SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) > filter_param;

-- 1B. Anomaly counts by derived channel.
WITH cleaned_inventory AS (
  SELECT
    SAFE_CAST(SKU_ID AS INT64) AS SKU_ID,
    LOCATION_ID,
    SAFE_CAST(`DATE` AS DATE) AS `DATE`,
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS UNITS_ON_HAND,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS UNITS_AVAILABLE,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS UNITS_INBOUND,
    SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) AS SNAPSHOT_TIME
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(`DATE` AS DATE) BETWEEN run_start_date AND run_end_date
    AND SAFE_CAST(`DATE` AS DATE) >= source_min_date
    AND SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) > filter_param
),
classified AS (
  SELECT
    i.*,
    CASE
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL' THEN 'RETAIL'
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
      ELSE NULL
    END AS derived_channel
  FROM cleaned_inventory i
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON LPAD(CAST(i.LOCATION_ID AS STRING), 10, '0') = LPAD(CAST(ld.ID AS STRING), 10, '0')
)
SELECT
  derived_channel,
  COUNT(*) AS row_count,
  COUNTIF(UNITS_ON_HAND < 0) AS negative_oh_rows,
  COUNTIF(UNITS_INBOUND < 0) AS negative_inbound_rows,
  COUNTIF(UNITS_AVAILABLE < 0) AS negative_available_rows,
  MIN(SNAPSHOT_TIME) AS min_snapshot_time,
  MAX(SNAPSHOT_TIME) AS max_snapshot_time
FROM classified
GROUP BY derived_channel
ORDER BY row_count DESC;

-- 1C. Channel derivation validation for raw inventory rows.
-- STRAT and other non-core channels are intentionally not derived in production
-- logic because downstream product tables do not support those product codes.
WITH cleaned_inventory AS (
  SELECT
    SAFE_CAST(SKU_ID AS INT64) AS SKU_ID,
    LOCATION_ID,
    SAFE_CAST(`DATE` AS DATE) AS `DATE`,
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS UNITS_ON_HAND,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS UNITS_AVAILABLE,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS UNITS_INBOUND,
    SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) AS SNAPSHOT_TIME
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(SKU_ID AS INT64) IS NOT NULL
    AND LOCATION_ID IS NOT NULL
    AND LOCATION_ID != ''
    AND SAFE_CAST(`DATE` AS DATE) BETWEEN run_start_date AND run_end_date
    AND SAFE_CAST(`DATE` AS DATE) >= source_min_date
    AND SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) > filter_param
),
classified AS (
  SELECT
    i.*,
    ld.TYPE_CODE AS location_details_type_code,
    ld.CHANNEL_CODE AS location_details_channel_code,
    CASE
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL' THEN 'RETAIL'
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
      ELSE NULL
    END AS derived_channel
  FROM cleaned_inventory i
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON LPAD(CAST(i.LOCATION_ID AS STRING), 10, '0') = LPAD(CAST(ld.ID AS STRING), 10, '0')
)
SELECT
  derived_channel,
  location_details_type_code,
  location_details_channel_code,
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
  location_details_channel_code
ORDER BY row_count DESC;

-- =============================================================================
-- Section 2 - Build normalized temp table
-- =============================================================================
-- This is the canonical transformation used by downstream validations and MERGE.
-- It centralizes all repeated logic:
--   - raw string-to-typed-field cleaning
--   - location-based channel derivation
--   - RETAIL / ECOMM channel enforcement for downstream product-code coverage
--   - product-code derivation as `SKU_ID_CHANNEL`
--   - latest-row selection by effective grain
--   - audit flags for derived values

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp`
PARTITION BY date
CLUSTER BY store_code, product_code AS
WITH cleaned_inventory AS (
  SELECT
    SAFE_CAST(SKU_ID AS INT64) AS SKU_ID,
    LOCATION_ID,
    SAFE_CAST(`DATE` AS DATE) AS `DATE`,
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS UNITS_ON_HAND,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS UNITS_AVAILABLE,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS UNITS_INBOUND,
    SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) AS SNAPSHOT_TIME
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(SKU_ID AS INT64) IS NOT NULL
    AND LOCATION_ID IS NOT NULL
    AND LOCATION_ID != ''
    AND SAFE_CAST(`DATE` AS DATE) BETWEEN run_start_date AND run_end_date
    AND SAFE_CAST(`DATE` AS DATE) >= source_min_date
    AND SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) IS NOT NULL
    AND SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) > filter_param
),
inventory_enriched AS (
  SELECT
    i.SKU_ID,
    i.LOCATION_ID,
    i.`DATE`,
    i.UNITS_ON_HAND,
    i.UNITS_AVAILABLE,
    i.UNITS_INBOUND,
    i.SNAPSHOT_TIME,
    derived_channel AS CHANNEL,
    CONCAT(CAST(i.SKU_ID AS STRING), '_', derived_channel) AS SKU_ID_CHANNEL,
    derived_channel
  FROM cleaned_inventory i
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON LPAD(CAST(i.LOCATION_ID AS STRING), 10, '0') = LPAD(CAST(ld.ID AS STRING), 10, '0')
  CROSS JOIN UNNEST([CASE
    WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
      OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL'
      THEN 'RETAIL'
    WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
      OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
    ELSE NULL
  END]) AS derived_channel
),
normalized_inventory AS (
  SELECT
    CAST(SKU_ID AS STRING) AS display_product_code,
    COALESCE(SKU_ID_CHANNEL, CONCAT(CAST(SKU_ID AS STRING), '_', derived_channel)) AS product_code,
    LOCATION_ID AS store_code,
    `DATE` AS date,
    COALESCE(CHANNEL, derived_channel) AS channel,
    SKU_ID_CHANNEL AS source_product_code,
    CHANNEL AS source_channel,
    SKU_ID_CHANNEL IS NULL OR SKU_ID_CHANNEL = '' AS product_code_was_derived,
    CHANNEL IS NULL OR CHANNEL = '' AS channel_was_derived,
    COALESCE(UNITS_ON_HAND, 0) AS oh,
    COALESCE(UNITS_INBOUND, 0) AS it,
    0 AS oo,
    COALESCE(UNITS_AVAILABLE, 0) AS available_units,
    SNAPSHOT_TIME AS syncstartdatetime,
    SNAPSHOT_TIME AS created_timestamp
  FROM inventory_enriched
  WHERE COALESCE(CHANNEL, derived_channel) IN ('RETAIL', 'ECOMM')
),
latest_inventory AS (
  SELECT * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY product_code, store_code, date, channel
        ORDER BY syncstartdatetime DESC
      ) AS rn
    FROM normalized_inventory
  )
  WHERE rn = 1
)
SELECT
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  source_product_code,
  source_channel,
  LOGICAL_OR(product_code_was_derived) AS product_code_was_derived,
  LOGICAL_OR(channel_was_derived) AS channel_was_derived,
  SUM(oh) AS oh,
  SUM(it) AS it,
  SUM(oo) AS oo,
  SUM(available_units) AS available_units,
  DATETIME(MIN(syncstartdatetime)) AS syncstartdatetime,
  DATETIME(MIN(created_timestamp)) AS created_timestamp
FROM latest_inventory
GROUP BY
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  source_product_code,
  source_channel;

-- =============================================================================
-- Section 3 - Validate temp output
-- =============================================================================
-- After core-channel filtering, expected 2025-08-28 output is RETAIL + ECOMM
-- only. Previously retained FO, STRAT, COMMUNITY, and CMNTY rows matched
-- product_intermediate at 0%, so they are excluded before MERGE.

-- 3A. Overall temp totals.
SELECT
  COUNT(*) AS temp_rows,
  COUNT(DISTINCT date) AS distinct_dates,
  COUNT(DISTINCT channel) AS distinct_channels,
  COUNT(DISTINCT product_code) AS distinct_products,
  COUNT(DISTINCT store_code) AS distinct_stores,
  MIN(date) AS min_date,
  MAX(date) AS max_date,
  SUM(oh) AS total_oh,
  SUM(it) AS total_it,
  SUM(oo) AS total_oo,
  SUM(available_units) AS total_available_units
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp`;

-- 3B. Channel/derivation breakdown.
SELECT
  channel,
  product_code_was_derived,
  channel_was_derived,
  COUNT(*) AS temp_rows,
  COUNT(DISTINCT product_code) AS distinct_products,
  COUNT(DISTINCT store_code) AS distinct_stores,
  SUM(oh) AS total_oh,
  SUM(it) AS total_it,
  SUM(available_units) AS total_available_units
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp`
GROUP BY
  channel,
  product_code_was_derived,
  channel_was_derived
ORDER BY temp_rows DESC;

-- 3C. Merge-key duplicate check.
SELECT
  product_code,
  store_code,
  date,
  channel,
  COUNT(*) AS rows_at_merge_key
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp`
GROUP BY
  product_code,
  store_code,
  date,
  channel
HAVING rows_at_merge_key > 1
ORDER BY rows_at_merge_key DESC
LIMIT 100;

-- 3D. Product hierarchy coverage by channel.
-- Observed for 2025-08-28 before the core-channel filter:
--   RETAIL and ECOMM match 100%.
--   FO, STRAT, COMMUNITY, and CMNTY match 0%, confirming product hierarchy is
--   scoped to core RETAIL/ECOMM product codes.
SELECT
  t.channel,
  t.product_code_was_derived,
  COUNT(*) AS inventory_rows,
  COUNT(DISTINCT t.product_code) AS distinct_product_codes,
  COUNTIF(h.sku_id_code IS NOT NULL) AS matched_rows,
  COUNTIF(h.sku_id_code IS NULL) AS unmatched_rows,
  ROUND(COUNTIF(h.sku_id_code IS NULL) * 100.0 / COUNT(*), 4) AS unmatched_pct
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp` t
LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy` h
  ON t.product_code = h.sku_id_code
GROUP BY
  t.channel,
  t.product_code_was_derived
ORDER BY unmatched_rows DESC;

-- =============================================================================
-- Section 4 - Initialize live target and MERGE after temp validation
-- =============================================================================
-- Run only after Sections 1-3 validate.
--
-- Current state observed 2026-05-04:
--   `lulu_sourcing_dev.inventory_intermediate` was initialized for 2025-08-28
--   and matched temp/raw exactly.
--
-- First run:
--   Run 4A only, then 4C.
--
-- Future runs:
--   Rebuild `inventory_intermediate_temp` for the new window, then run 4B + 4C.

-- 4A. One-time live-table initialization.
CREATE TABLE IF NOT EXISTS `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
PARTITION BY date
CLUSTER BY store_code, product_code AS
SELECT *
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp`;

-- 4B. Steady-state upsert from validated temp into live intermediate.
MERGE `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate` DL
USING `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp` A
ON DL.product_code = A.product_code
  AND DL.store_code = A.store_code
  AND DL.date = A.date
  AND DL.channel = A.channel

WHEN MATCHED THEN UPDATE SET
  DL.display_product_code = A.display_product_code,
  DL.source_product_code = A.source_product_code,
  DL.source_channel = A.source_channel,
  DL.product_code_was_derived = A.product_code_was_derived,
  DL.channel_was_derived = A.channel_was_derived,
  DL.oh = A.oh,
  DL.it = A.it,
  DL.oo = A.oo,
  DL.available_units = A.available_units,
  DL.syncstartdatetime = A.syncstartdatetime,
  DL.created_timestamp = A.created_timestamp

WHEN NOT MATCHED THEN INSERT (
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  source_product_code,
  source_channel,
  product_code_was_derived,
  channel_was_derived,
  oh,
  it,
  oo,
  available_units,
  syncstartdatetime,
  created_timestamp
)
VALUES (
  A.display_product_code,
  A.product_code,
  A.store_code,
  A.date,
  A.channel,
  A.source_product_code,
  A.source_channel,
  A.product_code_was_derived,
  A.channel_was_derived,
  A.oh,
  A.it,
  A.oo,
  A.available_units,
  A.syncstartdatetime,
  A.created_timestamp
);

-- 4C. Live target validation for the same date window.
-- Observed after first initialization for 2025-08-28:
--   live_rows_for_window = 5,539,053, exactly matching temp/raw.
SELECT
  COUNT(*) AS live_rows_for_window,
  COUNT(DISTINCT date) AS distinct_dates,
  COUNT(DISTINCT channel) AS distinct_channels,
  COUNT(DISTINCT product_code) AS distinct_products,
  COUNT(DISTINCT store_code) AS distinct_stores,
  MIN(date) AS min_date,
  MAX(date) AS max_date,
  SUM(oh) AS total_oh,
  SUM(it) AS total_it,
  SUM(oo) AS total_oo,
  SUM(available_units) AS total_available_units
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
WHERE date BETWEEN run_start_date AND run_end_date;

SELECT
  channel,
  product_code_was_derived,
  channel_was_derived,
  COUNT(*) AS live_rows,
  COUNT(DISTINCT product_code) AS distinct_products,
  COUNT(DISTINCT store_code) AS distinct_stores,
  SUM(oh) AS total_oh,
  SUM(it) AS total_it,
  SUM(available_units) AS total_available_units
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
WHERE date BETWEEN run_start_date AND run_end_date
GROUP BY
  channel,
  product_code_was_derived,
  channel_was_derived
ORDER BY live_rows DESC;
