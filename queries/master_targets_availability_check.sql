-- =============================================================================
-- MASTER TARGETS — AVAILABILITY CHECK (as named in the CSV "Table name" column)
-- =============================================================================
-- Checks the 6 master-table names exactly as labelled:
--   inventory_master, transaction_master_20251119, store_master_20251119,
--   product_master, events_master, fiscal_date_mapping
-- =============================================================================

WITH expected AS (
  SELECT * FROM UNNEST([
    'inventory_master',
    'transaction_master_20251119',
    'store_master_20251119',
    'product_master',
    'events_master',
    'fiscal_date_mapping'
  ]) AS expected_name
)
SELECT
  e.expected_name,
  CASE WHEN tbl.table_id IS NULL THEN 'MISSING' ELSE 'OK' END           AS status,
  tbl.row_count,
  ROUND(tbl.size_bytes / POW(1024, 3), 2)                              AS size_gb,
  FORMAT_TIMESTAMP('%F %T', TIMESTAMP_MILLIS(tbl.creation_time))       AS created_at,
  FORMAT_TIMESTAMP('%F %T', TIMESTAMP_MILLIS(tbl.last_modified_time))  AS last_modified_at,
  CASE tbl.type
    WHEN 1 THEN 'TABLE'
    WHEN 2 THEN 'VIEW'
    WHEN 4 THEN 'EXTERNAL'
    WHEN 5 THEN 'MATERIALIZED VIEW'
    ELSE CAST(tbl.type AS STRING)
  END                                                                  AS kind
FROM expected e
LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.__TABLES__` tbl
  ON tbl.table_id = e.expected_name
ORDER BY
  CASE WHEN tbl.table_id IS NULL THEN 0 ELSE 1 END,
  e.expected_name;
