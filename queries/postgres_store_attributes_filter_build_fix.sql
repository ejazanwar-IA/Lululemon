-- =============================================================================
-- Fix build_store_attributes_filter failures (Postgres dev/UAT)
-- =============================================================================
-- Symptom 1: column "active" specified more than once
--   → GSM active must be is_attribute=false (comes from global.store_master).
--
-- Symptom 2: invalid input syntax for type integer: "false"
--   → store_attributes had dc_flag='false'; normalize to 0/1 (see section 2).
--
-- Symptom 3: operator does not exist: character varying = bigint
--   → loc_type_code pivot is varchar but legacy SAF column was bigint.
--
-- Symptom 4 (manual DBeaver only): syntax error at or near "@"
--   → current_user email in temp table name. Use SET ROLE "mtp-dev" before CALL.
-- =============================================================================

-- 1) GSM: active on store_master only (not pivoted from store_attributes)
UPDATE global.store_generic_schema_mapping
SET is_attribute = false,
    generic_column_datatype = 'boolean',
    is_null_allowed = false
WHERE generic_column_name = 'active';

-- dc_flag: match SAF boolean + BQ store_master BOOL semantics
UPDATE global.store_generic_schema_mapping
SET generic_column_datatype = 'boolean'
WHERE generic_column_name = 'dc_flag';

-- 2) Bad dc_flag attribute values (boolean strings in integer pivot)
UPDATE global.store_attributes
SET attribute_value = CASE
  WHEN LOWER(attribute_value) IN ('false', 'f', 'no', 'n') THEN '0'
  WHEN LOWER(attribute_value) IN ('true', 't', 'yes', 'y') THEN '1'
  ELSE attribute_value
END
WHERE attribute_name = 'dc_flag'
  AND attribute_value !~ '^[01]$';

-- 3) SAF column type for loc_type_code (Lululemon values: S, W, …)
ALTER TABLE global.store_attributes_filter
  ALTER COLUMN loc_type_code TYPE character varying
  USING loc_type_code::character varying;

-- 4) Optional sanity check
SELECT generic_column_name, is_attribute, generic_column_datatype
FROM global.store_generic_schema_mapping
WHERE generic_column_name IN ('active', 'dc_flag', 'loc_type_code', 'store_name', 'store_code', 's3_id')
ORDER BY 1;

-- 5) Re-test (Airflow uses mtp-dev; in DBeaver run SET ROLE first if needed)
-- SET ROLE "mtp-dev";
-- CALL global.build_store_attributes_filter('');
