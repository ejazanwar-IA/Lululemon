-- =============================================================================
-- Transaction Master - Phase 3: Cross-Table Integrity
--
-- Goal:
--   A1: Are there SKUs in transactions that don't exist in product_master?
--   A2: What ~1M SKUs in product_master never sold? Characterize them.
--   A3: Confirm the "virtual stores" hypothesis — which store_codes dominate?
--
-- Tables touched:
--   - transaction_master (73 GB, full scan once)
--   - product_master    (1.1 GB, full scan)
--
-- Est cost: ~$0.38.
-- =============================================================================

WITH

-- Distinct products sold, with row count (how many txns)
txn_products AS (
  SELECT
    product_code,
    COUNT(*) AS rows_in_txn,
    COUNTIF(qty > 0) AS real_sales_rows,
    COUNTIF(qty = 0) AS zero_qty_rows
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  WHERE product_code IS NOT NULL
  GROUP BY product_code
),

-- Distinct stores used in txns
txn_stores AS (
  SELECT
    store_code,
    ANY_VALUE(channel_code) AS any_channel_code,
    APPROX_COUNT_DISTINCT(channel_code) AS distinct_channel_codes_at_store,
    COUNT(*) AS rows_in_txn,
    COUNTIF(qty > 0) AS real_sales_rows,
    COUNTIF(qty = 0) AS zero_qty_rows,
    ROUND(100.0 * COUNTIF(qty = 0) / COUNT(*), 2) AS pct_zero
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  WHERE store_code IS NOT NULL
  GROUP BY store_code
),

-- Product master with derived gender/active/placeholder (inline, matching
-- product_master_clean_view.sql logic)
pm AS (
  SELECT
    product_code,
    l2_name,
    l3_name,
    l5_name,
    flex_status,
    gender,
    LENGTH(COALESCE(article_original, '')) <= 3 AS is_placeholder,
    CASE
      WHEN l5_name LIKE 'Lab Womens%' OR l5_name LIKE 'Lab Mens%' THEN TRUE
      ELSE FALSE
    END AS is_lab_line
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
),

-- ========== A1: Orphan products (in txn, NOT in product_master) ==========
orphan_products AS (
  SELECT t.product_code, t.rows_in_txn, t.real_sales_rows, t.zero_qty_rows
  FROM txn_products t
  LEFT JOIN pm ON pm.product_code = t.product_code
  WHERE pm.product_code IS NULL
),
orphan_summary AS (
  SELECT
    COUNT(*) AS distinct_orphan_products,
    SUM(rows_in_txn) AS total_orphan_rows,
    SUM(real_sales_rows) AS total_orphan_real_sales
  FROM orphan_products
),
orphan_top20 AS (
  SELECT product_code, rows_in_txn, real_sales_rows, zero_qty_rows
  FROM orphan_products
  ORDER BY rows_in_txn DESC
  LIMIT 20
),
a1 AS (
  SELECT 'A1' AS query_id,
         'Orphan SKUs: in transactions but NOT in product_master' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT AS STRUCT * FROM orphan_summary) AS summary,
           (SELECT ARRAY_AGG(STRUCT(product_code, rows_in_txn, real_sales_rows, zero_qty_rows)) FROM orphan_top20) AS top_20_orphans
         )) AS results_json
),

-- ========== A2: Unsold SKUs (in product_master, NOT in transactions) ==========
unsold_products AS (
  SELECT pm.product_code, pm.l2_name, pm.l3_name, pm.l5_name,
         pm.flex_status, pm.gender, pm.is_placeholder, pm.is_lab_line
  FROM pm
  LEFT JOIN txn_products t ON t.product_code = pm.product_code
  WHERE t.product_code IS NULL
),
unsold_summary AS (
  SELECT
    COUNT(*) AS distinct_unsold_products,
    COUNTIF(flex_status = 'Active') AS active_unsold,
    COUNTIF(flex_status = 'Drop') AS drop_unsold,
    COUNTIF(flex_status = 'Inactive') AS inactive_unsold,
    COUNTIF(flex_status IS NULL OR flex_status NOT IN ('Active','Drop','Inactive')) AS other_status_unsold,
    COUNTIF(is_placeholder) AS placeholder_unsold,
    COUNTIF(is_lab_line) AS lab_line_unsold
  FROM unsold_products
),
unsold_by_l2 AS (
  SELECT l2_name, COUNT(*) AS unsold_product_count
  FROM unsold_products
  GROUP BY l2_name
  ORDER BY unsold_product_count DESC
),
a2 AS (
  SELECT 'A2' AS query_id,
         'Unsold SKUs: in product_master but NOT in transactions' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT AS STRUCT * FROM unsold_summary) AS summary,
           (SELECT ARRAY_AGG(STRUCT(l2_name, unsold_product_count)) FROM unsold_by_l2) AS by_l2_name
         )) AS results_json
),

-- ========== A3: Store breakdown in transaction_master ==========
-- Top 30 stores by row count. Looking for:
-- - Stores matching channel_code totals (= virtual stores)
-- - Stores with extreme zero-qty% (= fulfillment / digital locations)
a3_top30 AS (
  SELECT
    store_code,
    any_channel_code,
    distinct_channel_codes_at_store,
    rows_in_txn,
    real_sales_rows,
    zero_qty_rows,
    pct_zero
  FROM txn_stores
  ORDER BY rows_in_txn DESC
  LIMIT 30
),
a3_summary AS (
  SELECT
    COUNT(*) AS distinct_stores_in_txn,
    COUNTIF(pct_zero >= 40) AS stores_with_40pct_plus_zero,
    COUNTIF(pct_zero >= 50) AS stores_with_50pct_plus_zero,
    COUNTIF(pct_zero < 10) AS stores_with_low_zero
  FROM txn_stores
),
a3 AS (
  SELECT 'A3' AS query_id,
         'Store breakdown in transaction_master (top 30 by row count)' AS description,
         TO_JSON_STRING(STRUCT(
           (SELECT AS STRUCT * FROM a3_summary) AS summary,
           (SELECT ARRAY_AGG(STRUCT(store_code, any_channel_code, distinct_channel_codes_at_store, rows_in_txn, real_sales_rows, zero_qty_rows, pct_zero)) FROM a3_top30) AS top_30_stores
         )) AS results_json
),

-- ========== A4 (bonus): store_master schema probe ==========
-- So we know the column names for a future cross-check
a4_rows AS (
  SELECT column_name, data_type, ordinal_position
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'store_master'
  ORDER BY ordinal_position
),
a4 AS (
  SELECT 'A4' AS query_id,
         'store_master schema (for future cross-check)' AS description,
         TO_JSON_STRING(ARRAY_AGG(STRUCT(column_name, data_type, ordinal_position))) AS results_json
  FROM a4_rows
)

SELECT * FROM a1
UNION ALL SELECT * FROM a2
UNION ALL SELECT * FROM a3
UNION ALL SELECT * FROM a4
ORDER BY query_id;
