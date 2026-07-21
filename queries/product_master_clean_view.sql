-- =============================================================================
-- product_master_clean — Final Cleaned Product Master SELECT
--
-- Produces a clean, derived Product Master ready for downstream EDA (Transaction,
-- Inventory joins) and modeling. Incorporates all Phase 3 findings + fixes:
--
--   - gender column has literal '\N' strings (not true NULL) — treated as missing
--   - Derivation priority: populated gender wins over l5_name prefix
--   - Extended l5_name derivation to cover Lab line (Lab Womens%/Lab Mens%)
--   - color_description IS the color name already (no parsing needed)
--   - Added: is_multicolor (contains '/'), primary_color (first token)
--   - is_active (flex_status = 'Active'), is_in_sellcycle (Active or Drop)
--   - is_placeholder (short article codes ≤ 3 chars)
--
-- USAGE:
--   (A) PREVIEW: run as-is (LIMIT 100)
--   (B) MATERIALIZE:  CREATE OR REPLACE VIEW `<dataset>.product_master_clean` AS
--                     <paste the SELECT below, removing LIMIT>
-- =============================================================================

SELECT
  -- ============ PRIMARY KEYS / IDENTIFIERS ============
  product_code,                              -- unique per row (true PK)
  product_code_original,                     -- channel-agnostic
  article,
  article_original,
  l1_name AS channel,                        -- RETAIL or ECOMM (no l1_id exists)
  size,
  color_code,

  -- ============ HIERARCHY (use IDs for joins, names for display) ============
  l2_id, l2_name,
  l3_id, l3_name,
  l4_id, l4_name,
  l5_id, l5_name,
  l6_id, l6_name,
  l7_id, l7_name,
  l8_id, l8_name,

  -- ============ DERIVED COLUMNS ============

  -- Gender: populated wins > l5 prefix > Lab variants > Unisex fallback
  CASE
    WHEN gender IS NOT NULL AND gender NOT IN ('\\N', '') THEN gender
    WHEN l5_name LIKE 'Womens%'     THEN 'Womens'
    WHEN l5_name LIKE 'Mens%'       THEN 'Mens'
    WHEN l5_name LIKE 'ivivva%'     THEN 'Girls'
    WHEN l5_name LIKE 'Lab Womens%' THEN 'Womens'
    WHEN l5_name LIKE 'Lab Mens%'   THEN 'Mens'
    ELSE 'Unisex'
  END AS derived_gender,

  -- Trace how derived_gender was set (for QC / debugging)
  CASE
    WHEN gender IS NOT NULL AND gender NOT IN ('\\N', '') THEN 'populated'
    WHEN l5_name LIKE 'Womens%' OR l5_name LIKE 'Mens%' OR l5_name LIKE 'ivivva%' THEN 'l5_prefix'
    WHEN l5_name LIKE 'Lab Womens%' OR l5_name LIKE 'Lab Mens%' THEN 'lab_prefix'
    ELSE 'fallback_unisex'
  END AS gender_source,

  -- Active / lifecycle flags
  (flex_status = 'Active')                      AS is_active,
  (flex_status IN ('Active', 'Drop'))           AS is_in_sellcycle,
  flex_status,

  -- Color
  color_description,
  -- Primary color = first token before '/', trimmed
  TRIM(SPLIT(color_description, '/')[SAFE_OFFSET(0)]) AS primary_color,
  -- Multi-color flag
  CONTAINS_SUBSTR(color_description, '/')       AS is_multicolor,

  -- Placeholder flag (short article codes are suspected placeholders)
  (LENGTH(COALESCE(article_original, '')) <= 3) AS is_placeholder,

  -- ============ RAW ATTRIBUTES (as-is, for modeling input) ============
  product_name,
  season_code,                                 -- NOTE: all rows = '25-4WI' currently
  silhouette,
  planning_product_grouping,
  fit_classification,
  design_line,
  designed_for_activity,
  global_merch_team,
  product_line,
  size_scale,                                  -- coded single letter, needs lookup
  product_development_pod,
  product_size_definition,
  global_line_segment_style_category,
  article_status,                              -- uniformly 'ACTIVE' (not useful as filter)
  active_flag,                                 -- uniformly 1 (not useful as filter)
  product_bucket_code,
  gender AS gender_raw                         -- raw value for audit
  -- launch_date, color_family, ordering are 100% NULL - not included

FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
LIMIT 100;
