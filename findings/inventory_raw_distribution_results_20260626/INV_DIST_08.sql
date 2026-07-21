-- Full raw vs active date scope vs active core-channel scope.
WITH typed AS (
  SELECT
    SAFE_CAST(i.`DATE` AS DATE) AS snap_date,
    SAFE_CAST(i.UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(i.UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(i.UNITS_INBOUND AS INT64) AS inb,
    CASE
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'RETAIL'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%_RTL' THEN 'RETAIL'
      WHEN UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOMM'
        OR UPPER(COALESCE(ld.TYPE_CODE, '')) = 'ECOM'
        OR UPPER(COALESCE(ld.CHANNEL_CODE, '')) LIKE '%ECOMM%' THEN 'ECOMM'
      ELSE 'NON_CORE'
    END AS derived_channel
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot` i
  LEFT JOIN `lululemon-01042025.lulu_sourcing_dev.location_details` ld
    ON LPAD(CAST(i.LOCATION_ID AS STRING), 10, '0') = LPAD(CAST(ld.ID AS STRING), 10, '0')
),
scoped AS (
  SELECT 'full_raw' AS scope_name, * FROM typed
  UNION ALL
  SELECT 'active_date_scope' AS scope_name, * FROM typed
  WHERE snap_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
  UNION ALL
  SELECT 'active_core_scope' AS scope_name, * FROM typed
  WHERE snap_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)
    AND derived_channel IN ('RETAIL', 'ECOMM')
),
q AS (
  SELECT
    scope_name,
    COUNT(*) AS row_count,
    MIN(snap_date) AS min_date,
    MAX(snap_date) AS max_date,
    COUNT(DISTINCT snap_date) AS distinct_dates,
    COUNTIF(derived_channel = 'RETAIL') AS retail_rows,
    COUNTIF(derived_channel = 'ECOMM') AS ecomm_rows,
    COUNTIF(derived_channel = 'NON_CORE') AS non_core_rows,
    COUNTIF(oh = -1) AS oh_sentinel,
    COUNTIF(oh < -1) AS oh_real_negative,
    COUNTIF(oh = 0) AS oh_zero,
    COUNTIF(oh > 0) AS oh_positive,
    COUNTIF(av > oh) AS av_gt_oh,
    COUNTIF(inb > 0 AND oh = 0) AS inb_pos_oh_zero,
    APPROX_QUANTILES(oh, 100)[OFFSET(50)] AS oh_p50,
    APPROX_QUANTILES(oh, 100)[OFFSET(99)] AS oh_p99,
    APPROX_QUANTILES(av, 100)[OFFSET(50)] AS av_p50,
    APPROX_QUANTILES(av, 100)[OFFSET(99)] AS av_p99,
    APPROX_QUANTILES(inb, 100)[OFFSET(50)] AS inb_p50,
    APPROX_QUANTILES(inb, 100)[OFFSET(99)] AS inb_p99
  FROM scoped
  GROUP BY scope_name
)
SELECT *
FROM q
ORDER BY scope_name;
