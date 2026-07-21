-- =============================================================================
-- Inbound Drop EDA Pack — generic table profile (manual / agent-assisted)
-- =============================================================================
-- Set the four DECLAREs, then run sections in order.
-- Billing: bq query --project_id=lululemon-data-scan --use_legacy_sql=false
--
-- Phase 1 companion: scripts/inbound_drop_eda.py (automates Tier 0–2 for
-- views in findings/inbound_drop_agent/view_profiles.yaml)
-- =============================================================================

DECLARE project_id STRING DEFAULT 'lululemon-01042025';
DECLARE dataset_id STRING DEFAULT 'lululemon_souricng_outbound';
DECLARE table_id STRING DEFAULT 'inventory_snapshot_cleaned';
DECLARE sample_date DATE DEFAULT DATE '2025-08-28';

-- =============================================================================
-- Tier 0 — Metadata (~$0)
-- =============================================================================

-- T0.1 Table inventory
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 3) AS size_gb,
  TIMESTAMP_MILLIS(creation_time) AS created_at,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified_at,
  type
FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
WHERE table_id = 'inventory_snapshot_cleaned';

-- T0.2 Column list
SELECT
  column_name,
  data_type,
  is_nullable,
  is_partitioning_column,
  clustering_ordinal_position
FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'inventory_snapshot_cleaned'
ORDER BY ordinal_position;

-- =============================================================================
-- Tier 1 — Grain (full table — confirm size in T0 first)
-- =============================================================================

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT CONCAT(
    CAST(SKU_ID_CHANNEL AS STRING), '|',
    CAST(LOCATION_ID AS STRING), '|',
    CAST(`DATE` AS STRING)
  )) AS distinct_grain,
  COUNT(*) - COUNT(DISTINCT CONCAT(
    CAST(SKU_ID_CHANNEL AS STRING), '|',
    CAST(LOCATION_ID AS STRING), '|',
    CAST(`DATE` AS STRING)
  )) AS duplicate_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`;

-- =============================================================================
-- Tier 2 — Date coverage (sample date + global min/max on filtered scan)
-- =============================================================================

SELECT
  `DATE` AS business_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT SKU_ID_CHANNEL) AS distinct_sku,
  COUNT(DISTINCT LOCATION_ID) AS distinct_location
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` = sample_date
GROUP BY 1;

-- T2.2 Available business dates (expensive — limit on large tables)
SELECT
  MIN(`DATE`) AS min_date,
  MAX(`DATE`) AS max_date,
  COUNT(DISTINCT `DATE`) AS distinct_dates
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` >= DATE '2024-01-01';

-- =============================================================================
-- Tier 3 — Sentinels (STRING columns — edit list per table)
-- =============================================================================

SELECT
  COUNT(*) AS rows_on_sample_date,
  COUNTIF(CHANNEL IS NULL OR CHANNEL = '' OR CAST(CHANNEL AS STRING) = '\\N') AS channel_null_sentinel,
  COUNTIF(SKU_ID_CHANNEL IS NULL OR SKU_ID_CHANNEL = '' OR CAST(SKU_ID_CHANNEL AS STRING) = '\\N') AS sku_null_sentinel
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
WHERE `DATE` = sample_date;

-- =============================================================================
-- Tier 4 — Join readiness (sample date)
-- =============================================================================

WITH feed AS (
  SELECT DISTINCT SKU_ID_CHANNEL AS sku_key
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
  WHERE `DATE` = sample_date
),
pm AS (
  SELECT DISTINCT product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
)
SELECT
  COUNT(*) AS feed_distinct_sku,
  COUNTIF(p.product_code IS NOT NULL) AS matched_to_pm,
  COUNTIF(p.product_code IS NULL) AS orphan_sku,
  ROUND(100.0 * COUNTIF(p.product_code IS NULL) / COUNT(*), 2) AS orphan_pct
FROM feed f
LEFT JOIN pm p ON f.sku_key = p.product_code;
