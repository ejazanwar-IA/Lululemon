-- Lululemon historic product intermediate build

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.product_intermediate` AS
WITH
-- Pivot raw product_group_hierarchy from EAV (LEVEL_NAME / VALUE_*) into wide hierarchy columns.
-- One output row per SKU_ID with brand-through-planning-style-size codes and names.
pgh_pivot AS (
  SELECT
    SKU_ID,
    MAX(CASE WHEN LEVEL_NAME = 'BRAND' THEN VALUE_NAME END) AS BRAND_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'BRAND' THEN VALUE_CODE END) AS BRAND_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'DIVISION' THEN VALUE_NAME END) AS DIVISION_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'DIVISION' THEN VALUE_CODE END) AS DIVISION_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'DEPARTMENT' THEN VALUE_NAME END) AS DEPARTMENT_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'DEPARTMENT' THEN VALUE_CODE END) AS DEPARTMENT_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'CLASS' THEN VALUE_NAME END) AS CLASS_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'CLASS' THEN VALUE_CODE END) AS CLASS_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'SUBCLASS' THEN VALUE_NAME END) AS SUBCLASS_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'SUBCLASS' THEN VALUE_CODE END) AS SUBCLASS_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'MASTER_STYLE' THEN VALUE_NAME END) AS MASTER_STYLE_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'MASTER_STYLE' THEN VALUE_CODE END) AS MASTER_STYLE_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'STYLE' THEN VALUE_NAME END) AS STYLE_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'STYLE' THEN VALUE_CODE END) AS STYLE_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_OPTION' THEN VALUE_NAME END) AS PLANNING_STYLE_OPTION_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_OPTION' THEN VALUE_CODE END) AS PLANNING_STYLE_OPTION_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_SIZE' THEN VALUE_NAME END) AS PLANNING_STYLE_SIZE_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_SIZE' THEN VALUE_CODE END) AS PLANNING_STYLE_SIZE_CODE
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID
),
-- Duplicate each SKU for ECOMM and RETAIL so product_code matches txn/inventory suffix convention.
-- Builds sku_id_code as {SKU_ID}_{channel}, the grain of product_intermediate.
pgh_cleaned AS (
  SELECT
    p.*,
    channel,
    CONCAT(CAST(p.SKU_ID AS STRING), '_', channel) AS sku_id_code
  FROM pgh_pivot p
  CROSS JOIN UNNEST(['ECOMM', 'RETAIL']) AS channel
),
-- Collapse eligibility (PSO x store x week) to one earliest first-selling day per style option.
-- Joined on article_original (PLANNING_STYLE_OPTION_CODE) to populate launch_date (~54% row fill).
pso_launch_dates AS (
  SELECT
    PLANNING_STYLE_OPTION_ID AS article_original,
    MIN(SAFE.PARSE_DATE('%Y-%m-%d', WP_FIRST_SELLING_DAY_ID)) AS launch_date
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility`
  WHERE WP_FIRST_SELLING_DAY_ID IS NOT NULL
    AND WP_FIRST_SELLING_DAY_ID != ''
    AND WP_FIRST_SELLING_DAY_ID != '\\N'
  GROUP BY 1
),
-- Text color family from product_attribute_so, bridged to PSO grain via style_option's primary
-- style option (validated 2026-07-21: 0 grain conflicts, 87.58% coverage). See
-- findings/product_intermediate_color_family_source_found.md.
color_family_lookup AS (
  SELECT
    so.PLANNING_STYLE_OPTION_ID,
    pas.COLOUR_FAMILY AS color_family
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_so` pas
  JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON pas.STYLE_OPTION_ID = so.STYLE_OPTION_ID
  WHERE so.IS_PRIMARY_STYLE_OPTION = 'true'
    AND pas.COLOUR_FAMILY IS NOT NULL
    AND TRIM(pas.COLOUR_FAMILY) NOT IN ('', '\\N')
)
-- Join PGH spine to sku_details, product_attribute_s, and PSO launch dates; project intermediate columns.
SELECT
  a.sku_id_code AS product_code,
  SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(0)] AS product_code_original,
  CONCAT(a.PLANNING_STYLE_OPTION_CODE, '_', SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]) AS article,
  a.PLANNING_STYLE_OPTION_CODE AS article_original,
  a.BRAND_NAME AS l0_name,
  SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)] AS l1_name,
  a.DIVISION_NAME AS l2_name,
  a.DEPARTMENT_NAME AS l3_name,
  a.CLASS_NAME AS l4_name,
  a.SUBCLASS_NAME AS l5_name,
  a.MASTER_STYLE_NAME AS l6_name,
  a.STYLE_NAME AS l7_name,
  a.PLANNING_STYLE_SIZE_NAME AS l8_name,
  a.BRAND_CODE AS l0_id,
  a.DIVISION_CODE AS l2_id,
  a.DEPARTMENT_CODE AS l3_id,
  a.CLASS_CODE AS l4_id,
  a.SUBCLASS_CODE AS l5_id,
  a.MASTER_STYLE_CODE AS l6_id,
  a.STYLE_CODE AS l7_id,
  CONCAT(a.PLANNING_STYLE_OPTION_CODE, '_', SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]) AS l8_id,
  a.PLANNING_STYLE_SIZE_NAME AS product_name,
  b.DESCRIPTION AS product_description,
  b.SIZE_NAME AS size,
  CAST(b.COLOR_CODE AS STRING) AS color_code,
  b.COLOR_NAME AS color_description,
  cfl.color_family AS color_family,
  SAFE_CAST(b.SIZE_RANK AS INT64) AS ordering,
  b.SEASON_CODE AS season_code,
  ld.launch_date AS launch_date,
  CASE UPPER(NULLIF(NULLIF(TRIM(c.FLEX_STATUS), ''), '\\N'))
    WHEN 'ACTIVE' THEN 'ACTIVE'
    WHEN 'DROP' THEN 'DROP'
    WHEN 'INACTIVE' THEN 'INACTIVE'
    WHEN 'HOLD' THEN 'HOLD'
    ELSE NULL
  END AS article_status,
  CASE UPPER(NULLIF(NULLIF(TRIM(c.FLEX_STATUS), ''), '\\N'))
    WHEN 'ACTIVE' THEN 1
    ELSE 0
  END AS active_flag,
  CAST(
    CONCAT(
      (SELECT SUM(ASCII(ch)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.BRAND_CODE, '', a.BRAND_NAME) AS STRING), '')) ch),
      (SELECT SUM(ASCII(ch)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.DIVISION_CODE, '', a.DIVISION_NAME) AS STRING), '')) ch),
      (SELECT SUM(ASCII(ch)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.DEPARTMENT_CODE, '', a.DEPARTMENT_NAME) AS STRING), '')) ch),
      (SELECT SUM(ASCII(ch)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.CLASS_CODE, '', a.CLASS_NAME) AS STRING), '')) ch)
    ) AS INT64
  ) AS product_bucket_code,
  c.PRODUCT_GENDER AS gender,
  c.FLEX_STATUS AS flex_status,
  c.SILHOUETTE AS silhouette,
  c.PLANNING_PRODUCT_GROUPING AS planning_product_grouping,
  c.GLOBAL_MERCH_TEAM AS global_merch_team,
  c.FIT_CLASSIFICATION AS fit_classification,
  c.DESIGN_LINE AS design_line,
  c.DESIGNED_FOR_ACTIVITY AS designed_for_activity,
  c.PRODUCT_LINE AS product_line,
  c.SIZE_SCALE AS size_scale,
  c.PRODUCT_DEVELOPMENT_POD AS product_development_pod,
  c.PRODUCT_SIZE_DEFINITION AS product_size_definition,
  c.GLOBAL_LINE_SEGMENT_STYLE_CATEGORY AS global_line_segment_style_category
FROM pgh_cleaned a
LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.sku_details` b
  ON CAST(a.SKU_ID AS STRING) = CAST(b.ID AS STRING)
LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` c
  ON a.STYLE_CODE = c.STYLE_ID
LEFT JOIN pso_launch_dates ld
  ON a.PLANNING_STYLE_OPTION_CODE = ld.article_original
LEFT JOIN color_family_lookup cfl
  ON a.PLANNING_STYLE_OPTION_CODE = cfl.PLANNING_STYLE_OPTION_ID
WHERE a.sku_id_code IS NOT NULL;
