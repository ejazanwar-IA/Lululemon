# Fiscal Calendar

| Field | Value |
|---|---|
| Confluence page ID | `966459429` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966459429/Fiscal+Calendar |
| Mirrored from | Impact Analytics Confluence (IA space) |
| Created (Confluence) | 2023-08-31T09:44:27.176Z |
| Last mirrored | 2026-05-21 |

---

**SUMMARY:**

  * The table contains calendar date, along with various aspects of the calendar date like fiscal year number (2020) of the , fiscal quarter number, fiscal month number, fiscal week number, fiscal day number, and fiscal week day number (identifies the number of day in the week starting from Sunday as 1), etc.




**EXPLANATION OF CODE:**

  * The fiscal calendar data begins from 2020-02-02, this being the first day of fiscal year.

  * Fiscal year week is a calculated field which is concatenation of fiscal year number and fiscal week number.

  * Fiscal year month has been renamed as fiscal month num to maintain uniformity in naming.




**FISCAL CALENDAR SOURCING QUERY:**
    
    
    CREATE OR REPLACE TABLE
      victorias-secret-393308.vs_sourcing_dev.fiscal_calendar_intermediate AS
    SELECT
      CAL_DATE AS `DATE`,
      CAL_DATE,
      FISCAL_YEAR_NUM,
      FISCAL_QUARTER_NUM,
      FISCAL_YEAR_MONTH AS FISCAL_MONTH_NUM,
      FISCAL_WEEK_NUM,
      FISCAL_DAY_NUM,
      FISCAL_WEEK_DAY_NUM,
      FISCAL_YEAR_QTR,
      CAST(CONCAT(FISCAL_YEAR_NUM, LPAD(CAST(FISCAL_WEEK_NUM AS STRING),2,'0')) AS INT64) AS FISCAL_YEAR_WEEK,
      CAST(FORMAT_DATETIME('%Y-%m-%d %H:%M:%S',CURRENT_DATETIME()) AS DATETIME) AS SYNCSTARTDATETIME
    FROM
      victorias-secret-393308.vs_sourcing_dev.vs_fiscal_calendar_v1
