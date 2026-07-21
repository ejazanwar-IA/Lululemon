-- Fiscal pipeline validation gates (BQ + cross-layer)
-- Run read-only via lululemon-data-scan (BQ) and postgres preflight (PG).

-- =============================================================================
-- BQ — raw
-- =============================================================================
SELECT
  'raw.calendar_hierarchy' AS gate,
  COUNT(*) AS row_count,
  COUNT(DISTINCT DAY_ID) AS distinct_days,
  MIN(DAY_ID) AS min_date,
  MAX(DAY_ID) AS max_date
FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`;

-- =============================================================================
-- BQ — sourcing intermediate (after create_fiscal_calendar_intermediate_*.sql)
-- =============================================================================
SELECT
  'sourcing.fiscal_calendar_intermediate' AS gate,
  COUNT(*) AS row_count,
  COUNT(DISTINCT DATE) AS distinct_dates,
  MIN(DATE) AS min_date,
  MAX(DATE) AS max_date
FROM `lululemon-01042025.lulu_sourcing_dev.fiscal_calendar_intermediate`;

-- Week grain sanity: 7 days per fiscal_year_week (flag weeks != 7)
SELECT
  fiscal_year_week,
  COUNT(*) AS days_in_week
FROM `lululemon-01042025.lulu_sourcing_dev.fiscal_calendar_intermediate`
GROUP BY 1
HAVING COUNT(*) NOT IN (7, 8)  -- 53-week years may have edge cases
ORDER BY 1
LIMIT 20;

-- =============================================================================
-- BQ — ingestion master
-- =============================================================================
SELECT
  'ingestion.fiscal_date_mapping' AS gate,
  COUNT(*) AS row_count,
  COUNT(DISTINCT date) AS distinct_dates,
  MIN(date) AS min_date,
  MAX(date) AS max_date
FROM `lululemon-01042025.lulu_ingestion_dev.fiscal_date_mapping`;

-- Txn dates missing from fiscal (expect 0)
SELECT COUNT(DISTINCT t.date) AS txn_dates_missing_fiscal
FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master` t
WHERE NOT EXISTS (
  SELECT 1
  FROM `lululemon-01042025.lulu_ingestion_dev.fiscal_date_mapping` f
  WHERE f.date = t.date
);

-- =============================================================================
-- Cross-layer row-count parity (expect match after full rebuild)
-- =============================================================================
SELECT
  (SELECT COUNT(*) FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`) AS raw_rows,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.fiscal_calendar_intermediate`) AS intermediate_rows,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.fiscal_date_mapping`) AS master_rows;
