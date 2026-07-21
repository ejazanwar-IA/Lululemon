-- =============================================================================
-- Lululemon: align global.product_master with corrected GSM
-- =============================================================================
-- Run in Postgres (psql / DBeaver) on target env — NOT BigQuery.

-- PRE-FLIGHT (run first on the target DB)
SELECT
  current_database() AS db,
  BOOL_OR(column_name = 'article') AS has_article,
  BOOL_OR(column_name = 'l0_name') AS has_l0_name,
  BOOL_OR(column_name = 'product_bucket_code') AS has_product_bucket_code
FROM information_schema.columns
WHERE table_schema = 'global' AND table_name = 'product_master';
-- All true → skip ALTER block below

SELECT COUNT(*) AS gsm_sync_cols_missing_on_pm
FROM global.product_generic_schema_mapping g
WHERE g.required_in_product AND NOT g.is_attribute
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'global' AND c.table_name = 'product_master'
      AND c.column_name = g.generic_column_name);
-- Expect 0 before sync
-- Prerequisite: platform approval for DDL on global.product_master.
--
-- Adds columns that corrected GSM marks is_attribute=false and
-- sync_product_master expects on global.product_master.
-- Does NOT add l0_id–l8_id (those remain product_attributes_filter only).
-- =============================================================================

BEGIN;

-- Lululemon hierarchy / bucket cols missing from generic Signet-style shell
ALTER TABLE global.product_master ADD COLUMN IF NOT EXISTS article varchar;
ALTER TABLE global.product_master ADD COLUMN IF NOT EXISTS l0_name varchar;
ALTER TABLE global.product_master ADD COLUMN IF NOT EXISTS product_bucket_code bigint;

-- One-time backfill from validated staging (run after ALTER)
UPDATE global.product_master pm
SET
  article = pvt.article,
  l0_name = pvt.l0_name,
  product_bucket_code = pvt.product_bucket_code
FROM public.product_validated_table pvt
WHERE pm.product_code = pvt.product_code
  AND (
    pm.article IS DISTINCT FROM pvt.article
    OR pm.l0_name IS DISTINCT FROM pvt.l0_name
    OR pm.product_bucket_code IS DISTINCT FROM pvt.product_bucket_code
  );

-- Staging must expose `active` (bool) for sync_product_master; Dataflow copies
-- active_flag from BQ. Until pipeline materializes `active`, backfill from active_flag:
ALTER TABLE public.product_validated_table ADD COLUMN IF NOT EXISTS active boolean;
UPDATE public.product_validated_table
SET active = (active_flag = 1)
WHERE active IS NULL AND active_flag IS NOT NULL;

COMMIT;

-- -----------------------------------------------------------------------------
-- Post-migration checks (read-only)
-- -----------------------------------------------------------------------------

-- Should return 0 rows
SELECT g.generic_column_name
FROM global.product_generic_schema_mapping g
WHERE g.required_in_product
  AND NOT g.is_attribute
  AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema = 'global'
      AND c.table_name = 'product_master'
      AND c.column_name = g.generic_column_name
  )
ORDER BY 1;

-- Optional: run sync (requires GSM uploaded with matching flags)
-- CALL public.sync_product_master();
