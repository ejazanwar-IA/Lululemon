-- =============================================================================
-- MASTER-BUILD MISSING TABLES — FUZZY SEARCH
-- =============================================================================
-- Purpose: availability_check returned MISSING for 4 tables. Find out whether
--   a renamed / un-suffixed / differently-dated variant exists, either in the
--   same dataset or anywhere else in the project.
--
-- Missing tables to track down:
--   1. store_master_20251119
--   2. product_master_20251119
--   3. transaction_master_20251119
--   4. sku_details_cleaned_20251119  (known, canonical is sku_details_cleaned)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- BLOCK 1 — any variant inside lululemon_souricng_outbound
-- -----------------------------------------------------------------------------
SELECT
  'BLOCK-1 (same dataset)'                                         AS block,
  'lululemon_souricng_outbound'                                    AS dataset_id,
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 2)                              AS size_gb,
  FORMAT_TIMESTAMP('%F %T', TIMESTAMP_MILLIS(creation_time))       AS created_at,
  FORMAT_TIMESTAMP('%F %T', TIMESTAMP_MILLIS(last_modified_time))  AS last_modified_at
FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
WHERE
     LOWER(table_id) LIKE '%store_master%'
  OR LOWER(table_id) LIKE '%product_master%'
  OR LOWER(table_id) LIKE '%transaction_master%'
  OR LOWER(table_id) LIKE '%sku_detail%'
ORDER BY table_id;


-- -----------------------------------------------------------------------------
-- BLOCK 2 — any other dataset in the project that has one of these tables
-- Run this SEPARATELY (it's a different query, not UNION-able cleanly across
-- region.INFORMATION_SCHEMA without region flag).
-- -----------------------------------------------------------------------------
/*
SELECT
  table_schema AS dataset_id,
  table_name,
  table_type
FROM `lululemon-01042025.region-us.INFORMATION_SCHEMA.TABLES`
WHERE
     LOWER(table_name) LIKE '%store_master%'
  OR LOWER(table_name) LIKE '%product_master%'
  OR LOWER(table_name) LIKE '%transaction_master%'
  OR LOWER(table_name) LIKE '%sku_detail%'
ORDER BY table_schema, table_name;
*/


-- -----------------------------------------------------------------------------
-- BLOCK 3 — list every dataset in the project (to confirm #2 search scope)
-- -----------------------------------------------------------------------------
/*
SELECT
  schema_name AS dataset_id,
  location,
  FORMAT_TIMESTAMP('%F %T', creation_time) AS created_at
FROM `lululemon-01042025.INFORMATION_SCHEMA.SCHEMATA`
ORDER BY schema_name;
*/
