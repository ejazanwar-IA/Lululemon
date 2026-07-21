-- =============================================================================
-- Store Master EDA - Phase 1 CONSOLIDATED
--
-- Table: lululemon-01042025.lululemon_souricng_outbound.store_master
--        (1,853 rows, <1 MB) — tiny, cheap, comprehensive
--
-- 7 queries, single consolidated output.
-- =============================================================================

WITH

-- ========== Q1: Row counts + distincts + channel/geography ==========
q1 AS (
  SELECT
    'Q1' AS query_id,
    'Row counts + distinct IDs + channel/geography' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNT(DISTINCT store_code) AS distinct_store_code,
      COUNT(DISTINCT store_name) AS distinct_store_name,
      COUNT(DISTINCT channel) AS distinct_channel,
      COUNT(DISTINCT channel_code) AS distinct_channel_code,
      COUNT(DISTINCT ws_channel) AS distinct_ws_channel,
      COUNT(DISTINCT geography) AS distinct_geography,
      COUNT(DISTINCT region) AS distinct_region,
      COUNT(DISTINCT city) AS distinct_city,
      COUNT(DISTINCT state) AS distinct_state,
      COUNT(DISTINCT country_from_company_name) AS distinct_company_name_countries,
      COUNT(DISTINCT store_format_code) AS distinct_store_format_code,
      COUNT(DISTINCT store_type) AS distinct_store_type,
      COUNT(DISTINCT loc_type_code) AS distinct_loc_type_code,
      COUNT(DISTINCT s3_id) AS distinct_s3_id
    )) AS results_json
  FROM (
    SELECT *, company_name AS country_from_company_name
    FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  )
),

-- ========== Q2: Null / blank / '\N' counts per column (all 34) ==========
q2 AS (
  SELECT
    'Q2' AS query_id,
    'Null/blank/\\N counts per column (type-aware)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      -- STRING columns (NULL / '' / '\N')
      COUNTIF(s0_name IS NULL OR s0_name = '' OR s0_name = '\\N') AS null_s0_name,
      COUNTIF(s1_name IS NULL OR s1_name = '' OR s1_name = '\\N') AS null_s1_name,
      COUNTIF(s2_name IS NULL OR s2_name = '' OR s2_name = '\\N') AS null_s2_name,
      COUNTIF(s3_name IS NULL OR s3_name = '' OR s3_name = '\\N') AS null_s3_name,
      COUNTIF(s3_id IS NULL OR s3_id = '' OR s3_id = '\\N') AS null_s3_id,
      COUNTIF(s4_name IS NULL OR s4_name = '' OR s4_name = '\\N') AS null_s4_name,
      COUNTIF(store_code IS NULL OR store_code = '' OR store_code = '\\N') AS null_store_code,
      COUNTIF(store_name IS NULL OR store_name = '' OR store_name = '\\N') AS null_store_name,
      COUNTIF(location_num_store_name IS NULL OR location_num_store_name = '' OR location_num_store_name = '\\N') AS null_location_num_store_name,
      COUNTIF(channel IS NULL OR channel = '' OR channel = '\\N') AS null_channel,
      COUNTIF(ws_channel IS NULL OR ws_channel = '' OR ws_channel = '\\N') AS null_ws_channel,
      COUNTIF(channel_code IS NULL OR channel_code = '' OR channel_code = '\\N') AS null_channel_code,
      COUNTIF(store_format_code IS NULL OR store_format_code = '' OR store_format_code = '\\N') AS null_store_format_code,
      COUNTIF(loc_type_code IS NULL OR loc_type_code = '' OR loc_type_code = '\\N') AS null_loc_type_code,
      COUNTIF(store_type IS NULL OR store_type = '' OR store_type = '\\N') AS null_store_type,
      COUNTIF(company_code IS NULL OR company_code = '' OR company_code = '\\N') AS null_company_code,
      COUNTIF(company_name IS NULL OR company_name = '' OR company_name = '\\N') AS null_company_name,
      COUNTIF(open_date IS NULL OR open_date = '' OR open_date = '\\N') AS null_open_date,
      COUNTIF(close_date IS NULL OR close_date = '' OR close_date = '\\N') AS null_close_date,
      COUNTIF(active IS NULL OR active = '' OR active = '\\N') AS null_active,
      COUNTIF(geography IS NULL OR geography = '' OR geography = '\\N') AS null_geography,
      COUNTIF(region IS NULL OR region = '' OR region = '\\N') AS null_region,
      COUNTIF(district_name IS NULL OR district_name = '' OR district_name = '\\N') AS null_district_name,
      COUNTIF(like_store_id IS NULL OR like_store_id = '' OR like_store_id = '\\N') AS null_like_store_id,
      COUNTIF(city IS NULL OR city = '' OR city = '\\N') AS null_city,
      COUNTIF(state IS NULL OR state = '' OR state = '\\N') AS null_state,
      COUNTIF(zipcode IS NULL OR zipcode = '' OR zipcode = '\\N') AS null_zipcode,
      COUNTIF(latitude IS NULL OR latitude = '' OR latitude = '\\N') AS null_latitude,
      COUNTIF(longitude IS NULL OR longitude = '' OR longitude = '\\N') AS null_longitude,
      COUNTIF(location_hierarchy_region_code IS NULL OR location_hierarchy_region_code = '' OR location_hierarchy_region_code = '\\N') AS null_location_hierarchy_region_code,
      -- INT64
      COUNTIF(location_attrib_squareft IS NULL) AS null_location_attrib_squareft,
      COUNTIF(dc_flag IS NULL) AS null_dc_flag,
      COUNTIF(special_classification IS NULL) AS null_special_classification,
      -- BOOL
      COUNTIF(is_deleted IS NULL) AS null_is_deleted
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
),

-- ========== Q3: Duplicates at store_code ==========
q3_rows AS (
  SELECT store_code, COUNT(*) AS dup_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY store_code
  HAVING COUNT(*) > 1
  ORDER BY dup_count DESC
  LIMIT 20
),
q3 AS (
  SELECT 'Q3' AS query_id,
         'Duplicates at store_code level' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT COUNT(*) FROM q3_rows) AS duplicate_store_code_count,
           (SELECT ARRAY_AGG(STRUCT(store_code, dup_count)) FROM q3_rows) AS duplicates
         )) AS results_json
),

-- ========== Q4: Hierarchy s0→s4 integrity ==========
-- Each level: distinct IDs vs names, and children-with-multiple-parents
q4_levels AS (
  SELECT 's0' AS level, COUNT(DISTINCT s0_name) AS distinct_names, NULL AS distinct_ids, NULL AS ids_with_multi_names, NULL AS names_with_multi_ids
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  UNION ALL
  SELECT 's1', COUNT(DISTINCT s1_name), NULL, NULL, NULL FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  UNION ALL
  SELECT 's2', COUNT(DISTINCT s2_name), NULL, NULL, NULL FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  UNION ALL
  SELECT 's3', COUNT(DISTINCT s3_name), COUNT(DISTINCT s3_id),
         (SELECT COUNT(*) FROM (SELECT s3_id FROM `lululemon-01042025.lululemon_souricng_outbound.store_master` GROUP BY s3_id HAVING COUNT(DISTINCT s3_name)>1)),
         (SELECT COUNT(*) FROM (SELECT s3_name FROM `lululemon-01042025.lululemon_souricng_outbound.store_master` GROUP BY s3_name HAVING COUNT(DISTINCT s3_id)>1))
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  UNION ALL
  SELECT 's4', COUNT(DISTINCT s4_name), NULL, NULL, NULL FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
),
q4 AS (
  SELECT 'Q4' AS query_id,
         'Hierarchy s0-s4 integrity' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(level, distinct_names, distinct_ids, ids_with_multi_names, names_with_multi_ids))) AS results_json
  FROM q4_levels
),

-- ========== Q5: Lifecycle — active / is_deleted / open_date / close_date ==========
q5_summary AS (
  SELECT
    COUNT(*) AS total_stores,
    COUNTIF(is_deleted = TRUE) AS deleted_stores,
    COUNTIF(is_deleted = FALSE OR is_deleted IS NULL) AS non_deleted_stores,
    COUNT(DISTINCT active) AS distinct_active_values,
    COUNTIF(close_date IS NOT NULL AND close_date != '' AND close_date != '\\N') AS stores_with_close_date,
    COUNTIF(close_date IS NULL OR close_date = '' OR close_date = '\\N') AS stores_without_close_date,
    COUNTIF(open_date IS NOT NULL AND open_date != '' AND open_date != '\\N') AS stores_with_open_date,
    MIN(open_date) AS min_open_date_text,
    MAX(open_date) AS max_open_date_text,
    MIN(close_date) AS min_close_date_text,
    MAX(close_date) AS max_close_date_text
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
),
q5_active AS (
  SELECT COALESCE(active, '<NULL>') AS active_val, COUNT(*) AS cnt
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY active
  ORDER BY cnt DESC
),
q5 AS (
  SELECT 'Q5' AS query_id,
         'Lifecycle (active / is_deleted / open_date / close_date)' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT AS STRUCT * FROM q5_summary) AS summary,
           (SELECT ARRAY_AGG(STRUCT(active_val, cnt)) FROM q5_active) AS active_distribution
         )) AS results_json
),

-- ========== Q6: Categorical distributions for top classification columns ==========
q6_channel_code AS (
  SELECT 'channel_code' AS attribute, COALESCE(channel_code, '<NULL>') AS value, COUNT(*) AS cnt
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY channel_code
),
q6_geography AS (
  SELECT 'geography', COALESCE(geography, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY geography
),
q6_region AS (
  SELECT 'region', COALESCE(region, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY region
),
q6_loc_type_code AS (
  SELECT 'loc_type_code', COALESCE(loc_type_code, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY loc_type_code
),
q6_store_type AS (
  SELECT 'store_type', COALESCE(store_type, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY store_type
),
q6_store_format_code AS (
  SELECT 'store_format_code', COALESCE(store_format_code, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY store_format_code
),
q6_dc_flag AS (
  SELECT 'dc_flag', CAST(dc_flag AS STRING), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY dc_flag
),
q6_special_class AS (
  SELECT 'special_classification', CAST(special_classification AS STRING), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY special_classification
),
q6_company_code AS (
  SELECT 'company_code', COALESCE(company_code, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY company_code
),
q6_channel AS (
  SELECT 'channel', COALESCE(channel, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY channel
),
q6_ws_channel AS (
  SELECT 'ws_channel', COALESCE(ws_channel, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  GROUP BY ws_channel
),
q6_all AS (
  SELECT * FROM q6_channel_code
  UNION ALL SELECT * FROM q6_geography
  UNION ALL SELECT * FROM q6_region
  UNION ALL SELECT * FROM q6_loc_type_code
  UNION ALL SELECT * FROM q6_store_type
  UNION ALL SELECT * FROM q6_store_format_code
  UNION ALL SELECT * FROM q6_dc_flag
  UNION ALL SELECT * FROM q6_special_class
  UNION ALL SELECT * FROM q6_company_code
  UNION ALL SELECT * FROM q6_channel
  UNION ALL SELECT * FROM q6_ws_channel
),
q6 AS (
  SELECT 'Q6' AS query_id,
         'Categorical distributions (attribute / value / count)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(attribute, value, cnt) ORDER BY attribute, cnt DESC)) AS results_json
  FROM q6_all
),

-- ========== Q7: Virtual store cross-check ==========
-- The 10 virtual stores identified in Txn Master A3 — what does store_master say about them?
q7_rows AS (
  SELECT
    store_code,
    store_name,
    channel,
    channel_code,
    ws_channel,
    loc_type_code,
    store_type,
    store_format_code,
    dc_flag,
    special_classification,
    geography,
    region,
    country_from_company AS company_name,
    active,
    is_deleted,
    open_date,
    close_date,
    city,
    state
  FROM (
    SELECT *, company_name AS country_from_company
    FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
  )
  WHERE store_code IN (
    '0000009198',  -- LLL_USA_ECOM
    '0000009188',  -- LLL_CAN_ECOM
    '0000045189',  -- LLL_CHINA_ECOM
    '0000060188',  -- LLL_EUR_ECOM
    '0000045187',  -- LLL_CHINA_ECOM
    '0000059188',  -- LLL_AUS_NZ_ECOM
    '0000045186',  -- LLL_CHINA_ECOM
    '0000065188',  -- LLL_EUR_ECOM
    '0000044188',  -- LLL_ASIA_ECOM
    '0000066188'   -- LLL_EUR_ECOM
  )
),
q7 AS (
  SELECT 'Q7' AS query_id,
         'Virtual stores cross-check: metadata for 10 stores identified in Txn Master A3' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(
           store_code, store_name, channel, channel_code, ws_channel,
           loc_type_code, store_type, store_format_code,
           dc_flag, special_classification,
           geography, region, company_name,
           active, is_deleted, open_date, close_date,
           city, state
         ))) AS results_json
  FROM q7_rows
)

SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
UNION ALL SELECT * FROM q5
UNION ALL SELECT * FROM q6
UNION ALL SELECT * FROM q7
ORDER BY query_id;
