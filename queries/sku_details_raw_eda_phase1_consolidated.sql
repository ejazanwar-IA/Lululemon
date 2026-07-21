-- =============================================================================
-- SKU Details (RAW) EDA - Phase 1 CONSOLIDATED
--
-- Table: lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119
--        Raw per-SKU catalog (one row per ITEM_ID + SIZE combination).
--
-- Column set (all STRING per G2): ID, ITEM_ID, DESCRIPTION, PRICE_CURRENCY,
--   COST_PRICE, SELLING_PRICE, STYLE_NAME, STYLE_CODE, COLOR_NAME, COLOR_CODE,
--   SEASON_NAME, SEASON_YEAR, SEASON_CODE, SIZE_NAME, SIZE_CODE, SIZE_RANK,
--   BRAND_NAME, BRAND_CODE, SEGMENT_NAME, SEGMENT_CODE, IMAGE_URL
--
-- 8 queries, single consolidated JSON-per-row output.
-- =============================================================================

WITH

-- ========== Q1: Shape + distinct-value fingerprint ==========
q1 AS (
  SELECT
    'Q1' AS query_id,
    'Shape: row count + distinct counts across key dimensions' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*)                              AS total_rows,
      COUNT(DISTINCT ID)                    AS distinct_id,
      COUNT(DISTINCT ITEM_ID)               AS distinct_item_id,
      COUNT(DISTINCT STYLE_CODE)            AS distinct_style_code,
      COUNT(DISTINCT COLOR_CODE)            AS distinct_color_code,
      COUNT(DISTINCT SIZE_NAME)             AS distinct_size_name,
      COUNT(DISTINCT SIZE_CODE)             AS distinct_size_code,
      COUNT(DISTINCT SEASON_CODE)           AS distinct_season_code,
      COUNT(DISTINCT SEASON_YEAR)           AS distinct_season_year,
      COUNT(DISTINCT BRAND_CODE)            AS distinct_brand_code,
      COUNT(DISTINCT SEGMENT_CODE)          AS distinct_segment_code,
      COUNT(DISTINCT PRICE_CURRENCY)        AS distinct_currency
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
),

-- ========== Q2: Grain confirmation (which column / combo is the PK?) ==========
q2 AS (
  SELECT
    'Q2' AS query_id,
    'Grain test: is ID unique? is (ITEM_ID, SIZE_NAME) unique? is (STYLE_CODE, COLOR_CODE, SIZE_NAME) unique?' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT COUNT(*) FROM (
        SELECT ID FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY ID HAVING COUNT(*) > 1
      )) AS duplicate_id_keys,
      (SELECT COUNT(*) FROM (
        SELECT ITEM_ID, SIZE_NAME FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY ITEM_ID, SIZE_NAME HAVING COUNT(*) > 1
      )) AS duplicate_item_size_keys,
      (SELECT COUNT(*) FROM (
        SELECT STYLE_CODE, COLOR_CODE, SIZE_NAME FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY STYLE_CODE, COLOR_CODE, SIZE_NAME HAVING COUNT(*) > 1
      )) AS duplicate_style_color_size_keys,
      (SELECT COUNT(*) FROM (
        SELECT SIZE_CODE FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY SIZE_CODE HAVING COUNT(*) > 1
      )) AS duplicate_size_code_keys
    )) AS results_json
),

-- ========== Q3: Null / blank counts per column (all 21) ==========
-- Uses CAST(col AS STRING) defensive pattern (G10) so the string sentinels
-- '' and '\N' work regardless of whether the column is STRING or INT64.
q3 AS (
  SELECT
    'Q3' AS query_id,
    'Null or blank (IS NULL or = "" or = "\\\\N") counts per column' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(ID             IS NULL OR CAST(ID             AS STRING) IN ('', '\\N')) AS null_id,
      COUNTIF(ITEM_ID        IS NULL OR CAST(ITEM_ID        AS STRING) IN ('', '\\N')) AS null_item_id,
      COUNTIF(DESCRIPTION    IS NULL OR CAST(DESCRIPTION    AS STRING) IN ('', '\\N')) AS null_description,
      COUNTIF(PRICE_CURRENCY IS NULL OR CAST(PRICE_CURRENCY AS STRING) IN ('', '\\N')) AS null_price_currency,
      COUNTIF(COST_PRICE     IS NULL OR CAST(COST_PRICE     AS STRING) IN ('', '\\N')) AS null_cost_price,
      COUNTIF(SELLING_PRICE  IS NULL OR CAST(SELLING_PRICE  AS STRING) IN ('', '\\N')) AS null_selling_price,
      COUNTIF(STYLE_NAME     IS NULL OR CAST(STYLE_NAME     AS STRING) IN ('', '\\N')) AS null_style_name,
      COUNTIF(STYLE_CODE     IS NULL OR CAST(STYLE_CODE     AS STRING) IN ('', '\\N')) AS null_style_code,
      COUNTIF(COLOR_NAME     IS NULL OR CAST(COLOR_NAME     AS STRING) IN ('', '\\N')) AS null_color_name,
      COUNTIF(COLOR_CODE     IS NULL OR CAST(COLOR_CODE     AS STRING) IN ('', '\\N')) AS null_color_code,
      COUNTIF(SEASON_NAME    IS NULL OR CAST(SEASON_NAME    AS STRING) IN ('', '\\N')) AS null_season_name,
      COUNTIF(SEASON_YEAR    IS NULL OR CAST(SEASON_YEAR    AS STRING) IN ('', '\\N')) AS null_season_year,
      COUNTIF(SEASON_CODE    IS NULL OR CAST(SEASON_CODE    AS STRING) IN ('', '\\N')) AS null_season_code,
      COUNTIF(SIZE_NAME      IS NULL OR CAST(SIZE_NAME      AS STRING) IN ('', '\\N')) AS null_size_name,
      COUNTIF(SIZE_CODE      IS NULL OR CAST(SIZE_CODE      AS STRING) IN ('', '\\N')) AS null_size_code,
      COUNTIF(SIZE_RANK      IS NULL OR CAST(SIZE_RANK      AS STRING) IN ('', '\\N')) AS null_size_rank,
      COUNTIF(BRAND_NAME     IS NULL OR CAST(BRAND_NAME     AS STRING) IN ('', '\\N')) AS null_brand_name,
      COUNTIF(BRAND_CODE     IS NULL OR CAST(BRAND_CODE     AS STRING) IN ('', '\\N')) AS null_brand_code,
      COUNTIF(SEGMENT_NAME   IS NULL OR CAST(SEGMENT_NAME   AS STRING) IN ('', '\\N')) AS null_segment_name,
      COUNTIF(SEGMENT_CODE   IS NULL OR CAST(SEGMENT_CODE   AS STRING) IN ('', '\\N')) AS null_segment_code,
      COUNTIF(IMAGE_URL      IS NULL OR CAST(IMAGE_URL      AS STRING) IN ('', '\\N')) AS null_image_url
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
),

-- ========== Q4: Placeholder / zero concentration on price fields ==========
q4 AS (
  SELECT
    'Q4' AS query_id,
    'Placeholder detection: DUMMY_CURRENCY, zero prices, distribution of non-zero prices' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*)                                                                    AS total_rows,
      COUNTIF(CAST(PRICE_CURRENCY AS STRING) = 'DUMMY_CURRENCY')                  AS rows_dummy_currency,
      COUNTIF(SAFE_CAST(COST_PRICE    AS FLOAT64) = 0)                           AS rows_cost_price_zero_num,
      COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) = 0)                           AS rows_selling_price_zero_num,
      COUNTIF(SAFE_CAST(COST_PRICE    AS FLOAT64) > 0)                           AS rows_cost_price_positive,
      COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) > 0)                           AS rows_selling_price_positive,
      COUNTIF(SAFE_CAST(COST_PRICE    AS FLOAT64) < 0)                           AS rows_cost_price_negative,
      COUNTIF(SAFE_CAST(SELLING_PRICE AS FLOAT64) < 0)                           AS rows_selling_price_negative,
      MIN(SAFE_CAST(COST_PRICE    AS FLOAT64))                                   AS min_cost_price,
      MAX(SAFE_CAST(COST_PRICE    AS FLOAT64))                                   AS max_cost_price,
      MIN(SAFE_CAST(SELLING_PRICE AS FLOAT64))                                   AS min_selling_price,
      MAX(SAFE_CAST(SELLING_PRICE AS FLOAT64))                                   AS max_selling_price,
      APPROX_QUANTILES(SAFE_CAST(COST_PRICE    AS FLOAT64), 4)                   AS cost_price_quartiles,
      APPROX_QUANTILES(SAFE_CAST(SELLING_PRICE AS FLOAT64), 4)                   AS selling_price_quartiles
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
),

-- ========== Q5: Top-N categorical distributions ==========
-- Uses ARRAY_AGG with LIMIT inside subqueries to collapse top values into JSON.
q5 AS (
  SELECT
    'Q5' AS query_id,
    'Top categorical distributions: brand, segment, season, currency' AS description,
    TO_JSON_STRING(STRUCT(
      ARRAY(
        SELECT AS STRUCT BRAND_CODE, BRAND_NAME, COUNT(*) AS n
        FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY BRAND_CODE, BRAND_NAME ORDER BY n DESC LIMIT 20
      ) AS brand_distribution,
      ARRAY(
        SELECT AS STRUCT SEGMENT_CODE, SEGMENT_NAME, COUNT(*) AS n
        FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY SEGMENT_CODE, SEGMENT_NAME ORDER BY n DESC LIMIT 20
      ) AS segment_distribution,
      ARRAY(
        SELECT AS STRUCT SEASON_CODE, SEASON_NAME, SEASON_YEAR, COUNT(*) AS n
        FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY SEASON_CODE, SEASON_NAME, SEASON_YEAR ORDER BY n DESC LIMIT 30
      ) AS season_distribution,
      ARRAY(
        SELECT AS STRUCT PRICE_CURRENCY, COUNT(*) AS n
        FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY PRICE_CURRENCY ORDER BY n DESC LIMIT 20
      ) AS currency_distribution
    )) AS results_json
),

-- ========== Q6: Size spread + SIZE_RANK sanity ==========
q6 AS (
  SELECT
    'Q6' AS query_id,
    'Size distribution and SIZE_RANK numeric sanity' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(DISTINCT SIZE_NAME) AS distinct_size_names,
      COUNT(DISTINCT SIZE_RANK) AS distinct_size_ranks,
      MIN(SAFE_CAST(SIZE_RANK AS INT64)) AS min_size_rank,
      MAX(SAFE_CAST(SIZE_RANK AS INT64)) AS max_size_rank,
      COUNTIF(SAFE_CAST(SIZE_RANK AS INT64) IS NULL AND SIZE_RANK IS NOT NULL) AS size_rank_non_numeric_rows,
      ARRAY(
        SELECT AS STRUCT SIZE_NAME, SIZE_RANK, COUNT(*) AS n
        FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY SIZE_NAME, SIZE_RANK ORDER BY n DESC LIMIT 30
      ) AS top_sizes,
      ARRAY(
        SELECT AS STRUCT SIZE_NAME, COUNT(DISTINCT SIZE_RANK) AS n_ranks
        FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
        GROUP BY SIZE_NAME HAVING COUNT(DISTINCT SIZE_RANK) > 1 ORDER BY n_ranks DESC LIMIT 10
      ) AS size_names_with_inconsistent_rank
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
),

-- ========== Q7: Structural consistency — does SIZE_CODE = ITEM_ID || '-' || SIZE_NAME? ==========
q7 AS (
  SELECT
    'Q7' AS query_id,
    'Structural consistency: SIZE_CODE vs ITEM_ID-SIZE_NAME pattern; ITEM_ID encodes COLOR_CODE?' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*)                                                                             AS total_rows,
      COUNTIF(CAST(SIZE_CODE AS STRING) = CONCAT(CAST(ITEM_ID AS STRING), '-', CAST(SIZE_NAME AS STRING)))
                                                                                            AS size_code_matches_pattern,
      COUNTIF(CAST(SIZE_CODE AS STRING) != CONCAT(CAST(ITEM_ID AS STRING), '-', CAST(SIZE_NAME AS STRING)))
                                                                                            AS size_code_breaks_pattern,
      COUNTIF(ENDS_WITH(CAST(ITEM_ID AS STRING), CONCAT('-', CAST(COLOR_CODE AS STRING))))
                                                                                            AS item_id_ends_with_color_code,
      COUNTIF(NOT ENDS_WITH(CAST(ITEM_ID AS STRING), CONCAT('-', CAST(COLOR_CODE AS STRING))))
                                                                                            AS item_id_does_not_end_with_color_code,
      COUNTIF(SAFE_CAST(SEASON_YEAR AS INT64) IS NOT NULL
              AND STARTS_WITH(CAST(SEASON_CODE AS STRING), SUBSTR(CAST(SEASON_YEAR AS STRING), 3, 2))
             )                                                                              AS season_code_year_matches,
      COUNTIF(SAFE_CAST(SEASON_YEAR AS INT64) IS NOT NULL
              AND NOT STARTS_WITH(CAST(SEASON_CODE AS STRING), SUBSTR(CAST(SEASON_YEAR AS STRING), 3, 2))
             )                                                                              AS season_code_year_mismatch
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`
),

-- ========== Q8: Coverage vs product_group_hierarchy_cleaned_20251119 ==========
-- Product-master build LEFT-JOINS sku_details on product_group_hierarchy_cleaned.sku_id_code
-- = sku_details.sku_id_code. This table doesn't have sku_id_code, but ITEM_ID appears to be
-- the same thing. Test coverage and see how many PGH skus have a matching sku_details row.
q8 AS (
  SELECT
    'Q8' AS query_id,
    'Coverage: how many product_group_hierarchy SKUs have a sku_details match via ITEM_ID?' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT COUNT(DISTINCT sku_id_code) FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119`) AS pgh_distinct_sku_id_code,
      (SELECT COUNT(DISTINCT ITEM_ID)     FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119`)                     AS sku_details_distinct_item_id,
      (SELECT COUNT(DISTINCT pgh.sku_id_code)
         FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119` pgh
         LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119` sd
           ON pgh.sku_id_code = sd.ITEM_ID
         WHERE sd.ITEM_ID IS NOT NULL)                                                                                                    AS pgh_skus_with_match,
      (SELECT COUNT(DISTINCT pgh.sku_id_code)
         FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119` pgh
         LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119` sd
           ON pgh.sku_id_code = sd.ITEM_ID
         WHERE sd.ITEM_ID IS NULL)                                                                                                        AS pgh_skus_without_match,
      (SELECT COUNT(DISTINCT sd.ITEM_ID)
         FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_20251119` sd
         LEFT JOIN `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119` pgh
           ON sd.ITEM_ID = pgh.sku_id_code
         WHERE pgh.sku_id_code IS NULL)                                                                                                   AS sku_details_orphans
    )) AS results_json
)

-- ========== Consolidate all 8 queries into one result set ==========
SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
UNION ALL SELECT * FROM q5
UNION ALL SELECT * FROM q6
UNION ALL SELECT * FROM q7
UNION ALL SELECT * FROM q8
ORDER BY query_id;
