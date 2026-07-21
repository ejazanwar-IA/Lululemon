-- =============================================================================
-- GET ALL JOBS RUN BY A LIST OF USERS (for DevOps to run)
-- =============================================================================
-- Purpose: Audit / recover all BigQuery jobs run by a specific list of users
--          across a project. Useful for: build-SQL recovery, ad-hoc usage
--          audit, identifying authors of orphaned tables.
--
-- Run as : a principal with `bigquery.jobs.listAll` on the project being
--          scanned (predefined role: `roles/bigquery.resourceAdmin`).
--          The DevOps team has this; the requestor (Ejaz) does not.
--
-- Project: JOBS_BY_PROJECT lists jobs *billed* to the project, not jobs that
--          *wrote to* tables in the project. Default below scans
--          `lululemon-data-scan`. To also sweep `lululemon-01042025`, change
--          the project on the FROM line and re-run.
--
-- Users  : 6 unique principals (taken from the user-list image, 2026-05-13):
--            - sri.harsha@impactanalytics.co
--            - aniket.nichat@impactanalytics.co
--            - ejaz.anwar@impactanalytics.co
--            - ritik.prakash@impactanalytics.co
--            - shreyansh.jain@impactanalytics.co
--            - raghav.kirkol@impactanalytics.co
--
-- Output : two queries in this file. Run Query A first (cheap summary), then
--          Query B if the volume is reasonable (full detail, includes SQL text).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- QUERY A — SUMMARY: job counts per user × statement_type × destination dataset
--                    Use this FIRST. Tells you the volume before the detail pull.
-- -----------------------------------------------------------------------------

SELECT
  user_email,
  statement_type,
  destination_table.dataset_id          AS dest_dataset,
  COUNT(*)                              AS jobs,
  COUNTIF(error_result IS NOT NULL)     AS failed_jobs,
  COUNTIF(destination_table IS NOT NULL) AS jobs_with_destination,
  MIN(creation_time)                    AS earliest,
  MAX(creation_time)                    AS latest,
  SUM(total_bytes_processed) / POW(1024, 4) AS tib_processed
FROM `lululemon-data-scan.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
  AND state       = 'DONE'
  AND user_email IN (
    'sri.harsha@impactanalytics.co',
    'aniket.nichat@impactanalytics.co',
    'ejaz.anwar@impactanalytics.co',
    'ritik.prakash@impactanalytics.co',
    'shreyansh.jain@impactanalytics.co',
    'raghav.kirkol@impactanalytics.co'
  )
GROUP BY user_email, statement_type, dest_dataset
ORDER BY user_email, jobs DESC;


-- -----------------------------------------------------------------------------
-- QUERY B — DETAIL: every destination-writing job, with full SQL text.
--                   Skip SELECTs (anonymous-result writes); keep only the jobs
--                   that meaningfully changed the world. Save results to CSV.
-- -----------------------------------------------------------------------------

SELECT
  user_email,
  creation_time,
  end_time,
  job_id,
  statement_type,
  destination_table.project_id          AS dest_project,
  destination_table.dataset_id          AS dest_dataset,
  destination_table.table_id            AS dest_table,
  ARRAY_TO_STRING(
    ARRAY(
      SELECT FORMAT('%s.%s.%s', r.project_id, r.dataset_id, r.table_id)
      FROM UNNEST(referenced_tables) r
    ),
    ', '
  )                                     AS source_tables_csv,
  total_bytes_processed,
  state,
  error_result.message                  AS error_message,
  query
FROM `lululemon-data-scan.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
  AND user_email IN (
    'sri.harsha@impactanalytics.co',
    'aniket.nichat@impactanalytics.co',
    'ejaz.anwar@impactanalytics.co',
    'ritik.prakash@impactanalytics.co',
    'shreyansh.jain@impactanalytics.co',
    'raghav.kirkol@impactanalytics.co'
  )
  AND job_type     = 'QUERY'
  -- Exhaustive list of state-changing statement_types from BQ's QueryStatementType enum.
  -- Excludes only: SELECT, ASSERT, ALTER_RECOMMENDATION, ALTER_INSIGHT (non-state-changing).
  -- See: https://cloud.google.com/bigquery/docs/reference/auditlogs/rest/Shared.Types/BigQueryAuditMetadata.QueryStatementType
  AND statement_type IN (
    -- CREATE family (objects that hold logic / data)
    'CREATE_TABLE',
    'CREATE_TABLE_AS_SELECT',
    'CREATE_VIEW',
    'CREATE_MATERIALIZED_VIEW',
    'CREATE_APPROX_VIEW',
    'CREATE_EXTERNAL_TABLE',
    'CREATE_SNAPSHOT_TABLE',
    'CREATE_FUNCTION',
    'CREATE_TABLE_FUNCTION',
    'CREATE_PROCEDURE',         -- 7 of these already known to exist in this dataset
    'CREATE_MODEL',
    'CREATE_ROW_ACCESS_POLICY',
    'CREATE_SCHEMA',
    -- DML (rows in/out)
    'INSERT', 'MERGE', 'UPDATE', 'DELETE', 'TRUNCATE_TABLE', 'LOAD_DATA',
    -- ALTER (schema changes worth knowing about)
    'ALTER_TABLE', 'ALTER_VIEW', 'ALTER_MATERIALIZED_VIEW', 'ALTER_APPROX_VIEW', 'ALTER_SCHEMA',
    -- DROP (destructive — track who deleted what)
    'DROP_TABLE', 'DROP_EXTERNAL_TABLE', 'DROP_VIEW', 'DROP_MATERIALIZED_VIEW', 'DROP_APPROX_VIEW',
    'DROP_FUNCTION', 'DROP_PROCEDURE', 'DROP_SCHEMA', 'DROP_ROW_ACCESS_POLICY',
    'DROP_SNAPSHOT_TABLE', 'DROP_MODEL',
    -- Data movement / invocation
    'EXPORT_DATA',              -- data leaving BQ
    'CALL',                     -- procedure invocations (children appear as SCRIPT rows)
    'SCRIPT'                    -- multi-statement scripts; child statements appear as separate rows
  )
ORDER BY user_email, creation_time DESC;


-- -----------------------------------------------------------------------------
-- OPTIONAL — QUERY C: full audit. Every state-changing statement_type, robust
--                     to future BQ enum additions (uses NOT IN exclusion rather
--                     than IN whitelist). Excludes only read-only / metadata
--                     types: SELECT, ASSERT, ALTER_RECOMMENDATION, ALTER_INSIGHT.
--                     Volume can be large — Shreyansh's 90-day user history
--                     alone returned 343 SELECTs (which this query excludes).
--                     Uncomment if needed.
-- -----------------------------------------------------------------------------

-- SELECT
--   user_email,
--   creation_time,
--   job_id,
--   job_type,
--   statement_type,
--   destination_table.dataset_id AS dest_dataset,
--   destination_table.table_id   AS dest_table,
--   total_bytes_processed,
--   state,
--   query
-- FROM `lululemon-data-scan.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
-- WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
--   AND user_email IN (
--     'sri.harsha@impactanalytics.co',
--     'aniket.nichat@impactanalytics.co',
--     'ejaz.anwar@impactanalytics.co',
--     'ritik.prakash@impactanalytics.co',
--     'shreyansh.jain@impactanalytics.co',
--     'raghav.kirkol@impactanalytics.co'
--   )
--   AND statement_type IS NOT NULL
--   AND statement_type NOT IN ('SELECT', 'ASSERT', 'ALTER_RECOMMENDATION', 'ALTER_INSIGHT')
-- ORDER BY user_email, creation_time DESC;
