-- Lululemon lulu_dev ingestion preflight gates (read-only)
-- Consumed by scripts/postgres_ingestion_preflight.sh
-- One row per gate: gate_id | gate_name | actual | expected | severity | passed (t/f)

SELECT gate_id, gate_name, actual::text, expected::text, severity, passed::text
FROM (
  SELECT
    'G01' AS gate_id,
    'product_master_missing_gsm_pm_columns' AS gate_name,
    COUNT(*)::bigint AS actual,
    0::bigint AS expected,
    'fail' AS severity,
    (COUNT(*) = 0) AS passed
  FROM global.product_generic_schema_mapping g
  WHERE g.required_in_product AND NOT g.is_attribute
    AND NOT EXISTS (
      SELECT 1 FROM information_schema.columns c
      WHERE c.table_schema = 'global' AND c.table_name = 'product_master'
        AND c.column_name = g.generic_column_name)

  UNION ALL

  SELECT
    'G02',
    'store_master_missing_gsm_pm_columns',
    COUNT(*)::bigint,
    0::bigint,
    'fail',
    (COUNT(*) = 0)
  FROM global.store_generic_schema_mapping g
  WHERE g.required_in_product AND NOT g.is_attribute
    AND NOT EXISTS (
      SELECT 1 FROM information_schema.columns c
      WHERE c.table_schema = 'global' AND c.table_name = 'store_master'
        AND c.column_name = g.generic_column_name)

  UNION ALL

  SELECT
    'G03',
    'product_pm_missing_eav_l0_name',
    COUNT(*)::bigint,
    0::bigint,
    'fail',
    (COUNT(*) = 0)
  FROM global.product_master pm
  WHERE NOT EXISTS (
    SELECT 1 FROM global.product_attributes pa
    WHERE pa.product_code = pm.product_code
      AND pa.attribute_name = 'l0_name')

  UNION ALL

  SELECT
    'G04',
    'product_hierarchies_filter_duplicate_active_sku_level',
    COUNT(*)::bigint,
    0::bigint,
    'fail',
    (COUNT(*) = 0)
  FROM (
    SELECT path ->> 'product_code' AS product_code, level
    FROM global.product_hierarchies_filter
    WHERE active
      AND path ->> 'product_code' IS NOT NULL
    GROUP BY 1, 2
    HAVING COUNT(*) > 1
  ) s

  UNION ALL

  SELECT
    'G05',
    'store_saf_gsm_datatype_mismatches',
    COUNT(*)::bigint,
    0::bigint,
    'fail',
    (COUNT(*) = 0)
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

  UNION ALL

  SELECT
    'G06',
    'store_active_gsm_is_attribute_true',
    COUNT(*)::bigint,
    0::bigint,
    'warn',
    (COUNT(*) = 0)
  FROM global.store_generic_schema_mapping g
  WHERE g.generic_column_name = 'active'
    AND g.is_attribute
    AND EXISTS (
      SELECT 1 FROM information_schema.columns c
      WHERE c.table_schema = 'global' AND c.table_name = 'store_master'
        AND c.column_name = 'active')

  UNION ALL

  SELECT
    'G07',
    'latest_sync_product_master_not_end',
    CASE WHEN COALESCE(l.status, '') = 'end' THEN 0 ELSE 1 END::bigint,
    0::bigint,
    'warn',
    (COALESCE(l.status, '') = 'end')
  FROM (
    SELECT status
    FROM global.data_ingestion_logs
    WHERE target_table_sp = 'public.sync_product_master'
    ORDER BY created_at DESC
    LIMIT 1
  ) l

  UNION ALL

  SELECT
    'G08',
    'latest_sync_store_master_not_end',
    CASE WHEN COALESCE(l.status, '') = 'end' THEN 0 ELSE 1 END::bigint,
    0::bigint,
    'warn',
    (COALESCE(l.status, '') = 'end')
  FROM (
    SELECT status
    FROM global.data_ingestion_logs
    WHERE target_table_sp = 'public.sync_store_master'
    ORDER BY created_at DESC
    LIMIT 1
  ) l
) gates
ORDER BY gate_id;
