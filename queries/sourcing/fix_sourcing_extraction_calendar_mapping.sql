-- Fix sourcing_extraction_* failure at fetch_the_sourcing_params
--
-- Error: AttributeError: 'NoneType' object has no attribute 'lower'
-- Cause: calendar row in view_mapping_table with NULL schedule_interval;
--        croniter(row["schedule_interval"]) in airflow_options/utils.py.
--
-- Fiscal calendar is built via Self-Help SQL (create_fiscal_calendar_intermediate_*.sql),
-- not GCS extraction — exclude it from view_mapping_table for the extraction DAG.
--
-- Applied 2026-05-27 on lulu_sourcing_dev (1 row updated).

UPDATE `lululemon-01042025.lulu_sourcing_dev.view_mapping_table`
SET is_deleted = TRUE
WHERE `table` = 'calendar'
  AND `view` = 'calendar_hierarchy'
  AND is_deleted = FALSE;

-- Optional: set exec order on mapping row (intermediate build DAG; not extraction)
UPDATE `lululemon-01042025.lulu_sourcing_dev.mapping`
SET inter_query_exec_order = 0
WHERE `table` = 'calendar'
  AND intermediate_table = 'fiscal_calendar_intermediate'
  AND is_deleted = FALSE;

-- Verify extraction DAG param query returns 7 GCS rows, all with schedule_interval:
-- SELECT v.table, v.view, v.schedule_interval, v.connector
-- FROM `lululemon-01042025.lulu_sourcing_dev.view_mapping_table` v
-- JOIN `lululemon-01042025.lulu_sourcing_dev.mapping` i ON v.table = i.table
-- WHERE v.is_deleted = FALSE AND i.is_deleted = FALSE AND v.view IS NOT NULL;
