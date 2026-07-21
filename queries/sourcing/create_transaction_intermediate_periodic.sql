-- Lululemon periodic transaction intermediate build
--
-- Platform pattern (Signet baseline): filter_param from mapping, temp build from
-- incremental sales_transactions, MERGE into live intermediate, drop temp.
--
-- Source: lulu_sourcing_dev.sales_transactions (SYNCSTARTDATETIME > filter_param)
-- Joins: product_intermediate, store_intermediate, sku_details
-- Target: lulu_sourcing_dev.transaction_intermediate (32 cols)
-- Business-date window: 2 full prior years plus current year-to-date.
--
-- MERGE grain (verified 2026-05-20): transaction_code + product_code + store_code + date
--   — 0 duplicate groups in live table at that grain.
--
-- Self-Help prerequisites:
--   mapping.intermediate_table = 'transaction_intermediate' (is_deleted = FALSE)
--   view_mapping_table.view = 'sales_transactions' for table = 'transaction'
--   product_intermediate and store_intermediate must be current before this runs.

DECLARE filter_param DATETIME DEFAULT (
  SELECT COALESCE(
    MAX(COALESCE(DATETIME(filter_param), DATETIME(dataingestion_filterparam))),
    DATETIME('1900-01-01 00:00:00')
  )
  FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
  WHERE is_deleted = FALSE
    AND intermediate_table = 'transaction_intermediate'
);

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate_temp`
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
    sm.channel AS channel,
    CONCAT(b.SKU_ID, '_', sm.channel) AS sku_id_channel
  FROM (
    SELECT
      CAST(SKU_ID AS STRING) AS SKU_ID,
      LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS LOCATION_ID_SALES,
      DATE_TRANSACTION,
      SALES_ORDER_ID,
      SALES_ORDER_ITEM_ID,
      CAST(UNITS AS STRING) AS UNITS,
      CURRENCY_CODE,
      PRICE_SALES_TOTAL,
      PRICE_SALES_UNIT,
      SALES_SERVICE_TYPE,
      TRANSACTION_TYPE,
      SYNCSTARTDATETIME
    FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
    WHERE SYNCSTARTDATETIME > filter_param
      AND SAFE_CAST(DATE_TRANSACTION AS DATE) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
  ) b
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.store_intermediate` sm
    ON b.LOCATION_ID_SALES = sm.store_code
),

all_skus AS (
  SELECT
    a.product_code AS sku_id_channel,
    AVG(SAFE_CAST(b.COST_PRICE AS FLOAT64)) AS cost_price,
    AVG(SAFE_CAST(b.SELLING_PRICE AS FLOAT64)) AS selling_price
  FROM `lululemon-01042025.lulu_sourcing_dev.product_intermediate` a
  LEFT JOIN sku_cleaned b
    ON a.product_code = b.sku_id_code
  GROUP BY 1
),

txn_projected AS (
  SELECT
    lm.s1_name AS channel,
    NULL AS line_id,
    pi.l0_name AS brand,
    NULL AS launch_price,
    0 AS clearance,
    0 AS unit_discount_amount,
    0 AS total_discount_amount,
    SAFE_CAST(txn.UNITS AS INT64) AS qty,
    NULL AS transaction_type,
    txn.LOCATION_ID_SALES AS store_code,
    NULL AS fullfilment_location_customer,
    0 AS flagged_rows,
    txn.SALES_ORDER_ID AS transaction_code,
    lm.channel_code AS channel_code,
    SAFE_CAST(txn.DATE_TRANSACTION AS DATE) AS date,
    txn.sku_id_channel AS product_code,
    NULL AS revenue_before_tax,
    NULL AS ship_to_country,
    NULL AS freight_cost,
    lm.ws_channel AS ws_channel,
    lm.geography AS geography,
    0 AS clearance_price,
    NULL AS store_contribution,
    NULL AS workstream,
    lm.s2_name AS ecomm_country,
    txn.PRICE_SALES_TOTAL AS revenue,
    sd.cost_price AS cost,
    NULL AS currency_exchange_rate,
    NULL AS order_type,
    NULL AS transaction_category,
    sd.selling_price AS msrp,
    txn.PRICE_SALES_UNIT AS price,
    txn.SYNCSTARTDATETIME AS syncstartdatetime
  FROM txn_cleaned AS txn
  JOIN `lululemon-01042025.lulu_sourcing_dev.product_intermediate` AS pi
    ON pi.product_code = txn.sku_id_channel
  JOIN all_skus AS sd
    ON sd.sku_id_channel = txn.sku_id_channel
  JOIN `lululemon-01042025.lulu_sourcing_dev.store_intermediate` AS lm
    ON lm.store_code = txn.LOCATION_ID_SALES
)

SELECT * EXCEPT(rn, syncstartdatetime)
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY transaction_code, product_code, store_code, date
      ORDER BY syncstartdatetime DESC
    ) AS rn
  FROM txn_projected
)
WHERE rn = 1;

MERGE `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate` DL
USING `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate_temp` A
ON DL.transaction_code = A.transaction_code
  AND DL.product_code = A.product_code
  AND DL.store_code = A.store_code
  AND DL.date = A.date

WHEN MATCHED THEN UPDATE SET
  DL.channel = A.channel,
  DL.line_id = A.line_id,
  DL.brand = A.brand,
  DL.launch_price = A.launch_price,
  DL.clearance = A.clearance,
  DL.unit_discount_amount = A.unit_discount_amount,
  DL.total_discount_amount = A.total_discount_amount,
  DL.qty = A.qty,
  DL.transaction_type = A.transaction_type,
  DL.fullfilment_location_customer = A.fullfilment_location_customer,
  DL.flagged_rows = A.flagged_rows,
  DL.channel_code = A.channel_code,
  DL.revenue_before_tax = A.revenue_before_tax,
  DL.ship_to_country = A.ship_to_country,
  DL.freight_cost = A.freight_cost,
  DL.ws_channel = A.ws_channel,
  DL.geography = A.geography,
  DL.clearance_price = A.clearance_price,
  DL.store_contribution = A.store_contribution,
  DL.workstream = A.workstream,
  DL.ecomm_country = A.ecomm_country,
  DL.revenue = A.revenue,
  DL.cost = A.cost,
  DL.currency_exchange_rate = A.currency_exchange_rate,
  DL.order_type = A.order_type,
  DL.transaction_category = A.transaction_category,
  DL.msrp = A.msrp,
  DL.price = A.price

WHEN NOT MATCHED THEN INSERT (
  channel,
  line_id,
  brand,
  launch_price,
  clearance,
  unit_discount_amount,
  total_discount_amount,
  qty,
  transaction_type,
  store_code,
  fullfilment_location_customer,
  flagged_rows,
  transaction_code,
  channel_code,
  date,
  product_code,
  revenue_before_tax,
  ship_to_country,
  freight_cost,
  ws_channel,
  geography,
  clearance_price,
  store_contribution,
  workstream,
  ecomm_country,
  revenue,
  cost,
  currency_exchange_rate,
  order_type,
  transaction_category,
  msrp,
  price
)
VALUES (
  A.channel,
  A.line_id,
  A.brand,
  A.launch_price,
  A.clearance,
  A.unit_discount_amount,
  A.total_discount_amount,
  A.qty,
  A.transaction_type,
  A.store_code,
  A.fullfilment_location_customer,
  A.flagged_rows,
  A.transaction_code,
  A.channel_code,
  A.date,
  A.product_code,
  A.revenue_before_tax,
  A.ship_to_country,
  A.freight_cost,
  A.ws_channel,
  A.geography,
  A.clearance_price,
  A.store_contribution,
  A.workstream,
  A.ecomm_country,
  A.revenue,
  A.cost,
  A.currency_exchange_rate,
  A.order_type,
  A.transaction_category,
  A.msrp,
  A.price
);

DROP TABLE IF EXISTS `lululemon-01042025.lulu_sourcing_dev.transaction_intermediate_temp`;
