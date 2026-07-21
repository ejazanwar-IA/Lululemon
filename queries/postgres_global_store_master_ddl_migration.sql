-- =============================================================================
-- Lululemon: align global.store_master with store GSM
-- =============================================================================
-- Run in Postgres (dev/UAT/prod) — NOT BigQuery.
-- sync_store_master expects s3_id on global.store_master (is_attribute=false).
-- =============================================================================

-- PRE-FLIGHT (run first on the target DB; skip ALTER if already OK)
SELECT
  current_database() AS db,
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'global' AND table_name = 'store_master' AND column_name = 's3_id'
  ) AS has_s3_id,
  (
    SELECT COUNT(*) FROM global.store_generic_schema_mapping g
    WHERE g.required_in_product AND NOT g.is_attribute
      AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns c
        WHERE c.table_schema = 'global' AND c.table_name = 'store_master'
          AND c.column_name = g.generic_column_name)
  ) AS gsm_sync_cols_missing_on_pm;
-- has_s3_id = true  → skip ALTER below (already migrated)
-- gsm_sync_cols_missing_on_pm = 0 → GSM/PM aligned for sync

BEGIN;

ALTER TABLE global.store_master ADD COLUMN IF NOT EXISTS s3_id varchar;

UPDATE global.store_master sm
SET s3_id = svt.s3_id
FROM public.store_validated_table svt
WHERE sm.store_code = svt.store_code
  AND sm.s3_id IS DISTINCT FROM svt.s3_id;

COMMIT;

-- Should return 0 rows
SELECT g.generic_column_name
FROM global.store_generic_schema_mapping g
WHERE g.required_in_product AND NOT g.is_attribute
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'global' AND c.table_name = 'store_master'
      AND c.column_name = g.generic_column_name)
ORDER BY 1;

-- GSM fix (Self-Help or SQL): store_name must be is_attribute=false so sync
-- populates NOT NULL global.store_master.store_name (not only store_code/s3_id).
-- UPDATE global.store_generic_schema_mapping SET is_attribute = false
--   WHERE generic_column_name = 'store_name';

-- CALL public.sync_store_master();
