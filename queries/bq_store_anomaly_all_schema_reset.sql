-- Reset store_anomaly_all when GSM type fixes change validated/anomaly column types.
--
-- Error: Query column 25 has type BOOL which cannot be inserted into column active,
--        which has type STRING (store_anomaly_data_persist task).
--
-- Cause: store_anomaly_all was created under old GSM (active STRING, dc_flag INT64).
--        Current store_anomaly has active BOOL, dc_flag BOOL per store GSM alignment.
--
-- Safe when store_anomaly_all is empty or history loss is acceptable.
-- Run: bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
--        < queries/bq_store_anomaly_all_schema_reset.sql
--
-- Pre-flight:
--   SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.store_anomaly_all`;

DROP TABLE IF EXISTS `lululemon-01042025.lulu_ingestion_dev.store_anomaly_all`;

-- Next data_ingestion run recreates via:
--   CREATE TABLE IF NOT EXISTS store_anomaly_all AS SELECT * FROM store_anomaly LIMIT 0;
