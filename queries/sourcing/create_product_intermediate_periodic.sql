-- Lululemon periodic product intermediate build
--
-- Platform pattern: filter_param from mapping, temp from incremental raw feeds,
-- MERGE into live intermediate, drop temp.
--
-- Sources (all lulu_sourcing_dev):
--   product_group_hierarchy, sku_details, product_attribute_s
-- Incremental: SYNCSTARTDATETIME > filter_param on any feed; union affected SKU_IDs
--   (attribute-only changes expand via STYLE rows in PGH)
-- MERGE key: product_code (1,977,528 rows live; grain verified unique)
--
-- Transformation: Ejaz product_intermediate build (2026-05-14); PGH pivot inlined
-- from raw EAV (same as inventory_intermediate_build.sql), not static cleaned table.
--
-- Self-Help prerequisites:
--   mapping.intermediate_table = 'product_intermediate' (is_deleted = FALSE)
--   view_mapping_table views = product_group_hierarchy, sku_details, product_attribute_s

DECLARE filter_param DATETIME DEFAULT (
  SELECT COALESCE(
    MAX(COALESCE(DATETIME(filter_param), DATETIME(dataingestion_filterparam))),
    DATETIME('1900-01-01 00:00:00')
  )
  FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
  WHERE is_deleted = FALSE
    AND intermediate_table = 'product_intermediate'
);

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.product_intermediate_temp` AS
WITH
changed_style_ids AS (
  SELECT DISTINCT STYLE_ID
  FROM `lululemon-01042025.lulu_sourcing_dev.product_attribute_s`
  WHERE SYNCSTARTDATETIME > filter_param
),
changed_sku_ids AS (
  SELECT DISTINCT CAST(SKU_ID AS STRING) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE SYNCSTARTDATETIME > filter_param
  UNION DISTINCT
  SELECT DISTINCT CAST(ID AS STRING) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
  WHERE SYNCSTARTDATETIME > filter_param
  UNION DISTINCT
  SELECT DISTINCT CAST(SKU_ID AS STRING) AS sku_id
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  WHERE LEVEL_NAME = 'STYLE'
    AND VALUE_CODE IN (SELECT STYLE_ID FROM changed_style_ids)
),
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
  WHERE CAST(SKU_ID AS STRING) IN (SELECT sku_id FROM changed_sku_ids)
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
    WHERE CAST(ID AS STRING) IN (SELECT sku_id FROM changed_sku_ids)
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

MERGE `lululemon-01042025.lulu_sourcing_dev.product_intermediate` DL
USING `lululemon-01042025.lulu_sourcing_dev.product_intermediate_temp` A
ON DL.product_code = A.product_code

WHEN MATCHED THEN UPDATE SET
  DL.l0_name = A.l0_name,
  DL.l1_name = A.l1_name,
  DL.l2_name = A.l2_name,
  DL.l3_name = A.l3_name,
  DL.l4_name = A.l4_name,
  DL.l5_name = A.l5_name,
  DL.l6_name = A.l6_name,
  DL.l7_name = A.l7_name,
  DL.l8_name = A.l8_name,
  DL.article_status = A.article_status,
  DL.product_bucket_code = A.product_bucket_code,
  DL.l0_id = A.l0_id,
  DL.l2_id = A.l2_id,
  DL.l3_id = A.l3_id,
  DL.l4_id = A.l4_id,
  DL.l5_id = A.l5_id,
  DL.l6_id = A.l6_id,
  DL.l7_id = A.l7_id,
  DL.l8_id = A.l8_id,
  DL.product_name = A.product_name,
  DL.size = A.size,
  DL.product_description = A.product_description,
  DL.article = A.article,
  DL.active_flag = A.active_flag,
  DL.color_code = A.color_code,
  DL.color_description = A.color_description,
  DL.color_family = A.color_family,
  DL.ordering = A.ordering,
  DL.launch_date = A.launch_date,
  DL.season_code = A.season_code,
  DL.silhouette = A.silhouette,
  DL.planning_product_grouping = A.planning_product_grouping,
  DL.gender = A.gender,
  DL.flex_status = A.flex_status,
  DL.global_merch_team = A.global_merch_team,
  DL.fit_classification = A.fit_classification,
  DL.design_line = A.design_line,
  DL.designed_for_activity = A.designed_for_activity,
  DL.product_line = A.product_line,
  DL.size_scale = A.size_scale,
  DL.product_development_pod = A.product_development_pod,
  DL.product_size_definition = A.product_size_definition,
  DL.global_line_segment_style_category = A.global_line_segment_style_category,
  DL.product_code_original = A.product_code_original,
  DL.article_original = A.article_original

WHEN NOT MATCHED THEN INSERT (
  l0_name,
  l1_name,
  l2_name,
  l3_name,
  l4_name,
  l5_name,
  l6_name,
  l7_name,
  l8_name,
  article_status,
  product_bucket_code,
  l0_id,
  l2_id,
  l3_id,
  l4_id,
  l5_id,
  l6_id,
  l7_id,
  l8_id,
  product_name,
  size,
  product_code,
  product_description,
  article,
  active_flag,
  color_code,
  color_description,
  color_family,
  ordering,
  launch_date,
  season_code,
  silhouette,
  planning_product_grouping,
  gender,
  flex_status,
  global_merch_team,
  fit_classification,
  design_line,
  designed_for_activity,
  product_line,
  size_scale,
  product_development_pod,
  product_size_definition,
  global_line_segment_style_category,
  product_code_original,
  article_original
)
VALUES (
  A.l0_name,
  A.l1_name,
  A.l2_name,
  A.l3_name,
  A.l4_name,
  A.l5_name,
  A.l6_name,
  A.l7_name,
  A.l8_name,
  A.article_status,
  A.product_bucket_code,
  A.l0_id,
  A.l2_id,
  A.l3_id,
  A.l4_id,
  A.l5_id,
  A.l6_id,
  A.l7_id,
  A.l8_id,
  A.product_name,
  A.size,
  A.product_code,
  A.product_description,
  A.article,
  A.active_flag,
  A.color_code,
  A.color_description,
  A.color_family,
  A.ordering,
  A.launch_date,
  A.season_code,
  A.silhouette,
  A.planning_product_grouping,
  A.gender,
  A.flex_status,
  A.global_merch_team,
  A.fit_classification,
  A.design_line,
  A.designed_for_activity,
  A.product_line,
  A.size_scale,
  A.product_development_pod,
  A.product_size_definition,
  A.global_line_segment_style_category,
  A.product_code_original,
  A.article_original
);

DROP TABLE IF EXISTS `lululemon-01042025.lulu_sourcing_dev.product_intermediate_temp`;
