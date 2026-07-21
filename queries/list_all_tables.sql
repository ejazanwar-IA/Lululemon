-- =============================================================================
-- List all tables in lululemon_souricng_outbound dataset
-- With row counts, size, and last-modified timestamp.
-- =============================================================================

SELECT
  table_id                                                AS table_name,
  row_count,
  ROUND(size_bytes / POW(1024, 2), 2)                     AS size_mb,
  ROUND(size_bytes / POW(1024, 3), 2)                     AS size_gb,
  FORMAT_TIMESTAMP('%Y-%m-%d %H:%M', TIMESTAMP_MILLIS(creation_time))       AS created,
  FORMAT_TIMESTAMP('%Y-%m-%d %H:%M', TIMESTAMP_MILLIS(last_modified_time))  AS last_modified
FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
ORDER BY row_count DESC;


-- Fallback: if __TABLES__ doesn't work (rare), run this INFORMATION_SCHEMA
-- version instead (no row counts, just the list of tables):
--
-- SELECT
--   table_name,
--   table_type,
--   FORMAT_TIMESTAMP('%Y-%m-%d', creation_time) AS created
-- FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.TABLES`
-- ORDER BY table_name;
