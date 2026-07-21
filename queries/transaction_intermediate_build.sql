-- transaction_intermediate — built from raw sales_transactions + sku_details,
-- joined to product_intermediate + store_intermediate. Cleaning inlined.
-- Output: lulu_sourcing_dev.transaction_intermediate (32 cols, partition=date, cluster=channel).
-- Business-date window: 2 full prior years plus current year-to-date.

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate`
PARTITION BY date
CLUSTER BY channel AS

WITH
sku_cleaned AS (
  SELECT
    b.*,
    channel,
    CONCAT(CAST(b.ID AS STRING), '_', channel) AS sku_id_code
  FROM (
    SELECT DISTINCT *
    FROM `lululemon-01042025.lulu_sourcing_dev.sku_details`
  ) b
  CROSS JOIN UNNEST(['ECOMM', 'RETAIL']) AS channel
),

txn_cleaned AS (
  SELECT DISTINCT
    b.*,
    sm.channel                                       AS channel,
    CONCAT(b.SKU_ID, '_', sm.channel)                AS sku_id_channel
  FROM (
    SELECT
      CAST(SKU_ID AS STRING)                              AS SKU_ID,
      LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0')    AS LOCATION_ID_SALES,
      DATE_TRANSACTION,
      SALES_ORDER_ID,
      SALES_ORDER_ITEM_ID,
      CAST(UNITS AS STRING)                               AS UNITS,
      CURRENCY_CODE,
      PRICE_SALES_TOTAL,
      PRICE_SALES_UNIT,
      SALES_SERVICE_TYPE,
      TRANSACTION_TYPE
    FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
    WHERE SAFE_CAST(DATE_TRANSACTION AS DATE) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
  ) b
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.store_intermediate` sm
    ON b.LOCATION_ID_SALES = sm.store_code
),

all_skus AS (
  SELECT
    a.product_code                             AS sku_id_channel,
    AVG(SAFE_CAST(b.COST_PRICE AS FLOAT64))    AS cost_price,
    AVG(SAFE_CAST(b.SELLING_PRICE AS FLOAT64)) AS selling_price
  FROM      `lululemon-01042025.lulu_sourcing_dev.product_intermediate` a
  LEFT JOIN sku_cleaned b
    ON a.product_code = b.sku_id_code
  GROUP BY 1
)

SELECT DISTINCT
  lm.s1_name                          AS channel,
  NULL                                AS line_id,
  pi.l0_name                          AS brand,
  NULL                                AS launch_price,
  0                                   AS clearance,
  0                                   AS unit_discount_amount,
  0                                   AS total_discount_amount,
  SAFE_CAST(txn.UNITS AS INT64)       AS qty,
  NULL                                AS transaction_type,
  txn.LOCATION_ID_SALES               AS store_code,
  NULL                                AS fullfilment_location_customer,
  0                                   AS flagged_rows,
  txn.SALES_ORDER_ID                  AS transaction_code,
  lm.channel_code                     AS channel_code,
  SAFE_CAST(txn.DATE_TRANSACTION AS DATE) AS date,
  txn.sku_id_channel                  AS product_code,
  NULL                                AS revenue_before_tax,
  NULL                                AS ship_to_country,
  NULL                                AS freight_cost,
  lm.ws_channel                       AS ws_channel,
  lm.geography                        AS geography,
  0                                   AS clearance_price,
  NULL                                AS store_contribution,
  NULL                                AS workstream,
  lm.s2_name                          AS ecomm_country,
  txn.PRICE_SALES_TOTAL               AS revenue,
  sd.cost_price                       AS cost,
  NULL                                AS currency_exchange_rate,
  NULL                                AS order_type,
  NULL                                AS transaction_category,
  sd.selling_price                    AS msrp,
  txn.PRICE_SALES_UNIT                AS price
FROM       txn_cleaned                                                    AS txn
JOIN       `lululemon-01042025.lulu_sourcing_dev.product_intermediate`    AS pi
  ON pi.product_code = txn.sku_id_channel
JOIN       all_skus                                                       AS sd
  ON sd.sku_id_channel = txn.sku_id_channel
JOIN       `lululemon-01042025.lulu_sourcing_dev.store_intermediate`      AS lm
  ON lm.store_code = txn.LOCATION_ID_SALES;


-- ---- Validation (run separately) -------------------------------------------
-- SELECT COUNT(*) AS rows, COUNT(DISTINCT product_code) AS skus,
--        MIN(date) AS earliest, MAX(date) AS latest
-- FROM `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate`;
--
-- SELECT channel, COUNT(*) FROM `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate` GROUP BY 1;
--
-- SELECT ROUND(COUNTIF(qty=0 AND revenue=0)/COUNT(*)*100,1) AS pct_zero
-- FROM `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate`;
