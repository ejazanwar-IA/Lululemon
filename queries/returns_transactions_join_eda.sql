-- =============================================================================
-- Returns transactions: EDA + join feasibility vs sales_transactions
--
-- Project:  lululemon-01042025
-- Returns:  lululemon_souricng_outbound.returns_transactions_20251119 (Nov POC)
-- Sales:    lulu_sourcing_dev.sales_transactions (GCS extraction, May 2026 load)
--
-- Run sections independently in BigQuery console.
-- Job project: use --project_id=lululemon-data-scan (lululemon-01042025 lacks jobs.create for this account).
-- Last updated: 2026-06-24
-- =============================================================================

-- =============================================================================
-- RTN.1: Returns foundation (row count, dates, zeros, order-id pattern)
-- =============================================================================

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT SKU_ID) AS distinct_skus,
  COUNT(DISTINCT LOCATION_ID_SALES) AS distinct_locations,
  MIN(DATE_TRANSACTION) AS min_date,
  MAX(DATE_TRANSACTION) AS max_date,
  COUNT(DISTINCT DATE_TRANSACTION) AS distinct_dates
FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`;


-- RTN.2: Zero / sign distribution (returns)

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(UNITS = 0) AS units_zero,
  COUNTIF(UNITS > 0) AS units_positive,
  COUNTIF(UNITS < 0) AS units_negative,
  COUNTIF(PRICE_SALES_TOTAL = 0) AS price_zero,
  COUNTIF(PRICE_SALES_TOTAL != 0) AS price_nonzero,
  ROUND(100 * COUNTIF(UNITS = 0) / COUNT(*), 2) AS pct_units_zero,
  ROUND(100 * COUNTIF(UNITS > 0) / COUNT(*), 2) AS pct_units_positive
FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`;


-- RTN.3: Order ID pattern (RETURNS suffix)

SELECT
  COUNTIF(SALES_ORDER_ID LIKE '%|RETURNS') AS order_id_returns_suffix,
  COUNTIF(SALES_ORDER_ID = SALES_ORDER_ITEM_ID) AS order_equals_item,
  COUNT(*) AS total_rows,
  ROUND(100 * COUNTIF(SALES_ORDER_ID LIKE '%|RETURNS') / COUNT(*), 4) AS pct_returns_suffix
FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`;


-- RTN.4: Synthetic key check (returns): DATE|SKU|STORE|RETURNS

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(
    SALES_ORDER_ID = CONCAT(
      CAST(DATE_TRANSACTION AS STRING), '|',
      CAST(SKU_ID AS STRING), '|',
      CAST(LOCATION_ID_SALES AS STRING), '|RETURNS'
    )
  ) AS synthetic_match,
  COUNTIF(
    SALES_ORDER_ID != CONCAT(
      CAST(DATE_TRANSACTION AS STRING), '|',
      CAST(SKU_ID AS STRING), '|',
      CAST(LOCATION_ID_SALES AS STRING), '|RETURNS'
    )
  ) AS non_match
FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`;


-- RTN.5: Grain duplication on (SKU, LOC, DATE, ORDER_ID, ITEM_ID)

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT CONCAT(
    CAST(SKU_ID AS STRING), '|',
    CAST(LOCATION_ID_SALES AS STRING), '|',
    CAST(DATE_TRANSACTION AS STRING), '|',
    SALES_ORDER_ID, '|',
    SALES_ORDER_ITEM_ID
  )) AS distinct_line_keys,
  ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT CONCAT(
    CAST(SKU_ID AS STRING), '|',
    CAST(LOCATION_ID_SALES AS STRING), '|',
    CAST(DATE_TRANSACTION AS STRING), '|',
    SALES_ORDER_ID, '|',
    SALES_ORDER_ITEM_ID
  )), 0), 4) AS dup_ratio
FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`;


-- =============================================================================
-- RTN.6: Sales vs returns date overlap (by year)
-- =============================================================================

WITH sales AS (
  SELECT
    EXTRACT(YEAR FROM SAFE_CAST(DATE_TRANSACTION AS DATE)) AS yr,
    COUNT(*) AS sales_rows,
    COUNTIF(SAFE_CAST(UNITS AS FLOAT64) > 0) AS sales_units_pos
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
  GROUP BY 1
),
returns AS (
  SELECT
    EXTRACT(YEAR FROM DATE_TRANSACTION) AS yr,
    COUNT(*) AS return_rows,
    COUNTIF(UNITS > 0) AS return_units_pos
  FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`
  GROUP BY 1
)
SELECT
  COALESCE(s.yr, r.yr) AS yr,
  s.sales_rows,
  s.sales_units_pos,
  r.return_rows,
  r.return_units_pos
FROM sales s
FULL OUTER JOIN returns r ON s.yr = r.yr
ORDER BY yr;


-- =============================================================================
-- RTN.7: Join overlap (2023 sample year): normalized order-id match
-- Returns order_id = DATE|SKU|STORE|RETURNS  →  strip suffix for sales join
-- Sales order_id   = DATE|SKU|STORE
-- =============================================================================

WITH returns_2023 AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    DATE_TRANSACTION AS date_transaction,
    SALES_ORDER_ID,
    REGEXP_REPLACE(SALES_ORDER_ID, r'\|RETURNS$', '') AS order_id_normalized,
    UNITS,
    PRICE_SALES_TOTAL
  FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`
  WHERE EXTRACT(YEAR FROM DATE_TRANSACTION) = 2023
),
sales_2023 AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    SAFE_CAST(DATE_TRANSACTION AS DATE) AS date_transaction,
    SALES_ORDER_ID,
    SAFE_CAST(UNITS AS FLOAT64) AS units,
    SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64) AS price_sales_total
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
  WHERE EXTRACT(YEAR FROM SAFE_CAST(DATE_TRANSACTION AS DATE)) = 2023
),
return_keys AS (
  SELECT DISTINCT order_id_normalized FROM returns_2023 WHERE order_id_normalized IS NOT NULL
),
sales_keys AS (
  SELECT DISTINCT SALES_ORDER_ID FROM sales_2023 WHERE SALES_ORDER_ID IS NOT NULL
),
line_overlap AS (
  SELECT
    r.sku_id,
    r.location_id_sales,
    r.date_transaction,
    r.order_id_normalized
  FROM returns_2023 r
  INNER JOIN sales_2023 s
    ON r.order_id_normalized = s.SALES_ORDER_ID
)
SELECT
  (SELECT COUNT(*) FROM returns_2023) AS return_rows_2023,
  (SELECT COUNT(*) FROM sales_2023) AS sales_rows_2023,
  (SELECT COUNT(*) FROM return_keys) AS distinct_return_order_ids,
  (SELECT COUNT(*) FROM sales_keys) AS distinct_sales_order_ids,
  (SELECT COUNT(*) FROM return_keys rk INNER JOIN sales_keys sk ON rk.order_id_normalized = sk.SALES_ORDER_ID) AS overlapping_order_ids,
  (SELECT COUNT(*) FROM line_overlap) AS overlapping_return_rows_on_order_id;


-- =============================================================================
-- RTN.8: SKU × Store × Day overlap (2023): lines with units > 0 only
-- =============================================================================

WITH returns_pos AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    DATE_TRANSACTION AS date_transaction,
    SUM(UNITS) AS return_units,
    SUM(PRICE_SALES_TOTAL) AS return_revenue
  FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`
  WHERE EXTRACT(YEAR FROM DATE_TRANSACTION) = 2023
    AND UNITS > 0
  GROUP BY 1, 2, 3
),
sales_pos AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    SAFE_CAST(DATE_TRANSACTION AS DATE) AS date_transaction,
    SUM(SAFE_CAST(UNITS AS FLOAT64)) AS sales_units,
    SUM(SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64)) AS sales_revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
  WHERE EXTRACT(YEAR FROM SAFE_CAST(DATE_TRANSACTION AS DATE)) = 2023
    AND SAFE_CAST(UNITS AS FLOAT64) > 0
  GROUP BY 1, 2, 3
)
SELECT
  (SELECT COUNT(*) FROM returns_pos) AS return_ssd_keys_pos,
  (SELECT COUNT(*) FROM sales_pos) AS sales_ssd_keys_pos,
  (SELECT COUNT(*)
   FROM returns_pos r
   INNER JOIN sales_pos s USING (sku_id, location_id_sales, date_transaction)
  ) AS ssd_keys_in_both,
  (SELECT COUNT(*) FROM returns_pos r
   LEFT JOIN sales_pos s USING (sku_id, location_id_sales, date_transaction)
   WHERE s.sku_id IS NULL
  ) AS return_only_ssd_keys,
  (SELECT COUNT(*) FROM sales_pos s
   LEFT JOIN returns_pos r USING (sku_id, location_id_sales, date_transaction)
   WHERE r.sku_id IS NULL
  ) AS sales_only_ssd_keys;


-- =============================================================================
-- RTN.9: Net vs gross reconciliation (2023 to 2025), SKU × Store × Day, units>0
-- =============================================================================

WITH sales_agg AS (
  SELECT
    EXTRACT(YEAR FROM SAFE_CAST(DATE_TRANSACTION AS DATE)) AS yr,
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    SAFE_CAST(DATE_TRANSACTION AS DATE) AS date_transaction,
    SUM(SAFE_CAST(UNITS AS FLOAT64)) AS gross_units,
    SUM(SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64)) AS gross_revenue
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
  WHERE EXTRACT(YEAR FROM SAFE_CAST(DATE_TRANSACTION AS DATE)) BETWEEN 2023 AND 2025
    AND SAFE_CAST(UNITS AS FLOAT64) > 0
  GROUP BY 1, 2, 3, 4
),
returns_agg AS (
  SELECT
    EXTRACT(YEAR FROM DATE_TRANSACTION) AS yr,
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    DATE_TRANSACTION AS date_transaction,
    SUM(UNITS) AS return_units,
    SUM(PRICE_SALES_TOTAL) AS return_revenue
  FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`
  WHERE EXTRACT(YEAR FROM DATE_TRANSACTION) BETWEEN 2023 AND 2025
    AND UNITS > 0
  GROUP BY 1, 2, 3, 4
),
combined AS (
  SELECT
    COALESCE(s.yr, r.yr) AS yr,
    COALESCE(s.sku_id, r.sku_id) AS sku_id,
    COALESCE(s.location_id_sales, r.location_id_sales) AS location_id_sales,
    COALESCE(s.date_transaction, r.date_transaction) AS date_transaction,
    IFNULL(s.gross_units, 0) AS gross_units,
    IFNULL(r.return_units, 0) AS return_units,
    IFNULL(s.gross_revenue, 0) AS gross_revenue,
    IFNULL(r.return_revenue, 0) AS return_revenue
  FROM sales_agg s
  FULL OUTER JOIN returns_agg r
    ON s.sku_id = r.sku_id
   AND s.location_id_sales = r.location_id_sales
   AND s.date_transaction = r.date_transaction
)
SELECT
  yr,
  COUNT(*) AS ssd_keys,
  SUM(gross_units) AS total_gross_units,
  SUM(return_units) AS total_return_units,
  SUM(gross_units) - SUM(return_units) AS net_units,
  ROUND(100 * SUM(return_units) / NULLIF(SUM(gross_units), 0), 2) AS return_rate_pct_units,
  SUM(gross_revenue) AS total_gross_revenue,
  SUM(return_revenue) AS total_return_revenue,
  SUM(gross_revenue) - SUM(return_revenue) AS net_revenue,
  ROUND(100 * SUM(return_revenue) / NULLIF(SUM(gross_revenue), 0), 2) AS return_rate_pct_revenue,
  COUNTIF(return_units > 0 AND gross_units > 0) AS keys_with_both,
  COUNTIF(return_units > 0 AND gross_units = 0) AS return_only_keys,
  COUNTIF(return_units = 0 AND gross_units > 0) AS sales_only_keys
FROM combined
GROUP BY yr
ORDER BY yr;


-- =============================================================================
-- RTN.10: Union prototype row counts (2024 sample, pos units only)
-- =============================================================================

WITH sales_u AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    SAFE_CAST(DATE_TRANSACTION AS DATE) AS date_transaction,
    SALES_ORDER_ID,
    SAFE_CAST(UNITS AS FLOAT64) AS units,
    SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64) AS price_sales_total,
    'SALE' AS txn_source
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
  WHERE EXTRACT(YEAR FROM SAFE_CAST(DATE_TRANSACTION AS DATE)) = 2024
    AND SAFE_CAST(UNITS AS FLOAT64) > 0
),
returns_u AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    DATE_TRANSACTION AS date_transaction,
    SALES_ORDER_ID,
    CAST(UNITS AS FLOAT64) AS units,
    PRICE_SALES_TOTAL AS price_sales_total,
    'RETURN' AS txn_source
  FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`
  WHERE EXTRACT(YEAR FROM DATE_TRANSACTION) = 2024
    AND UNITS > 0
),
unioned AS (
  SELECT * FROM sales_u
  UNION ALL
  SELECT * FROM returns_u
)
SELECT
  txn_source,
  COUNT(*) AS line_rows,
  SUM(units) AS total_units,
  SUM(price_sales_total) AS total_revenue
FROM unioned
GROUP BY txn_source
ORDER BY txn_source;
