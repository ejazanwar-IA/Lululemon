-- =============================================================================
-- GET TABLE BUILD SQL FROM INFORMATION_SCHEMA.JOBS_BY_PROJECT
-- =============================================================================
-- Purpose: For each named raw "_cleaned" / master table, recover the most recent
--          successful query job that wrote to it, and return the source SQL
--          text. Use this when the build SQL was authored by another team
--          (e.g. the PC / DevOps Admin) and we need to capture it for our
--          lineage / master-build documentation.
--
-- Run as : a principal with `bigquery.jobs.listAll` on the project being
--          scanned (predefined role: `roles/bigquery.resourceAdmin`).
--          The DevOps Admin already has this on `lululemon-data-scan`.
--
-- Project: JOBS_BY_PROJECT lists jobs *billed* to the project, not jobs that
--          *wrote to* tables in that project. The build jobs may run from
--          either project. If the first project below returns 0 rows for a
--          given table, swap the project on line 36 and re-run.
--          - try first : lululemon-data-scan      (admin's normal scope)
--          - try second: lululemon-01042025       (where the data lives)
--
-- Output : one row per (dest_dataset, dest_table) — most recent build job.
--          Columns: dest_dataset, dest_table, statement_type, user_email,
--                   creation_time, source_tables_csv, job_id, query.
--
-- Notes  :
--  * `store_master` is listed in the user's request as living in
--    `lululemon_souricng_outbound`, but the canonical `store_master` actually
--    lives in `lulu_ingestion_dev` (see Lululemon BQ Context, Section 2.2).
--    This query does NOT filter on dest_dataset, so we'll pick up whichever
--    dataset the build job targeted, in either case.
--  * Per gotcha G8, several base names also have `_20251119` "live" variants.
--    Those are included below so we don't miss the active build SQL.
-- =============================================================================

WITH builds AS (
  SELECT
    destination_table.project_id  AS dest_project,
    destination_table.dataset_id  AS dest_dataset,
    destination_table.table_id    AS dest_table,
    statement_type,
    user_email,
    creation_time,
    end_time,
    job_id,
    total_bytes_processed,
    query,
    ARRAY_TO_STRING(
      ARRAY(
        SELECT FORMAT('%s.%s.%s', r.project_id, r.dataset_id, r.table_id)
        FROM UNNEST(referenced_tables) r
      ),
      ', '
    ) AS source_tables_csv,
    ROW_NUMBER() OVER (
      PARTITION BY destination_table.dataset_id, destination_table.table_id
      ORDER BY creation_time DESC
    ) AS rn
  FROM `lululemon-data-scan.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
  WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
    AND job_type        = 'QUERY'
    AND state           = 'DONE'
    AND error_result    IS NULL
    AND destination_table.table_id IN (
      -- user-requested base names
      'inventory_snapshot_cleaned',
      'product_group_hierarchy_cleaned',
      'sales_transactions_4y_cleaned',
      'store_master',
      'location_group_hierarchy_cleaned',
      'location_details_cleaned',
      'promotional_events_cleaned',
      'calendar_hierarchy',
      -- _20251119 "live" variants per gotcha G8
      'product_group_hierarchy_cleaned_20251119',
      'location_group_hierarchy_cleaned_20251119',
      'location_details_cleaned_20251119',
      'sales_transactions_4y_cleaned_20251119'
    )
    -- statement_type is a single enum (BQ QueryStatementType). We list every
    -- value that legitimately writes to a destination table:
    --   CREATE_TABLE_AS_SELECT  CREATE [OR REPLACE] TABLE foo AS SELECT ...
    --   CREATE_TABLE            CREATE [OR REPLACE] TABLE foo (col INT64)
    --   INSERT / MERGE / UPDATE the obvious DML
    --   LOAD_DATA               LOAD DATA INTO foo FROM FILES (...)
    --   SCRIPT                  multi-statement scripts; parent row carries
    --                           the destination_table when applicable
    -- Note: there is no CREATE_OR_REPLACE_TABLE enum — "OR REPLACE" is folded
    -- into CREATE_TABLE / CREATE_TABLE_AS_SELECT.
    AND statement_type IN (
      'CREATE_TABLE_AS_SELECT',
      'CREATE_TABLE',
      'INSERT',
      'MERGE',
      'UPDATE',
      'LOAD_DATA',
      'SCRIPT'
    )
)
SELECT
  dest_project,
  dest_dataset,
  dest_table,
  statement_type,
  user_email,
  creation_time,
  source_tables_csv,
  job_id,
  query
FROM builds
WHERE rn = 1
ORDER BY dest_dataset, dest_table;
