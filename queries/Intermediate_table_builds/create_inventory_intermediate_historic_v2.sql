-- Lululemon historic inventory intermediate build, v2.
-- Business-date window: 2 full prior years plus current year-to-date.


CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
PARTITION BY date
CLUSTER BY store_code, product_code AS
WITH
-- Cast raw inventory_snapshot strings to typed fields for downstream joins and filters.
typed_inventory AS (
  SELECT
    SAFE_CAST(SKU_ID AS INT64) AS sku_id,
    LOCATION_ID AS location_id,
    SAFE_CAST(`DATE` AS DATE) AS inventory_date,
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS units_on_hand,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS units_available,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS units_inbound,
    SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) AS snapshot_time
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
),
-- Map each location to one RETAIL or ECOMM channel; dedupe location_details to one row per location_key.
location_channels AS (
  SELECT
    LPAD(CAST(ID AS STRING), 10, '0') AS location_key,
    CASE
      WHEN UPPER(COALESCE(TYPE_CODE, '')) = 'RETAIL'
        OR UPPER(COALESCE(CHANNEL_CODE, '')) LIKE '%_RTL'
        THEN 'RETAIL'
      WHEN UPPER(COALESCE(TYPE_CODE, '')) = 'ECOMM'
        OR UPPER(COALESCE(CHANNEL_CODE, '')) LIKE '%ECOMM%'
        THEN 'ECOMM'
    END AS channel
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY LPAD(CAST(ID AS STRING), 10, '0')
    ORDER BY SYNCSTARTDATETIME DESC, ID DESC
  ) = 1
),
-- Join inventory to location channel, apply the business-date window, and project intermediate-table columns.
normalized_inventory AS (
  SELECT
    CAST(i.sku_id AS STRING) AS display_product_code,
    CONCAT(CAST(i.sku_id AS STRING), '_', lc.channel) AS product_code,
    i.location_id AS store_code,
    i.inventory_date AS date,
    lc.channel,
    CONCAT(CAST(i.sku_id AS STRING), '_', lc.channel) AS source_product_code,
    lc.channel AS source_channel,
    FALSE AS product_code_was_derived,
    FALSE AS channel_was_derived,
    COALESCE(i.units_on_hand, 0) AS oh,
    COALESCE(i.units_inbound, 0) AS it,
    0 AS oo,
    COALESCE(i.units_available, 0) AS available_units,
    i.snapshot_time
  FROM typed_inventory i
  INNER JOIN location_channels lc
    ON LPAD(CAST(i.location_id AS STRING), 10, '0') = lc.location_key
  WHERE i.sku_id IS NOT NULL
    AND i.location_id IS NOT NULL
    AND i.location_id != ''
    AND i.inventory_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
    AND i.snapshot_time IS NOT NULL
    AND lc.channel IN ('RETAIL', 'ECOMM')
)
-- Keep the latest snapshot per product_code, store_code, date, and channel.
SELECT
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  source_product_code,
  source_channel,
  product_code_was_derived,
  channel_was_derived,
  oh,
  it,
  oo,
  available_units,
  DATETIME(snapshot_time) AS syncstartdatetime,
  DATETIME(snapshot_time) AS created_timestamp
FROM normalized_inventory
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY product_code, store_code, date, channel
  ORDER BY snapshot_time DESC, oh DESC, it DESC, available_units DESC
) = 1;
