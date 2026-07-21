-- =============================================================================
-- SKU x Store x Week Eligibility (forward-looking, sourcing-only)
--
-- Horizon: current week + 26 forward weeks (revised SOW Jul 2026).
--
-- Prerequisites (all lulu_sourcing_dev, raw view tables only):
--   calendar_hierarchy, eligibility, assortment_plan, style_option,
--   product_group_hierarchy, location_group_hierarchy
--
-- Logic:
--   1) Week-native PSO x store x week from eligibility (no snapshot cross-join)
--   2) SKU gate from assortment ASSORT_TO_STORE + FLEX_SIZE_VALUE size expand
--      (all quarters unioned per style x store; DISTINCT collapses duplicate SKUs)
--   3) Intersect on (PSO, store), resolve product_code via inline PGH pivot
--      + channel expand, aligned to store channel from location_group_hierarchy
--   4) Output: product_code x store_code x week_id
--
-- P0 client follow-up: true SKU-level eligibility feed replaces assortment gate.
--
-- Preflight (read-only, before assortment_plan lands):
--   bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
--     < queries/sourcing/validate_sku_store_eligibility_preflight.sql
--
-- Build (writes lulu_sourcing_dev.sku_store_eligibility):
--   bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
--     < queries/sourcing/create_sku_store_eligibility_weekly.sql
--
-- Post-build validation:
--   bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
--     < queries/sourcing/validate_sku_store_eligibility_postbuild.sql
-- =============================================================================

DECLARE forward_weeks INT64 DEFAULT 26;

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.sku_store_eligibility`
CLUSTER BY product_code, store_code, week_id AS

WITH current_ctx AS (
  SELECT CAST(WEEK_ID AS INT64) AS current_week
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`
  WHERE DAY_ID = CURRENT_DATE()
  LIMIT 1
),
horizon_weeks AS (
  SELECT DISTINCT CAST(ch.WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy` ch
  CROSS JOIN current_ctx c
  WHERE CAST(ch.WEEK_ID AS INT64) >= c.current_week
    AND ch.DAY_ID BETWEEN CURRENT_DATE()
                      AND DATE_ADD(CURRENT_DATE(), INTERVAL forward_weeks WEEK)
),
-- Gate 1: week-native PSO x store x week from client eligibility feed
elig_pso_store_week AS (
  SELECT DISTINCT
    TRIM(e.PLANNING_STYLE_OPTION_ID) AS pso,
    LPAD(TRIM(CAST(e.STORE_ID AS STRING)), 10, '0') AS store_code,
    CAST(e.WEEK_ID AS INT64) AS week_id
  FROM `lululemon-01042025.lulu_sourcing_dev.eligibility` e
  INNER JOIN horizon_weeks hw
    ON CAST(e.WEEK_ID AS INT64) = hw.week_id
  WHERE TRIM(e.PLANNING_STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(e.STORE_ID AS STRING)) NOT IN ('', '\\N')
),
-- Gate 2: explicit assorted sizes only (style_option x store -> PSO x size)
assortment_pso_store_size AS (
  SELECT DISTINCT
    COALESCE(
      NULLIF(TRIM(so.PLANNING_STYLE_OPTION_ID), ''),
      NULLIF(TRIM(ap.PLANNING_STYLE_OPTION), '\\N'),
      TRIM(ap.STYLE_OPTION_ID)
    ) AS pso,
    LPAD(TRIM(CAST(ap.STORE_ID AS STRING)), 10, '0') AS store_code,
    TRIM(size_token) AS size_name
  FROM `lululemon-01042025.lulu_sourcing_dev.assortment_plan` ap
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.style_option` so
    ON TRIM(ap.STYLE_OPTION_ID) = TRIM(so.STYLE_OPTION_ID)
  CROSS JOIN UNNEST(SPLIT(ap.FLEX_SIZE_VALUE, ',')) AS size_token
  WHERE LOWER(TRIM(ap.ASSORT_TO_STORE)) = 'true'
    AND TRIM(ap.STYLE_OPTION_ID) NOT IN ('', '\\N')
    AND TRIM(CAST(ap.STORE_ID AS STRING)) NOT IN ('', '\\N')
    AND TRIM(size_token) NOT IN ('', '\\N')
),
-- Store channel from raw location hierarchy (matches store_intermediate derivation)
store_raw AS (
  SELECT DISTINCT
    LPAD(CAST(LOC_ID AS STRING), 10, '0') AS store_code,
    SPLIT(SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)] AS channel
  FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
  WHERE TRIM(CAST(LOC_ID AS STRING)) NOT IN ('', '\\N')
),
-- Inline PGH pivot + channel expand (matches product_intermediate grain)
pgh_sku_channel AS (
  SELECT
    TRIM(p.SKU_ID) AS sku_id,
    channel,
    CONCAT(TRIM(p.SKU_ID), '_', channel) AS product_code,
    TRIM(p.PLANNING_STYLE_OPTION_CODE) AS pso_code,
    TRIM(p.PLANNING_STYLE_SIZE_NAME) AS pss_name
  FROM (
    SELECT
      SKU_ID,
      MAX(CASE WHEN LEVEL_NAME = 'BRAND' THEN VALUE_NAME END) AS BRAND_NAME,
      MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_OPTION' THEN VALUE_CODE END) AS PLANNING_STYLE_OPTION_CODE,
      MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_SIZE' THEN VALUE_NAME END) AS PLANNING_STYLE_SIZE_NAME
    FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
    GROUP BY SKU_ID
  ) p
  CROSS JOIN UNNEST(['ECOMM', 'RETAIL']) AS channel
  WHERE TRIM(p.BRAND_NAME) = 'lululemon'
    AND TRIM(p.SKU_ID) NOT IN ('', '\\N')
),
-- Map assorted sizes to product_code; align PGH channel to store channel
assortment_sku_store AS (
  SELECT DISTINCT
    ass.pso,
    ass.store_code,
    pgh.product_code
  FROM assortment_pso_store_size ass
  INNER JOIN pgh_sku_channel pgh
    ON ass.pso = pgh.pso_code
   AND ass.size_name = pgh.pss_name
  INNER JOIN store_raw sr
    ON ass.store_code = sr.store_code
   AND pgh.channel = sr.channel
)

SELECT DISTINCT
  ass.product_code,
  eps.store_code,
  eps.week_id
FROM elig_pso_store_week eps
INNER JOIN assortment_sku_store ass
  ON eps.pso = ass.pso
 AND eps.store_code = ass.store_code;
