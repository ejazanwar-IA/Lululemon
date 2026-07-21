-- =============================================================================
-- RAW SOURCE TABLE EXISTENCE CHECK
-- =============================================================================
-- Purpose: Before running the verification queries, confirm each raw table
--          actually exists in the dataset and find the correct name if the
--          _20251119 suffix variant is missing.
--
-- Returns: 1 row. JSON of table name → status + row count + size.
-- =============================================================================

WITH target_tables AS (
  SELECT * FROM UNNEST([
    STRUCT('sku_details_cleaned_20251119' AS expected_name),
    STRUCT('sku_details_cleaned'),
    STRUCT('sku_details'),
    STRUCT('product_attribute_s_20251119'),
    STRUCT('product_attribute_s'),
    STRUCT('product_attribute_s_cleaned'),
    STRUCT('location_group_hierarchy_cleaned_20251119'),
    STRUCT('location_group_hierarchy_cleaned'),
    STRUCT('location_group_hierarchy'),
    STRUCT('location_details_cleaned_20251119'),
    STRUCT('location_details_cleaned'),
    STRUCT('inventory_snapshot_cleaned'),
    STRUCT('inventory_snapshot'),
    STRUCT('product_group_hierarchy_cleaned_20251119'),
    STRUCT('product_group_hierarchy_cleaned'),
    STRUCT('product_group_hierarchy'),
    STRUCT('sales_transactions_4y_cleaned_20251119'),
    STRUCT('sales_transactions_4y_cleaned'),
    STRUCT('sales_transactions_4y'),
    STRUCT('sales_transactions')
  ])
)
SELECT
  TO_JSON_STRING(ARRAY_AGG(
    STRUCT(
      t.expected_name,
      IFNULL(tbl.table_id, '— NOT FOUND —') AS actual_name,
      tbl.row_count,
      ROUND(tbl.size_bytes / POW(1024, 3), 2) AS size_gb
    )
    ORDER BY t.expected_name
  )) AS existence_check_json
FROM target_tables t
LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.__TABLES__` tbl
  ON tbl.table_id = t.expected_name;

-- -----------------------------------------------------------------------------
-- Fuzzy search — find all tables containing these keywords
-- Run this separately if anything above is "— NOT FOUND —"
-- -----------------------------------------------------------------------------
/*
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 2) AS size_gb
FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
WHERE
     LOWER(table_id) LIKE '%sku_detail%'
  OR LOWER(table_id) LIKE '%product_attribute%'
  OR LOWER(table_id) LIKE '%location_group%'
  OR LOWER(table_id) LIKE '%location_detail%'
  OR LOWER(table_id) LIKE '%inventory_snapshot%'
  OR LOWER(table_id) LIKE '%product_group_hierarchy%'
  OR LOWER(table_id) LIKE '%sales_transaction%'
ORDER BY table_id;
*/
