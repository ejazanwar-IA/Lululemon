-- =============================================================================
-- Product Master EDA - Phase 3 CONSOLIDATED
--
-- Goal: Validate derivations (gender, active, color) work correctly, then
--       build a cleaned/derived product_master ready for downstream modeling.
--
-- This file has TWO PARTS. Run them as two separate queries:
--   PART A: Validation queries (one query, 4 rows out - JSON)
--   PART B: Cleaned master SELECT (preview 100 rows; wrap in CREATE VIEW
--           when you want to persist it)
-- =============================================================================


-- ===========================================================================
-- PART A: Validation queries (run this first)
-- ===========================================================================

WITH

-- ---- Q1: Gender derivation agreement (l5_name prefix vs populated gender) ----
-- Purpose: For rows where gender IS populated, does the l5_name prefix agree?
-- If agreement is ~100%, the derivation is safe to apply to NULL rows.
q1_rows AS (
  SELECT
    gender AS populated_gender,
    CASE
      WHEN l5_name LIKE 'Womens%' THEN 'Womens'
      WHEN l5_name LIKE 'Mens%'   THEN 'Mens'
      WHEN l5_name LIKE 'ivivva%' THEN 'Girls'
      ELSE 'OTHER'
    END AS derived_gender,
    COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE gender IS NOT NULL
  GROUP BY populated_gender, derived_gender
),
q1 AS (
  SELECT 'Q1' AS query_id,
         'Gender derivation agreement (l5_name prefix vs populated gender)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(populated_gender, derived_gender, row_count) ORDER BY row_count DESC)) AS results_json
  FROM q1_rows
),

-- ---- Q2: Gender derivation validation via product_line prefix ----
-- Secondary validation - does product_line prefix also agree?
q2_rows AS (
  SELECT
    gender AS populated_gender,
    CASE
      WHEN product_line LIKE 'W %'  OR product_line = 'W No Sweat' THEN 'Womens'
      WHEN product_line LIKE 'M %'  OR product_line = 'M No Sweat' THEN 'Mens'
      WHEN product_line LIKE 'FT %' OR product_line = 'FT No Sweat' THEN 'FastTurn/Unknown'
      ELSE 'OTHER'
    END AS derived_from_product_line,
    COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE gender IS NOT NULL AND product_line IS NOT NULL
  GROUP BY populated_gender, derived_from_product_line
),
q2 AS (
  SELECT 'Q2' AS query_id,
         'Gender derivation agreement (product_line prefix vs populated gender)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(populated_gender, derived_from_product_line, row_count) ORDER BY row_count DESC)) AS results_json
  FROM q2_rows
),

-- ---- Q3: Color name parsing preview ----
-- Purpose: color_description format is "<product_name> | <color_name>".
-- Extract the part after last '|' and preview samples + coverage.
q3_rows AS (
  SELECT
    COUNT(*) AS total_rows,
    COUNTIF(REGEXP_CONTAINS(color_description, r'\|')) AS rows_with_pipe,
    COUNTIF(NOT REGEXP_CONTAINS(color_description, r'\|')) AS rows_without_pipe,
    COUNT(DISTINCT TRIM(REGEXP_EXTRACT(color_description, r'\|\s*([^|]*)$'))) AS distinct_parsed_color_names
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE color_description IS NOT NULL
),
q3_samples AS (
  SELECT TRIM(REGEXP_EXTRACT(color_description, r'\|\s*([^|]*)$')) AS parsed_color_name,
         COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE color_description IS NOT NULL
    AND REGEXP_CONTAINS(color_description, r'\|')
  GROUP BY parsed_color_name
  ORDER BY row_count DESC
  LIMIT 30
),
q3 AS (
  SELECT 'Q3' AS query_id,
         'Color name parsing preview (after pipe in color_description)' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT AS STRUCT * FROM q3_rows) AS summary,
           (SELECT ARRAY_AGG(STRUCT(parsed_color_name, row_count)) FROM q3_samples) AS top_30_parsed_colors
         )) AS results_json
),

-- ---- Q4: Cleaned master row-count summary ----
-- Expected final row counts after derivations + placeholder flag.
q4_rows AS (
  SELECT
    COUNT(*) AS total_rows,
    COUNTIF(flex_status = 'Active') AS active_rows,
    COUNTIF(flex_status IN ('Active', 'Drop')) AS active_or_drop_rows,
    COUNTIF(LENGTH(COALESCE(article_original, '')) <= 3) AS placeholder_rows,
    COUNTIF(l5_name LIKE 'Womens%' OR l5_name LIKE 'Mens%' OR l5_name LIKE 'ivivva%') AS rows_with_derivable_gender,
    COUNTIF(gender IS NOT NULL) AS rows_with_populated_gender,
    -- rows where gender can be derived OR is already populated
    COUNTIF(gender IS NOT NULL
            OR l5_name LIKE 'Womens%'
            OR l5_name LIKE 'Mens%'
            OR l5_name LIKE 'ivivva%') AS rows_with_known_gender_after_derivation
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
),
q4 AS (
  SELECT 'Q4' AS query_id,
         'Cleaned master row-count summary (derivations applied)' AS description,
         TO_JSON_STRING((SELECT AS STRUCT * FROM q4_rows)) AS results_json
)

SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
ORDER BY query_id;


-- ===========================================================================
-- PART B: Cleaned master SELECT (run as a SEPARATE query)
-- ===========================================================================
-- This is the "clean" Product Master ready for downstream use.
-- Preview 100 rows first; wrap in CREATE OR REPLACE VIEW when ready.
--
-- To materialize as a view (when you have DDL access):
--
--   CREATE OR REPLACE VIEW `<your-dataset>.product_master_clean` AS
--   <paste the SELECT below>
--
-- Or use it as a CTE in downstream queries.
-- ---------------------------------------------------------------------------

-- COMMENT OUT PART A above and UNCOMMENT this block when you want to run PART B.

/*
SELECT
  -- ---- Primary keys / identifiers ----
  product_code,                         -- PK (unique per row)
  product_code_original,                -- channel-agnostic
  article,
  article_original,
  l1_name AS channel,                   -- RETAIL or ECOMM
  size,
  color_code,

  -- ---- Hierarchy ----
  l2_id, l2_name,
  l3_id, l3_name,
  l4_id, l4_name,
  l5_id, l5_name,
  l6_id, l6_name,
  l7_id, l7_name,
  l8_id, l8_name,

  -- ---- Derived columns ----
  -- Derived gender (l5_name-based, falls back to populated gender if l5 prefix doesn't match)
  CASE
    WHEN l5_name LIKE 'Womens%' THEN 'Womens'
    WHEN l5_name LIKE 'Mens%'   THEN 'Mens'
    WHEN l5_name LIKE 'ivivva%' THEN 'Girls'
    ELSE gender                         -- Unisex or other pre-populated values
  END AS derived_gender,

  -- Whether gender came from the l5 prefix derivation (for debugging / QC)
  CASE
    WHEN l5_name LIKE 'Womens%' OR l5_name LIKE 'Mens%' OR l5_name LIKE 'ivivva%' THEN 'derived'
    WHEN gender IS NOT NULL THEN 'populated'
    ELSE 'unknown'
  END AS gender_source,

  -- Active flag based on flex_status
  CASE
    WHEN flex_status = 'Active' THEN TRUE
    ELSE FALSE
  END AS is_active,

  -- Also expose the raw flex_status and a "in_sellcycle" (Active OR Drop) indicator
  flex_status,
  CASE
    WHEN flex_status IN ('Active', 'Drop') THEN TRUE
    ELSE FALSE
  END AS is_in_sellcycle,

  -- Parsed color name (after last '|' in color_description)
  TRIM(REGEXP_EXTRACT(color_description, r'\|\s*([^|]*)$')) AS parsed_color_name,
  color_description,

  -- Placeholder flag (short article codes are suspected placeholders/competitor refs)
  (LENGTH(COALESCE(article_original, '')) <= 3) AS is_placeholder,

  -- ---- Other useful attributes (raw) ----
  product_name,
  season_code,
  silhouette,
  planning_product_grouping,
  fit_classification,
  design_line,
  designed_for_activity,
  global_merch_team,
  product_line,
  size_scale,
  product_development_pod,
  product_size_definition,
  global_line_segment_style_category,
  article_status,
  active_flag,
  product_bucket_code

FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
LIMIT 100;
*/
