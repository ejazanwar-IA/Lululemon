-- Lululemon periodic store intermediate build
--
-- Platform pattern: filter_param from mapping, temp from incremental location feeds,
-- MERGE into live intermediate, drop temp.
--
-- Sources (all lulu_sourcing_dev):
--   location_group_hierarchy, location_details
-- Incremental: SYNCSTARTDATETIME > filter_param on either feed; rebuild affected store_code rows
-- MERGE key: store_code (1,853 rows live; grain verified unique)
--
-- Transformation: queries/store_master_intermediate_build.sql
--
-- Self-Help prerequisites:
--   mapping.intermediate_table = 'store_intermediate' (is_deleted = FALSE)
--   view_mapping_table views = location_details, location_group_hierarchy for table = store

DECLARE filter_param DATETIME DEFAULT (
  SELECT COALESCE(
    MAX(COALESCE(DATETIME(filter_param), DATETIME(dataingestion_filterparam))),
    DATETIME('1900-01-01 00:00:00')
  )
  FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
  WHERE is_deleted = FALSE
    AND intermediate_table = 'store_intermediate'
);

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.store_intermediate_temp` AS
WITH changed_loc_ids AS (
  SELECT DISTINCT LPAD(CAST(LOC_ID AS STRING), 10, '0') AS loc_id
  FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
  WHERE SYNCSTARTDATETIME > filter_param
  UNION DISTINCT
  SELECT DISTINCT LPAD(CAST(ID AS STRING), 10, '0') AS loc_id
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
  WHERE SYNCSTARTDATETIME > filter_param
),
lgh_cleaned AS (
  SELECT
    LPAD(CAST(LOC_ID AS STRING), 10, '0') AS LOC_ID,
    NULLIF(TRIM(BRAND_ID), '\\N') AS BRAND_ID,
    NULLIF(TRIM(BRAND_NAME), '\\N') AS BRAND_NAME,
    NULLIF(TRIM(MARKET_ID), '\\N') AS MARKET_ID,
    NULLIF(TRIM(MARKET_NAME), '\\N') AS MARKET_NAME,
    NULLIF(TRIM(PLANNING_MARKET_CURRENCY), '\\N') AS PLANNING_MARKET_CURRENCY,
    NULLIF(TRIM(MARKET_CHANNEL_ID), '\\N') AS MARKET_CHANNEL_ID,
    NULLIF(TRIM(MARKET_CHANNEL_NAME), '\\N') AS MARKET_CHANNEL_NAME,
    NULLIF(TRIM(SUB_MARKET_CHANNEL_ID), '\\N') AS SUB_MARKET_CHANNEL_ID,
    NULLIF(TRIM(SUB_MARKET_CHANNEL_NAME), '\\N') AS SUB_MARKET_CHANNEL_NAME,
    NULLIF(TRIM(LOC_NAME), '\\N') AS LOC_NAME,
    NULLIF(TRIM(LOC_TYPE), '\\N') AS LOC_TYPE,
    NULLIF(TRIM(LOC_FORMAT), '\\N') AS LOC_FORMAT,
    NULLIF(TRIM(CAST(PRIMARY_DC_ID AS STRING)), '\\N') AS PRIMARY_DC_ID,
    NULLIF(TRIM(MFP_PLANNING_TYPE), '\\N') AS MFP_PLANNING_TYPE,
    NULLIF(TRIM(COUNTRY_ID), '\\N') AS COUNTRY_ID,
    NULLIF(TRIM(COUNTRY_NAME), '\\N') AS COUNTRY_NAME,
    NULLIF(TRIM(CURRENCY_ID), '\\N') AS CURRENCY_ID,
    NULLIF(TRIM(POSTAL_CODE), '\\N') AS POSTAL_CODE,
    NULLIF(TRIM(OPERATIONAL_OPEN_DAY_ID), '\\N') AS OPERATIONAL_OPEN_DAY_ID,
    NULLIF(TRIM(OPERATIONAL_CLOSE_DAY_ID), '\\N') AS OPERATIONAL_CLOSE_DAY_ID,
    NULLIF(TRIM(MPA_OPEN_DAY_ID), '\\N') AS MPA_OPEN_DAY_ID,
    NULLIF(TRIM(MPA_CLOSE_DAY_ID), '\\N') AS MPA_CLOSE_DAY_ID,
    NULLIF(TRIM(REGION_ID), '\\N') AS REGION_ID,
    NULLIF(TRIM(REGION_NAME), '\\N') AS REGION_NAME,
    NULLIF(TRIM(AREA_ID), '\\N') AS AREA_ID,
    NULLIF(TRIM(AREA_NAME), '\\N') AS AREA_NAME,
    NULLIF(TRIM(PHYSICAL_COUNTRY_ID), '\\N') AS PHYSICAL_COUNTRY_ID,
    NULLIF(TRIM(SERVICE_COUNTRY_ID), '\\N') AS SERVICE_COUNTRY_ID,
    NULLIF(TRIM(EXTERNAL_ID), '\\N') AS EXTERNAL_ID,
    NULLIF(TRIM(GEO_REGION_ID), '\\N') AS GEO_REGION_ID,
    NULLIF(TRIM(GEO_REGION_NAME), '\\N') AS GEO_REGION_NAME,
    NULLIF(TRIM(GEO_REGION_CHANNEL_ID), '\\N') AS GEO_REGION_CHANNEL_ID,
    NULLIF(TRIM(GEO_REGION_CHANNEL_NAME), '\\N') AS GEO_REGION_CHANNEL_NAME,
    NULLIF(TRIM(PHYSICAL_DC_ID), '\\N') AS PHYSICAL_DC_ID,
    NULLIF(TRIM(CITY), '\\N') AS CITY,
    NULLIF(TRIM(STATE), '\\N') AS STATE,
    NULLIF(TRIM(LONGITUDE), '\\N') AS LONGITUDE,
    NULLIF(TRIM(LATITUDE), '\\N') AS LATITUDE,
    NULLIF(TRIM(LOC_CLOSED_IND), '\\N') AS LOC_CLOSED_IND,
    PLACEHOLDER_FLAG,
    DC_DIRECT_DEMAND,
    DELETE_IND
  FROM `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy`
  WHERE LPAD(CAST(LOC_ID AS STRING), 10, '0') IN (SELECT loc_id FROM changed_loc_ids)
),
ld_cleaned AS (
  SELECT
    LPAD(CAST(ID AS STRING), 10, '0') AS ID,
    NULLIF(TRIM(DISPLAY_NAME), '\\N') AS DISPLAY_NAME,
    NULLIF(TRIM(TYPE_CODE), '\\N') AS TYPE_CODE,
    NULLIF(TRIM(COUNTRY_CODE), '\\N') AS COUNTRY_CODE,
    NULLIF(TRIM(CHANNEL_CODE), '\\N') AS CHANNEL_CODE,
    NULLIF(TRIM(STATE), '\\N') AS STATE,
    NULLIF(TRIM(REGION), '\\N') AS REGION,
    NULLIF(TRIM(CITY), '\\N') AS CITY,
    NULLIF(TRIM(POSTAL_CODE), '\\N') AS POSTAL_CODE,
    FIRST_OPEN_DATE,
    NULLIF(TRIM(PERMANANENT_CLOSE_DATE), '\\N') AS PERMANANENT_CLOSE_DATE,
    LATITUDE,
    LONGITUDE,
    DELETE_IND
  FROM `lululemon-01042025.lulu_sourcing_dev.location_details`
  WHERE LPAD(CAST(ID AS STRING), 10, '0') IN (SELECT loc_id FROM changed_loc_ids)
)
SELECT DISTINCT
  a.BRAND_NAME AS s0_name,
  SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)] AS s1_name,
  a.COUNTRY_NAME AS s2_name,
  a.AREA_NAME AS s3_name,
  a.REGION_NAME AS s4_name,
  SPLIT(a.SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)] AS channel,
  a.LOC_NAME AS store_name,
  a.LONGITUDE AS longitude,
  a.LATITUDE AS latitude,
  0 AS location_attrib_squareft,
  a.LOC_FORMAT AS store_format_code,
  a.LOC_TYPE AS loc_type_code,
  b.TYPE_CODE AS ws_channel,
  CONCAT(a.LOC_ID, '_', a.LOC_NAME) AS location_num_store_name,
  a.POSTAL_CODE AS zipcode,
  a.LOC_ID AS store_code,
  a.AREA_ID AS s3_id,
  CONCAT(a.REGION_ID, '_', COALESCE(a.REGION_NAME, '')) AS location_hierarchy_region_code,
  a.BRAND_NAME AS company_name,
  a.SUB_MARKET_CHANNEL_ID AS channel_code,
  a.OPERATIONAL_OPEN_DAY_ID AS open_date,
  a.OPERATIONAL_CLOSE_DAY_ID AS close_date,
  CASE WHEN UPPER(a.LOC_TYPE) = 'S' THEN 'Store' ELSE 'DC' END AS store_type,
  a.BRAND_ID AS company_code,
  a.LOC_CLOSED_IND AS active,
  a.GEO_REGION_NAME AS geography,
  CASE WHEN UPPER(a.LOC_TYPE) = 'W' THEN 1 ELSE 0 END AS dc_flag,
  CAST(NULL AS INT64) AS special_classification,
  a.AREA_NAME AS district_name,
  a.REGION_NAME AS region,
  a.LOC_ID AS like_store_id,
  a.DELETE_IND AS is_deleted,
  a.CITY AS city,
  a.STATE AS state
FROM lgh_cleaned a
LEFT JOIN ld_cleaned b ON a.LOC_ID = b.ID;

MERGE `lululemon-01042025.lulu_sourcing_dev.store_intermediate` DL
USING `lululemon-01042025.lulu_sourcing_dev.store_intermediate_temp` A
ON DL.store_code = A.store_code

WHEN MATCHED THEN UPDATE SET
  DL.s0_name = A.s0_name,
  DL.s1_name = A.s1_name,
  DL.s2_name = A.s2_name,
  DL.s3_name = A.s3_name,
  DL.s4_name = A.s4_name,
  DL.channel = A.channel,
  DL.store_name = A.store_name,
  DL.longitude = A.longitude,
  DL.latitude = A.latitude,
  DL.location_attrib_squareft = A.location_attrib_squareft,
  DL.store_format_code = A.store_format_code,
  DL.loc_type_code = A.loc_type_code,
  DL.ws_channel = A.ws_channel,
  DL.location_num_store_name = A.location_num_store_name,
  DL.zipcode = A.zipcode,
  DL.s3_id = A.s3_id,
  DL.location_hierarchy_region_code = A.location_hierarchy_region_code,
  DL.company_name = A.company_name,
  DL.channel_code = A.channel_code,
  DL.open_date = A.open_date,
  DL.close_date = A.close_date,
  DL.store_type = A.store_type,
  DL.company_code = A.company_code,
  DL.active = A.active,
  DL.geography = A.geography,
  DL.dc_flag = A.dc_flag,
  DL.special_classification = A.special_classification,
  DL.district_name = A.district_name,
  DL.region = A.region,
  DL.like_store_id = A.like_store_id,
  DL.is_deleted = A.is_deleted,
  DL.city = A.city,
  DL.state = A.state

WHEN NOT MATCHED THEN INSERT (
  s0_name,
  s1_name,
  s2_name,
  s3_name,
  s4_name,
  channel,
  store_name,
  longitude,
  latitude,
  location_attrib_squareft,
  store_format_code,
  loc_type_code,
  ws_channel,
  location_num_store_name,
  zipcode,
  store_code,
  s3_id,
  location_hierarchy_region_code,
  company_name,
  channel_code,
  open_date,
  close_date,
  store_type,
  company_code,
  active,
  geography,
  dc_flag,
  special_classification,
  district_name,
  region,
  like_store_id,
  is_deleted,
  city,
  state
)
VALUES (
  A.s0_name,
  A.s1_name,
  A.s2_name,
  A.s3_name,
  A.s4_name,
  A.channel,
  A.store_name,
  A.longitude,
  A.latitude,
  A.location_attrib_squareft,
  A.store_format_code,
  A.loc_type_code,
  A.ws_channel,
  A.location_num_store_name,
  A.zipcode,
  A.store_code,
  A.s3_id,
  A.location_hierarchy_region_code,
  A.company_name,
  A.channel_code,
  A.open_date,
  A.close_date,
  A.store_type,
  A.company_code,
  A.active,
  A.geography,
  A.dc_flag,
  A.special_classification,
  A.district_name,
  A.region,
  A.like_store_id,
  A.is_deleted,
  A.city,
  A.state
);

DROP TABLE IF EXISTS `lululemon-01042025.lulu_sourcing_dev.store_intermediate_temp`;
