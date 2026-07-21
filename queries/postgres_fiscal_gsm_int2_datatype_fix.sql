-- Fix fiscal GSM datatypes for ingestion DAG (lulu_dev)
-- =============================================================================
-- Error: KeyError: 'int2' in generate_transformed_validated_query_fiscal_date
-- Cause: OOTB global.fiscal_date_generic_schema_mapping uses Postgres int2/int4;
--        Airflow db_to_wh_dtypes only accepts smallint/integer/bigint aliases.
--
-- The DAG reads global.fiscal_date_generic_schema_mapping (NOT fiscal_generic_schema_mapping).
-- Self-Help upload target: fiscal_date_generic_schema_mapping
--   CSV: reference_docs/Lululemon/Generic Schema Mappings/fiscal_date_generic_schema_mapping_selfhelp_upload.csv
--
-- Run only with DI approval (writes). Prefer Self-Help re-upload over raw UPDATE.
-- =============================================================================

-- Pre-flight (read-only)
SELECT
  'fiscal_date_generic_schema_mapping' AS tbl,
  COUNT(*) AS rows,
  COUNT(*) FILTER (WHERE source_column_datatype IN ('int2','int4') OR generic_column_datatype IN ('int2','int4')) AS bad_rows
FROM global.fiscal_date_generic_schema_mapping;

SELECT
  'fiscal_generic_schema_mapping' AS tbl,
  COUNT(*) AS rows,
  COUNT(*) FILTER (WHERE source_column_datatype IN ('int2','int4') OR generic_column_datatype IN ('int2','int4')) AS bad_rows
FROM global.fiscal_generic_schema_mapping;

SELECT source_table, generic_mapping_table, destination_table
FROM global.generic_master_mapping
WHERE destination_table = 'fiscal_date_mapping';

-- Fix (requires approval) — prefer Self-Help re-upload; or run as connected user with write access:
-- NOTE: Use integer (not smallint) for all numeric cols — Dataflow cannot bind BQ INT64 to PG smallint.
-- See queries/postgres_fiscal_gsm_dataflow_smallint_fix.sql

UPDATE global.fiscal_date_generic_schema_mapping
SET
  source_column_datatype = CASE source_column_datatype
    WHEN 'int2' THEN 'integer'
    WHEN 'int4' THEN 'integer'
    WHEN 'smallint' THEN 'integer'
    ELSE source_column_datatype
  END,
  generic_column_datatype = CASE generic_column_datatype
    WHEN 'int2' THEN 'integer'
    WHEN 'int4' THEN 'integer'
    WHEN 'smallint' THEN 'integer'
    ELSE generic_column_datatype
  END
WHERE source_column_datatype IN ('int2', 'int4', 'smallint')
   OR generic_column_datatype IN ('int2', 'int4', 'smallint');

UPDATE global.fiscal_date_generic_schema_mapping
SET unique_by = true, is_null_allowed = false
WHERE generic_column_name = 'date';

UPDATE global.fiscal_date_generic_schema_mapping
SET is_attribute = false, unique_by = false, is_null_allowed = true
WHERE generic_column_name = 'fiscal_day_name_abb';

-- Align generic_master_mapping if still pointing at wrong GSM table:
-- UPDATE global.generic_master_mapping
-- SET generic_mapping_table = 'fiscal_date_generic_schema_mapping'
-- WHERE destination_table = 'fiscal_date_mapping'
--   AND generic_mapping_table = 'fiscal_generic_schema_mapping';

-- Post-fix verify (expect bad_rows = 0)
-- SELECT COUNT(*) FROM global.fiscal_date_generic_schema_mapping
-- WHERE source_column_datatype IN ('int2','int4') OR generic_column_datatype IN ('int2','int4');
