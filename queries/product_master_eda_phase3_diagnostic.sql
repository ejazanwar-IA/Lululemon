-- =============================================================================
-- Product Master - Phase 3 Diagnostic
-- Probes for color_description format + OTHER l5_name values.
-- Runs as one consolidated query, 3 rows out.
-- =============================================================================

WITH

-- ---- D1: Sample 30 distinct color_description values and their lengths ----
-- Purpose: see the actual delimiter (since no rows had '|').
d1_samples AS (
  SELECT color_description, LENGTH(color_description) AS len
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE color_description IS NOT NULL
  GROUP BY color_description
  ORDER BY RAND()
  LIMIT 30
),
d1 AS (
  SELECT 'D1' AS query_id,
         'Sample 30 distinct color_description values (randomly picked)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(color_description, len))) AS results_json
  FROM d1_samples
),

-- ---- D2: Character-frequency check on color_description ----
-- Purpose: see which non-alphanumeric delimiters are actually present.
d2_counts AS (
  SELECT
    COUNT(*) AS total_non_null_rows,
    COUNTIF(REGEXP_CONTAINS(color_description, r'\|'))  AS contains_pipe,
    COUNTIF(REGEXP_CONTAINS(color_description, r'/'))   AS contains_slash,
    COUNTIF(REGEXP_CONTAINS(color_description, r','))   AS contains_comma,
    COUNTIF(REGEXP_CONTAINS(color_description, r'-'))   AS contains_dash,
    COUNTIF(REGEXP_CONTAINS(color_description, r':'))   AS contains_colon,
    COUNTIF(REGEXP_CONTAINS(color_description, r';'))   AS contains_semicolon,
    COUNTIF(REGEXP_CONTAINS(color_description, r'\s-\s')) AS contains_space_dash_space,
    COUNTIF(REGEXP_CONTAINS(color_description, r'\t'))  AS contains_tab
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE color_description IS NOT NULL
),
d2 AS (
  SELECT 'D2' AS query_id,
         'Delimiter presence in color_description' AS description,
         TO_JSON_STRING((SELECT AS STRUCT * FROM d2_counts)) AS results_json
),

-- ---- D3: l5_name values that DON'T match Womens/Mens/ivivva prefix ----
-- Purpose: 31,362 "OTHER" rows had l5_names outside our pattern. What are they?
d3_rows AS (
  SELECT l5_name, COALESCE(gender, '<NULL>') AS gender, COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE l5_name IS NOT NULL
    AND l5_name NOT LIKE 'Womens%'
    AND l5_name NOT LIKE 'Mens%'
    AND l5_name NOT LIKE 'ivivva%'
  GROUP BY l5_name, gender
  ORDER BY row_count DESC
  LIMIT 50
),
d3 AS (
  SELECT 'D3' AS query_id,
         'l5_name values that do NOT match Womens/Mens/ivivva (top 50)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(l5_name, gender, row_count))) AS results_json
  FROM d3_rows
)

SELECT * FROM d1
UNION ALL SELECT * FROM d2
UNION ALL SELECT * FROM d3
ORDER BY query_id;
