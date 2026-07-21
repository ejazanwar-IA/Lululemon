-- =============================================================================
-- Backfill global.product_attributes.l0_name after GSM / sync_product_master
-- =============================================================================
-- Symptom (Airflow create_attributes_filter_table_postgresql_product):
--   Ingestion needs attention: N products without attributes.
--
-- Cause: global.build_product_attributes_filter() requires every row in
-- global.product_master to have attribute_name = 'l0_name' in the EAV table
-- global.product_attributes — even when GSM has l0_name as is_attribute=false
-- (column on product_master from sync_product_master).
--
-- After moving l0_name to product_master, sync updates PM but does not insert
-- matching EAV rows for products that were missing l0_name in product_attributes.
--
-- Run on dev/UAT after sync_product_master succeeds, before
-- create_attributes_filter_table_postgresql_product.
-- =============================================================================

-- Pre-check
SELECT COUNT(*) AS products_missing_l0_name_attr
FROM global.product_master pm
WHERE NOT EXISTS (
  SELECT 1
  FROM global.product_attributes pa
  WHERE pm.product_code = pa.product_code
    AND pa.attribute_name = 'l0_name'
);

BEGIN;

INSERT INTO global.product_attributes (product_code, attribute_name, attribute_value)
SELECT pm.product_code,
       'l0_name',
       pm.l0_name
FROM global.product_master pm
WHERE pm.l0_name IS NOT NULL
  AND pm.l0_name <> ''
  AND NOT EXISTS (
    SELECT 1
    FROM global.product_attributes pa
    WHERE pa.product_code = pm.product_code
      AND pa.attribute_name = 'l0_name'
  );

COMMIT;

-- Post-check (expect 0)
SELECT COUNT(*) AS products_missing_l0_name_attr
FROM global.product_master pm
WHERE NOT EXISTS (
  SELECT 1
  FROM global.product_attributes pa
  WHERE pm.product_code = pa.product_code
    AND pa.attribute_name = 'l0_name'
);

-- SET ROLE "mtp-dev";
-- CALL global.build_product_attributes_filter('');
