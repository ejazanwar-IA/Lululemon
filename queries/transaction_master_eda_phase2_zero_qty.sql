-- =============================================================================
-- Transaction Master - Phase 2: Zero-Qty Mystery Investigation
--
-- Goal: Characterize the 105.9M rows where qty=0 so we can hypothesize what
-- they are (staff purchases? cancelled? comp items? adjustments?).
--
-- One consolidated query. ~1 full-table scan of 73 GB. Est cost ~$0.37.
-- Table: lululemon-01042025.lululemon_souricng_outbound.transaction_master
-- =============================================================================

WITH

-- ========== D1: Zero-qty concentration by channel_code ==========
d1_rows AS (
  SELECT
    channel_code,
    COUNT(*) AS total_rows,
    COUNTIF(qty = 0) AS zero_qty_rows,
    ROUND(100.0 * COUNTIF(qty = 0) / COUNT(*), 2) AS pct_zero_qty
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY channel_code
),
d1 AS (
  SELECT
    'D1' AS query_id,
    'Zero-qty concentration by channel_code' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(channel_code, total_rows, zero_qty_rows, pct_zero_qty) ORDER BY zero_qty_rows DESC)) AS results_json
  FROM d1_rows
),

-- ========== D2: Zero-qty trend by year ==========
d2_rows AS (
  SELECT
    EXTRACT(YEAR FROM date) AS year,
    COUNT(*) AS total_rows,
    COUNTIF(qty = 0) AS zero_qty_rows,
    ROUND(100.0 * COUNTIF(qty = 0) / COUNT(*), 2) AS pct_zero_qty
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY year
  ORDER BY year
),
d2 AS (
  SELECT
    'D2' AS query_id,
    'Zero-qty trend by year' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(year, total_rows, zero_qty_rows, pct_zero_qty) ORDER BY year)) AS results_json
  FROM d2_rows
),

-- ========== D3: Zero-qty ↔ zero-price ↔ zero-revenue overlap ==========
-- Are the 106M zero rows the SAME 106M rows across qty/price/revenue?
d3 AS (
  SELECT
    'D3' AS query_id,
    'Zero-qty <-> zero-price <-> zero-revenue overlap' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(qty = 0) AS zero_qty,
      COUNTIF(price = 0) AS zero_price,
      COUNTIF(revenue = 0) AS zero_revenue,
      -- All three zero together
      COUNTIF(qty = 0 AND price = 0 AND revenue = 0) AS all_three_zero,
      -- Just qty zero but price/revenue non-zero
      COUNTIF(qty = 0 AND (price != 0 OR revenue != 0)) AS qty_zero_but_price_or_rev_nonzero,
      -- Just price zero but qty/revenue non-zero (free items)
      COUNTIF(price = 0 AND qty != 0) AS price_zero_but_qty_nonzero,
      -- Combinations table
      COUNTIF(qty = 0 AND price = 0 AND revenue = 0) AS cat_all_zero,
      COUNTIF(qty > 0 AND price > 0 AND revenue > 0) AS cat_all_positive,
      COUNTIF(qty > 0 AND price = 0 AND revenue = 0) AS cat_qty_only_positive,
      COUNTIF(qty = 0 AND price > 0 AND revenue > 0) AS cat_no_qty_but_money,
      COUNTIF(qty = 0 AND price > 0 AND revenue = 0) AS cat_weird_price_only,
      COUNTIF(qty = 0 AND price = 0 AND revenue > 0) AS cat_weird_rev_only
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
),

-- ========== D4: Zero-qty distribution by brand ==========
-- Is zero-qty concentrated in ivivva (deprecated brand)?
d4_rows AS (
  SELECT
    brand,
    COUNT(*) AS total_rows,
    COUNTIF(qty = 0) AS zero_qty_rows,
    ROUND(100.0 * COUNTIF(qty = 0) / COUNT(*), 2) AS pct_zero_qty
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY brand
),
d4 AS (
  SELECT
    'D4' AS query_id,
    'Zero-qty by brand' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(brand, total_rows, zero_qty_rows, pct_zero_qty))) AS results_json
  FROM d4_rows
),

-- ========== D5: Top 20 products with highest zero-qty count ==========
-- If specific SKUs are always zero, they might be system placeholders / gift cards
d5_rows AS (
  SELECT
    product_code,
    COUNT(*) AS total_rows,
    COUNTIF(qty = 0) AS zero_qty_rows,
    ROUND(100.0 * COUNTIF(qty = 0) / COUNT(*), 2) AS pct_zero_qty
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY product_code
  HAVING COUNTIF(qty = 0) > 0
  ORDER BY zero_qty_rows DESC
  LIMIT 20
),
d5 AS (
  SELECT
    'D5' AS query_id,
    'Top 20 product_codes by zero-qty count' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(product_code, total_rows, zero_qty_rows, pct_zero_qty))) AS results_json
  FROM d5_rows
),

-- ========== D6: Top 20 stores with highest zero-qty count ==========
d6_rows AS (
  SELECT
    store_code,
    COUNT(*) AS total_rows,
    COUNTIF(qty = 0) AS zero_qty_rows,
    ROUND(100.0 * COUNTIF(qty = 0) / COUNT(*), 2) AS pct_zero_qty
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY store_code
  HAVING COUNTIF(qty = 0) > 0
  ORDER BY zero_qty_rows DESC
  LIMIT 20
),
d6 AS (
  SELECT
    'D6' AS query_id,
    'Top 20 store_codes by zero-qty count' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(store_code, total_rows, zero_qty_rows, pct_zero_qty))) AS results_json
  FROM d6_rows
),

-- ========== D7: Sample 20 actual rows from zero-qty set ==========
-- Raw samples so we can eyeball what's happening
d7_rows AS (
  SELECT
    channel_code,
    date,
    store_code,
    product_code,
    qty,
    price,
    revenue,
    unit_discount_amount,
    total_discount_amount,
    clearance,
    transaction_code
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  WHERE qty = 0
  LIMIT 20
),
d7 AS (
  SELECT
    'D7' AS query_id,
    'Sample 20 rows where qty = 0' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(channel_code, date, store_code, product_code, qty, price, revenue, unit_discount_amount, total_discount_amount, clearance, transaction_code))) AS results_json
  FROM d7_rows
)

SELECT * FROM d1
UNION ALL SELECT * FROM d2
UNION ALL SELECT * FROM d3
UNION ALL SELECT * FROM d4
UNION ALL SELECT * FROM d5
UNION ALL SELECT * FROM d6
UNION ALL SELECT * FROM d7
ORDER BY query_id;
