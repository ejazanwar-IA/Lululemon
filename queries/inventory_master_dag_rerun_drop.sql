-- =============================================================================
-- Fix create_master_table_inventory: 409 Already Exists inventory_master
-- =============================================================================
-- The DAG runs:
--   CREATE TABLE `...inventory_master` PARTITION BY date ... AS
--   SELECT ... FROM `...inventory_validated_table`
-- It does NOT use CREATE OR REPLACE, so a prior run blocks retries.
--
-- PRE-FLIGHT (run first):
-- =============================================================================

SELECT table_id, row_count, ROUND(size_bytes / 1e9, 2) AS gb,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified
FROM `lululemon-01042025.lulu_ingestion_dev.__TABLES__`
WHERE table_id IN ('inventory_master', 'inventory_validated_table')
ORDER BY table_id;

-- Only DROP inventory_master if inventory_validated_table has the rows you want
-- to load (this dev run: both ~5.5M rows as of 2026-05-20).
--
-- DO NOT DROP product_master, transaction_master, or large history tables.

DROP TABLE IF EXISTS `lululemon-01042025.lulu_ingestion_dev.inventory_master`;

-- Then clear/re-run Airflow task: create_master_table_inventory
