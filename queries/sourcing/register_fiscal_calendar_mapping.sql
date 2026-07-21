-- Register fiscal calendar in lulu_sourcing_dev platform config
--
-- Run after create_fiscal_calendar_intermediate_full.sql succeeds.
-- Requires write access on lulu_sourcing_dev.mapping + view_mapping_table.
--
-- Pre-check (read-only):
--   SELECT table, intermediate_table, is_deleted
--   FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
--   WHERE intermediate_table LIKE '%fiscal%' OR `table` LIKE '%fiscal%';

-- =============================================================================
-- 1) view_mapping_table — DO NOT register calendar for GCS extraction
-- =============================================================================
-- Fiscal calendar is built via Self-Help SQL (create_fiscal_calendar_intermediate_*.sql),
-- not GCS extraction. A view_mapping row with NULL schedule_interval breaks
-- sourcing_extraction_* at fetch_the_sourcing_params (croniter AttributeError).
--
-- If a calendar row was added earlier, soft-delete it:
--   UPDATE `lululemon-01042025.lulu_sourcing_dev.view_mapping_table`
--   SET is_deleted = TRUE
--   WHERE `table` = 'calendar' AND `view` = 'calendar_hierarchy';

-- =============================================================================
-- 2) mapping — intermediate build registration
-- =============================================================================

MERGE `lululemon-01042025.lulu_sourcing_dev.mapping` AS target
USING (
  SELECT
    'calendar' AS `table`,
    'fiscal_calendar_intermediate' AS intermediate_table,
    DATE '2026-05-01' AS dataingestion_filterparam,
    CAST(NULL AS TIMESTAMP) AS filter_param,
    'full' AS pull_type,
    0 AS inter_query_exec_order,
    FALSE AS is_deleted
) AS source
ON target.`table` = source.`table`
  AND target.intermediate_table = source.intermediate_table
WHEN MATCHED THEN UPDATE SET
  dataingestion_filterparam = source.dataingestion_filterparam,
  filter_param = source.filter_param,
  pull_type = source.pull_type,
  inter_query_exec_order = source.inter_query_exec_order,
  is_deleted = source.is_deleted
WHEN NOT MATCHED THEN INSERT (
  `table`, intermediate_table, dataingestion_filterparam, filter_param, pull_type,
  inter_query_exec_order, is_deleted
) VALUES (
  source.`table`, source.intermediate_table, source.dataingestion_filterparam,
  source.filter_param, source.pull_type, source.inter_query_exec_order, source.is_deleted
);

-- =============================================================================
-- 3) Post-register verification (read-only)
-- =============================================================================
-- SELECT * FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
-- WHERE intermediate_table = 'fiscal_calendar_intermediate';
-- SELECT COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.fiscal_calendar_intermediate`;
