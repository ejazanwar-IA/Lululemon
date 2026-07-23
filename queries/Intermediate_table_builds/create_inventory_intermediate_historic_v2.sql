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
-- location_key is the raw ID (STRING, unpadded) -- verified no leading-zero variants exist in source.
location_channels AS (
  SELECT
    ID AS location_key,
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
    PARTITION BY ID
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
    COALESCE(i.units_on_hand, 0) AS oh,
    COALESCE(i.units_inbound, 0) AS it,
    COALESCE(i.units_available, 0) AS available_units,
    i.snapshot_time
  FROM typed_inventory i
  INNER JOIN location_channels lc
    ON i.location_id = lc.location_key
  WHERE i.sku_id IS NOT NULL
    AND i.location_id IS NOT NULL
    AND i.location_id != ''
    AND i.inventory_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
    AND i.snapshot_time IS NOT NULL
    AND lc.channel IN ('RETAIL', 'ECOMM')
),
-- Latest snapshot per product_code, store_code, date, channel.
dedup_inventory AS (
  SELECT
    display_product_code, product_code, store_code, date, channel,
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
  JOIN location_channels lc ON db.store_code = lc.location_key
  WHERE lc.channel IN ('RETAIL', 'ECOMM')
),
-- Merge inventory rows and balance events into one stream per key, ordered by date (balance events
-- first on ties), so oo can be carried forward with LAST_VALUE instead of a range join + QUALIFY --
-- ~5x faster and ~2.8x less slot time on a one-month benchmark, verified to produce identical output.
timeline AS (
  SELECT
    product_code, store_code, date, FALSE AS is_balance_row, CAST(NULL AS INT64) AS oo_event,
    display_product_code, channel, oh, it, available_units, snapshot_time
  FROM dedup_inventory
  UNION ALL
  SELECT
    product_code, store_code, event_date AS date, TRUE, open_qty,
    CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS INT64), CAST(NULL AS INT64), CAST(NULL AS INT64), CAST(NULL AS TIMESTAMP)
  FROM balance_with_channel
),
-- Carry the last known balance forward onto every inventory row for that key.
filled AS (
  SELECT
    *,
    LAST_VALUE(oo_event IGNORE NULLS) OVER (
      PARTITION BY product_code, store_code
      ORDER BY date, is_balance_row DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS oo
  FROM timeline
)
SELECT
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  oh,
  it,
  COALESCE(oo, 0) AS oo,
  available_units,
  DATETIME(snapshot_time) AS syncstartdatetime,
  DATETIME(snapshot_time) AS created_timestamp
FROM filled
WHERE is_balance_row = FALSE;
