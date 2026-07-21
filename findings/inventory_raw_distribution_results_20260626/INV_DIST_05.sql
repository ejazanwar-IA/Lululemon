-- Relationship checks and gap distributions.
WITH typed AS (
  SELECT
    SAFE_CAST(UNITS_ON_HAND AS INT64) AS oh,
    SAFE_CAST(UNITS_AVAILABLE AS INT64) AS av,
    SAFE_CAST(UNITS_INBOUND AS INT64) AS inb
  FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`
),
base AS (
  SELECT
    *,
    av - oh AS av_minus_oh,
    ABS(av - oh) AS abs_av_oh_gap,
    SAFE_DIVIDE(inb, NULLIF(oh, 0)) AS inb_to_oh_ratio
  FROM typed
),
q AS (
  SELECT
    COUNT(*) AS total_rows,
    COUNTIF(av > oh) AS av_gt_oh,
    COUNTIF(av < oh) AS av_lt_oh,
    COUNTIF(av = oh) AS av_eq_oh,
    COUNTIF(oh > 0 AND av = 0) AS oh_pos_av_zero,
    COUNTIF(inb > 0 AND oh = 0) AS inb_pos_oh_zero,
    COUNTIF(oh < -1 OR av < -1 OR inb < 0) AS any_real_negative,
    COUNTIF(abs_av_oh_gap >= 100) AS abs_gap_ge_100,
    COUNTIF(abs_av_oh_gap >= 1000) AS abs_gap_ge_1000,
    COUNTIF(inb_to_oh_ratio > 10) AS inb_ratio_gt_10,
    APPROX_QUANTILES(abs_av_oh_gap, 1000) AS gap_q,
    APPROX_QUANTILES(IF(inb_to_oh_ratio IS NULL, NULL, inb_to_oh_ratio), 1000 IGNORE NULLS) AS ratio_q,
    MAX(abs_av_oh_gap) AS max_abs_gap,
    MAX(inb_to_oh_ratio) AS max_inb_to_oh_ratio
  FROM base
)
SELECT
  total_rows,
  av_gt_oh,
  av_lt_oh,
  av_eq_oh,
  oh_pos_av_zero,
  inb_pos_oh_zero,
  any_real_negative,
  abs_gap_ge_100,
  abs_gap_ge_1000,
  inb_ratio_gt_10,
  gap_q[OFFSET(500)] AS abs_gap_p50,
  gap_q[OFFSET(950)] AS abs_gap_p95,
  gap_q[OFFSET(990)] AS abs_gap_p99,
  gap_q[OFFSET(999)] AS abs_gap_p999,
  gap_q[OFFSET(1000)] AS abs_gap_p1000,
  max_abs_gap,
  ratio_q[OFFSET(500)] AS inb_to_oh_ratio_p50,
  ratio_q[OFFSET(950)] AS inb_to_oh_ratio_p95,
  ratio_q[OFFSET(990)] AS inb_to_oh_ratio_p99,
  ratio_q[OFFSET(999)] AS inb_to_oh_ratio_p999,
  ratio_q[OFFSET(1000)] AS inb_to_oh_ratio_p1000,
  max_inb_to_oh_ratio
FROM q;
