-- Inventory snapshot batch comparison (read-only external-table scans)
-- Billing project: lululemon-data-scan
-- Run one batch at a time via bq query --external_table_definition=t::/path/to/json
--
-- Example:
--   bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
--     --external_table_definition=t::/tmp/lulu_inv/nov.json \
--     "$(sed -n '/^-- AGG:/,/^-- END/p' queries/inventory_snapshot_batch_compare.sql | grep -v '^--')"

-- AGG: per-batch row / grain / snapshot-date summary
SELECT
  COUNT(*) AS row_cnt,
  COUNT(DISTINCT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE)) AS distinct_grains,
  COUNT(DISTINCT SAFE_CAST(DATE AS DATE)) AS distinct_snapshot_dates,
  MIN(SAFE_CAST(DATE AS DATE)) AS min_snapshot_date,
  MAX(SAFE_CAST(DATE AS DATE)) AS max_snapshot_date,
  ROUND(
    COUNT(*) / NULLIF(COUNT(DISTINCT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE)), 0),
    2
  ) AS dup_ratio
FROM t;
-- END

-- OVERLAP: NOV vs 2026-05-08 BQ-mix source CSVs
-- Requires: --external_table_definition=nov::... --external_table_definition=mix::...
WITH keys AS (
  SELECT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE) AS k, "n" AS src FROM nov
  UNION ALL
  SELECT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE) AS k, "m" AS src FROM mix
),
g AS (
  SELECT k, LOGICAL_OR(src = "n") AS has_n, LOGICAL_OR(src = "m") AS has_m
  FROM keys GROUP BY k
)
SELECT
  COUNTIF(has_n AND has_m) AS in_both,
  COUNTIF(has_n AND NOT has_m) AS nov_only,
  COUNTIF(has_m AND NOT has_n) AS mix_only,
  COUNT(*) AS union_keys
FROM g;

-- BQ table load duplication check (native table, no external def)
-- SELECT
--   COUNT(*) AS bq_rows,
--   COUNT(DISTINCT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE)) AS bq_distinct_grains,
--   COUNT(DISTINCT SAFE_CAST(DATE AS DATE)) AS bq_distinct_dates
-- FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`;

-- GCS URI patterns (external table sourceUris):
-- AUG:    gs://client_data_lululemon/Historic/s3_to_gcs/2025-08-28/outbound/inventory_snapshot/new/*
-- OCT:    gs://client_data_lululemon/Historic/s3_to_gcs/2025-10-08/outbound/inventory_snapshot/new/*
-- NOV:    gs://client_data_lululemon/Historic/s3_to_gcs/2025-11-18/outbound/inventory_snapshot/new/*
-- DEC02:  gs://client_data_lululemon/Historic/s3_to_gcs/2025-12-03/outbound/inventory_snapshot/new/*
-- DEC04:  gs://client_data_lululemon/Historic/s3_to_gcs/2025-12-05/outbound/inventory_snapshot/new/inventory_snapshot*.csv
-- BQ mix: gs://client_data_lululemon/Historic/s3_to_gcs/2026-05-08/inventory_snapshot*.csv
