-- Lululemon fiscal calendar intermediate — periodic refresh (WIDE shape)
--
-- Same wide projection as create_fiscal_calendar_intermediate_full.sql.
-- Calendar is small (~4,746 rows): full replace each run is safe.
--
-- Wire into Self-Help Data Sourcing for fiscal_calendar_intermediate (Historic/SQL).

CREATE OR REPLACE TABLE `lululemon-01042025.lulu_sourcing_dev.fiscal_calendar_intermediate` AS
SELECT
  quarter_desc AS fiscal_quarter_name,
  QUARTER_KEY AS fiscal_quarter_name_abb,
  YEAR_ID * 100 + QUARTER_NUMBER AS fiscal_year_quarter,
  SAFE_CAST(REGEXP_REPLACE(CAST(DAY_ID AS STRING), '[^0-9]', '') AS INT64) AS date_id,
  UPPER(FORMAT_DATE('%A', DAY_ID)) AS fiscal_day_name,
  ROW_NUMBER() OVER (PARTITION BY YEAR_ID * 100 + QUARTER_NUMBER ORDER BY DAY_ID) AS fiscal_day_in_quarter,
  DENSE_RANK() OVER (
    PARTITION BY YEAR_ID * 100 + QUARTER_NUMBER
    ORDER BY YEAR_ID * 100 + MONTH_NUMBER
  ) AS fiscal_month_in_quarter,
  YEAR_ID * 100 + DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID) - 100 AS fiscal_prior_year_comp_week,
  DAY_ID AS calendar_date,
  RANK() OVER (PARTITION BY YEAR_ID ORDER BY DAY_ID) AS fiscal_day_in_year,
  FORMAT_DATE('%B', PARSE_DATE('%b', SPLIT(MONTH_DESC, ' ')[OFFSET(1)])) AS fiscal_month_name,
  SPLIT(MONTH_DESC, ' ')[OFFSET(1)] AS fiscal_month_name_abb,
  YEAR_ID * 100 + MONTH_NUMBER AS fiscal_year_period,
  DAY_NUMBER AS fiscal_day_in_week,
  YEAR_ID * 100 + MONTH_NUMBER AS fiscal_year_month,
  DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID) AS fiscal_week_in_year,
  MONTH_NUMBER AS fiscal_month,
  WEEK_NUMBER AS fiscal_week,
  YEAR_ID AS fiscal_year,
  WEEK_ID AS fiscal_year_week,
  MIN(DAY_ID) OVER (PARTITION BY WEEK_ID) AS fiscal_week_begin_date,
  MAX(DAY_ID) OVER (PARTITION BY WEEK_ID) AS fiscal_week_end_date,
  MIN(DAY_ID) OVER (PARTITION BY YEAR_ID * 100 + MONTH_NUMBER) AS fiscal_month_begin_date,
  MIN(DAY_ID) OVER (PARTITION BY YEAR_ID * 100 + QUARTER_NUMBER) AS fiscal_quarter_begin_date,
  MAX(DAY_ID) OVER (PARTITION BY YEAR_ID * 100 + QUARTER_NUMBER) AS fiscal_quarter_end_date,
  MIN(DAY_ID) OVER (PARTITION BY YEAR_ID) AS fiscal_year_begin_date,
  MAX(DAY_ID) OVER (PARTITION BY YEAR_ID) AS fiscal_year_end_date,
  QUARTER_NUMBER AS fiscal_quarter,
  ROW_NUMBER() OVER (PARTITION BY YEAR_ID ORDER BY DAY_ID) AS fiscal_day,
  DENSE_RANK() OVER (PARTITION BY YEAR_ID * 100 + MONTH_NUMBER ORDER BY WEEK_ID) AS fiscal_week_in_month,
  DENSE_RANK() OVER (PARTITION BY YEAR_ID * 100 + QUARTER_NUMBER ORDER BY WEEK_ID) AS fiscal_week_in_quarter,
  LEFT(UPPER(FORMAT_DATE('%A', DAY_ID)), 3) AS fiscal_day_name_abb,
  DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY YEAR_ID * 100 + MONTH_NUMBER) AS fiscal_month_in_year,
  DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY YEAR_ID * 100 + QUARTER_NUMBER) AS fiscal_quarter_in_year,
  CASE WHEN UPPER(FORMAT_DATE('%A', DAY_ID)) IN ('SATURDAY', 'SUNDAY') THEN 'N' ELSE 'Y' END AS weekday_indicator,
  ROW_NUMBER() OVER (PARTITION BY YEAR_ID * 100 + MONTH_NUMBER ORDER BY DAY_ID) AS fiscal_day_in_month,
  DAY_ID AS date,
  LAG(WEEK_ID, 7) OVER (ORDER BY WEEK_ID) AS fiscal_year_week_prior,
  CAST(NULL AS INT64) AS fiscal_month_in_season,
  CASE
    WHEN ROUND(DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID) / 2, 0) > 26 THEN 26
    ELSE ROUND(DENSE_RANK() OVER (PARTITION BY YEAR_ID ORDER BY WEEK_ID) / 2, 0)
  END AS fiscal_bi_week,
  ROW_NUMBER() OVER (PARTITION BY WEEK_ID ORDER BY DAY_ID) AS day_of_week,
  CAST(NULL AS INT64) AS fiscal_year_quarter_prior,
  SAFE_CAST(REGEXP_EXTRACT(SEASON_CODE, r'^(\d+)') AS INT64) AS fiscal_year_season,
  CAST(NULL AS INT64) AS fiscal_year_season_prior,
  CAST(NULL AS INT64) AS fiscal_quarter_in_season,
  CAST(NULL AS INT64) AS fiscal_week_in_season,
  MAX(DAY_ID) OVER (PARTITION BY YEAR_ID * 100 + MONTH_NUMBER) AS fiscal_month_end_date,
  CAST(NULL AS INT64) AS fiscal_year_week_2wa,
  MIN(DAY_ID) OVER (PARTITION BY SEASON_CODE) AS fiscal_season_begin_date,
  CAST(NULL AS INT64) AS fiscal_season_in_year,
  MAX(DAY_ID) OVER (PARTITION BY SEASON_CODE) AS fiscal_season_end_date,
  RANK() OVER (PARTITION BY SEASON_CODE ORDER BY DAY_ID ASC) AS fiscal_day_in_season,
  CAST(NULL AS INT64) AS fiscal_year_month_prior,
  CAST(NULL AS STRING) AS fiscal_season_name,
  CAST(NULL AS STRING) AS fiscal_season_name_abb,
  CAST(NULL AS INT64) AS fiscal_year_week_3wa,
  CAST(NULL AS STRING) AS holiday,
  CAST(NULL AS INT64) AS trend,
  CAST(NULL AS DATE) AS cal_week_start_day,
  CAST(NULL AS DATE) AS cal_week_end_day,
  CAST(NULL AS INT64) AS fiscal_half_year,
  CAST(NULL AS STRING) AS half_year_name,
  CURRENT_DATETIME() AS syncstartdatetime
FROM `lululemon-01042025.lulu_sourcing_dev.calendar_hierarchy`;
