-- =============================================================================
-- BQ Master Tables Health Check — 4 canonical masters
-- =============================================================================
-- Project: lululemon-01042025
-- Dataset: lulu_ingestion_dev
-- Run sections in order. Combine metrics per table to minimize scan passes.
-- Billing project for bq CLI: lululemon-data-scan
--   bq query --project_id=lululemon-data-scan ...
-- =============================================================================

-- =============================================================================
-- TIER 0 — Metadata (all 4 tables, ~$0)
-- =============================================================================

-- T0.1 Table inventory
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 3) AS size_gb,
  TIMESTAMP_MILLIS(creation_time) AS created_at,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified_at,
  type
FROM `lululemon-01042025.lulu_ingestion_dev.__TABLES__`
WHERE table_id IN (
  'product_master',
  'store_master',
  'transaction_master',
  'inventory_master'
)
ORDER BY table_id;

-- T0.2 Column list (compare to findings/schema_inventory.md)
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable
FROM `lululemon-01042025.lulu_ingestion_dev.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN (
  'product_master',
  'store_master',
  'transaction_master',
  'inventory_master'
)
ORDER BY table_name, ordinal_position;

-- =============================================================================
-- TIER 1.1 — product_master (full scan, ~1–2 GB)
-- =============================================================================

SELECT
  'product_master' AS table_name,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT product_code) AS distinct_product_code,
  COUNT(*) - COUNT(DISTINCT product_code) AS pk_duplicate_rows,
  COUNT(DISTINCT article) AS distinct_article,
  COUNTIF(l1_name = 'RETAIL') AS retail_rows,
  COUNTIF(l1_name = 'ECOMM') AS ecomm_rows,
  ROUND(100.0 * COUNTIF(l0_name IS NULL OR l0_name = '' OR l0_name = '\\N') / COUNT(*), 2) AS pct_null_l0_name,
  ROUND(100.0 * COUNTIF(l2_name IS NULL OR l2_name = '' OR l2_name = '\\N') / COUNT(*), 2) AS pct_null_l2_name,
  ROUND(100.0 * COUNTIF(product_name IS NULL OR product_name = '' OR product_name = '\\N') / COUNT(*), 2) AS pct_null_product_name,
  ROUND(100.0 * COUNTIF(article IS NULL OR article = '' OR article = '\\N') / COUNT(*), 2) AS pct_null_article,
  ROUND(100.0 * COUNTIF(product_bucket_code IS NULL) / COUNT(*), 2) AS pct_null_product_bucket_code,
  COUNTIF(
    (l0_name IS NULL OR l0_name = '' OR l0_name = '\\N')
    AND (product_name IS NULL OR product_name = '' OR product_name = '\\N')
  ) AS cohort_hollow,
  COUNTIF(
    l0_name IS NOT NULL AND l0_name NOT IN ('', '\\N')
    AND (product_name IS NULL OR product_name = '' OR product_name = '\\N')
  ) AS cohort_hierarchy_only,
  COUNTIF(
    (l0_name IS NULL OR l0_name = '' OR l0_name = '\\N')
    AND product_name IS NOT NULL AND product_name NOT IN ('', '\\N')
  ) AS cohort_name_only,
  COUNTIF(ENDS_WITH(product_code, '_RETAIL')) AS suffix_retail,
  COUNTIF(ENDS_WITH(product_code, '_ECOMM')) AS suffix_ecomm,
  COUNTIF(active IS TRUE) AS active_true_rows,
  COUNTIF(active IS FALSE) AS active_false_rows,
  COUNTIF(active IS NULL) AS active_null_rows,
  COUNT(DISTINCT article_status) AS distinct_article_status,
  COUNT(DISTINCT season_code) AS distinct_season_code
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`;

-- T1.1b product_master — l0_name distribution (top values)
SELECT l0_name, COUNT(*) AS row_count
FROM `lululemon-01042025.lulu_ingestion_dev.product_master`
GROUP BY ALL
ORDER BY row_count DESC
LIMIT 10;

-- =============================================================================
-- TIER 1.2 — store_master (full scan, trivial)
-- =============================================================================

SELECT
  'store_master' AS table_name,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT store_code) AS distinct_store_code,
  COUNT(*) - COUNT(DISTINCT store_code) AS pk_duplicate_rows,
  COUNTIF(dc_flag = 0) AS dc_flag_store,
  COUNTIF(dc_flag = 1) AS dc_flag_dc,
  COUNTIF(dc_flag NOT IN (0, 1) OR dc_flag IS NULL) AS dc_flag_other,
  COUNTIF(channel = 'RETAIL') AS channel_retail,
  COUNTIF(channel = 'ECOMM') AS channel_ecomm,
  COUNTIF(dc_flag = 0 AND channel = 'RETAIL') AS in_scope_retail_stores,
  COUNT(DISTINCT loc_type_code) AS distinct_loc_type_code,
  COUNT(DISTINCT store_format_code) AS distinct_store_format_code,
  COUNT(DISTINCT active) AS distinct_active_values
FROM `lululemon-01042025.lulu_ingestion_dev.store_master`;

-- T1.2b store_master — key dimension distributions
SELECT 'channel' AS dim, CAST(channel AS STRING) AS value, COUNT(*) AS n
FROM `lululemon-01042025.lulu_ingestion_dev.store_master`
GROUP BY ALL
UNION ALL
SELECT 'loc_type_code', CAST(loc_type_code AS STRING), COUNT(*)
FROM `lululemon-01042025.lulu_ingestion_dev.store_master`
GROUP BY ALL
ORDER BY dim, n DESC;

-- =============================================================================
-- TIER 1.3 — transaction_master (full history, ~73 GB / pass)
-- =============================================================================

SELECT
  'transaction_master' AS table_name,
  COUNT(*) AS total_rows,
  MIN(date) AS min_date,
  MAX(date) AS max_date,
  COUNT(DISTINCT date) AS distinct_dates,
  COUNT(DISTINCT CONCAT(CAST(date AS STRING), '|', store_code, '|', product_code)) AS distinct_grain_keys,
  COUNT(*) - COUNT(DISTINCT CONCAT(CAST(date AS STRING), '|', store_code, '|', product_code)) AS grain_duplicate_rows,
  COUNTIF(qty > 0 AND revenue > 0) AS real_sales_rows,
  ROUND(100.0 * COUNTIF(qty > 0 AND revenue > 0) / COUNT(*), 2) AS pct_real_sales,
  COUNTIF(qty = 0 AND revenue = 0 AND price = 0) AS zero_qty_zero_rev_price_rows,
  ROUND(100.0 * COUNTIF(qty = 0 AND revenue = 0 AND price = 0) / COUNT(*), 2) AS pct_zero_slice,
  COUNTIF(line_id IS NULL) AS null_line_id_rows,
  COUNTIF(transaction_type IS NULL) AS null_transaction_type_rows,
  COUNTIF(clearance = 0) AS clearance_eq_zero_rows,
  COUNTIF(unit_discount_amount = 0) AS unit_discount_zero_rows,
  COUNT(DISTINCT product_code) AS distinct_product_code,
  COUNT(DISTINCT store_code) AS distinct_store_code,
  COUNT(DISTINCT channel) AS distinct_channel
FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`;

-- =============================================================================
-- TIER 1.4 — inventory_master (all dates; 2 passes — date rollup + global metrics)
-- =============================================================================

-- T1.4a Date coverage + per-date grain dupes
SELECT
  date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CONCAT(store_code, '|', product_code)) AS distinct_store_product,
  COUNT(*) - COUNT(DISTINCT CONCAT(store_code, '|', product_code)) AS duplicate_rows_on_date
FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master`
GROUP BY date
ORDER BY date;

-- T1.4b Global grain + measures (full scan ~650 GB — largest cost block)
SELECT
  'inventory_master' AS table_name,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT date) AS distinct_dates,
  MIN(date) AS min_date,
  MAX(date) AS max_date,
  COUNT(DISTINCT CONCAT(CAST(date AS STRING), '|', store_code, '|', product_code)) AS distinct_grain_keys,
  COUNT(*) - COUNT(DISTINCT CONCAT(CAST(date AS STRING), '|', store_code, '|', product_code)) AS grain_duplicate_rows,
  COUNT(DISTINCT store_code) AS distinct_store_code,
  COUNT(DISTINCT product_code) AS distinct_product_code,
  COUNT(DISTINCT display_product_code) AS distinct_display_product_code,
  ROUND(100.0 * COUNTIF(oh IS NULL) / COUNT(*), 4) AS pct_null_oh,
  ROUND(100.0 * COUNTIF(it IS NULL) / COUNT(*), 4) AS pct_null_it,
  ROUND(100.0 * COUNTIF(oo = 0 OR oo IS NULL) / COUNT(*), 4) AS pct_zero_or_null_oo,
  ROUND(100.0 * COUNTIF(product_code_was_derived) / COUNT(*), 4) AS pct_product_code_derived,
  ROUND(100.0 * COUNTIF(channel_was_derived) / COUNT(*), 4) AS pct_channel_derived,
  MIN(oh) AS min_oh,
  MAX(oh) AS max_oh,
  SUM(CASE WHEN oh > 0 THEN 1 ELSE 0 END) AS rows_with_positive_oh
FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master`;

-- =============================================================================
-- TIER 2 — Cross-master integrity
-- =============================================================================

-- X1: Txn product_code not in product_master
SELECT
  'X1_txn_product_orphan' AS check_id,
  COUNT(DISTINCT t.product_code) AS orphan_distinct_product_codes,
  COUNT(*) AS orphan_txn_rows
FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master` t
LEFT JOIN `lululemon-01042025.lulu_ingestion_dev.product_master` p
  ON t.product_code = p.product_code
WHERE t.product_code IS NOT NULL
  AND p.product_code IS NULL;

-- X2: Txn store_code not in store_master
SELECT
  'X2_txn_store_orphan' AS check_id,
  COUNT(DISTINCT t.store_code) AS orphan_distinct_store_codes,
  COUNT(*) AS orphan_txn_rows
FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master` t
LEFT JOIN `lululemon-01042025.lulu_ingestion_dev.store_master` s
  ON t.store_code = s.store_code
WHERE t.store_code IS NOT NULL
  AND s.store_code IS NULL;

-- X3: Inventory product_code not in product_master (strict suffixed join)
-- Orphans are expected when inv suffix is FO/STRAT/COMMUNITY/CMNTY; PM only has RETAIL/ECOMM.
SELECT
  'X3_inv_product_orphan_strict' AS check_id,
  COUNT(DISTINCT i.product_code) AS orphan_distinct_product_codes,
  COUNT(*) AS orphan_inv_rows
FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master` i
LEFT JOIN `lululemon-01042025.lulu_ingestion_dev.product_master` p
  ON i.product_code = p.product_code
WHERE i.product_code IS NOT NULL
  AND p.product_code IS NULL;

-- X3b: Orphan SKUs whose bare SKU is missing from product_master (true gaps; expect 0)
WITH orphan_skus AS (
  SELECT DISTINCT
    i.product_code,
    SPLIT(i.product_code, '_')[OFFSET(0)] AS bare_sku
  FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master` i
  LEFT JOIN `lululemon-01042025.lulu_ingestion_dev.product_master` p
    ON i.product_code = p.product_code
  WHERE i.product_code IS NOT NULL
    AND p.product_code IS NULL
)
SELECT
  'X3b_inv_bare_sku_missing_from_pm' AS check_id,
  COUNT(*) AS orphan_skus_with_no_pm_bare_sku
FROM orphan_skus o
WHERE NOT EXISTS (
  SELECT 1
  FROM `lululemon-01042025.lulu_ingestion_dev.product_master` p
  WHERE p.product_code_original = o.bare_sku
);

-- X3c: Strict orphan rows by inventory product_code suffix (diagnostic)
WITH orphan_inv AS (
  SELECT
    i.*,
    SPLIT(i.product_code, '_')[OFFSET(ARRAY_LENGTH(SPLIT(i.product_code, '_')) - 1)] AS inv_suffix
  FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master` i
  LEFT JOIN `lululemon-01042025.lulu_ingestion_dev.product_master` p
    ON i.product_code = p.product_code
  WHERE i.product_code IS NOT NULL
    AND p.product_code IS NULL
)
SELECT
  'X3c_inv_orphan_by_suffix' AS check_id,
  inv_suffix,
  COUNT(*) AS row_count,
  COUNT(DISTINCT product_code) AS sku_count,
  SUM(CASE WHEN oh > 0 THEN 1 ELSE 0 END) AS rows_positive_oh
FROM orphan_inv
GROUP BY inv_suffix
ORDER BY row_count DESC;

-- X4: Inventory store_code not in store_master
SELECT
  'X4_inv_store_orphan' AS check_id,
  COUNT(DISTINCT i.store_code) AS orphan_distinct_store_codes,
  COUNT(*) AS orphan_inv_rows
FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master` i
LEFT JOIN `lululemon-01042025.lulu_ingestion_dev.store_master` s
  ON i.store_code = s.store_code
WHERE i.store_code IS NOT NULL
  AND s.store_code IS NULL;

-- X5: Product_master SKUs never in transaction_master (real sales)
WITH txn_products AS (
  SELECT DISTINCT product_code
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`
  WHERE product_code IS NOT NULL
    AND qty > 0
    AND revenue > 0
)
SELECT
  'X5_pm_never_sold' AS check_id,
  COUNT(*) AS pm_rows_never_sold,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`), 2) AS pct_of_pm
FROM `lululemon-01042025.lulu_ingestion_dev.product_master` p
LEFT JOIN txn_products t USING (product_code)
WHERE t.product_code IS NULL;

-- X6: Channel naming — txn vs product l1_name for sold SKUs
WITH txn_ch AS (
  SELECT product_code, APPROX_TOP_COUNT(channel, 1)[OFFSET(0)].value AS txn_channel
  FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`
  WHERE qty > 0 AND revenue > 0
  GROUP BY product_code
)
SELECT
  p.l1_name AS pm_channel,
  t.txn_channel,
  COUNT(*) AS sku_count
FROM `lululemon-01042025.lulu_ingestion_dev.product_master` p
JOIN txn_ch t USING (product_code)
GROUP BY ALL
ORDER BY sku_count DESC;

-- X7: Reference counts (denominator context)
SELECT
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.product_master`) AS product_master_rows,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.store_master`) AS store_master_rows,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.transaction_master`) AS transaction_master_rows,
  (SELECT COUNT(*) FROM `lululemon-01042025.lulu_ingestion_dev.inventory_master`) AS inventory_master_rows;
