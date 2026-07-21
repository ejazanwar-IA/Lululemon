-- =============================================================================
-- INVENTORY INTERMEDIATE — built from sourced raw inventory + PGH + store_master
--                          intermediate, with cleaning inlined
-- =============================================================================
-- Purpose : Reproduce the canonical `inventory_master` shape directly from the
--           two raw tables that the IA Platform's Sourcing DAG materialises into
--           `lulu_sourcing_dev`, plus the `store_master_intermediate` you just
--           built. Cleaning is INLINED (no separate `*_cleaned` tables).
--
-- Inputs  :
--   `lulu_sourcing_dev.inventory_snapshot`         (raw, sourced via DAG)
--   `lulu_sourcing_dev.product_group_hierarchy`    (raw EAV format, sourced via DAG)
--   `lulu_sourcing_dev.store_master_intermediate`  (built by store_master_intermediate_build.sql)
--
-- Output  :
--   `lulu_sourcing_dev.inventory_intermediate`     (matches inventory_master schema)
--
-- Lineage : Combines three recovered build steps:
--   1. PGH CLEANING — EAV pivot (9 LEVEL_NAMEs × 2 = 18 NAME/CODE cols) plus
--      channel expansion via CROSS JOIN UNNEST(['ECOMM','RETAIL']) and
--      sku_id_code = CONCAT(SKU_ID, '_', channel). Recipe extracted from
--      `reference_docs/Lululemon/Cleaned Table Builds/product_group_hierarchy_cleaned_20251119.sql`.
--   2. INVENTORY CLEANING — LPAD(LOCATION_ID), JOIN store_master to attach
--      CHANNEL, then composite key SKU_ID_CHANNEL = sku_id || '_' || channel.
--      Recipe extracted from the 2025-12-05 INSERT by ritik (job
--      `bquxjob_1f117971_19aef03cfcc`) into `inventory_snapshot_cleaned_20251205`.
--   3. INVENTORY MASTER BUILD — INNER JOIN cleaned inventory + cleaned PGH on
--      `sku_id_channel = sku_id_code`, project 10 output columns. Logic from
--      Ejaz's existing build (corrected join key per workspace gotcha G9).
--
-- Notes :
--   - Join key uses `B.sku_id_code` (not `B.sku_id_channel`) per gotcha G9.
--     PGH's canonical SKU key is `sku_id_code`; inventory's is `sku_id_channel`;
--     these are the same string format, just different column names per side.
--   - INNER JOIN drops inventory rows whose SKU isn't in PGH (documented data
--     quality issue — see `findings/inventory_master_eda.md`).
--   - Inventory cleaning depends on `store_master_intermediate` for the
--     LOCATION_ID → CHANNEL mapping. Run the store_master build first.
-- =============================================================================

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
PARTITION BY DATE(date)
CLUSTER BY store_code AS

WITH
-- ----------------------------------------------------------------------------
-- Step 1: Pivot raw EAV product_group_hierarchy + expand channel
--   - GROUP BY SKU_ID with MAX(CASE WHEN LEVEL_NAME = '<x>' THEN VALUE_X END)
--     produces one row per SKU with 18 hierarchy NAME/CODE columns.
--   - CROSS JOIN UNNEST(['ECOMM','RETAIL']) doubles the row count to give
--     each SKU both channels.
--   - sku_id_code = CONCAT(SKU_ID, '_', channel) is the canonical join key.
-- ----------------------------------------------------------------------------
pgh_pivot AS (
  SELECT
    SKU_ID,
    MAX(CASE WHEN LEVEL_NAME = 'BRAND'                THEN VALUE_NAME END) AS BRAND_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'BRAND'                THEN VALUE_CODE END) AS BRAND_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'DIVISION'             THEN VALUE_NAME END) AS DIVISION_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'DIVISION'             THEN VALUE_CODE END) AS DIVISION_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'DEPARTMENT'           THEN VALUE_NAME END) AS DEPARTMENT_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'DEPARTMENT'           THEN VALUE_CODE END) AS DEPARTMENT_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'CLASS'                THEN VALUE_NAME END) AS CLASS_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'CLASS'                THEN VALUE_CODE END) AS CLASS_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'SUBCLASS'             THEN VALUE_NAME END) AS SUBCLASS_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'SUBCLASS'             THEN VALUE_CODE END) AS SUBCLASS_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'MASTER_STYLE'         THEN VALUE_NAME END) AS MASTER_STYLE_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'MASTER_STYLE'         THEN VALUE_CODE END) AS MASTER_STYLE_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'STYLE'                THEN VALUE_NAME END) AS STYLE_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'STYLE'                THEN VALUE_CODE END) AS STYLE_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_OPTION' THEN VALUE_NAME END) AS PLANNING_STYLE_OPTION_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_OPTION' THEN VALUE_CODE END) AS PLANNING_STYLE_OPTION_CODE,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_SIZE'   THEN VALUE_NAME END) AS PLANNING_STYLE_SIZE_NAME,
    MAX(CASE WHEN LEVEL_NAME = 'PLANNING_STYLE_SIZE'   THEN VALUE_CODE END) AS PLANNING_STYLE_SIZE_CODE
  FROM `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy`
  GROUP BY SKU_ID
),

pgh_cleaned AS (
  SELECT
    p.*,
    channel,
    CONCAT(CAST(p.SKU_ID AS STRING), '_', channel) AS sku_id_code
  FROM pgh_pivot p
  CROSS JOIN UNNEST(['ECOMM', 'RETAIL']) AS channel
),

-- ----------------------------------------------------------------------------
-- Step 2: Clean inventory_snapshot raw + attach CHANNEL via store_master JOIN
--   - LPAD LOCATION_ID to 10-char zero-padded string (canonical Lululemon idiom)
--   - JOIN store_master_intermediate to attach CHANNEL per location
--   - Compose sku_id_channel = sku_id || '_' || channel for the master join
-- ----------------------------------------------------------------------------
inv_cleaned AS (
  SELECT DISTINCT
    a.SKU_ID                                                  AS sku_id,
    LPAD(CAST(a.LOCATION_ID AS STRING), 10, '0')              AS LOCATION_ID,
    a.DATE                                                    AS DATE,
    a.UNITS_ON_HAND                                           AS UNITS_ON_HAND,
    a.UNITS_AVAILABLE                                         AS UNITS_AVAILABLE,
    a.UNITS_INBOUND                                           AS UNITS_INBOUND,
    a.SNAPSHOT_TIME                                           AS SNAPSHOT_TIME,
    b.channel                                                 AS CHANNEL,
    CONCAT(CAST(a.SKU_ID AS STRING), '_', b.channel)          AS sku_id_channel
  FROM      `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`         a
  JOIN      `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate`  b
    ON LPAD(CAST(a.LOCATION_ID AS STRING), 10, '0') = b.store_code
)

-- ----------------------------------------------------------------------------
-- Step 3: Build inventory_master shape
--   INNER JOIN — inventory rows without a matching SKU in PGH are dropped
--   (matches existing build behaviour; documented data-loss in the workspace).
-- ----------------------------------------------------------------------------
SELECT
  B.BRAND_NAME           AS brand,
  A.DATE                 AS date,
  A.UNITS_ON_HAND        AS oh,
  A.UNITS_INBOUND        AS it,
  0                      AS oo,
  0                      AS wip,
  0                      AS initial_oh_quantity,
  A.UNITS_ON_HAND        AS total_units,
  A.LOCATION_ID          AS store_code,
  A.sku_id_channel       AS product_code
FROM inv_cleaned   A
JOIN pgh_cleaned   B
  ON A.sku_id_channel = B.sku_id_code;


-- =============================================================================
-- POST-BUILD VALIDATION (run separately after the CTAS finishes)
-- =============================================================================
--
-- 1. Row count + grain integrity
--    Grain should be (date, product_code, store_code). If total_rows >
--    distinct_grain, there are duplicates from the source inventory data.
--
-- SELECT
--   COUNT(*)                                               AS total_rows,
--   COUNT(DISTINCT CONCAT(date, '|', product_code, '|', store_code)) AS distinct_grain,
--   COUNT(DISTINCT date)                                   AS distinct_dates,
--   COUNT(DISTINCT store_code)                             AS distinct_stores,
--   MIN(date)                                              AS earliest_date,
--   MAX(date)                                              AS latest_date,
--   COUNTIF(brand IS NULL)                                 AS null_brand
-- FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`;
--
-- 2. INNER JOIN drop rate (how many inventory rows had no PGH match?)
--    Compare against a LEFT JOIN baseline.
--
-- WITH
-- inv_lpad AS (
--   SELECT LPAD(CAST(LOCATION_ID AS STRING), 10, '0') AS LOC, SKU_ID
--   FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
-- ),
-- left_join_count AS (
--   SELECT COUNT(*) AS n
--   FROM inv_lpad i
--   JOIN `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate` s
--     ON i.LOC = s.store_code  -- post-store-master join (same as inv_cleaned)
-- ),
-- inner_join_count AS (
--   SELECT COUNT(*) AS n
--   FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
-- )
-- SELECT
--   (SELECT n FROM left_join_count)  AS rows_after_store_join,
--   (SELECT n FROM inner_join_count) AS rows_after_pgh_join,
--   ((SELECT n FROM left_join_count) - (SELECT n FROM inner_join_count)) AS dropped_by_pgh_join,
--   SAFE_DIVIDE(
--     (SELECT n FROM left_join_count) - (SELECT n FROM inner_join_count),
--     (SELECT n FROM left_join_count)
--   ) AS drop_pct;
--
-- 3. Per-channel row counts (sanity-check that ECOMM and RETAIL both populated)
--
-- SELECT
--   SPLIT(product_code, '_')[OFFSET(1)] AS channel,
--   COUNT(*) AS n
-- FROM `lululemon-01042025.lulu_sourcing_dev.inventory_intermediate`
-- GROUP BY channel ORDER BY n DESC;
--
-- =============================================================================
-- IF YOU GET A "Name X not found" ERROR
-- =============================================================================
-- Verify the column names in your sourced raw tables:
--
-- SELECT table_name, column_name, data_type
-- FROM `lululemon-01042025.lulu_sourcing_dev.INFORMATION_SCHEMA.COLUMNS`
-- WHERE table_name IN ('inventory_snapshot', 'product_group_hierarchy', 'store_master_intermediate')
-- ORDER BY table_name, ordinal_position;
--
-- Common causes:
--   - DAG output uses different `view` value than expected (see Self Note
--     `ia_platform_sourcing_dag_behavior.md`)
--   - DAG added SYNCSTARTDATETIME (harmless — not referenced above)
--   - Raw schema uses different casing on a column name (BQ is case-insensitive
--     for column refs, so this should be transparent)
-- =============================================================================
