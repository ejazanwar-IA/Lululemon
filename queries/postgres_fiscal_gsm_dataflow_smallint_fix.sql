-- Fix fiscal GSM smallint → integer for BQ→Postgres Dataflow (lulu_dev)
-- =============================================================================
-- Error (Dataflow worker):
--   fieldType SMALLINT did not match with any given types
--   org.postgresql.util.PSQLException: No value specified for parameter 25
--
-- Parameter 25 = fiscal_day (first GSM smallint column in INSERT order).
-- Cause: BqToDbPipeline reads BQ INT64; Beam JDBC cannot bind INT64 to PG SMALLINT
--        when dbTableSchema (from GSM generic_column_datatype) says "smallint".
--
-- Validation DAG still accepts "integer" (db_to_wh_dtypes). global.fiscal_date_mapping
-- keeps OOTB smallint DDL; sync casts integer validated cols → smallint on INSERT.
--
-- Run only with DI approval. Prefer Self-Help re-upload of:
--   reference_docs/Lululemon/Generic Schema Mappings/fiscal_date_generic_schema_mapping_selfhelp_upload.csv
-- (all smallint → integer in source_column_datatype + generic_column_datatype)
-- =============================================================================

-- Pre-flight (read-only)
SELECT
  COUNT(*) FILTER (WHERE generic_column_datatype = 'smallint') AS smallint_cols,
  COUNT(*) FILTER (WHERE generic_column_datatype = 'integer') AS integer_cols
FROM global.fiscal_date_generic_schema_mapping;

SELECT source_column_name, generic_column_datatype
FROM global.fiscal_date_generic_schema_mapping
WHERE generic_column_datatype = 'smallint'
ORDER BY source_column_name;

-- Fix (requires approval)
UPDATE global.fiscal_date_generic_schema_mapping
SET
  source_column_datatype = CASE
    WHEN source_column_datatype = 'smallint' THEN 'integer'
    ELSE source_column_datatype
  END,
  generic_column_datatype = CASE
    WHEN generic_column_datatype = 'smallint' THEN 'integer'
    ELSE generic_column_datatype
  END
WHERE source_column_datatype = 'smallint'
   OR generic_column_datatype = 'smallint';

-- Post-fix verify (expect smallint_cols = 0)
SELECT
  COUNT(*) FILTER (WHERE generic_column_datatype = 'smallint') AS remaining_smallint
FROM global.fiscal_date_generic_schema_mapping;
