-- Lululemon fiscal_date_mapping — Postgres ingestion setup (lulu_dev)
-- =============================================================================
-- Run in psql / DBeaver on lulu_dev after BQ master is stable.
-- Requires platform approval for DDL / generic_master_mapping writes.
--
-- Companion: findings/fiscal_date_mapping_pipeline.md
-- Training ref: reference_docs/Training/DI_Course_3_Ingestion_Basics_for_Analytics_Teams.md
--   Section "Generic master mapping" — destination MUST be fiscal_date_mapping
--
-- BEFORE ANY CALL:
--   SET ROLE "mtp-dev";
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A) Pre-flight — current state (read-only)
-- -----------------------------------------------------------------------------

SELECT current_database() AS db, current_user AS usr;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('global', 'public')
  AND table_name ILIKE '%fiscal%'
ORDER BY 1, 2;

SELECT
  master_table_name,
  source_table,
  destination_table,
  to_be_ingested,
  persist_to_postgres,
  pull_type,
  is_deleted
FROM global.generic_master_mapping
WHERE destination_table ILIKE '%fiscal%'
   OR master_table_name ILIKE '%fiscal%'
ORDER BY 1;

SELECT target_table_sp, status, created_at
FROM global.data_ingestion_logs
WHERE target_table_sp ILIKE '%fiscal%'
ORDER BY created_at DESC
LIMIT 10;

-- Expect after first successful sync:
--   public.sync_fiscal_date_mapping | end

-- Row count gate (match BQ: 4746 as of 2026-05-21)
SELECT COUNT(*) AS pg_fiscal_rows FROM global.fiscal_date_mapping;
SELECT COUNT(DISTINCT date) AS pg_distinct_dates FROM global.fiscal_date_mapping;

-- PK duplicate check (expect 0)
SELECT date, COUNT(*) AS n
FROM global.fiscal_date_mapping
GROUP BY date
HAVING COUNT(*) > 1
LIMIT 10;

-- Calendar continuity sample (expect 0 gaps in range)
WITH bounds AS (
  SELECT MIN(date) AS dmin, MAX(date) AS dmax
  FROM global.fiscal_date_mapping
)
SELECT COUNT(*) AS missing_days
FROM bounds b,
UNNEST(GENERATE_SERIES(b.dmin, b.dmax, INTERVAL '1 day')::date[]) AS d(day)
WHERE NOT EXISTS (
  SELECT 1 FROM global.fiscal_date_mapping f WHERE f.date = d.day
);

-- -----------------------------------------------------------------------------
-- B) generic_master_mapping — template row (DI / platform to confirm & insert)
-- -----------------------------------------------------------------------------
-- Fiscal has NO product-style GSM attributes/hierarchies. Typical flags:
--   to_be_ingested = true
--   persist_to_postgres = true
--   pull_type = 'full'  (small table; full replace each run)
--   persist_attributes_table = false
--   persist_hierarchies_table = false
--   cross_validations = NULL
--   source_table = 'fiscal_calendar_intermediate'  (or fiscal_date_mapping if BQ-only path)
--   destination_table = 'fiscal_date_mapping'
--
-- Insert via data_platform.save_generic_master_mapping(jsonb) OR platform UI —
-- NOT raw INSERT unless DI approves. Example shape only:
--
-- SELECT data_platform.save_generic_master_mapping('[
--   {
--     "master_table_name": "fiscal_date_mapping",
--     "source_table": "fiscal_calendar_intermediate",
--     "generic_mapping_table": "fiscal_generic_schema_mapping",
--     "destination_table": "fiscal_date_mapping",
--     "to_be_ingested": true,
--     "is_required_in_master": true,
--     "persist_attributes_table": false,
--     "persist_hierarchies_table": false,
--     "cross_validations": null,
--     "pull_type": "full",
--     "persist_to_postgres": true,
--     "data_loss_threshold": 5
--   }
-- ]'::jsonb);

-- -----------------------------------------------------------------------------
-- C) Sync procedure (after Dataflow lands public.fiscal_date_mapping_validated_table)
-- -----------------------------------------------------------------------------

-- SET ROLE "mtp-dev";
-- CALL public.sync_fiscal_date_mapping();

-- -----------------------------------------------------------------------------
-- D) Post-sync verification
-- -----------------------------------------------------------------------------

-- SELECT COUNT(*) FROM global.fiscal_date_mapping;
-- SELECT MIN(date), MAX(date) FROM global.fiscal_date_mapping;
-- SELECT fiscal_year, fiscal_year_week, COUNT(*) AS days
-- FROM global.fiscal_date_mapping
-- GROUP BY 1, 2
-- ORDER BY 1 DESC, 2 DESC
-- LIMIT 5;
