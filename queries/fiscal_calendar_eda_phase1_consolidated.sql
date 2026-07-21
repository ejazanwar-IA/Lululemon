-- =============================================================================
-- Fiscal Calendar EDA - Phase 1 CONSOLIDATED
--
-- Table: lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy
--        (4,746 rows, 1.5 MB) — tiny, cheap, comprehensive
--
-- 8 queries, single consolidated output.
-- =============================================================================

WITH

-- ========== Q1: Shape ==========
q1 AS (
  SELECT
    'Q1' AS query_id,
    'Shape: row count, date range, distinct hierarchy IDs' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNT(DISTINCT DAY_ID) AS distinct_day_id,
      COUNT(DISTINCT WEEK_ID) AS distinct_week_id,
      COUNT(DISTINCT WEEK_KEY) AS distinct_week_key,
      COUNT(DISTINCT MONTH_ID) AS distinct_month_id,
      COUNT(DISTINCT QUARTER_ID) AS distinct_quarter_id,
      COUNT(DISTINCT YEAR_ID) AS distinct_year_id,
      COUNT(DISTINCT SEASON_CODE) AS distinct_season_code,
      COUNT(DISTINCT BUYING_PERIOD) AS distinct_buying_period,
      MIN(DAY_ID) AS min_day,
      MAX(DAY_ID) AS max_day,
      DATE_DIFF(MAX(DAY_ID), MIN(DAY_ID), DAY) + 1 AS calendar_span_days,
      MIN(YEAR_ID) AS min_year,
      MAX(YEAR_ID) AS max_year
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
),

-- ========== Q2: Null counts per column (all 37) ==========
q2 AS (
  SELECT
    'Q2' AS query_id,
    'Null counts per column' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      -- DATE columns (IS NULL only — DATE can't compare to '')
      COUNTIF(DAY_ID IS NULL) AS null_day_id,
      COUNTIF(DAY_KEY IS NULL) AS null_day_key,
      COUNTIF(DAY_DESC IS NULL) AS null_day_desc,
      COUNTIF(WEEK_START_DAY_ID IS NULL) AS null_week_start_day_id,
      COUNTIF(WEEK_END_DAY_ID IS NULL) AS null_week_end_day_id,
      COUNTIF(QUARTER_START_DAY_ID IS NULL) AS null_quarter_start_day_id,
      COUNTIF(QUARTER_END_DAY_ID IS NULL) AS null_quarter_end_day_id,
      -- INT64
      COUNTIF(DAY_SID IS NULL) AS null_day_sid,
      COUNTIF(DAY_NUMBER IS NULL) AS null_day_number,
      COUNTIF(WEEK_ID IS NULL) AS null_week_id,
      COUNTIF(WEEK_NUMBER IS NULL) AS null_week_number,
      COUNTIF(WEEK_OF_YEAR IS NULL) AS null_week_of_year,
      COUNTIF(MONTH_WEEK_NUMBER IS NULL) AS null_month_week_number,
      COUNTIF(MONTH_ID IS NULL) AS null_month_id,
      COUNTIF(MONTH_NUMBER IS NULL) AS null_month_number,
      COUNTIF(QUARTER_ID IS NULL) AS null_quarter_id,
      COUNTIF(QUARTER_NUMBER IS NULL) AS null_quarter_number,
      COUNTIF(YEAR_ID IS NULL) AS null_year_id,
      COUNTIF(YEAR_KEY IS NULL) AS null_year_key,
      COUNTIF(WEEK_SERIAL_NUMBER IS NULL) AS null_week_serial_number,
      COUNTIF(QUARTER_SERIAL_NUMBER IS NULL) AS null_quarter_serial_number,
      COUNTIF(ADJUSTED_LY_WEEK_ID IS NULL) AS null_adjusted_ly_week_id,
      COUNTIF(ADJUSTED_2LY_WEEK_ID IS NULL) AS null_adjusted_2ly_week_id,
      -- STRING columns (NULL / '' / '\N')
      COUNTIF(WEEK_KEY IS NULL OR WEEK_KEY = '' OR WEEK_KEY = '\\N') AS null_week_key,
      COUNTIF(WEEK_DESC IS NULL OR WEEK_DESC = '' OR WEEK_DESC = '\\N') AS null_week_desc,
      COUNTIF(MONTH_WEEK_KEY IS NULL OR MONTH_WEEK_KEY = '' OR MONTH_WEEK_KEY = '\\N') AS null_month_week_key,
      COUNTIF(MONTH_KEY IS NULL OR MONTH_KEY = '' OR MONTH_KEY = '\\N') AS null_month_key,
      COUNTIF(MONTH_DESC IS NULL OR MONTH_DESC = '' OR MONTH_DESC = '\\N') AS null_month_desc,
      COUNTIF(QUARTER_KEY IS NULL OR QUARTER_KEY = '' OR QUARTER_KEY = '\\N') AS null_quarter_key,
      COUNTIF(QUARTER_DESC IS NULL OR QUARTER_DESC = '' OR QUARTER_DESC = '\\N') AS null_quarter_desc,
      COUNTIF(SEASON_CODE IS NULL OR SEASON_CODE = '' OR SEASON_CODE = '\\N') AS null_season_code,
      COUNTIF(BUYING_PERIOD IS NULL OR BUYING_PERIOD = '' OR BUYING_PERIOD = '\\N') AS null_buying_period,
      COUNTIF(WEEK_SID IS NULL OR WEEK_SID = '' OR WEEK_SID = '\\N') AS null_week_sid,
      COUNTIF(MONTH_SID IS NULL OR MONTH_SID = '' OR MONTH_SID = '\\N') AS null_month_sid,
      COUNTIF(QUARTER_SID IS NULL OR QUARTER_SID = '' OR QUARTER_SID = '\\N') AS null_quarter_sid,
      COUNTIF(ADJUSTED_LY_WEEK_SID IS NULL OR ADJUSTED_LY_WEEK_SID = '' OR ADJUSTED_LY_WEEK_SID = '\\N') AS null_adjusted_ly_week_sid,
      COUNTIF(ADJUSTED_2LY_WEEK_SID IS NULL OR ADJUSTED_2LY_WEEK_SID = '' OR ADJUSTED_2LY_WEEK_SID = '\\N') AS null_adjusted_2ly_week_sid
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
),

-- ========== Q3: Duplicates at DAY_ID ==========
q3 AS (
  SELECT
    'Q3' AS query_id,
    'Duplicates at DAY_ID (should be 0 for 1-row-per-day)' AS description,
    TO_JSON_STRING(STRUCT(
      COUNT(*) AS total_rows,
      COUNT(DISTINCT DAY_ID) AS distinct_days,
      COUNT(*) - COUNT(DISTINCT DAY_ID) AS duplicate_row_count
    )) AS results_json
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
),

-- ========== Q4: Years covered + weeks/days per year ==========
q4_rows AS (
  SELECT
    YEAR_ID,
    COUNT(*) AS days,
    COUNT(DISTINCT WEEK_ID) AS distinct_weeks,
    COUNT(DISTINCT MONTH_ID) AS distinct_months,
    COUNT(DISTINCT QUARTER_ID) AS distinct_quarters,
    COUNT(DISTINCT SEASON_CODE) AS distinct_seasons,
    COUNT(DISTINCT BUYING_PERIOD) AS distinct_bps,
    MIN(DAY_ID) AS min_day,
    MAX(DAY_ID) AS max_day
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
  GROUP BY YEAR_ID
  ORDER BY YEAR_ID
),
q4 AS (
  SELECT
    'Q4' AS query_id,
    'Years covered: days/weeks/months/quarters per fiscal year' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(YEAR_ID, days, distinct_weeks, distinct_months, distinct_quarters, distinct_seasons, distinct_bps, min_day, max_day) ORDER BY YEAR_ID)) AS results_json
  FROM q4_rows
),

-- ========== Q5: Hierarchy consistency ==========
-- Each DAY should map to exactly 1 WEEK, MONTH, QUARTER, YEAR, SEASON
-- Plus: each WEEK to exactly 1 MONTH, each MONTH to 1 QUARTER, etc.
q5_rows AS (
  -- Each day in > 1 week
  SELECT 'day_has_multi_weeks' AS check_name,
         (SELECT COUNT(*) FROM (SELECT DAY_ID FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` GROUP BY DAY_ID HAVING COUNT(DISTINCT WEEK_ID) > 1)) AS failing_count
  UNION ALL SELECT 'week_has_multi_months',
         (SELECT COUNT(*) FROM (SELECT WEEK_ID FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` GROUP BY WEEK_ID HAVING COUNT(DISTINCT MONTH_ID) > 1))
  UNION ALL SELECT 'week_has_multi_quarters',
         (SELECT COUNT(*) FROM (SELECT WEEK_ID FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` GROUP BY WEEK_ID HAVING COUNT(DISTINCT QUARTER_ID) > 1))
  UNION ALL SELECT 'month_has_multi_quarters',
         (SELECT COUNT(*) FROM (SELECT MONTH_ID FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` GROUP BY MONTH_ID HAVING COUNT(DISTINCT QUARTER_ID) > 1))
  UNION ALL SELECT 'quarter_has_multi_years',
         (SELECT COUNT(*) FROM (SELECT QUARTER_ID FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` GROUP BY QUARTER_ID HAVING COUNT(DISTINCT YEAR_ID) > 1))
  UNION ALL SELECT 'quarter_has_multi_seasons',
         (SELECT COUNT(*) FROM (SELECT QUARTER_ID FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` GROUP BY QUARTER_ID HAVING COUNT(DISTINCT SEASON_CODE) > 1))
  UNION ALL SELECT 'season_has_multi_buying_periods',
         (SELECT COUNT(*) FROM (SELECT SEASON_CODE FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` GROUP BY SEASON_CODE HAVING COUNT(DISTINCT BUYING_PERIOD) > 1))
),
q5 AS (
  SELECT
    'Q5' AS query_id,
    'Hierarchy consistency (all should be 0)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(check_name, failing_count))) AS results_json
  FROM q5_rows
),

-- ========== Q6: SEASON_CODE + BUYING_PERIOD mapping ==========
q6_rows AS (
  SELECT
    SEASON_CODE,
    ANY_VALUE(BUYING_PERIOD) AS buying_period,
    ANY_VALUE(QUARTER_DESC) AS quarter_desc,
    COUNT(*) AS days,
    MIN(DAY_ID) AS season_start,
    MAX(DAY_ID) AS season_end
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
  GROUP BY SEASON_CODE
  ORDER BY season_start
),
q6 AS (
  SELECT
    'Q6' AS query_id,
    'SEASON_CODE <-> BUYING_PERIOD mapping (1 row per season)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(SEASON_CODE, buying_period, quarter_desc, days, season_start, season_end) ORDER BY season_start)) AS results_json
  FROM q6_rows
),

-- ========== Q7: ADJUSTED_LY_WEEK_ID analysis ==========
q7_summary AS (
  SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ADJUSTED_LY_WEEK_ID) AS distinct_ly_week_id,
    COUNT(DISTINCT ADJUSTED_2LY_WEEK_ID) AS distinct_2ly_week_id,
    COUNTIF(ADJUSTED_LY_WEEK_ID = 201401) AS rows_with_ly_201401,
    COUNTIF(ADJUSTED_2LY_WEEK_ID = 201301) AS rows_with_2ly_201301,
    MIN(ADJUSTED_LY_WEEK_ID) AS min_ly_week_id,
    MAX(ADJUSTED_LY_WEEK_ID) AS max_ly_week_id,
    MIN(ADJUSTED_2LY_WEEK_ID) AS min_2ly_week_id,
    MAX(ADJUSTED_2LY_WEEK_ID) AS max_2ly_week_id
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
),
q7_distribution AS (
  SELECT ADJUSTED_LY_WEEK_ID, COUNT(*) AS cnt
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
  GROUP BY ADJUSTED_LY_WEEK_ID
  ORDER BY cnt DESC
  LIMIT 10
),
q7 AS (
  SELECT
    'Q7' AS query_id,
    'ADJUSTED_LY_WEEK_ID verification (samples showed 201401 for all rows)' AS description,
    TO_JSON_STRING(STRUCT(
      (SELECT AS STRUCT * FROM q7_summary) AS summary,
      (SELECT ARRAY_AGG(STRUCT(ADJUSTED_LY_WEEK_ID, cnt)) FROM q7_distribution) AS top_10_ly_values
    )) AS results_json
),

-- ========== Q8: DAY_NUMBER → weekday consistency ==========
-- DAY_NUMBER 1 should always be Monday, 7 should be Sunday
q8_rows AS (
  SELECT
    DAY_NUMBER,
    FORMAT_DATE('%A', DAY_ID) AS weekday_name,
    COUNT(*) AS cnt
  FROM `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy`
  WHERE DAY_ID IS NOT NULL AND DAY_NUMBER IS NOT NULL
  GROUP BY DAY_NUMBER, weekday_name
  ORDER BY DAY_NUMBER, cnt DESC
),
q8 AS (
  SELECT
    'Q8' AS query_id,
    'DAY_NUMBER → actual weekday consistency (1=Mon should always be Monday)' AS description,
    TO_JSON_STRING(ARRAY_AGG(STRUCT(DAY_NUMBER, weekday_name, cnt))) AS results_json
  FROM q8_rows
)

SELECT * FROM q1
UNION ALL SELECT * FROM q2
UNION ALL SELECT * FROM q3
UNION ALL SELECT * FROM q4
UNION ALL SELECT * FROM q5
UNION ALL SELECT * FROM q6
UNION ALL SELECT * FROM q7
UNION ALL SELECT * FROM q8
ORDER BY query_id;
