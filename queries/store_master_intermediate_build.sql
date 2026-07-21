-- =============================================================================
-- STORE MASTER INTERMEDIATE — built from sourced raw locations + inline cleaning
-- =============================================================================
--
-- Inputs  :
--   `lulu_sourcing_dev.location_group_hierarchy`   (raw, sourced via DAG)
--   `lulu_sourcing_dev.location_details`           (raw, sourced via DAG)
-- =============================================================================

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.store_intermediate` AS

WITH
-- ----------------------------------------------------------------------------
-- Step 1: Clean location_group_hierarchy
--   LPAD(LOC_ID, 10, '0') + NULLIF(TRIM(...), '\N') over every STRING field
-- ----------------------------------------------------------------------------
lgh_cleaned AS (
  SELECT
    LPAD(CAST(LOC_ID AS STRING), 10, '0')                  AS LOC_ID,

    NULLIF(TRIM(BRAND_ID), '\\N')                          AS BRAND_ID,
    NULLIF(TRIM(BRAND_NAME), '\\N')                        AS BRAND_NAME,

    NULLIF(TRIM(MARKET_ID), '\\N')                         AS MARKET_ID,
    NULLIF(TRIM(MARKET_NAME), '\\N')                       AS MARKET_NAME,
    NULLIF(TRIM(PLANNING_MARKET_CURRENCY), '\\N')          AS PLANNING_MARKET_CURRENCY,

    NULLIF(TRIM(MARKET_CHANNEL_ID), '\\N')                 AS MARKET_CHANNEL_ID,
    NULLIF(TRIM(MARKET_CHANNEL_NAME), '\\N')               AS MARKET_CHANNEL_NAME,

    NULLIF(TRIM(SUB_MARKET_CHANNEL_ID), '\\N')             AS SUB_MARKET_CHANNEL_ID,
    NULLIF(TRIM(SUB_MARKET_CHANNEL_NAME), '\\N')           AS SUB_MARKET_CHANNEL_NAME,

    NULLIF(TRIM(LOC_NAME), '\\N')                          AS LOC_NAME,
    NULLIF(TRIM(LOC_TYPE), '\\N')                          AS LOC_TYPE,
    NULLIF(TRIM(LOC_FORMAT), '\\N')                        AS LOC_FORMAT,

    NULLIF(TRIM(CAST(PRIMARY_DC_ID AS STRING)), '\\N')     AS PRIMARY_DC_ID,

    NULLIF(TRIM(MFP_PLANNING_TYPE), '\\N')                 AS MFP_PLANNING_TYPE,
    NULLIF(TRIM(COUNTRY_ID), '\\N')                        AS COUNTRY_ID,
    NULLIF(TRIM(COUNTRY_NAME), '\\N')                      AS COUNTRY_NAME,
    NULLIF(TRIM(CURRENCY_ID), '\\N')                       AS CURRENCY_ID,
    NULLIF(TRIM(POSTAL_CODE), '\\N')                       AS POSTAL_CODE,

    NULLIF(TRIM(OPERATIONAL_OPEN_DAY_ID), '\\N')           AS OPERATIONAL_OPEN_DAY_ID,
    NULLIF(TRIM(OPERATIONAL_CLOSE_DAY_ID), '\\N')          AS OPERATIONAL_CLOSE_DAY_ID,
    NULLIF(TRIM(MPA_OPEN_DAY_ID), '\\N')                   AS MPA_OPEN_DAY_ID,
    NULLIF(TRIM(MPA_CLOSE_DAY_ID), '\\N')                  AS MPA_CLOSE_DAY_ID,

    NULLIF(TRIM(REGION_ID), '\\N')                         AS REGION_ID,
    NULLIF(TRIM(REGION_NAME), '\\N')                       AS REGION_NAME,
    NULLIF(TRIM(AREA_ID), '\\N')                           AS AREA_ID,
    NULLIF(TRIM(AREA_NAME), '\\N')                         AS AREA_NAME,

    NULLIF(TRIM(PHYSICAL_COUNTRY_ID), '\\N')               AS PHYSICAL_COUNTRY_ID,
    NULLIF(TRIM(SERVICE_COUNTRY_ID), '\\N')                AS SERVICE_COUNTRY_ID,
    NULLIF(TRIM(EXTERNAL_ID), '\\N')                       AS EXTERNAL_ID,

    NULLIF(TRIM(GEO_REGION_ID), '\\N')                     AS GEO_REGION_ID,
    NULLIF(TRIM(GEO_REGION_NAME), '\\N')                   AS GEO_REGION_NAME,
    NULLIF(TRIM(GEO_REGION_CHANNEL_ID), '\\N')             AS GEO_REGION_CHANNEL_ID,
    NULLIF(TRIM(GEO_REGION_CHANNEL_NAME), '\\N')           AS GEO_REGION_CHANNEL_NAME,

    NULLIF(TRIM(PHYSICAL_DC_ID), '\\N')                    AS PHYSICAL_DC_ID,
    NULLIF(TRIM(CITY), '\\N')                              AS CITY,
    NULLIF(TRIM(STATE), '\\N')                             AS STATE,
    NULLIF(TRIM(LONGITUDE), '\\N')                         AS LONGITUDE,
    NULLIF(TRIM(LATITUDE), '\\N')                          AS LATITUDE,
    NULLIF(TRIM(LOC_CLOSED_IND), '\\N')                    AS LOC_CLOSED_IND,

    PLACEHOLDER_FLAG,
    DC_DIRECT_DEMAND,
    DELETE_IND
  FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
),

-- ----------------------------------------------------------------------------
-- Step 2: Clean location_details (same recipe)
-- ----------------------------------------------------------------------------
ld_cleaned AS (
  SELECT
    LPAD(CAST(ID AS STRING), 10, '0')                      AS ID,

    NULLIF(TRIM(DISPLAY_NAME), '\\N')                      AS DISPLAY_NAME,
    NULLIF(TRIM(TYPE_CODE), '\\N')                         AS TYPE_CODE,
    NULLIF(TRIM(COUNTRY_CODE), '\\N')                      AS COUNTRY_CODE,
    NULLIF(TRIM(CHANNEL_CODE), '\\N')                      AS CHANNEL_CODE,
    NULLIF(TRIM(STATE), '\\N')                             AS STATE,
    NULLIF(TRIM(REGION), '\\N')                            AS REGION,
    NULLIF(TRIM(CITY), '\\N')                              AS CITY,
    NULLIF(TRIM(POSTAL_CODE), '\\N')                       AS POSTAL_CODE,

    FIRST_OPEN_DATE,
    NULLIF(TRIM(PERMANANENT_CLOSE_DATE), '\\N')            AS PERMANANENT_CLOSE_DATE,

    LATITUDE,
    LONGITUDE,
    DELETE_IND
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
)

-- ----------------------------------------------------------------------------
-- Step 3: Build store_master shape (LEFT JOIN + columnar transforms)
--   Column order matches the canonical store_master schema (s0...s4, channel,
--   then the rest). The aliases use the semantically-correct mapping per
--   IA-platform convention: s0=brand, s1=market/channel, s2=country, s3=area,
--   s4=region. NOTE: production today may have these positions populated by
--   AREA/REGION/COUNTRY/CHANNEL/CHANNEL/BRAND respectively, due to a position-
--   based INSERT bug in the original 2025-11-20 09:54 build by shreyansh.
--   See chat history 2026-05-14 for diagnosis.
-- ----------------------------------------------------------------------------
SELECT DISTINCT
  a.BRAND_NAME                                             AS s0_name,
  SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]         AS s1_name,
  a.COUNTRY_NAME                                           AS s2_name,
  a.AREA_NAME                                              AS s3_name,
  a.REGION_NAME                                            AS s4_name,
  SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]         AS channel,
  a.LOC_NAME                                               AS store_name,
  a.LONGITUDE                                              AS longitude,
  a.LATITUDE                                               AS latitude,
  0                                                        AS location_attrib_squareft,
  a.LOC_FORMAT                                             AS store_format_code,
  a.LOC_TYPE                                               AS loc_type_code,
  b.TYPE_CODE                                              AS ws_channel,
  CONCAT(a.LOC_ID, '_', a.LOC_NAME)                        AS location_num_store_name,
  a.POSTAL_CODE                                            AS zipcode,
  a.LOC_ID                                                 AS store_code,
  a.AREA_ID                                                AS s3_id,
  CONCAT(a.REGION_ID, '_', COALESCE(a.REGION_NAME, ''))    AS location_hierarchy_region_code,
  a.BRAND_NAME                                             AS company_name,
  a.SUB_MARKET_CHANNEL_ID                                  AS channel_code,
  a.OPERATIONAL_OPEN_DAY_ID                                AS open_date,
  a.OPERATIONAL_CLOSE_DAY_ID                               AS close_date,
  CASE WHEN UPPER(a.LOC_TYPE) = 'S' THEN 'Store' ELSE 'DC' END AS store_type,
  a.BRAND_ID                                               AS company_code,
  a.LOC_CLOSED_IND                                         AS active,
  a.GEO_REGION_NAME                                        AS geography,
  CASE WHEN UPPER(a.LOC_TYPE) = 'W' THEN 1 ELSE 0 END      AS dc_flag,
  NULL                                                     AS special_classification,
  a.AREA_NAME                                              AS district_name,
  a.REGION_NAME                                            AS region,
  a.LOC_ID                                                 AS like_store_id,
  a.DELETE_IND                                             AS is_deleted,
  a.CITY                                                   AS city,
  a.STATE                                                  AS state
FROM      lgh_cleaned a
LEFT JOIN ld_cleaned   b ON a.LOC_ID = b.ID;


-- =============================================================================
-- POST-BUILD VALIDATION (run separately after the CTAS finishes)
-- =============================================================================
--
-- 1. Row count + grain integrity (store_code should be unique)
--
-- SELECT
--   COUNT(*)                          AS total_rows,
--   COUNT(DISTINCT store_code)        AS distinct_stores,
--   COUNTIF(store_code IS NULL)       AS null_store_code,
--   COUNTIF(ws_channel IS NULL)       AS missing_location_details_match
-- FROM `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate`;
--
-- 2. DC vs Store split (sanity check on the CASE expressions)
--
-- SELECT store_type, dc_flag, COUNT(*) AS n
-- FROM `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate`
-- GROUP BY 1, 2 ORDER BY 1, 2;
--
-- 3. Distinct channel values (should be RETAIL / ECOMM only after the SPLIT)
--
-- SELECT channel, COUNT(*) AS n
-- FROM `lululemon-01042025.lulu_sourcing_dev.store_master_intermediate`
-- GROUP BY 1 ORDER BY n DESC;
--
-- =============================================================================
-- IF YOU GET A "Name X not found" ERROR
-- =============================================================================
-- Your Sourcing DAG output may differ from the raw _20251119 schema. Verify
-- which columns actually exist in your sourced tables:
--
-- SELECT column_name, data_type
-- FROM `lululemon-01042025.lulu_sourcing_dev.INFORMATION_SCHEMA.COLUMNS`
-- WHERE table_name IN ('location_group_hierarchy', 'location_details')
-- ORDER BY table_name, ordinal_position;
--
-- If the Sourcing DAG added a `SYNCSTARTDATETIME` column (per Lululemon BQ
-- context — Sourcing DAG behavior), it's harmless: just doesn't get selected
-- in the cleaning CTEs above. No action needed unless you want to carry it
-- through to the intermediate output.
-- =============================================================================
