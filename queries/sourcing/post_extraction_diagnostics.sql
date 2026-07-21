-- Post sourcing-extraction DAG diagnostics (read-only)
-- Run after sourcing_extraction_* completes. Billing project: lululemon-data-scan
--
-- Answers: Did raw tables grow? Was data appended? Any new SYNCSTARTDATETIME?

-- =============================================================================
-- 1) Checkpoint vs table metadata (quick gate)
-- =============================================================================
SELECT
  v.table,
  v.view,
  CAST(v.filter_param AS STRING) AS filter_param_after_run,
  CAST(v.extraction_sync_dt AS STRING) AS extraction_sync_dt,
  t.row_count,
  TIMESTAMP_MILLIS(t.last_modified_time) AS table_last_modified
FROM `lululemon-01042025.lulu_sourcing_dev.view_mapping_table` v
LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.__TABLES__` t
  ON v.view = t.table_id
WHERE v.is_deleted = FALSE
ORDER BY v.table, v.view;

-- =============================================================================
-- 2) Per-feed: total rows, max sync, distinct sync timestamps
--    (single sync value = one GCS drop loaded; no newer drop yet)
-- =============================================================================
SELECT
  'product_group_hierarchy' AS raw_table,
  COUNT(*) AS row_count,
  MAX(SYNCSTARTDATETIME) AS max_sync,
  COUNT(DISTINCT SYNCSTARTDATETIME) AS distinct_sync_ts
FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
UNION ALL
SELECT 'sku_details', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
UNION ALL
SELECT 'product_attribute_s', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
UNION ALL
SELECT 'location_details', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
UNION ALL
SELECT 'location_group_hierarchy', COUNT(*), MAX(SYNCSTARTDATETIME), COUNT(DISTINCT SYNCSTARTDATETIME)
FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`;

-- Large tables — run separately with higher bytes cap if needed:
-- sales_transactions (~683M rows), inventory_snapshot (~404M rows)

-- =============================================================================
-- 3) Rows loaded AFTER a checkpoint (replace @checkpoint with pre-run filter_param)
-- =============================================================================
-- DECLARE checkpoint DATETIME DEFAULT DATETIME('2026-05-19 09:21:05');
-- SELECT COUNT(*) AS incremental_rows, MAX(SYNCSTARTDATETIME) AS max_sync
-- FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
-- WHERE SYNCSTARTDATETIME > checkpoint;

-- =============================================================================
-- 4) Append duplicate smell (same id + same sync timestamp twice)
-- =============================================================================
-- SELECT ID, SYNCSTARTDATETIME, COUNT(*) AS c
-- FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
-- GROUP BY 1, 2 HAVING COUNT(*) > 1
-- ORDER BY c DESC LIMIT 20;
