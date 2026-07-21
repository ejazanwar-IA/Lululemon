-- product_attribute_s EDA (Req 12: Product attributes)
-- Billing project: lululemon-data-scan
-- Table: lululemon-01042025.lulu_sourcing_dev.product_attribute_s
-- Verified reload: 2026-07-02 (86,135 rows, 1 row per STYLE_ID)
-- Run sections independently in BigQuery Console.

-- =============================================================================
-- 0) Foundation: row counts, schema, metadata
-- =============================================================================

SELECT
  table_id,
  row_count,
  ROUND(size_bytes / 1e6, 2) AS size_mb,
  TIMESTAMP_MILLIS(creation_time) AS created,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified
FROM `lululemon-01042025.lulu_sourcing_dev.__TABLES__`
WHERE table_id = 'product_attribute_s';

SELECT table_name, column_name, data_type, ordinal_position
FROM `lululemon-01042025.lulu_sourcing_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'product_attribute_s'
ORDER BY ordinal_position;

SELECT COUNT(*) AS row_count,
  COUNT(DISTINCT STYLE_ID) AS distinct_style_id
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`;

-- =============================================================================
-- 1) Grain: STYLE_ID uniqueness
-- =============================================================================

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT STYLE_ID) AS distinct_style_id,
  COUNT(*) - COUNT(DISTINCT STYLE_ID) AS duplicate_rows,
  ROUND(100 * (COUNT(*) - COUNT(DISTINCT STYLE_ID)) / COUNT(*), 4) AS dup_pct
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`;

WITH g AS (
  SELECT STYLE_ID, COUNT(*) AS c
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  GROUP BY 1
  HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS duplicate_style_groups, COALESCE(SUM(c - 1), 0) AS extra_rows
FROM g;

-- =============================================================================
-- 2) Completeness: 14 build-used columns + key long-tail attrs
-- Sentinel: NULL, empty, \N, \\N
-- =============================================================================

SELECT
  col,
  missing,
  total,
  ROUND(100 * missing / total, 2) AS pct_missing
FROM (
  SELECT 'STYLE_ID' AS col,
    COUNTIF(NULLIF(TRIM(STYLE_ID), '') IS NULL OR TRIM(STYLE_ID) IN ('\\N', '\\\\N')) AS missing,
    COUNT(*) AS total
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'GENDER',
    COUNTIF(NULLIF(TRIM(GENDER), '') IS NULL OR GENDER IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'SILHOUETTE',
    COUNTIF(NULLIF(TRIM(SILHOUETTE), '') IS NULL OR SILHOUETTE IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'PLANNING_PRODUCT_GROUPING',
    COUNTIF(NULLIF(TRIM(PLANNING_PRODUCT_GROUPING), '') IS NULL OR PLANNING_PRODUCT_GROUPING IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'FLEX_STATUS',
    COUNTIF(NULLIF(TRIM(FLEX_STATUS), '') IS NULL OR FLEX_STATUS IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'GLOBAL_MERCH_TEAM',
    COUNTIF(NULLIF(TRIM(GLOBAL_MERCH_TEAM), '') IS NULL OR GLOBAL_MERCH_TEAM IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'FIT_CLASSIFICATION',
    COUNTIF(NULLIF(TRIM(FIT_CLASSIFICATION), '') IS NULL OR FIT_CLASSIFICATION IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'DESIGN_LINE',
    COUNTIF(NULLIF(TRIM(DESIGN_LINE), '') IS NULL OR DESIGN_LINE IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'DESIGNED_FOR_ACTIVITY',
    COUNTIF(NULLIF(TRIM(DESIGNED_FOR_ACTIVITY), '') IS NULL OR DESIGNED_FOR_ACTIVITY IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'PRODUCT_LINE',
    COUNTIF(NULLIF(TRIM(PRODUCT_LINE), '') IS NULL OR PRODUCT_LINE IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'SIZE_SCALE',
    COUNTIF(NULLIF(TRIM(SIZE_SCALE), '') IS NULL OR SIZE_SCALE IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'PRODUCT_DEVELOPMENT_POD',
    COUNTIF(NULLIF(TRIM(PRODUCT_DEVELOPMENT_POD), '') IS NULL OR PRODUCT_DEVELOPMENT_POD IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'PRODUCT_SIZE_DEFINITION',
    COUNTIF(NULLIF(TRIM(PRODUCT_SIZE_DEFINITION), '') IS NULL OR PRODUCT_SIZE_DEFINITION IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'GLOBAL_LINE_SEGMENT_STYLE_CATEGORY',
    COUNTIF(NULLIF(TRIM(GLOBAL_LINE_SEGMENT_STYLE_CATEGORY), '') IS NULL OR GLOBAL_LINE_SEGMENT_STYLE_CATEGORY IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'PRODUCT_GENDER',
    COUNTIF(NULLIF(TRIM(PRODUCT_GENDER), '') IS NULL OR PRODUCT_GENDER IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'ACTIVITY',
    COUNTIF(NULLIF(TRIM(ACTIVITY), '') IS NULL OR ACTIVITY IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  UNION ALL SELECT 'FABRIC_FAMILY',
    COUNTIF(NULLIF(TRIM(FABRIC_FAMILY), '') IS NULL OR FABRIC_FAMILY IN ('\\N', '\\\\N')), COUNT(*)
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
)
ORDER BY pct_missing;

-- =============================================================================
-- 3) Distributions: key attributes
-- =============================================================================

SELECT FLEX_STATUS, COUNT(*) AS n,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
GROUP BY 1 ORDER BY n DESC;

SELECT GENDER, COUNT(*) AS n,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
GROUP BY 1 ORDER BY n DESC;

SELECT APPROX_TOP_COUNT(SILHOUETTE, 10) AS top_silhouette
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`;

SELECT APPROX_TOP_COUNT(PLANNING_PRODUCT_GROUPING, 10) AS top_ppg
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`;

SELECT APPROX_TOP_COUNT(ACTIVITY, 10) AS top_activity
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`;

-- =============================================================================
-- 4) Cross-table matches (bidirectional summary table)
-- Join key: TRIM(STYLE_ID) = TRIM(VALUE_CODE) for PGH STYLE
-- =============================================================================

WITH pa AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  WHERE TRIM(STYLE_ID) != ''
),
pgh_style AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
style_opt AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
  WHERE TRIM(STYLE_ID) != ''
),
seasonal AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
  WHERE TRIM(STYLE_ID) != ''
),
so_seasonal AS (
  SELECT DISTINCT TRIM(so.STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so_seasonal` paso
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON paso.STYLE_OPTION_ID = so.STYLE_OPTION_ID
  WHERE TRIM(so.STYLE_ID) != ''
),
planned AS (
  SELECT DISTINCT TRIM(so.STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.planned_sales` ps
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON ps.STYLE_OPTION_ID = so.STYLE_OPTION_ID
  WHERE TRIM(so.STYLE_ID) != ''
)
SELECT 'product_attribute_s -> PGH STYLE' AS comparison,
  (SELECT COUNT(*) FROM pa) AS left_distinct,
  (SELECT COUNT(*) FROM pgh_style) AS right_distinct,
  (SELECT COUNT(*) FROM pa p INNER JOIN pgh_style g ON p.style_id = g.style_id) AS in_both,
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN pgh_style g ON p.style_id = g.style_id) / (SELECT COUNT(*) FROM pa), 2) AS pct_left_in_right,
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN pgh_style g ON p.style_id = g.style_id) / (SELECT COUNT(*) FROM pgh_style), 2) AS pct_right_in_left
UNION ALL
SELECT 'product_attribute_s -> style_option',
  (SELECT COUNT(*) FROM pa), (SELECT COUNT(*) FROM style_opt),
  (SELECT COUNT(*) FROM pa p INNER JOIN style_opt s ON p.style_id = s.style_id),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN style_opt s ON p.style_id = s.style_id) / (SELECT COUNT(*) FROM pa), 2),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN style_opt s ON p.style_id = s.style_id) / (SELECT COUNT(*) FROM style_opt), 2)
UNION ALL
SELECT 'product_attribute_s -> product_attribute_s_seasonal',
  (SELECT COUNT(*) FROM pa), (SELECT COUNT(*) FROM seasonal),
  (SELECT COUNT(*) FROM pa p INNER JOIN seasonal s ON p.style_id = s.style_id),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN seasonal s ON p.style_id = s.style_id) / (SELECT COUNT(*) FROM pa), 2),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN seasonal s ON p.style_id = s.style_id) / (SELECT COUNT(*) FROM seasonal), 2)
UNION ALL
SELECT 'product_attribute_s -> product_attribute_so_seasonal (via style_option)',
  (SELECT COUNT(*) FROM pa), (SELECT COUNT(*) FROM so_seasonal),
  (SELECT COUNT(*) FROM pa p INNER JOIN so_seasonal s ON p.style_id = s.style_id),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN so_seasonal s ON p.style_id = s.style_id) / (SELECT COUNT(*) FROM pa), 2),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN so_seasonal s ON p.style_id = s.style_id) / (SELECT COUNT(*) FROM so_seasonal), 2)
UNION ALL
SELECT 'product_attribute_s -> planned_sales (via style_option)',
  (SELECT COUNT(*) FROM pa), (SELECT COUNT(*) FROM planned),
  (SELECT COUNT(*) FROM pa p INNER JOIN planned pl ON p.style_id = pl.style_id),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN planned pl ON p.style_id = pl.style_id) / (SELECT COUNT(*) FROM pa), 2),
  ROUND(100 * (SELECT COUNT(*) FROM pa p INNER JOIN planned pl ON p.style_id = pl.style_id) / (SELECT COUNT(*) FROM planned), 2)
ORDER BY comparison;

-- Orphan counts
WITH pa AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
),
pgh_style AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
style_opt AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
)
SELECT
  (SELECT COUNT(*) FROM pa p LEFT JOIN pgh_style g ON p.style_id = g.style_id WHERE g.style_id IS NULL) AS pa_only_not_in_pgh,
  (SELECT COUNT(*) FROM pgh_style g LEFT JOIN pa p ON g.style_id = p.style_id WHERE p.style_id IS NULL) AS pgh_only_not_in_pa,
  (SELECT COUNT(*) FROM pa p LEFT JOIN style_opt s ON p.style_id = s.style_id WHERE s.style_id IS NULL) AS pa_only_not_in_style_option,
  (SELECT COUNT(*) FROM style_opt s LEFT JOIN pa p ON s.style_id = p.style_id WHERE p.style_id IS NULL) AS style_option_only_not_in_pa;

-- =============================================================================
-- 5) SKU / downstream rollups via PGH STYLE join
-- =============================================================================

WITH pgh_sku_style AS (
  SELECT SKU_ID,
    MAX(IF(LEVEL_NAME = 'STYLE', TRIM(VALUE_CODE), NULL)) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY 1
),
pa AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
)
SELECT
  COUNT(DISTINCT ps.SKU_ID) AS pgh_skus,
  COUNT(DISTINCT IF(pa.style_id IS NOT NULL, ps.SKU_ID, NULL)) AS skus_with_pa_via_style,
  ROUND(100 * COUNT(DISTINCT IF(pa.style_id IS NOT NULL, ps.SKU_ID, NULL)) / COUNT(DISTINCT ps.SKU_ID), 2) AS pct_skus_with_pa
FROM pgh_sku_style ps
LEFT JOIN pa ON ps.style_id = pa.style_id;

-- product_intermediate flex_status populated when PA joins
SELECT
  COUNT(*) AS product_intermediate_rows,
  COUNTIF(flex_status IS NOT NULL AND TRIM(flex_status) NOT IN ('', '\\N')) AS rows_with_flex_status,
  ROUND(100 * COUNTIF(flex_status IS NOT NULL AND TRIM(flex_status) NOT IN ('', '\\N')) / COUNT(*), 2) AS pct_with_flex_status
FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate`;

-- =============================================================================
-- 6) Sibling feed alignment: static vs seasonal FLEX_STATUS at latest quarter
-- =============================================================================

-- Use quarter with most distinct styles (MAX(QUARTER_ID) hits sparse future quarters)
WITH rep_q AS (
  SELECT QUARTER_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
  GROUP BY 1
  ORDER BY COUNT(DISTINCT STYLE_ID) DESC
  LIMIT 1
),
paired AS (
  SELECT
    TRIM(s.STYLE_ID) AS style_id,
    TRIM(s.FLEX_STATUS) AS static_flex,
    TRIM(se.FLEX_STATUS) AS seasonal_flex,
    se.QUARTER_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` s
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal` se
    ON TRIM(s.STYLE_ID) = TRIM(se.STYLE_ID)
  WHERE se.QUARTER_ID = (SELECT QUARTER_ID FROM rep_q)
)
SELECT
  (SELECT QUARTER_ID FROM rep_q) AS quarter_used,
  COUNT(*) AS paired_styles,
  COUNTIF(static_flex = seasonal_flex) AS flex_status_match,
  COUNTIF(static_flex != seasonal_flex) AS flex_status_mismatch,
  ROUND(100 * COUNTIF(static_flex = seasonal_flex) / COUNT(*), 2) AS pct_match
FROM paired;

-- =============================================================================
-- 7) PA-only styles (not in PGH): FLEX_STATUS profile + style_option coverage
-- =============================================================================

WITH pa AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
),
pgh_style AS (
  SELECT DISTINCT TRIM(VALUE_CODE) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
),
pa_only AS (
  SELECT p.style_id
  FROM pa p
  LEFT JOIN pgh_style g ON p.style_id = g.style_id
  WHERE g.style_id IS NULL
),
style_opt AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.style_option`
),
seasonal AS (
  SELECT DISTINCT TRIM(STYLE_ID) AS style_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s_seasonal`
)
SELECT
  COUNT(*) AS pa_only_styles,
  COUNTIF(so.style_id IS NOT NULL) AS also_in_style_option,
  ROUND(100 * COUNTIF(so.style_id IS NOT NULL) / COUNT(*), 2) AS pct_in_style_option,
  COUNTIF(se.style_id IS NOT NULL) AS also_in_seasonal,
  ROUND(100 * COUNTIF(se.style_id IS NOT NULL) / COUNT(*), 2) AS pct_in_seasonal
FROM pa_only po
LEFT JOIN style_opt so ON po.style_id = so.style_id
LEFT JOIN seasonal se ON po.style_id = se.style_id;

SELECT pa.FLEX_STATUS, COUNT(*) AS n,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` pa
INNER JOIN (
  SELECT p.style_id
  FROM (
    SELECT DISTINCT TRIM(STYLE_ID) AS style_id
    FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  ) p
  LEFT JOIN (
    SELECT DISTINCT TRIM(VALUE_CODE) AS style_id
    FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
    WHERE LEVEL_NAME = 'STYLE'
  ) g ON p.style_id = g.style_id
  WHERE g.style_id IS NULL
) po ON TRIM(pa.STYLE_ID) = po.style_id
GROUP BY 1 ORDER BY n DESC;

SELECT STYLE_ID, FLEX_STATUS, GENDER, SILHOUETTE
FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` pa
WHERE TRIM(STYLE_ID) IN (
  SELECT p.style_id
  FROM (
    SELECT DISTINCT TRIM(STYLE_ID) AS style_id
    FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  ) p
  LEFT JOIN (
    SELECT DISTINCT TRIM(VALUE_CODE) AS style_id
    FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
    WHERE LEVEL_NAME = 'STYLE'
  ) g ON p.style_id = g.style_id
  WHERE g.style_id IS NULL
)
ORDER BY STYLE_ID
LIMIT 20;
