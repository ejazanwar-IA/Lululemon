-- =============================================================================
-- Validation: product_master_clean derivation coverage at full scale
-- Run after previewing product_master_clean_view.sql.
-- Confirms gender/active/placeholder derivations work as expected on all 1.97M rows.
-- =============================================================================

WITH base AS (
  SELECT
    CASE
      WHEN gender IS NOT NULL AND gender NOT IN ('\\N', '') THEN gender
      WHEN l5_name LIKE 'Womens%'     THEN 'Womens'
      WHEN l5_name LIKE 'Mens%'       THEN 'Mens'
      WHEN l5_name LIKE 'ivivva%'     THEN 'Girls'
      WHEN l5_name LIKE 'Lab Womens%' THEN 'Womens'
      WHEN l5_name LIKE 'Lab Mens%'   THEN 'Mens'
      ELSE 'Unisex'
    END AS derived_gender,
    CASE
      WHEN gender IS NOT NULL AND gender NOT IN ('\\N', '') THEN 'populated'
      WHEN l5_name LIKE 'Womens%' OR l5_name LIKE 'Mens%' OR l5_name LIKE 'ivivva%' THEN 'l5_prefix'
      WHEN l5_name LIKE 'Lab Womens%' OR l5_name LIKE 'Lab Mens%' THEN 'lab_prefix'
      ELSE 'fallback_unisex'
    END AS gender_source,
    (flex_status = 'Active') AS is_active,
    (flex_status IN ('Active', 'Drop')) AS is_in_sellcycle,
    (LENGTH(COALESCE(article_original, '')) <= 3) AS is_placeholder,
    CONTAINS_SUBSTR(color_description, '/') AS is_multicolor
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
)

SELECT
  derived_gender,
  gender_source,
  COUNT(*) AS row_count,
  COUNTIF(is_active) AS active_count,
  COUNTIF(is_in_sellcycle) AS in_sellcycle_count,
  COUNTIF(is_placeholder) AS placeholder_count,
  COUNTIF(is_multicolor) AS multicolor_count
FROM base
GROUP BY derived_gender, gender_source
ORDER BY row_count DESC;
