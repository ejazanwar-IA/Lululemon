# Location Master

| Field | Value |
|---|---|
| Confluence page ID | `966361118` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966361118/Location+Master |
| Mirrored from | Impact Analytics Confluence (IA space) |
| Created (Confluence) | 2023-08-31T09:40:55.795Z |
| Last mirrored | 2026-05-21 |

---

**SUMMARY:**

  * Table contains details about all the stores and DCs, regarding their exact location, whether the store is clearance or full price store, the region in which the store lies (e.g. NA, APAC, MEA, etc.), whether the store is active or inactive, etc.




**EXPLANATION OF CODE:**

  * Level of data → store_id/ loc_num.

  * The code has been divided into 2 parts, one part is for 1066 active stores and DCs and the second part is for the 13 inactive DCs (These 13 inactive DC were requested by the clients to be added for now, and once the periodic ingestion starts, this union wont be required as IA will receive the feed with these inactive DC included)

  * The end date for all the Stores/ DC with blanks have been set to year 2099

  * Active/ Inactive/ Future Opening status is recalculated based on the start date and end date.

  * Few other columns are created to identify Domestic/ International locations etc




**LOCATION MASTER SOURCING QUERY:**
    
    
    CREATE OR REPLACE TABLE
      victorias-secret-393308.vs_sourcing_dev.store_intermediate AS
    WITH
      store_all AS (
      SELECT
        LPAD(LOC_NUM,4,'0') AS LOC_NUM,
        STORE_ID,
        BRAND_CODE,
        BRAND_NAME,
        CHANNEL_ID,
        CHANNEL_DESC,
        STORE_NAME,
        ZIP_CODE,
        STORE_FORMAT_CODE,
        IFNULL(STORE_OPEN_DATE, CAST('2000-01-01' AS date)) AS STORE_OPEN_DATE,
        IFNULL(STORE_CLOSE_DATE, CAST('2099-01-01' AS date)) AS STORE_CLOSE_DATE,
        STORE_TYPE,
        LOC_TYP_CD,
        LONGITUDE,
        LATITUDE,
        COUNTRY,
        DISTRICT,
        DISTRICT_CODE,
        REGION_CODE,
        CITY,
        STORE_SIZE,
        SISTERSTORECODE,
        STATE
      FROM
        victorias-secret-393308.vs_sourcing_dev.vs_store_list_final_v2
      UNION ALL
      SELECT
        LPAD(LOC_NUM,4,'0') AS LOC_NUM,
        STORE_ID,
        BRAND_CODE,
        BRAND_NAME,
        CHANNEL_ID,
        CHANNEL_DESC,
        STORE_NAME,
        ZIP_CODE,
        STORE_FORMAT_CODE,
        CAST('2000-01-01' AS date) AS STORE_OPEN_DATE,
        CAST('2000-01-02' AS date) AS STORE_CLOSE_DATE,
        STORE_TYPE,
        LOC_TYP_CD,
        LONGITUDE,
        LATITUDE,
        COUNTRY,
        DISTRICT,
        DISTRICT_CODE,
        REGION_CODE,
        CITY,
        STORE_SIZE,
        SISTERSTORECODE,
        STATE
      FROM
        victorias-secret-393308.vs_sourcing_dev.vs_store_master_v2
      WHERE
        loc_num IN ('S099',
          'S021',
          'S053',
          'S050',
          'S008',
          'S017',
          'S075',
          'S074',
          'S038',
          'S039',
          'S011',
          'S019',
          'S045') )
    SELECT
      *,
      CASE
        WHEN store_close_date < current_Date THEN 'Closed'
        WHEN store_close_date >= current_date
      AND store_open_date < current_date THEN 'Opened'
        WHEN store_open_date > current_date THEN 'Future Opening Store'
      ELSE
      NULL
    END
      AS store_status,
      CASE
        WHEN store_type = 'Partner Store' AND store_format_code = '12' THEN 'International Clearance'
        WHEN region_code IN (520,
        410)
      AND district_code IN (402,
        502)
      AND country IN ('United States',
        'Canada') THEN 'Domestic Clearance'
        WHEN country NOT IN ('United States', 'Canada') THEN 'International Full Price'
      ELSE
      'Domestic Full Price'
    END
      AS GEO_STORETYPE,
      CASE
        WHEN country IN ('United States', 'Canada') THEN 'Domestic'
      ELSE
      'International'
    END
      AS GEO_TAGGING,
    CASE
      when upper(loc_num) like 'S%' or upper(loc_num) like 'D%' then "DC"
      when upper(loc_num) like 'T%' then "SUBCONTRACTOR_VENDOR_SITE"
      else "STORE" end as STORE_CATEGORY,
    CASE
          WHEN COUNTRY IN ('Canada', 'United States') THEN 'NA'
          WHEN COUNTRY IN ('Panama','Costa Rica','El Salvador','Mexico') THEN 'CA'
          WHEN COUNTRY IN ('Peru', 'Paraguay', 'Colombia', 'Ecuador', 'Uruguay', 'Chile') THEN 'SA'
          WHEN COUNTRY IN ('Poland','Romania','Czech Republic','Italy','France','Spain','Portugal','United Kingdom','Ireland','Sweden','Netherlands') THEN 'EU'
          WHEN COUNTRY IN ('Kuwait', 'United Arab Emir.', 'Saudi Arabia', 'Turkey', 'Egypt', 'Qatar', 'Bahrain', 'Jordan', 'Oman', 'Israel') THEN 'MEA'
        ELSE 'APAC' END AS GEOGRAPHY,
    CASE
        WHEN store_close_date < current_Date THEN FALSE
        else TRUE end as ACTIVE,
      CAST(FORMAT_DATETIME('%Y-%m-%d %H:%M:%S',current_datetime()) AS DATETIME) AS SYNCSTARTDATETIME
    FROM
      store_all
