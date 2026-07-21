-- =============================================================================
-- MASTER-BUILD TABLES — AVAILABILITY CHECK
-- =============================================================================
-- Scope: ONLY the 14 tables that appear verbatim in the 6 master-build DDL
--        texts we have on record. We do NOT include tables that are only
--        implied by a "Table name" label — those are listed separately
--        (transaction_master_20251119, events_master) as inferred targets
--        whose DDL wrapper was not provided.
--
-- Dataset: lululemon-01042025.lululemon_souricng_outbound
-- Returns: 1 row per expected table (NULL metadata => NOT FOUND).
-- =============================================================================

WITH expected AS (
  SELECT * FROM UNNEST([
    -- ---------- Q1 inventory_master ----------------------------------------
    STRUCT('inventory_snapshot_cleaned'                 AS expected_name, 'Q1 inventory_master'  AS used_by, 'source' AS role),
    STRUCT('product_group_hierarchy_cleaned',                             'Q1 inventory_master',             'source'),
    STRUCT('inventory_master',                                            'Q1 inventory_master',             'target'),

    -- ---------- Q2 transaction_master (SELECT only; target is implied) -----
    STRUCT('sales_transactions_4y_cleaned_20251119',                      'Q2 transaction_master',           'source'),
    STRUCT('product_group_hierarchy_cleaned_20251119',                    'Q2 + Q4',                         'source'),
    STRUCT('sku_details_cleaned_20251119',                                'Q2 + Q4',                         'source'),
    STRUCT('store_master_20251119',                                       'Q2 (source) + Q3 (target)',       'source+target'),

    -- ---------- Q3 store_master --------------------------------------------
    STRUCT('location_group_hierarchy_cleaned_20251119',                   'Q3 store_master',                 'source'),
    STRUCT('location_details_cleaned_20251119',                           'Q3 store_master',                 'source'),

    -- ---------- Q4 product_master ------------------------------------------
    STRUCT('product_master_20251119',                                     'Q4 product_master',               'target'),
    STRUCT('product_attribute_s_20251119',                                'Q4 product_master',               'source'),

    -- ---------- Q5 events_master (SELECT only; target is implied) ----------
    STRUCT('promotional_events_cleaned',                                  'Q5 events_master',                'source'),

    -- ---------- Q6 fiscal_date_mapping -------------------------------------
    STRUCT('fiscal_date_mapping',                                         'Q6 fiscal_date_mapping',          'target'),
    STRUCT('calendar_hierarchy',                                          'Q6 fiscal_date_mapping',          'source')
  ])
)
SELECT
  e.expected_name,
  e.used_by,
  e.role,
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
  CASE WHEN tbl.table_id IS NULL THEN 0 ELSE 1 END,   -- MISSING first
  e.role DESC,
  e.expected_name;


-- =============================================================================
-- Inferred-but-not-in-DDL targets (Q2 + Q5 did not include a CREATE/INSERT
-- wrapper, so these names come only from the "Table name" column label).
-- Check only if you still want evidence of whether they exist anywhere.
-- =============================================================================
/*
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 2)                              AS size_gb,
  FORMAT_TIMESTAMP('%F %T', TIMESTAMP_MILLIS(last_modified_time))  AS last_modified_at
FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
WHERE table_id IN ('transaction_master_20251119', 'events_master')
   OR LOWER(table_id) LIKE 'transaction_master%'
   OR LOWER(table_id) LIKE 'events_master%'
ORDER BY table_id;
*/
