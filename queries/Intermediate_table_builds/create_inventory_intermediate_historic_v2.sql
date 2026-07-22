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
),
-- Latest snapshot per product_code, store_code, date, channel. Split from the final projection
-- since the oo asof-join below needs its own QUALIFY/dedup pass.
dedup_inventory AS (
  SELECT
    display_product_code, product_code, store_code, date, channel,
    source_product_code, source_channel, product_code_was_derived, channel_was_derived,
    oh, it, available_units, snapshot_time
  FROM normalized_inventory
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY product_code, store_code, date, channel
    ORDER BY snapshot_time DESC, oh DESC, it DESC, available_units DESC
  ) = 1
),
-- REPLEN/ALLOC transfer orders, typed. DATE_RECEIVED (99.997% populated) is the close-out signal,
-- not UNITS_SHIPPED/DATE_SHIPPED (<1% populated even when fulfilled).
transfer_typed AS (
  SELECT
    SAFE_CAST(SKU_ID AS INT64) AS sku_id,
    LOCATION_ID_RECEIVING AS store_code,
    SAFE_CAST(UNITS_ORDERED AS INT64) AS units_ordered,
    SAFE.PARSE_DATE('%Y-%m-%d', DATE_CREATED) AS date_created,
    SAFE.PARSE_DATE('%Y-%m-%d', DATE_RECEIVED) AS date_received
  FROM `lululemon-01042025.lulu_sourcing_dev.transfer_orders`
  WHERE TYPE_NAME IN ('REPLEN', 'ALLOC')
),
-- +ordered on creation, -ordered on receipt.
transfer_events AS (
  SELECT sku_id, store_code, date_created AS event_date, units_ordered AS delta
  FROM transfer_typed WHERE date_created IS NOT NULL
  UNION ALL
  SELECT sku_id, store_code, date_received AS event_date, -units_ordered AS delta
  FROM transfer_typed WHERE date_received IS NOT NULL
),
-- Collapse same-day events per key before the running balance.
daily_events AS (
  SELECT sku_id, store_code, event_date, SUM(delta) AS net_delta
  FROM transfer_events GROUP BY 1, 2, 3
),
-- Running open-quantity balance per SKU x store.
daily_balance AS (
  SELECT
    sku_id, store_code, event_date,
    SUM(net_delta) OVER (
      PARTITION BY sku_id, store_code ORDER BY event_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS open_qty
  FROM daily_events
),
-- store_code stays unpadded here to match inventory_intermediate's own convention (store_master pads to 10 digits).
balance_with_channel AS (
  SELECT
    CONCAT(CAST(db.sku_id AS STRING), '_', lc.channel) AS product_code,
    db.store_code,
    db.event_date,
    db.open_qty
  FROM daily_balance db
  JOIN location_channels lc ON LPAD(db.store_code, 10, '0') = lc.location_key
  WHERE lc.channel IN ('RETAIL', 'ECOMM')
)
SELECT
  i.display_product_code,
  i.product_code,
  i.store_code,
  i.date,
  i.channel,
  i.source_product_code,
  i.source_channel,
  i.product_code_was_derived,
  i.channel_was_derived,
  i.oh,
  i.it,
  COALESCE(b.open_qty, 0) AS oo,
  i.available_units,
  DATETIME(i.snapshot_time) AS syncstartdatetime,
  DATETIME(i.snapshot_time) AS created_timestamp
FROM dedup_inventory i
LEFT JOIN balance_with_channel b
  ON i.product_code = b.product_code
  AND i.store_code = b.store_code
  AND b.event_date <= i.date
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY i.product_code, i.store_code, i.date
  ORDER BY b.event_date DESC
) = 1;
