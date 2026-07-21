-- =============================================================================
-- Sample Rows - All Canonical Raw Tables
-- Uses size-appropriate sampling to avoid bias.
--
-- Sampling strategy:
--   < 10M rows       : ORDER BY RAND() LIMIT 3
--   10M-500M rows    : WHERE RAND() < 0.0001 LIMIT 3
--   > 500M rows      : TABLESAMPLE SYSTEM (0.001 PERCENT) + LIMIT 3
--
-- Each row is the random sample serialized as JSON so different schemas
-- can coexist in one UNION.
-- =============================================================================

-- ========== Small tables (< 10M rows) ==========
SELECT 'calendar_hierarchy' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'store_master' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.store_master` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'spatial_ai_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.spatial_ai_cleaned` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'anaplan_store_priority_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.anaplan_store_priority_cleaned` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'dc_store_mapping_cleaned_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.dc_store_mapping_cleaned_20251119` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'promotional_events_cleaned_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.promotional_events_cleaned_20251119` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'style_option_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.style_option_20251119` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'min_pres_eol' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.min_pres_eol` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'product_master' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.product_master` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'sku_details_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'anaplan_min_pres_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.anaplan_min_pres_cleaned` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'purchase_orders_cleaned_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.purchase_orders_cleaned_20251119` ORDER BY RAND() LIMIT 3) AS t

UNION ALL
SELECT 'product_group_hierarchy' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy` ORDER BY RAND() LIMIT 3) AS t

-- ========== Medium tables (10M-500M rows) — RAND() filter ==========
UNION ALL
SELECT 'assortment_plan_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.assortment_plan_cleaned` WHERE RAND() < 0.0001 LIMIT 3) AS t

UNION ALL
SELECT 'anaplan_allocation_calendar_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.anaplan_allocation_calendar_cleaned` WHERE RAND() < 0.0001 LIMIT 3) AS t

UNION ALL
SELECT 'anaplan_fdod_alloc_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.anaplan_fdod_alloc_cleaned` WHERE RAND() < 0.0001 LIMIT 3) AS t

UNION ALL
SELECT 'anaplan_fdod_replen_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.anaplan_fdod_replen_cleaned` WHERE RAND() < 0.0001 LIMIT 3) AS t

UNION ALL
SELECT 'anaplan_transit_calender_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.anaplan_transit_calender_cleaned` WHERE RAND() < 0.0001 LIMIT 3) AS t

UNION ALL
SELECT 'transfer_orders_new_cleaned' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.transfer_orders_new_cleaned` WHERE RAND() < 0.0001 LIMIT 3) AS t

UNION ALL
SELECT 'eligibility_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.eligibility_20251119` WHERE RAND() < 0.0001 LIMIT 3) AS t

UNION ALL
SELECT 'price_book' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.price_book` WHERE RAND() < 0.0001 LIMIT 3) AS t

-- ========== Large tables (> 500M rows) — TABLESAMPLE ==========
UNION ALL
SELECT 'transaction_master' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (
  SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master` TABLESAMPLE SYSTEM (0.001 PERCENT)
  LIMIT 3
) AS t

UNION ALL
SELECT 'returns_transactions_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (
  SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119` TABLESAMPLE SYSTEM (0.001 PERCENT)
  LIMIT 3
) AS t

UNION ALL
SELECT 'transfer_orders_cleaned_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (
  SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.transfer_orders_cleaned_20251119` TABLESAMPLE SYSTEM (0.001 PERCENT)
  LIMIT 3
) AS t

UNION ALL
SELECT 'eligibility_cleaned_20251119' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (
  SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.eligibility_cleaned_20251119` TABLESAMPLE SYSTEM (0.001 PERCENT)
  LIMIT 3
) AS t

UNION ALL
SELECT 'inventory_master' AS table_name, TO_JSON_STRING(t) AS sample_json
FROM (
  SELECT * FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master` TABLESAMPLE SYSTEM (0.001 PERCENT)
  LIMIT 3
) AS t

ORDER BY table_name;
