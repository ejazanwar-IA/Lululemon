-- Lululemon historic inventory intermediate build
--
-- Sources (all lulu_sourcing_dev, never souricng_outbound in intermediate builds):
--   inventory_snapshot, location_details
-- Target: lulu_sourcing_dev.inventory_intermediate
-- Business-date window: 2 full prior years plus current year-to-date.
--
-- Channel policy: emit only downstream-supported RETAIL / ECOMM product codes.
-- Non-core location channels (FO, STRAT, COMMUNITY, CMNTY) exist in location
-- metadata but do not exist in product_intermediate / product_master product_code
-- suffixes, so exclude them before writing the intermediate table.


CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
PARTITION BY date
CLUSTER BY store_code, product_code AS
WITH cleaned_inventory AS (
  SELECT
    SAFE_CAST(SKU_ID AS INT64) AS SKU_ID,
    LOCATION_ID,
    SAFE_CAST(`DATE` AS DATE) AS `DATE`,
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS UNITS_ON_HAND,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS UNITS_AVAILABLE,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS UNITS_INBOUND,
    SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) AS SNAPSHOT_TIME
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
  WHERE SAFE_CAST(SKU_ID AS INT64) IS NOT NULL
    AND LOCATION_ID IS NOT NULL
    AND LOCATION_ID != ''
    AND SAFE_CAST(`DATE` AS DATE) IS NOT NULL
    AND SAFE_CAST(`DATE` AS DATE) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
    AND SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) IS NOT NULL
),
inventory_enriched AS (
  SELECT
    i.SKU_ID,
    i.LOCATION_ID,
    i.`DATE`,
    i.UNITS_ON_HAND,
    i.UNITS_AVAILABLE,
    i.UNITS_INBOUND,
    i.SNAPSHOT_TIME,
    derived_channel AS CHANNEL,
    CONCAT(CAST(i.SKU_ID AS STRING), '_', derived_channel) AS SKU_ID_CHANNEL,
    derived_channel
  FROM cleaned_inventory i
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON LPAD(CAST(i.LOCATION_ID AS STRING), 10, '0') = LPAD(CAST(ld.ID AS STRING), 10, '0')
  CROSS JOIN UNNEST([CASE
    WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
      OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL'
      THEN 'RETAIL'
    WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
      OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
    ELSE NULL
  END]) AS derived_channel
),
normalized_inventory AS (
  SELECT
    CAST(SKU_ID AS STRING) AS display_product_code,
    COALESCE(SKU_ID_CHANNEL, CONCAT(CAST(SKU_ID AS STRING), '_', derived_channel)) AS product_code,
    LOCATION_ID AS store_code,
    `DATE` AS date,
    COALESCE(CHANNEL, derived_channel) AS channel,
    SKU_ID_CHANNEL AS source_product_code,
    CHANNEL AS source_channel,
    SKU_ID_CHANNEL IS NULL OR SKU_ID_CHANNEL = '' AS product_code_was_derived,
    CHANNEL IS NULL OR CHANNEL = '' AS channel_was_derived,
    COALESCE(UNITS_ON_HAND, 0) AS oh,
    COALESCE(UNITS_INBOUND, 0) AS it,
    0 AS oo,
    COALESCE(UNITS_AVAILABLE, 0) AS available_units,
    SNAPSHOT_TIME AS syncstartdatetime,
    SNAPSHOT_TIME AS created_timestamp
  FROM inventory_enriched
  WHERE COALESCE(CHANNEL, derived_channel) IN ('RETAIL', 'ECOMM')
),
latest_inventory AS (
  SELECT * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY product_code, store_code, date, channel
        ORDER BY syncstartdatetime DESC
      ) AS rn
    FROM normalized_inventory
  )
  WHERE rn = 1
)
SELECT
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  source_product_code,
  source_channel,
  LOGICAL_OR(product_code_was_derived) AS product_code_was_derived,
  LOGICAL_OR(channel_was_derived) AS channel_was_derived,
  SUM(oh) AS oh,
  SUM(it) AS it,
  SUM(oo) AS oo,
  SUM(available_units) AS available_units,
  DATETIME(MIN(syncstartdatetime)) AS syncstartdatetime,
  DATETIME(MIN(created_timestamp)) AS created_timestamp
FROM latest_inventory
GROUP BY
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  source_product_code,
  source_channel;
