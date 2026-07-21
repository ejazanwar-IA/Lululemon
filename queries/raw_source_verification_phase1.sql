-- =============================================================================
-- RAW SOURCE VERIFICATION — Phase 1 (STACKED, single-query version)
-- =============================================================================
-- Purpose: Verify whether master-table anomalies originate in raw sources
--          vs being introduced by the build scripts.
--
-- Output:  ONE result set, 15 rows — one per V1..V15 check.
--          Columns: query_id | description | results_json
--
-- Cost notes:
--   - Most CTEs hit tiny tables (~free)
--   - v9 scans 1 yr of sales_transactions_4y_cleaned_20251119 (~15 GB)
--   - v10 scans 1 yr of inventory_snapshot_cleaned (~300–400 GB) — heaviest
--   - Total estimate: ~$2–3
-- =============================================================================

WITH

-- -----------------------------------------------------------------------------
-- V1: sku_details_cleaned — cost/msrp distribution (raw source of cost & msrp)
-- -----------------------------------------------------------------------------
v1 AS (
  SELECT
    'V1' AS query_id,
    'sku_details_cleaned cost/selling_price distribution' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) IS NULL) AS cost_null_or_uncastable,
      COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) = 0) AS cost_zero,
      COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) > 0) AS cost_positive,
      COUNTIF(SAFE_CAST(COST_PRICE AS FLOAT64) < 0) AS cost_negative,
      MIN(SAFE_CAST(COST_PRICE AS FLOAT64)) AS cost_min,
      MAX(SAFE_CAST(COST_PRICE AS FLOAT64)) AS cost_max,
      ROUND(AVG(SAFE_CAST(COST_PRICE AS FLOAT64)), 4) AS cost_avg,
      COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) IS NULL) AS sp_null_or_uncastable,
      COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) = 0) AS sp_zero,
      COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) > 0) AS sp_positive,
      MIN(SAFE_CAST(SELLING_PRICE AS FLOAT64)) AS sp_min,
      MAX(SAFE_CAST(SELLING_PRICE AS FLOAT64)) AS sp_max
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned`
),

-- -----------------------------------------------------------------------------
-- V2: product_attribute_s — null % of fit_classification, size_scale, etc.
-- -----------------------------------------------------------------------------
v2 AS (
  SELECT
    'V2' AS query_id,
    'product_attribute_s_20251119 null rates' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(fit_classification IS NULL OR fit_classification = '' OR fit_classification = '\\N') AS fit_null,
      ROUND(COUNTIF(fit_classification IS NULL OR fit_classification = '' OR fit_classification = '\\N') * 100.0 / COUNT(*), 2) AS pct_fit_null,
      COUNT(DISTINCT fit_classification) AS distinct_fit_values,
      COUNTIF(size_scale IS NULL OR size_scale = '' OR size_scale = '\\N') AS size_scale_null,
      COUNT(DISTINCT size_scale) AS distinct_size_scale_values,
      COUNTIF(product_gender IS NULL OR product_gender = '' OR product_gender = '\\N') AS gender_null,
      COUNTIF(flex_status IS NULL OR flex_status = '' OR flex_status = '\\N') AS flex_status_null
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
),

-- -----------------------------------------------------------------------------
-- V3: product_attribute_s — all distinct size_scale codes with counts
-- -----------------------------------------------------------------------------
v3 AS (
  SELECT
    'V3' AS query_id,
    'size_scale distinct values with counts' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(size_scale, cnt) ORDER BY cnt DESC)) AS results_json
  FROM (
    SELECT size_scale, COUNT(*) AS cnt
    FROM `lululemon-01042025.lululemon_souricng_outbound.product_attribute_s_20251119`
    WHERE size_scale IS NOT NULL AND size_scale != '' AND size_scale != '\\N'
    GROUP BY size_scale
  )
),

-- -----------------------------------------------------------------------------
-- V4: location_group_hierarchy — CMNTY vs COMMUNITY + LOC_FORMAT nulls
-- -----------------------------------------------------------------------------
v4 AS (
  SELECT
    'V4' AS query_id,
    'CMNTY/COMMUNITY + LOC_FORMAT nulls in raw' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(UPPER(SUB_MARKET_CHANNEL_NAME) LIKE '%CMNTY%') AS cmnty_rows,
      COUNTIF(UPPER(SUB_MARKET_CHANNEL_NAME) LIKE '%COMMUNITY%') AS community_rows,
      COUNTIF(LOC_FORMAT IS NULL OR LOC_FORMAT = '') AS loc_format_null,
      ROUND(COUNTIF(LOC_FORMAT IS NULL OR LOC_FORMAT = '') * 100.0 / COUNT(*), 2) AS pct_loc_format_null
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119`
),

-- -----------------------------------------------------------------------------
-- V5: LOC_CLOSED_IND polarity check
-- -----------------------------------------------------------------------------
v5 AS (
  SELECT
    'V5' AS query_id,
    'LOC_CLOSED_IND polarity via close_date presence' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(
      LOC_CLOSED_IND,
      row_count,
      rows_with_close_date,
      pct_with_close_date,
      sample_stores
    ) ORDER BY LOC_CLOSED_IND)) AS results_json
  FROM (
    SELECT
      CAST(LOC_CLOSED_IND AS STRING) AS LOC_CLOSED_IND,
      COUNT(*) AS row_count,
      COUNTIF(OPERATIONAL_CLOSE_DAY_ID IS NOT NULL) AS rows_with_close_date,
      ROUND(COUNTIF(OPERATIONAL_CLOSE_DAY_ID IS NOT NULL) * 100.0 / COUNT(*), 2) AS pct_with_close_date,
      ARRAY_AGG(STRUCT(
        loc_id, LOC_NAME,
        CAST(OPERATIONAL_OPEN_DAY_ID AS STRING) AS open_date,
        CAST(OPERATIONAL_CLOSE_DAY_ID AS STRING) AS close_date
      ) LIMIT 3) AS sample_stores
    FROM `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119`
    GROUP BY LOC_CLOSED_IND
  )
),

-- -----------------------------------------------------------------------------
-- V6: Latitude/Longitude data types in raw
-- -----------------------------------------------------------------------------
v6 AS (
  SELECT
    'V6' AS query_id,
    'lat/long data types in raw' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(column_name, data_type) ORDER BY column_name)) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'location_group_hierarchy_cleaned_20251119'
    AND LOWER(column_name) IN ('latitude', 'longitude')
),

-- -----------------------------------------------------------------------------
-- V7: inventory_snapshot — any pre-2023 data?
-- -----------------------------------------------------------------------------
v7 AS (
  SELECT
    'V7' AS query_id,
    'inventory_snapshot_cleaned pre-2023 rows' AS description,
    TO_JSON_STRING(STRUCT(
      MIN(DATE) AS overall_min_date_pre2023,
      MAX(DATE) AS overall_max_date_pre2023,
      COUNT(*) AS pre_2023_rows,
      COUNT(DISTINCT DATE) AS pre_2023_distinct_dates
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
  WHERE DATE < '2023-01-01'
),

-- -----------------------------------------------------------------------------
-- V8: product_group_hierarchy — schema probe for launch/date columns
-- -----------------------------------------------------------------------------
v8 AS (
  SELECT
    'V8' AS query_id,
    'PGH schema date/launch/season columns' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(column_name, data_type) ORDER BY ordinal_position)) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'product_group_hierarchy_cleaned_20251119'
    AND (
      LOWER(column_name) LIKE '%date%'
      OR LOWER(column_name) LIKE '%launch%'
      OR LOWER(column_name) LIKE '%first_sell%'
      OR LOWER(column_name) LIKE '%season%'
    )
),

-- -----------------------------------------------------------------------------
-- V9: sales_transactions raw — zero-qty / outliers / free items (2024 sample)
-- NOTE: numeric columns may be STRING in raw; using SAFE_CAST for safety.
-- -----------------------------------------------------------------------------
v9 AS (
  SELECT
    'V9' AS query_id,
    'sales_transactions raw zero-qty/outliers (2024)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows_2024,
      COUNTIF(SAFE_CAST(units AS FLOAT64) = 0) AS zero_units,
      ROUND(COUNTIF(SAFE_CAST(units AS FLOAT64) = 0) * 100.0 / COUNT(*), 2) AS pct_zero_units,
      COUNTIF(SAFE_CAST(units AS FLOAT64) < 0) AS negative_units,
      COUNTIF(SAFE_CAST(units AS FLOAT64) > 0 AND SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64) = 0) AS free_items_rows,
      MAX(SAFE_CAST(units AS FLOAT64)) AS max_units,
      MIN(SAFE_CAST(units AS FLOAT64)) AS min_units,
      MAX(SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64)) AS max_revenue,
      MIN(SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64)) AS min_revenue,
      MAX(SAFE_CAST(PRICE_SALES_UNIT AS FLOAT64)) AS max_unit_price,
      COUNTIF(SAFE_CAST(PRICE_SALES_UNIT AS FLOAT64) < 0) AS negative_price_rows
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.sales_transactions_4y_cleaned_20251119`
  WHERE DATE_TRANSACTION BETWEEN '2024-01-01' AND '2024-12-31'
),

-- -----------------------------------------------------------------------------
-- V10: inventory_snapshot raw — negative OH (2024 sample)
-- -----------------------------------------------------------------------------
v10 AS (
  SELECT
    'V10' AS query_id,
    'inventory_snapshot raw negative OH (2024)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows_2024,
      COUNTIF(SAFE_CAST(UNITS_ON_HAND AS FLOAT64) < 0) AS negative_oh,
      ROUND(COUNTIF(SAFE_CAST(UNITS_ON_HAND AS FLOAT64) < 0) * 100.0 / COUNT(*), 2) AS pct_negative_oh,
      COUNTIF(SAFE_CAST(UNITS_ON_HAND AS FLOAT64) = 0) AS zero_oh,
      COUNTIF(SAFE_CAST(UNITS_ON_HAND AS FLOAT64) > 0) AS positive_oh,
      MIN(SAFE_CAST(UNITS_ON_HAND AS FLOAT64)) AS min_oh,
      MAX(SAFE_CAST(UNITS_ON_HAND AS FLOAT64)) AS max_oh
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
  WHERE DATE BETWEEN '2024-01-01' AND '2024-12-31'
),

-- -----------------------------------------------------------------------------
-- V11: PGH — ivivva brand confirmation in raw
-- -----------------------------------------------------------------------------
v11 AS (
  SELECT
    'V11' AS query_id,
    'ivivva brand in raw PGH' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(brand_name, row_count, distinct_skus) ORDER BY row_count DESC)) AS results_json
  FROM (
    SELECT brand_name, COUNT(*) AS row_count, COUNT(DISTINCT sku_id_code) AS distinct_skus
    FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119`
    GROUP BY brand_name
  )
),

-- -----------------------------------------------------------------------------
-- V12: PGH — short-code placeholder articles (HX, MV, NK, etc.)
-- -----------------------------------------------------------------------------
v12_base AS (
  SELECT
    SPLIT(PLANNING_STYLE_OPTION_CODE, '-')[SAFE_OFFSET(0)] AS short_code,
    COUNT(*) AS cnt
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119`
  WHERE LENGTH(SPLIT(PLANNING_STYLE_OPTION_CODE, '-')[SAFE_OFFSET(0)]) <= 2
  GROUP BY 1
),
v12 AS (
  SELECT
    'V12' AS query_id,
    'Short-code placeholder articles in raw PGH' AS description,
    TO_JSON_STRING(STRUCT(
      SUM(cnt) AS total_placeholder_rows,
      COUNT(*) AS distinct_short_article_codes,
      ARRAY_AGG(STRUCT(short_code, cnt) ORDER BY cnt DESC LIMIT 15) AS top_short_codes
    )) AS results_json
  FROM v12_base
),

-- -----------------------------------------------------------------------------
-- V13: LOC_FORMAT full distribution in raw
-- -----------------------------------------------------------------------------
v13 AS (
  SELECT
    'V13' AS query_id,
    'LOC_FORMAT distribution in raw' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(LOC_FORMAT, cnt) ORDER BY cnt DESC)) AS results_json
  FROM (
    SELECT LOC_FORMAT, COUNT(*) AS cnt
    FROM `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119`
    GROUP BY LOC_FORMAT
  )
),

-- -----------------------------------------------------------------------------
-- V14: sku_details_cleaned — full schema
-- -----------------------------------------------------------------------------
v14 AS (
  SELECT
    'V14' AS query_id,
    'sku_details_cleaned schema' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(column_name, data_type, is_nullable) ORDER BY ordinal_position)) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'sku_details_cleaned'
),

-- -----------------------------------------------------------------------------
-- V15: product_attribute_s — full schema
-- -----------------------------------------------------------------------------
v15 AS (
  SELECT
    'V15' AS query_id,
    'product_attribute_s_20251119 schema' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(column_name, data_type, is_nullable) ORDER BY ordinal_position)) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'product_attribute_s_20251119'
)

-- =============================================================================
-- FINAL OUTPUT — 15 rows, one per verification check
-- =============================================================================
SELECT * FROM v1 UNION ALL
SELECT * FROM v2 UNION ALL
SELECT * FROM v3 UNION ALL
SELECT * FROM v4 UNION ALL
SELECT * FROM v5 UNION ALL
SELECT * FROM v6 UNION ALL
SELECT * FROM v7 UNION ALL
SELECT * FROM v8 UNION ALL
SELECT * FROM v9 UNION ALL
SELECT * FROM v10 UNION ALL
SELECT * FROM v11 UNION ALL
SELECT * FROM v12 UNION ALL
SELECT * FROM v13 UNION ALL
SELECT * FROM v14 UNION ALL
SELECT * FROM v15
ORDER BY query_id;
