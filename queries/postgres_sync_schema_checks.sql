-- =============================================================================
-- Postgres vs BigQuery schema checks (DAG sync_*_master failures)
-- =============================================================================
-- DO NOT run the Postgres section in BigQuery — it will fail.
-- DO NOT run the BigQuery section in Postgres.
--
-- Errors being debugged:
--   sync_product_master()  -> column "article" does not exist
--   sync_store_master()    -> column "s3_id" does not exist
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A) BIGQUERY — run in console project lululemon-data-scan (or any project
--    that can query lululemon-01042025). Use dataset-qualified INFORMATION_SCHEMA.
-- -----------------------------------------------------------------------------

-- A1. Product + store master columns (canonical ingestion tables)
SELECT table_name, column_name, data_type, ordinal_position
FROM `lululemon-01042025.lulu_ingestion_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('product_master', 'product_validated_table', 'store_master', 'store_validated_table')
ORDER BY table_name, ordinal_position;

-- A2. Quick check: do BQ tables have the columns Postgres sync expects?
SELECT
  table_name,
  LOGICAL_OR(column_name = 'article') AS has_article,
  LOGICAL_OR(column_name = 'product_code') AS has_product_code
FROM `lululemon-01042025.lulu_ingestion_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('product_master', 'product_validated_table')
GROUP BY table_name;

SELECT
  table_name,
  LOGICAL_OR(column_name = 's3_id') AS has_s3_id,
  LOGICAL_OR(column_name = 'store_code') AS has_store_code
FROM `lululemon-01042025.lulu_ingestion_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('store_master', 'store_validated_table')
GROUP BY table_name;

-- -----------------------------------------------------------------------------
-- B) POSTGRES — run in psql / DBeaver / Cloud SQL against Lululemon UAT/dev
--    (connection: postgres_default in Airflow). NOT in BigQuery.
-- -----------------------------------------------------------------------------

-- B1. List product-related tables and columns
SELECT table_schema, table_name, column_name, ordinal_position, data_type
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_name ILIKE '%product%'
ORDER BY table_schema, table_name, ordinal_position;

-- B2. Does Postgres staging/master have article / s3_id?
SELECT table_name,
       BOOL_OR(column_name = 'article') AS has_article,
       BOOL_OR(column_name = 's3_id') AS has_s3_id
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('product_master', 'store_master')
GROUP BY table_name;

-- B3. Procedure source (Postgres only)
SELECT pg_get_functiondef('public.sync_product_master()'::regprocedure);

SELECT pg_get_functiondef('public.sync_store_master()'::regprocedure);
