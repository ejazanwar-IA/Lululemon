-- Segment distributions by year, month, derived channel, and location type.
WITH typed AS (
  SELECT
    SAFE_CAST(i.`DATE` AS DATE) AS snap_date,
    SAFE_CAST(i.UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(i.UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(i.UNITS_INBOUND AS INT64) AS inb,
    COALESCE(ld.TYPE_CODE, 'UNKNOWN') AS location_type,
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
grouped AS (
  SELECT
    EXTRACT(YEAR FROM snap_date) AS snap_year,
    DATE_TRUNC(snap_date, MONTH) AS snap_month,
    derived_channel,
    location_type,
    COUNT(*) AS row_count,
    COUNTIF(oh = -1) AS oh_sentinel,
    COUNTIF(oh < -1) AS oh_real_negative,
    COUNTIF(oh = 0) AS oh_zero,
    COUNTIF(oh > 0) AS oh_positive,
    COUNTIF(inb > 0) AS inb_positive,
    AVG(oh) AS oh_avg,
    AVG(av) AS av_avg,
    AVG(inb) AS inb_avg,
    APPROX_QUANTILES(oh, 100)[OFFSET(50)] AS oh_p50,
    APPROX_QUANTILES(oh, 100)[OFFSET(99)] AS oh_p99,
    APPROX_QUANTILES(av, 100)[OFFSET(50)] AS av_p50,
    APPROX_QUANTILES(av, 100)[OFFSET(99)] AS av_p99,
    APPROX_QUANTILES(inb, 100)[OFFSET(50)] AS inb_p50,
    APPROX_QUANTILES(inb, 100)[OFFSET(99)] AS inb_p99
  FROM typed
  GROUP BY 1, 2, 3, 4
)
SELECT *
FROM grouped
ORDER BY snap_month, derived_channel, location_type;
