-- =============================================================================
-- ordering column: BQ INT64 vs history STRING (product_anomaly_data_persist)
-- =============================================================================
-- Root cause: GSM had generic_column_datatype=varchar for Postgres PAF, but
-- product_anomaly_all history kept ordering INT64. New runs used STRING → INSERT fail.
--
-- Long-term fix: GSM generic_column_datatype=bigint for BQ; Postgres PAF keeps
-- ordering as varchar (Dataflow/JDBC casts on load). Re-upload product GSM CSV.
--
-- Run PRE-FLIGHT first:
-- =============================================================================

SELECT table_name, column_name, data_type
FROM `lululemon-01042025.lulu_ingestion_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('product_anomaly', 'product_anomaly_all')
  AND column_name = 'ordering'
ORDER BY table_name;

-- =============================================================================
-- Option B: migrate product_anomaly_all.ordering STRING → INT64 (keep history)
-- Skip if product_anomaly_all does not exist or ordering is already INT64.
-- =============================================================================

-- Step 1: add new column
ALTER TABLE `lululemon-01042025.lulu_ingestion_dev.product_anomaly_all`
  ADD COLUMN IF NOT EXISTS ordering_int INT64;

-- Step 2: backfill (SAFE_CAST handles varchar/numeric strings and blanks)
UPDATE `lululemon-01042025.lulu_ingestion_dev.product_anomaly_all`
SET ordering_int = SAFE_CAST(ordering AS INT64)
WHERE TRUE;

-- Step 3: drop old column (fails if name differs — check PRE-FLIGHT)
ALTER TABLE `lululemon-01042025.lulu_ingestion_dev.product_anomaly_all`
  DROP COLUMN IF EXISTS ordering;

-- Step 4: rename
ALTER TABLE `lululemon-01042025.lulu_ingestion_dev.product_anomaly_all`
  RENAME COLUMN ordering_int TO ordering;

-- =============================================================================
-- Option A: empty history only (0 rows) — drop and let DAG recreate
-- =============================================================================
-- DROP TABLE IF EXISTS `lululemon-01042025.lulu_ingestion_dev.product_anomaly_all`;

-- If this DAG run already built product_anomaly as STRING, align current table too:
-- (same 4 steps as above on product_anomaly)

-- Verify (both must be INT64 before product_anomaly_data_persist)
SELECT table_name, column_name, data_type
FROM `lululemon-01042025.lulu_ingestion_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('product_anomaly', 'product_anomaly_all')
  AND column_name = 'ordering'
ORDER BY table_name;
