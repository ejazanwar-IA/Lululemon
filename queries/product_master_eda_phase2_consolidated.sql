-- =============================================================================
-- Product Master EDA - Phase 2 CONSOLIDATED
-- Hierarchy integrity, gender derivability, placeholder articles,
-- color consistency, attribute distributions.
--
-- Run as one query, produces a single result table with one row per query_id.
-- Copy the full output, paste back.
--
-- Table: lululemon-01042025.lululemon_souricng_outbound.product_master
-- =============================================================================

WITH

-- ========== Q1: Hierarchy id <-> name 1-to-1 check per level ==========
-- For each level, how many distinct IDs, distinct names, and how many
-- IDs have >1 name (bad), how many names have >1 ID (bad).
l2_names_per_id AS (SELECT l2_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l2_id IS NOT NULL GROUP BY l2_id HAVING COUNT(DISTINCT l2_name) > 1),
l2_ids_per_name AS (SELECT l2_name FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l2_name IS NOT NULL GROUP BY l2_name HAVING COUNT(DISTINCT l2_id) > 1),
l3_names_per_id AS (SELECT l3_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l3_id IS NOT NULL GROUP BY l3_id HAVING COUNT(DISTINCT l3_name) > 1),
l3_ids_per_name AS (SELECT l3_name FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l3_name IS NOT NULL GROUP BY l3_name HAVING COUNT(DISTINCT l3_id) > 1),
l4_names_per_id AS (SELECT l4_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l4_id IS NOT NULL GROUP BY l4_id HAVING COUNT(DISTINCT l4_name) > 1),
l4_ids_per_name AS (SELECT l4_name FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l4_name IS NOT NULL GROUP BY l4_name HAVING COUNT(DISTINCT l4_id) > 1),
l5_names_per_id AS (SELECT l5_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l5_id IS NOT NULL GROUP BY l5_id HAVING COUNT(DISTINCT l5_name) > 1),
l5_ids_per_name AS (SELECT l5_name FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l5_name IS NOT NULL GROUP BY l5_name HAVING COUNT(DISTINCT l5_id) > 1),
l6_names_per_id AS (SELECT l6_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l6_id IS NOT NULL GROUP BY l6_id HAVING COUNT(DISTINCT l6_name) > 1),
l6_ids_per_name AS (SELECT l6_name FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l6_name IS NOT NULL GROUP BY l6_name HAVING COUNT(DISTINCT l6_id) > 1),
l7_names_per_id AS (SELECT l7_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l7_id IS NOT NULL GROUP BY l7_id HAVING COUNT(DISTINCT l7_name) > 1),
l7_ids_per_name AS (SELECT l7_name FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l7_name IS NOT NULL GROUP BY l7_name HAVING COUNT(DISTINCT l7_id) > 1),
l8_names_per_id AS (SELECT l8_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l8_id IS NOT NULL GROUP BY l8_id HAVING COUNT(DISTINCT l8_name) > 1),
l8_ids_per_name AS (SELECT l8_name FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l8_name IS NOT NULL GROUP BY l8_name HAVING COUNT(DISTINCT l8_id) > 1),

q1_rows AS (
  SELECT 'l2' AS level,
         (SELECT COUNT(DISTINCT l2_id) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`) AS distinct_ids,
         (SELECT COUNT(DISTINCT l2_name) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`) AS distinct_names,
         (SELECT COUNT(*) FROM l2_names_per_id) AS ids_with_multiple_names,
         (SELECT COUNT(*) FROM l2_ids_per_name) AS names_with_multiple_ids
  UNION ALL SELECT 'l3',
         (SELECT COUNT(DISTINCT l3_id) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(DISTINCT l3_name) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(*) FROM l3_names_per_id),
         (SELECT COUNT(*) FROM l3_ids_per_name)
  UNION ALL SELECT 'l4',
         (SELECT COUNT(DISTINCT l4_id) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(DISTINCT l4_name) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(*) FROM l4_names_per_id),
         (SELECT COUNT(*) FROM l4_ids_per_name)
  UNION ALL SELECT 'l5',
         (SELECT COUNT(DISTINCT l5_id) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(DISTINCT l5_name) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(*) FROM l5_names_per_id),
         (SELECT COUNT(*) FROM l5_ids_per_name)
  UNION ALL SELECT 'l6',
         (SELECT COUNT(DISTINCT l6_id) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(DISTINCT l6_name) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(*) FROM l6_names_per_id),
         (SELECT COUNT(*) FROM l6_ids_per_name)
  UNION ALL SELECT 'l7',
         (SELECT COUNT(DISTINCT l7_id) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(DISTINCT l7_name) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(*) FROM l7_names_per_id),
         (SELECT COUNT(*) FROM l7_ids_per_name)
  UNION ALL SELECT 'l8',
         (SELECT COUNT(DISTINCT l8_id) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(DISTINCT l8_name) FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`),
         (SELECT COUNT(*) FROM l8_names_per_id),
         (SELECT COUNT(*) FROM l8_ids_per_name)
),
q1 AS (
  SELECT 'Q1' AS query_id,
         'Hierarchy id <-> name 1-to-1 check per level' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(level, distinct_ids, distinct_names, ids_with_multiple_names, names_with_multiple_ids) ORDER BY level)) AS results_json
  FROM q1_rows
),

-- ========== Q2: Parent-child hierarchy integrity ==========
-- For each level L, how many child IDs belong to multiple parents at level L-1?
-- Should be 0 for a clean hierarchy. (l2 has no parent in this table; l3->l2, l4->l3, etc.)
q2_rows AS (
  SELECT 'l3_has_multi_l2_parents' AS check_name,
         COUNT(*) AS failing_children
  FROM (SELECT l3_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l3_id IS NOT NULL GROUP BY l3_id HAVING COUNT(DISTINCT l2_id) > 1)
  UNION ALL SELECT 'l4_has_multi_l3_parents',
         COUNT(*)
  FROM (SELECT l4_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l4_id IS NOT NULL GROUP BY l4_id HAVING COUNT(DISTINCT l3_id) > 1)
  UNION ALL SELECT 'l5_has_multi_l4_parents',
         COUNT(*)
  FROM (SELECT l5_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l5_id IS NOT NULL GROUP BY l5_id HAVING COUNT(DISTINCT l4_id) > 1)
  UNION ALL SELECT 'l6_has_multi_l5_parents',
         COUNT(*)
  FROM (SELECT l6_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l6_id IS NOT NULL GROUP BY l6_id HAVING COUNT(DISTINCT l5_id) > 1)
  UNION ALL SELECT 'l7_has_multi_l6_parents',
         COUNT(*)
  FROM (SELECT l7_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l7_id IS NOT NULL GROUP BY l7_id HAVING COUNT(DISTINCT l6_id) > 1)
  UNION ALL SELECT 'l8_has_multi_l7_parents',
         COUNT(*)
  FROM (SELECT l8_id FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` WHERE l8_id IS NOT NULL GROUP BY l8_id HAVING COUNT(DISTINCT l7_id) > 1)
),
q2 AS (
  SELECT 'Q2' AS query_id,
         'Hierarchy parent-child integrity (children with multiple parents)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(check_name, failing_children))) AS results_json
  FROM q2_rows
),

-- ========== Q3: Gender derivability from hierarchy/text ==========
-- Map each distinct (gender, l5_name, planning_product_grouping) combination
-- to see if gender is inferrable from those fields when gender is null.
q3_rows AS (
  SELECT
    COALESCE(gender, '<NULL>') AS gender,
    COALESCE(l5_name, '<NULL>') AS l5_name,
    COALESCE(planning_product_grouping, '<NULL>') AS planning_product_grouping,
    COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY gender, l5_name, planning_product_grouping
  ORDER BY row_count DESC
  LIMIT 50
),
q3 AS (
  SELECT 'Q3' AS query_id,
         'Gender derivability (top 50 combos of gender/l5_name/planning_product_grouping)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(gender, l5_name, planning_product_grouping, row_count))) AS results_json
  FROM q3_rows
),

-- ========== Q4: Placeholder articles (short article codes) ==========
-- Identify articles where the base (before _RETAIL/_ECOMM) is suspiciously short.
-- Also show top 20 short-code articles by row count.
q4_summary AS (
  SELECT
    COUNTIF(LENGTH(COALESCE(article_original, '')) <= 3) AS rows_with_short_article,
    COUNTIF(LENGTH(COALESCE(article_original, '')) BETWEEN 4 AND 6) AS rows_with_medium_short_article,
    COUNT(DISTINCT CASE WHEN LENGTH(COALESCE(article_original, '')) <= 3 THEN article_original END) AS distinct_short_articles,
    COUNT(*) AS total_rows
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
),
q4_examples AS (
  SELECT article_original, COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE LENGTH(COALESCE(article_original, '')) <= 3
  GROUP BY article_original
  ORDER BY row_count DESC
  LIMIT 20
),
q4 AS (
  SELECT 'Q4' AS query_id,
         'Placeholder / short-code articles: scope + top 20 examples' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT AS STRUCT * FROM q4_summary) AS summary,
           (SELECT ARRAY_AGG(STRUCT(article_original, row_count)) FROM q4_examples) AS top_20_short_articles
         )) AS results_json
),

-- ========== Q5: color_code <-> color_description consistency ==========
-- If one color_code maps to multiple color_descriptions (beyond the product-name prefix),
-- that's a standardization issue. Also check reverse.
q5_base AS (
  SELECT
    color_code,
    COUNT(DISTINCT color_description) AS distinct_descriptions,
    ANY_VALUE(color_description) AS sample_description
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE color_code IS NOT NULL
  GROUP BY color_code
),
q5_summary AS (
  SELECT
    COUNT(*) AS total_distinct_color_codes,
    COUNTIF(distinct_descriptions > 1) AS color_codes_with_multiple_descriptions,
    COUNTIF(distinct_descriptions = 1) AS color_codes_with_single_description,
    MAX(distinct_descriptions) AS max_descriptions_for_any_code,
    APPROX_QUANTILES(distinct_descriptions, 10) AS descriptions_per_code_deciles
  FROM q5_base
),
q5_worst AS (
  SELECT color_code, distinct_descriptions, sample_description
  FROM q5_base
  WHERE distinct_descriptions > 1
  ORDER BY distinct_descriptions DESC
  LIMIT 20
),
q5 AS (
  SELECT 'Q5' AS query_id,
         'color_code <-> color_description consistency' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT AS STRUCT * FROM q5_summary) AS summary,
           (SELECT ARRAY_AGG(STRUCT(color_code, distinct_descriptions, sample_description)) FROM q5_worst) AS worst_offenders
         )) AS results_json
),

-- ========== Q6: Distinct value distributions for key attributes ==========
-- One row per attribute showing: distinct value count, top values, null pct
q6_gender AS (
  SELECT 'gender' AS attribute, COALESCE(gender, '<NULL>') AS value, COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY gender
),
q6_flex AS (
  SELECT 'flex_status', COALESCE(flex_status, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY flex_status
),
q6_merch AS (
  SELECT 'global_merch_team', COALESCE(global_merch_team, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY global_merch_team
),
q6_fit AS (
  SELECT 'fit_classification', COALESCE(fit_classification, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY fit_classification
),
q6_design AS (
  SELECT 'design_line', COALESCE(design_line, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY design_line
),
q6_activity AS (
  SELECT 'designed_for_activity', COALESCE(designed_for_activity, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY designed_for_activity
),
q6_prodline AS (
  SELECT 'product_line', COALESCE(product_line, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY product_line
),
q6_sizescale AS (
  SELECT 'size_scale', COALESCE(size_scale, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY size_scale
),
q6_season AS (
  SELECT 'season_code', COALESCE(season_code, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY season_code
),
q6_silhouette AS (
  SELECT 'silhouette', COALESCE(silhouette, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  GROUP BY silhouette
),
q6_all AS (
  SELECT * FROM q6_gender
  UNION ALL SELECT * FROM q6_flex
  UNION ALL SELECT * FROM q6_merch
  UNION ALL SELECT * FROM q6_fit
  UNION ALL SELECT * FROM q6_design
  UNION ALL SELECT * FROM q6_activity
  UNION ALL SELECT * FROM q6_prodline
  UNION ALL SELECT * FROM q6_sizescale
  UNION ALL SELECT * FROM q6_season
  UNION ALL SELECT * FROM q6_silhouette
),
q6_ranked AS (
  SELECT
    attribute, value, row_count,
    ROW_NUMBER() OVER (PARTITION BY attribute ORDER BY row_count DESC) AS rnk
  FROM q6_all
),
q6_top AS (
  SELECT attribute, value, row_count
  FROM q6_ranked
  WHERE rnk <= 15  -- top 15 values per attribute
),
q6 AS (
  SELECT 'Q6' AS query_id,
         'Distinct value distributions for key categorical attributes (top 15 per attribute)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(attribute, value, row_count) ORDER BY attribute, row_count DESC)) AS results_json
  FROM q6_top
)

-- ========== Final union ==========
SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
UNION ALL SELECT * FROM q5
UNION ALL SELECT * FROM q6
ORDER BY query_id;
