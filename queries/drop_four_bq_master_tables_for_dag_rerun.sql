-- =============================================================================
-- Drop all 4 BQ master tables (lulu_ingestion_dev) for DAG re-create
-- =============================================================================
-- Use when tasks fail with: 409 Already Exists: Table ...inventory_master
-- (DAG uses CREATE TABLE ... AS SELECT, not CREATE OR REPLACE.)
--
-- Billing project: lululemon-data-scan (or your scan project)
-- Dataset: lululemon-01042025.lulu_ingestion_dev
--
-- KEEPS: *_validated_table, *_intermediate, Postgres tables, anomaly tables.
-- DESTROYS: master table data until the DAG rebuilds them from validated tables.
-- =============================================================================

-- PRE-FLIGHT: row counts before drop
SELECT table_id, row_count, ROUND(size_bytes / 1e9, 2) AS gb,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified
FROM `lululemon-01042025.lulu_ingestion_dev.__TABLES__`
WHERE table_id IN (
  'product_master',
  'store_master',
  'inventory_master',
  'transaction_master'
)
ORDER BY table_id;

-- DROP all four masters (run as one script)
DROP TABLE IF EXISTS `lululemon-01042025.lulu_ingestion_dev.product_master`;
DROP TABLE IF EXISTS `lululemon-01042025.lulu_ingestion_dev.store_master`;
DROP TABLE IF EXISTS `lululemon-01042025.lulu_ingestion_dev.inventory_master`;
DROP TABLE IF EXISTS `lululemon-01042025.lulu_ingestion_dev.transaction_master`;

-- POST-CHECK: should return 0 rows
SELECT table_id
FROM `lululemon-01042025.lulu_ingestion_dev.__TABLES__`
WHERE table_id IN (
  'product_master',
  'store_master',
  'inventory_master',
  'transaction_master'
);

-- Then in Airflow, clear/re-run (examples):
--   create_master_table_product
--   create_master_table_store
--   create_master_table_inventory
--   create_master_table_transaction
-- (exact task names may vary — match your data_ingestion DAG.)
