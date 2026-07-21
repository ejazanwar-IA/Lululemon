-- =============================================================================
-- Dedupe global.product_hierarchies_filter before build_product_hierarchies_filter
-- =============================================================================
-- Symptom (create_hierarchies_filter_table_postgresql_product):
--   duplicate key value violates unique constraint "product_hierarchies_filter_un"
--
-- Cause: Many SKUs have two active rows at the same level with the same
-- path->>'product_code' but slightly different path JSON (e.g. legacy path
-- includes product_code_original; new path does not). The procedure UPDATE
-- sets both rows to the same new path → duplicate (path, level).
--
-- Run on dev/UAT after PAF rebuild, before build_product_hierarchies_filter.
-- =============================================================================

-- Pre-check: groups with >1 active row per product_code + level
SELECT COUNT(*) AS product_code_level_groups_with_dupes
FROM (
  SELECT path ->> 'product_code' AS product_code, level
  FROM global.product_hierarchies_filter
  WHERE active
    AND path ->> 'product_code' IS NOT NULL
  GROUP BY 1, 2
  HAVING COUNT(*) > 1
) s;

BEGIN;

WITH ranked AS (
  SELECT
    hierarchy_code,
    ROW_NUMBER() OVER (
      PARTITION BY path ->> 'product_code', level
      ORDER BY updated_at DESC NULLS LAST, hierarchy_code DESC
    ) AS rn
  FROM global.product_hierarchies_filter
  WHERE active
    AND path ->> 'product_code' IS NOT NULL
)
UPDATE global.product_hierarchies_filter phf
SET active = false,
    updated_at = NOW()
FROM ranked r
WHERE phf.hierarchy_code = r.hierarchy_code
  AND r.rn > 1;

COMMIT;

-- Post-check (expect 0)
SELECT COUNT(*) AS product_code_level_groups_with_dupes
FROM (
  SELECT path ->> 'product_code' AS product_code, level
  FROM global.product_hierarchies_filter
  WHERE active
    AND path ->> 'product_code' IS NOT NULL
  GROUP BY 1, 2
  HAVING COUNT(*) > 1
) s;

-- SET ROLE "mtp-dev";
-- CALL global.build_product_hierarchies_filter();
-- CALL global.build_product_hierarchies_filter_flattern();
