-- Lululemon historic product intermediate build
--
-- Full rebuild for lulu_sourcing_dev.product_intermediate.
--
-- Sources (all lulu_sourcing_dev):
--   product_group_hierarchy, sku_details, product_attribute_s
--
-- Transformation:
--   1. Pivot raw product_group_hierarchy EAV rows into hierarchy columns.
--   2. Expand each SKU to ECOMM and RETAIL channels.
--   3. Build sku_id_code inline as CONCAT(SKU_ID, '_', channel).
--
-- This intentionally does not depend on product_group_hierarchy_cleaned.

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.product_intermediate` AS
WITH
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
pgh_cleaned AS (
  SELECT
    p.*,
    channel,
    CONCAT(CAST(p.SKU_ID AS STRING), '_', channel) AS sku_id_code
  FROM pgh_pivot p
  CROSS JOIN UNNEST(['ECOMM', 'RETAIL']) AS channel
),
sku_cleaned AS (
  SELECT
    b.*,
    channel,
    CONCAT(CAST(b.ID AS STRING), '_', channel) AS sku_id_code
  FROM (
    SELECT DISTINCT * EXCEPT (COST_PRICE, SELLING_PRICE)
    FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
  ) b
  CROSS JOIN UNNEST(['ECOMM', 'RETAIL']) AS channel
)
SELECT DISTINCT
  a.BRAND_NAME AS l0_name,
  SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)] AS l1_name,
  a.DIVISION_NAME AS l2_name,
  a.DEPARTMENT_NAME AS l3_name,
  a.CLASS_NAME AS l4_name,
  a.SUBCLASS_NAME AS l5_name,
  a.MASTER_STYLE_NAME AS l6_name,
  a.STYLE_NAME AS l7_name,
  a.PLANNING_STYLE_SIZE_NAME AS l8_name,
  'ACTIVE' AS article_status,
  CAST(
    CONCAT(
      (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.BRAND_CODE, '', a.BRAND_NAME) AS STRING), '')) c),
      (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.DIVISION_CODE, '', a.DIVISION_NAME) AS STRING), '')) c),
      (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.DEPARTMENT_CODE, '', a.DEPARTMENT_NAME) AS STRING), '')) c),
      (SELECT SUM(ASCII(c)) FROM UNNEST(SPLIT(SAFE_CAST(CONCAT(a.CLASS_CODE, '', a.CLASS_NAME) AS STRING), '')) c)
    ) AS INT64
  ) AS product_bucket_code,
  a.BRAND_CODE AS l0_id,
  a.DIVISION_CODE AS l2_id,
  a.DEPARTMENT_CODE AS l3_id,
  a.CLASS_CODE AS l4_id,
  a.SUBCLASS_CODE AS l5_id,
  a.MASTER_STYLE_CODE AS l6_id,
  a.STYLE_CODE AS l7_id,
  CONCAT(a.PLANNING_STYLE_OPTION_CODE, '_', SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]) AS l8_id,
  a.PLANNING_STYLE_SIZE_NAME AS product_name,
  b.SIZE_NAME AS size,
  a.sku_id_code AS product_code,
  b.DESCRIPTION AS product_description,
  CONCAT(a.PLANNING_STYLE_OPTION_CODE, '_', SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(1)]) AS article,
  1 AS active_flag,
  CAST(b.COLOR_CODE AS STRING) AS color_code,
  b.COLOR_NAME AS color_description,
  CAST(NULL AS INT64) AS color_family,
  CAST(NULL AS INT64) AS ordering,
  CAST(NULL AS DATE) AS launch_date,
  b.SEASON_CODE AS season_code,
  c.SILHOUETTE AS silhouette,
  c.PLANNING_PRODUCT_GROUPING AS planning_product_grouping,
  c.PRODUCT_GENDER AS gender,
  c.FLEX_STATUS AS flex_status,
  c.GLOBAL_MERCH_TEAM AS global_merch_team,
  c.FIT_CLASSIFICATION AS fit_classification,
  c.DESIGN_LINE AS design_line,
  c.DESIGNED_FOR_ACTIVITY AS designed_for_activity,
  c.PRODUCT_LINE AS product_line,
  c.SIZE_SCALE AS size_scale,
  c.PRODUCT_DEVELOPMENT_POD AS product_development_pod,
  c.PRODUCT_SIZE_DEFINITION AS product_size_definition,
  c.GLOBAL_LINE_SEGMENT_STYLE_CATEGORY AS global_line_segment_style_category,
  SPLIT(a.sku_id_code, '_')[SAFE_OFFSET(0)] AS product_code_original,
  a.PLANNING_STYLE_OPTION_CODE AS article_original
FROM pgh_cleaned a
LEFT JOIN sku_cleaned b
  ON a.sku_id_code = b.sku_id_code
LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` c
  ON a.STYLE_CODE = c.STYLE_ID
WHERE a.sku_id_code IS NOT NULL;
