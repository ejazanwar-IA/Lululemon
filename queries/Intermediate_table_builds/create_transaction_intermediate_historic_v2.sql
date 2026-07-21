-- Lululemon historic transaction intermediate build, v2.
--
-- Business-date window: 2 full prior years plus current year-to-date.
-- MSRP and clearance/discount fields come from price_book; cost stays on sku_details (zero until client feed).
-- Still blocked: line_id, launch_price, revenue_before_tax, fullfilment_location_customer, freight_cost,
-- store_contribution, workstream, currency_exchange_rate, transaction_category.

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate`
PARTITION BY date
CLUSTER BY channel AS
WITH
-- Cast raw sales_transactions strings to typed fields and apply the business-date window.
typed_transactions AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    SAFE_CAST(DATE_TRANSACTION AS DATE) AS transaction_date,
    DATE_TRANSACTION,
    SALES_ORDER_ID,
    SALES_ORDER_ITEM_ID,
    SAFE_CAST(UNITS AS INT64) AS units,
    CURRENCY_CODE,
    PRICE_SALES_TOTAL,
    PRICE_SALES_UNIT,
    SALES_SERVICE_TYPE,
    TRANSACTION_TYPE
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
  WHERE SAFE_CAST(DATE_TRANSACTION AS DATE) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
    AND SKU_ID IS NOT NULL
    AND SKU_ID != ''
    AND LOCATION_ID_SALES IS NOT NULL
    AND LOCATION_ID_SALES != ''
    AND SALES_ORDER_ID IS NOT NULL
    AND SALES_ORDER_ID != ''
    AND SAFE_CAST(DATE_TRANSACTION AS DATE) IS NOT NULL
),
-- Attach store channel once and derive the downstream product_code key.
txn_enriched AS (
  SELECT
    t.*,
    sm.channel AS store_channel,
    CONCAT(t.sku_id, '_', sm.channel) AS sku_id_channel,
    sm.s1_name,
    sm.channel_code,
    sm.ws_channel,
    sm.geography,
    sm.s2_name
  FROM typed_transactions t
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.store_intermediate` sm
    ON t.location_id_sales = sm.store_code
),
-- Pull cost per product_code from sku_details via the base SKU ID.
sku_cost AS (
  SELECT
    pi.product_code,
    AVG(SAFE_CAST(sd.COST_PRICE AS FLOAT64)) AS cost_price
  FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate` pi
  LEFT JOIN (
    SELECT
      CAST(ID AS STRING) AS sku_id,
      COST_PRICE
    FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
  ) sd
    ON sd.sku_id = SPLIT(pi.product_code, '_')[OFFSET(0)]
  GROUP BY pi.product_code
),
-- Pull reference prices from price_book by style option, store, and effective date range.
price_book_pricing AS (
  SELECT
    STYLE_OPTION_ID AS style_option_id,
    LPAD(CAST(LOC_ID AS STRING), 10, '0') AS store_code,
    SAFE_CAST(EFFECTIVE_FROM_DAY_ID AS DATE) AS effective_from_date,
    SAFE_CAST(EFFECTIVE_TO_DAY_ID AS DATE) AS effective_to_date,
    SAFE_CAST(ORIGINAL_PRICE AS FLOAT64) AS msrp,
    SAFE_CAST(REGULAR_PRICE AS FLOAT64) AS regular_price,
    SAFE_CAST(CLEARANCE_PRICE AS FLOAT64) AS clearance_price
  FROM `lululemon-01042025.lulu_sourcing_dev.price_book`
  WHERE SAFE_CAST(EFFECTIVE_TO_DAY_ID AS DATE) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
    AND SAFE_CAST(EFFECTIVE_FROM_DAY_ID AS DATE) <= CURRENT_DATE()
),
-- Join product, pricing, and store attributes into the intermediate-table shape.
txn_projected AS (
  SELECT
    txn.s1_name AS channel,
    CAST(NULL AS FLOAT64) AS line_id,
    pi.l0_name AS brand,
    CAST(NULL AS FLOAT64) AS launch_price,
    CASE
      WHEN pb.clearance_price > 0
        AND SAFE_CAST(txn.PRICE_SALES_UNIT AS FLOAT64) > 0
        AND SAFE_CAST(txn.PRICE_SALES_UNIT AS FLOAT64) <= pb.clearance_price
        THEN 1.0
      ELSE 0.0
    END AS clearance,
    CASE
      WHEN pb.msrp > 0
        THEN GREATEST(pb.msrp - SAFE_CAST(txn.PRICE_SALES_UNIT AS FLOAT64), 0.0)
      ELSE 0.0
    END AS unit_discount_amount,
    CASE
      WHEN pb.msrp > 0 AND txn.units > 0
        THEN GREATEST(
          (pb.msrp * txn.units) - SAFE_CAST(txn.PRICE_SALES_TOTAL AS FLOAT64),
          0.0
        )
      ELSE 0.0
    END AS total_discount_amount,
    txn.units AS qty,
    txn.TRANSACTION_TYPE AS transaction_type,
    txn.location_id_sales AS store_code,
    CAST(NULL AS STRING) AS fullfilment_location_customer,
    0 AS flagged_rows,
    txn.SALES_ORDER_ID AS transaction_code,
    txn.channel_code,
    txn.transaction_date AS date,
    txn.sku_id_channel AS product_code,
    CAST(NULL AS FLOAT64) AS revenue_before_tax,
    txn.s2_name AS ship_to_country,
    CAST(NULL AS FLOAT64) AS freight_cost,
    txn.ws_channel,
    txn.geography,
    pb.clearance_price AS clearance_price,
    CAST(NULL AS FLOAT64) AS store_contribution,
    CAST(NULL AS STRING) AS workstream,
    txn.s2_name AS ecomm_country,
    txn.PRICE_SALES_TOTAL AS revenue,
    sc.cost_price AS cost,
    CAST(NULL AS FLOAT64) AS currency_exchange_rate,
    txn.SALES_SERVICE_TYPE AS order_type,
    CAST(NULL AS STRING) AS transaction_category,
    pb.msrp AS msrp,
    txn.PRICE_SALES_UNIT AS price
  FROM txn_enriched txn
  INNER JOIN `lululemon-01042025.lulu_sourcing_dev.product_intermediate` pi
    ON pi.product_code = txn.sku_id_channel
  INNER JOIN sku_cost sc
    ON sc.product_code = txn.sku_id_channel
  LEFT JOIN price_book_pricing pb
    ON pi.article_original = pb.style_option_id
    AND txn.location_id_sales = pb.store_code
    AND txn.transaction_date BETWEEN pb.effective_from_date AND pb.effective_to_date
)
SELECT * FROM txn_projected;
