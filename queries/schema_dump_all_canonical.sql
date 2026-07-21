-- =============================================================================
-- Schema Dump - All Canonical Raw Tables
-- Metadata-only. Returns schemas + partitioning info + row counts for every
-- canonical table in one result set.
-- =============================================================================

WITH canonical_tables AS (
  SELECT tbl FROM UNNEST([
    'product_master',
    'transaction_master',
    'inventory_master',
    'store_master',
    'calendar_hierarchy',
    'returns_transactions_20251119',
    'price_book',
    'purchase_orders_cleaned_20251119',
    'transfer_orders_cleaned_20251119',
    'transfer_orders_new_cleaned',
    'promotional_events_cleaned_20251119',
    'eligibility_20251119',
    'eligibility_cleaned_20251119',
    'assortment_plan_cleaned',
    'anaplan_allocation_calendar_cleaned',
    'anaplan_fdod_alloc_cleaned',
    'anaplan_fdod_replen_cleaned',
    'anaplan_min_pres_cleaned',
    'anaplan_transit_calender_cleaned',
    'dc_store_mapping_cleaned_20251119',
    'anaplan_store_priority_cleaned',
    'spatial_ai_cleaned',
    'style_option_20251119',
    'sku_details_cleaned',
    'product_group_hierarchy',
    'min_pres_eol'
  ]) AS tbl
),

-- Schemas for all canonical tables
schemas AS (
  SELECT
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.is_nullable
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS` c
  JOIN canonical_tables ct ON c.table_name = ct.tbl
),

-- Partitioning / clustering info from DDL
ddl_info AS (
  SELECT
    t.table_name,
    REGEXP_EXTRACT(t.ddl, r'PARTITION BY\s+([^\s\n]+)') AS partition_expression,
    REGEXP_EXTRACT(t.ddl, r'CLUSTER BY\s+([^\n]+?)(?:OPTIONS|\n|$)') AS cluster_expression,
    t.table_type
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.TABLES` t
  JOIN canonical_tables ct ON t.table_name = ct.tbl
),

-- Row counts + sizes
sizes AS (
  SELECT
    table_id AS table_name,
    row_count,
    ROUND(size_bytes / POW(1024, 3), 2) AS size_gb
  FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
  WHERE table_id IN (SELECT tbl FROM canonical_tables)
)

SELECT
  'SCHEMA' AS section,
  table_name,
  CAST(ordinal_position AS STRING) AS key,
  CONCAT(column_name, ' :: ', data_type, CASE WHEN is_nullable = 'YES' THEN ' (nullable)' ELSE '' END) AS value
FROM schemas

UNION ALL

SELECT 'DDL' AS section, table_name, 'table_type' AS key, table_type AS value FROM ddl_info
UNION ALL
SELECT 'DDL', table_name, 'partition_by', COALESCE(partition_expression, '<none>') FROM ddl_info
UNION ALL
SELECT 'DDL', table_name, 'cluster_by', COALESCE(cluster_expression, '<none>') FROM ddl_info

UNION ALL

SELECT 'SIZE', table_name, 'row_count', CAST(row_count AS STRING) FROM sizes
UNION ALL
SELECT 'SIZE', table_name, 'size_gb', CAST(size_gb AS STRING) FROM sizes

ORDER BY section, table_name, SAFE_CAST(key AS INT64) NULLS LAST, key;
