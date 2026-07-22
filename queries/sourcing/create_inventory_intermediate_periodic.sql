-- Lululemon periodic inventory intermediate build
--
-- Platform pattern (Signet baseline): read filter_param from mapping, build
-- *_intermediate_temp from incremental raw, MERGE into live intermediate, drop temp.
--
-- Sources (all lulu_sourcing_dev — never souricng_outbound in intermediate builds):
--   inventory_snapshot, location_details
-- Target: lulu_sourcing_dev.inventory_intermediate
-- Incremental: SNAPSHOT_TIME > filter_param on inventory_snapshot
-- Business-date window: 2 full prior years plus current year-to-date.
-- After switching sources, run the historic/full rebuild once because MERGE does
-- not remove older rows that are no longer present in the latest raw source.
--
-- Validated transformation: queries/inventory_sourcing_stepwise.sql Section 2 + 4B
-- (2025-08-28 window: 5,539,053 rows; merge key unique on product/store/date/channel)
-- Channel policy: emit only downstream-supported RETAIL / ECOMM product codes.
-- Non-core location channels (FO, STRAT, COMMUNITY, CMNTY) do not exist in
-- product_intermediate / product_master product_code suffixes, so exclude them.
--
-- Self-Help prerequisites:
--   mapping.intermediate_table = 'inventory_intermediate' (is_deleted = FALSE)
--   view_mapping_table.view = 'inventory_snapshot' for table = 'inventory'
--
-- First run: live table must exist (run inventory_sourcing_stepwise.sql Section 4A once,
-- or CREATE TABLE IF NOT EXISTS from temp after a successful temp build).

DECLARE filter_param TIMESTAMP DEFAULT (
  SELECT COALESCE(
    MAX(COALESCE(filter_param, TIMESTAMP(dataingestion_filterparam))),
    TIMESTAMP('1900-01-01 00:00:00 UTC')
  )
  FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
  WHERE is_deleted = FALSE
    AND intermediate_table = 'inventory_intermediate'
);

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp`
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
    AND SAFE_CAST(SNAPSHOT_TIME AS TIMESTAMP) > filter_param
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
),
-- OO formulation (same logic as create_inventory_intermediate_historic_v2.sql, added 2026-07-22):
-- open DC->store REPLEN/ALLOC transfer-order pipeline (ordered, not yet received). DATE_RECEIVED is
-- used as the close-out signal (99.997% populated) instead of UNITS_SHIPPED/DATE_SHIPPED (<1%
-- populated even when fulfilled) -- so oo cannot be cleanly separated from it (in-transit) today.
-- The balance is computed over full transfer_orders history regardless of the incremental filter_param
-- window, since an open order can predate the incremental slice of inventory rows being merged.
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
transfer_events AS (
  SELECT sku_id, store_code, date_created AS event_date, units_ordered AS delta
  FROM transfer_typed WHERE date_created IS NOT NULL
  UNION ALL
  SELECT sku_id, store_code, date_received AS event_date, -units_ordered AS delta
  FROM transfer_typed WHERE date_received IS NOT NULL
),
daily_events AS (
  SELECT sku_id, store_code, event_date, SUM(delta) AS net_delta
  FROM transfer_events GROUP BY 1, 2, 3
),
daily_balance AS (
  SELECT
    sku_id, store_code, event_date,
    SUM(net_delta) OVER (
      PARTITION BY sku_id, store_code ORDER BY event_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS open_qty
  FROM daily_events
),
-- store_code here is intentionally NOT zero-padded, matching inventory_intermediate's own raw
-- LOCATION_ID convention (unlike store_intermediate/store_master, which pad to 10 digits).
balance_with_channel AS (
  SELECT
    CONCAT(CAST(db.sku_id AS STRING), '_', ld_chan.channel) AS product_code,
    db.store_code,
    db.event_date,
    db.open_qty
  FROM daily_balance db
  JOIN (
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
  ) ld_chan ON LPAD(db.store_code, 10, '0') = ld_chan.location_key
  WHERE ld_chan.channel IN ('RETAIL', 'ECOMM')
),
-- Attach oo via asof-join, then dedupe (a row can match multiple daily_balance event_dates <= its
-- date; QUALIFY keeps only the latest one). This has to happen before the final GROUP BY below,
-- since QUALIFY needs the pre-aggregation b.event_date column in scope.
inventory_with_oo AS (
  SELECT
    li.*,
    COALESCE(b.open_qty, 0) AS oo
  FROM latest_inventory li
  LEFT JOIN balance_with_channel b
    ON li.product_code = b.product_code
    AND li.store_code = b.store_code
    AND b.event_date <= li.date
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY li.product_code, li.store_code, li.date, li.channel, li.source_product_code, li.source_channel
    ORDER BY b.event_date DESC
  ) = 1
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
FROM inventory_with_oo
GROUP BY
  display_product_code,
  product_code,
  store_code,
  date,
  channel,
  source_product_code,
  source_channel;

MERGE `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate` DL
USING `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp` A
ON DL.product_code = A.product_code
  AND DL.store_code = A.store_code
  AND DL.date = A.date
  AND DL.channel = A.channel

WHEN MATCHED THEN UPDATE SET
  DL.display_product_code = A.display_product_code,
  DL.source_product_code = A.source_product_code,
  DL.source_channel = A.source_channel,
  DL.product_code_was_derived = A.product_code_was_derived,
  DL.channel_was_derived = A.channel_was_derived,
  DL.oh = A.oh,
  DL.it = A.it,
  DL.oo = A.oo,
  DL.available_units = A.available_units,
  DL.syncstartdatetime = A.syncstartdatetime,
  DL.created_timestamp = A.created_timestamp

WHEN NOT MATCHED THEN INSERT (
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
  syncstartdatetime,
  created_timestamp
)
VALUES (
  A.display_product_code,
  A.product_code,
  A.store_code,
  A.date,
  A.channel,
  A.source_product_code,
  A.source_channel,
  A.product_code_was_derived,
  A.channel_was_derived,
  A.oh,
  A.it,
  A.oo,
  A.available_units,
  A.syncstartdatetime,
  A.created_timestamp
);

DROP TABLE IF EXISTS `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate_temp`;
