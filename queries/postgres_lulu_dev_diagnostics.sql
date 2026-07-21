-- =============================================================================
-- Lululemon lulu_dev Postgres diagnostics (read-only)
-- Run via postgres-lulu-dev MCP (lulu_pg_query) or psql — NOT BigQuery.
-- =============================================================================

-- 1) Sync success by day
SELECT created_at::date AS run_day,
       target_table_sp,
       MAX(CASE WHEN status = 'end' THEN 1 ELSE 0 END) AS succeeded
FROM global.data_ingestion_logs
WHERE target_table_sp IN ('public.sync_product_master', 'public.sync_store_master')
GROUP BY 1, 2
ORDER BY 1 DESC
LIMIT 20;

-- 2) GSM columns missing on global.product_master
SELECT g.generic_column_name, g.generic_column_datatype
FROM global.product_generic_schema_mapping g
WHERE g.required_in_product AND NOT g.is_attribute
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'global' AND c.table_name = 'product_master'
      AND c.column_name = g.generic_column_name)
ORDER BY 1;

-- 3) GSM columns missing on global.store_master
SELECT g.generic_column_name, g.generic_column_datatype
FROM global.store_generic_schema_mapping g
WHERE g.required_in_product AND NOT g.is_attribute
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'global' AND c.table_name = 'store_master'
      AND c.column_name = g.generic_column_name)
ORDER BY 1;

-- 4) Row counts: global masters vs validated staging
SELECT 'global.product_master' AS t, COUNT(*)::bigint AS n FROM global.product_master
UNION ALL SELECT 'public.product_validated_table', COUNT(*) FROM public.product_validated_table
UNION ALL SELECT 'global.store_master', COUNT(*) FROM global.store_master
UNION ALL SELECT 'public.store_validated_table', COUNT(*) FROM public.store_validated_table;

-- 5) Latest sync attempt per procedure
SELECT DISTINCT ON (target_table_sp)
  target_table_sp, status, error_message, created_at
FROM global.data_ingestion_logs
WHERE target_table_sp IN ('public.sync_product_master', 'public.sync_store_master')
ORDER BY target_table_sp, created_at DESC;

-- 6) GSM required_in_product=true missing from product_attributes_filter
--    (excludes PM-only defaults: clearance, price, cost, original_price, receipt_date, audit cols)
SELECT g.generic_column_name, g.is_attribute, g.generic_column_datatype
FROM global.product_generic_schema_mapping g
WHERE g.required_in_product
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'global'
      AND c.table_name = 'product_attributes_filter'
      AND c.column_name = g.generic_column_name)
ORDER BY 1;

-- 7) GSM is_attribute=false columns (sync_product_master targets)
SELECT g.generic_column_name,
       g.required_in_product,
       g.is_hierarchy,
       g.hierarchy_level,
       EXISTS (
         SELECT 1 FROM information_schema.columns c
         WHERE c.table_schema = 'global'
           AND c.table_name = 'product_master'
           AND c.column_name = g.generic_column_name
       ) AS on_product_master
FROM global.product_generic_schema_mapping g
WHERE NOT g.is_attribute
ORDER BY g.generic_column_name;

-- 8) active_flag vs active (common GSM mismatch)
SELECT
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'global' AND table_name = 'product_attributes_filter'
      AND column_name = 'active_flag'
  ) AS paf_has_active_flag,
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'global' AND table_name = 'product_attributes_filter'
      AND column_name = 'active'
  ) AS paf_has_active,
  EXISTS (
    SELECT 1 FROM global.product_generic_schema_mapping
    WHERE generic_column_name = 'active' AND NOT is_attribute
  ) AS gsm_has_active_on_pm;

-- 9) Product: PM rows missing EAV l0_name (build_product_attributes_filter gate; expect 0)
SELECT COUNT(*)::bigint AS pm_missing_eav_l0_name
FROM global.product_master pm
WHERE NOT EXISTS (
  SELECT 1 FROM global.product_attributes pa
  WHERE pa.product_code = pm.product_code
    AND pa.attribute_name = 'l0_name');

-- 10) Product: duplicate active PHF rows per product_code + level (expect 0 before hierarchy build)
SELECT COUNT(*)::bigint AS phf_duplicate_active_sku_level_groups
FROM (
  SELECT path ->> 'product_code' AS product_code, level
  FROM global.product_hierarchies_filter
  WHERE active
    AND path ->> 'product_code' IS NOT NULL
  GROUP BY 1, 2
  HAVING COUNT(*) > 1
) s;

-- 11) Store: GSM pivot type vs SAF column type mismatches (attribute cols only)
SELECT g.generic_column_name,
       g.generic_column_datatype AS gsm_datatype,
       c.data_type AS saf_datatype
FROM global.store_generic_schema_mapping g
JOIN information_schema.columns c
  ON c.table_schema = 'global'
 AND c.table_name = 'store_attributes_filter'
 AND c.column_name = g.generic_column_name
WHERE g.required_in_product
  AND g.is_attribute
  AND (
    (g.generic_column_datatype IN ('varchar', 'string') AND c.data_type <> 'character varying')
    OR (g.generic_column_datatype = 'integer' AND c.data_type NOT IN ('integer', 'bigint', 'smallint'))
    OR (g.generic_column_datatype = 'boolean' AND c.data_type <> 'boolean')
  )
ORDER BY 1;

-- 12) Store: active on GSM — must be is_attribute=false if column exists on store_master (avoid duplicate in SAF build)
SELECT g.generic_column_name, g.is_attribute,
       EXISTS (
         SELECT 1 FROM information_schema.columns c
         WHERE c.table_schema = 'global' AND c.table_name = 'store_master'
           AND c.column_name = g.generic_column_name
       ) AS on_store_master
FROM global.store_generic_schema_mapping g
WHERE g.generic_column_name IN ('active', 'store_name', 's3_id')
ORDER BY 1;
