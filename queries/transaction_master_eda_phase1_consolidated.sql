-- =============================================================================
-- Transaction Master EDA - Phase 1 CONSOLIDATED
-- Single query, 9 rows out (one per Q), JSON-encoded results.
--
-- Table: lululemon-01042025.lululemon_souricng_outbound.transaction_master
--        (389M rows, 73 GB)
--
-- Cost awareness: table is ~73GB. This query touches it ~3-5 times.
-- Estimated on-demand cost: ~$2.
-- =============================================================================

WITH

-- ========== Q1: Row counts + distinct IDs + channel/geography ==========
q1 AS (
  SELECT
    'Q1' AS query_id,
    'Row counts + distinct IDs + channel/geography split' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      APPROX_COUNT_DISTINCT(transaction_code) AS distinct_transaction_code,
      APPROX_COUNT_DISTINCT(product_code) AS distinct_product_code,
      APPROX_COUNT_DISTINCT(store_code) AS distinct_store_code,
      APPROX_COUNT_DISTINCT(date) AS distinct_dates,
      COUNTIF(channel = 'ECOMM') AS ecomm_rows,
      COUNTIF(channel = 'RETAIL') AS retail_rows,
      COUNTIF(channel IS NULL OR channel NOT IN ('ECOMM', 'RETAIL')) AS other_channel_rows,
      APPROX_COUNT_DISTINCT(channel) AS distinct_channel_values,
      APPROX_COUNT_DISTINCT(channel_code) AS distinct_channel_code_values,
      APPROX_COUNT_DISTINCT(ws_channel) AS distinct_ws_channel_values,
      APPROX_COUNT_DISTINCT(geography) AS distinct_geography_values,
      APPROX_COUNT_DISTINCT(ecomm_country) AS distinct_ecomm_country_values,
      APPROX_COUNT_DISTINCT(brand) AS distinct_brand_values
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
),

-- ========== Q2: Null counts per column (all 32) ==========
q2 AS (
  SELECT
    'Q2' AS query_id,
    'Null counts per column (type-aware)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      -- STRING columns (NULL / '' / '\N')
      COUNTIF(channel IS NULL OR channel = '' OR channel = '\\N') AS null_channel,
      COUNTIF(brand IS NULL OR brand = '' OR brand = '\\N') AS null_brand,
      COUNTIF(store_code IS NULL OR store_code = '' OR store_code = '\\N') AS null_store_code,
      COUNTIF(transaction_code IS NULL OR transaction_code = '' OR transaction_code = '\\N') AS null_transaction_code,
      COUNTIF(channel_code IS NULL OR channel_code = '' OR channel_code = '\\N') AS null_channel_code,
      COUNTIF(product_code IS NULL OR product_code = '' OR product_code = '\\N') AS null_product_code,
      COUNTIF(ws_channel IS NULL OR ws_channel = '' OR ws_channel = '\\N') AS null_ws_channel,
      COUNTIF(geography IS NULL OR geography = '' OR geography = '\\N') AS null_geography,
      COUNTIF(ecomm_country IS NULL OR ecomm_country = '' OR ecomm_country = '\\N') AS null_ecomm_country,
      -- DATE
      COUNTIF(date IS NULL) AS null_date,
      -- INT64 columns (IS NULL only)
      COUNTIF(line_id IS NULL) AS null_line_id,
      COUNTIF(launch_price IS NULL) AS null_launch_price,
      COUNTIF(clearance IS NULL) AS null_clearance,
      COUNTIF(unit_discount_amount IS NULL) AS null_unit_discount_amount,
      COUNTIF(total_discount_amount IS NULL) AS null_total_discount_amount,
      COUNTIF(qty IS NULL) AS null_qty,
      COUNTIF(transaction_type IS NULL) AS null_transaction_type,
      COUNTIF(fullfilment_location_customer IS NULL) AS null_fullfilment_location_customer,
      COUNTIF(flagged_rows IS NULL) AS null_flagged_rows,
      COUNTIF(revenue_before_tax IS NULL) AS null_revenue_before_tax,
      COUNTIF(ship_to_country IS NULL) AS null_ship_to_country,
      COUNTIF(freight_cost IS NULL) AS null_freight_cost,
      COUNTIF(clearance_price IS NULL) AS null_clearance_price,
      COUNTIF(store_contribution IS NULL) AS null_store_contribution,
      COUNTIF(workstream IS NULL) AS null_workstream,
      COUNTIF(currency_exchange_rate IS NULL) AS null_currency_exchange_rate,
      COUNTIF(order_type IS NULL) AS null_order_type,
      COUNTIF(transaction_category IS NULL) AS null_transaction_category,
      -- FLOAT64 columns
      COUNTIF(revenue IS NULL) AS null_revenue,
      COUNTIF(cost IS NULL) AS null_cost,
      COUNTIF(msrp IS NULL) AS null_msrp,
      COUNTIF(price IS NULL) AS null_price
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
),

-- ========== Q3: Duplicates at transaction_code level (top 20) ==========
q3_dups AS (
  SELECT transaction_code, COUNT(*) AS dup_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  WHERE transaction_code IS NOT NULL
  GROUP BY transaction_code
  HAVING COUNT(*) > 1
  ORDER BY dup_count DESC
  LIMIT 20
),
q3_summary AS (
  SELECT
    COUNT(DISTINCT transaction_code) AS distinct_transaction_codes,
    COUNTIF(cnt > 1) AS transaction_codes_with_duplicates,
    SUM(CASE WHEN cnt > 1 THEN cnt ELSE 0 END) AS total_duplicate_rows,
    MAX(cnt) AS max_duplicates_for_any_code
  FROM (
    SELECT transaction_code, COUNT(*) AS cnt
    FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
    WHERE transaction_code IS NOT NULL
    GROUP BY transaction_code
  )
),
q3 AS (
  SELECT
    'Q3' AS query_id,
    'Duplicates at transaction_code level' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT AS STRUCT * FROM q3_summary) AS summary,
      (SELECT ARRAY_AGG(STRUCT(transaction_code, dup_count)) FROM q3_dups) AS top_20_duplicates
    )) AS results_json
),

-- ========== Q4: Grain test (PK candidates) ==========
q4_rows AS (
  SELECT 'transaction_code only' AS grain_test,
         COUNT(*) AS total_rows,
         COUNT(DISTINCT transaction_code) AS distinct_vals,
         COUNT(*) - COUNT(DISTINCT transaction_code) AS duplicate_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  UNION ALL
  SELECT 'transaction_code + product_code',
         COUNT(*),
         COUNT(DISTINCT CONCAT(COALESCE(transaction_code, ''), '|', COALESCE(product_code, ''))),
         COUNT(*) - COUNT(DISTINCT CONCAT(COALESCE(transaction_code, ''), '|', COALESCE(product_code, '')))
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  UNION ALL
  SELECT 'transaction_code + product_code + line_id',
         COUNT(*),
         COUNT(DISTINCT CONCAT(COALESCE(transaction_code, ''), '|', COALESCE(product_code, ''), '|', COALESCE(CAST(line_id AS STRING), ''))),
         COUNT(*) - COUNT(DISTINCT CONCAT(COALESCE(transaction_code, ''), '|', COALESCE(product_code, ''), '|', COALESCE(CAST(line_id AS STRING), '')))
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  UNION ALL
  SELECT 'date + product_code + store_code + channel',
         COUNT(*),
         COUNT(DISTINCT CONCAT(CAST(date AS STRING), '|', COALESCE(product_code, ''), '|', COALESCE(store_code, ''), '|', COALESCE(channel, ''))),
         COUNT(*) - COUNT(DISTINCT CONCAT(CAST(date AS STRING), '|', COALESCE(product_code, ''), '|', COALESCE(store_code, ''), '|', COALESCE(channel, '')))
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
),
q4 AS (
  SELECT
    'Q4' AS query_id,
    'Grain test (PK candidates)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(grain_test, total_rows, distinct_vals, duplicate_count))) AS results_json
  FROM q4_rows
),

-- ========== Q5: Date range + yearly distribution ==========
q5_yearly AS (
  SELECT
    EXTRACT(YEAR FROM date) AS year,
    COUNT(*) AS row_count,
    COUNT(DISTINCT date) AS distinct_dates
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  WHERE date IS NOT NULL
  GROUP BY year
  ORDER BY year
),
q5_summary AS (
  SELECT
    MIN(date) AS min_date,
    MAX(date) AS max_date,
    COUNT(DISTINCT date) AS distinct_dates,
    COUNTIF(date IS NULL) AS null_date_rows,
    DATE_DIFF(MAX(date), MIN(date), DAY) + 1 AS date_span_days
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
),
q5 AS (
  SELECT
    'Q5' AS query_id,
    'Date range + yearly distribution' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT AS STRUCT * FROM q5_summary) AS summary,
      (SELECT ARRAY_AGG(STRUCT(year, row_count, distinct_dates) ORDER BY year) FROM q5_yearly) AS yearly
    )) AS results_json
),

-- ========== Q6: Qty sanity ==========
q6 AS (
  SELECT
    'Q6' AS query_id,
    'Qty distribution + negative/zero checks' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNTIF(qty IS NULL) AS null_qty,
      COUNTIF(qty = 0) AS zero_qty,
      COUNTIF(qty > 0) AS positive_qty,
      COUNTIF(qty < 0) AS negative_qty_returns,
      COUNTIF(qty = 1) AS qty_eq_1,
      COUNTIF(qty > 1) AS qty_gt_1,
      MIN(qty) AS min_qty,
      MAX(qty) AS max_qty,
      APPROX_QUANTILES(qty, 10) AS qty_deciles
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
),

-- ========== Q7: Price / revenue / discount sanity (Signet SOP checks) ==========
q7 AS (
  SELECT
    'Q7' AS query_id,
    'Price/revenue/discount sanity (Signet SOP)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      -- price/revenue zeros / nulls
      COUNTIF(price IS NULL) AS null_price,
      COUNTIF(price = 0) AS zero_price,
      COUNTIF(price < 0) AS negative_price,
      COUNTIF(revenue IS NULL) AS null_revenue,
      COUNTIF(revenue = 0) AS zero_revenue,
      COUNTIF(revenue < 0) AS negative_revenue,
      -- SOP flag: qty > 0 but price / revenue = 0
      COUNTIF(qty > 0 AND (price IS NULL OR price = 0)) AS qty_positive_but_price_zero_or_null,
      COUNTIF(qty > 0 AND (revenue IS NULL OR revenue = 0)) AS qty_positive_but_revenue_zero_or_null,
      COUNTIF(qty < 0 AND revenue > 0) AS qty_negative_but_revenue_positive,
      -- discount sanity
      COUNTIF(unit_discount_amount > 0 AND qty > 0) AS discount_positive_with_qty_positive,
      COUNTIF(total_discount_amount < 0) AS negative_total_discount,
      -- cost vs price (negative margin)
      COUNTIF(cost IS NOT NULL AND price IS NOT NULL AND cost > price AND qty > 0) AS cost_greater_than_price,
      COUNTIF(cost = 0) AS zero_cost_rows,
      COUNTIF(msrp = 0) AS zero_msrp_rows,
      -- price ranges
      MIN(price) AS min_price,
      MAX(price) AS max_price,
      MIN(revenue) AS min_revenue,
      MAX(revenue) AS max_revenue,
      APPROX_QUANTILES(price, 10) AS price_deciles,
      APPROX_QUANTILES(revenue, 10) AS revenue_deciles
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
),

-- ========== Q8: Categorical distributions (top values per attribute) ==========
q8_channel AS (
  SELECT 'channel' AS attribute, COALESCE(channel, '<NULL>') AS value, COUNT(*) AS row_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY channel
),
q8_geography AS (
  SELECT 'geography', COALESCE(geography, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY geography
),
q8_channel_code AS (
  SELECT 'channel_code', COALESCE(channel_code, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY channel_code
),
q8_ws_channel AS (
  SELECT 'ws_channel', COALESCE(ws_channel, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY ws_channel
),
q8_ecomm_country AS (
  SELECT 'ecomm_country', COALESCE(ecomm_country, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY ecomm_country
),
q8_brand AS (
  SELECT 'brand', COALESCE(brand, '<NULL>'), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY brand
),
q8_clearance AS (
  SELECT 'clearance', CAST(clearance AS STRING), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY clearance
),
q8_flagged AS (
  SELECT 'flagged_rows', CAST(flagged_rows AS STRING), COUNT(*)
  FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
  GROUP BY flagged_rows
),
q8_all AS (
  SELECT * FROM q8_channel
  UNION ALL SELECT * FROM q8_geography
  UNION ALL SELECT * FROM q8_channel_code
  UNION ALL SELECT * FROM q8_ws_channel
  UNION ALL SELECT * FROM q8_ecomm_country
  UNION ALL SELECT * FROM q8_brand
  UNION ALL SELECT * FROM q8_clearance
  UNION ALL SELECT * FROM q8_flagged
),
q8_ranked AS (
  SELECT attribute, value, row_count,
         ROW_NUMBER() OVER (PARTITION BY attribute ORDER BY row_count DESC) AS rnk
  FROM q8_all
),
q8 AS (
  SELECT
    'Q8' AS query_id,
    'Categorical distributions (top 15 per attribute)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(attribute, value, row_count) ORDER BY attribute, row_count DESC)) AS results_json
  FROM q8_ranked
  WHERE rnk <= 15
),

-- Q9 was "compare vs sales_transactions_4y_cleaned_20251119" but that table
-- has a different schema (no `date` column). Run the schema probe below
-- SEPARATELY first, then we'll add a proper comparison query once we know
-- the column names.

-- ========== Final union ==========
SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
UNION ALL SELECT * FROM q5
UNION ALL SELECT * FROM q6
UNION ALL SELECT * FROM q7
UNION ALL SELECT * FROM q8
ORDER BY query_id;


-- =============================================================================
-- BONUS: Schema probe for the other transaction tables
-- Run this SEPARATELY (its own query). Tiny cost (metadata only).
-- Output will tell us whether transaction_master / sales_transactions_4y_cleaned /
-- sales_transactions_20251119 share the same columns or differ.
-- =============================================================================
/*
SELECT
  table_name,
  column_name,
  data_type,
  ordinal_position
FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN (
  'transaction_master',
  'sales_transactions_4y_cleaned_20251119',
  'sales_transactions_20251119'
)
ORDER BY table_name, ordinal_position;
*/

