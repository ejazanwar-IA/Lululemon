# Inventory Raw Distribution EDA

Date: 2026-06-26

Source table: `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot`

SQL: [`queries/inventory_raw_distribution_eda.sql`](../queries/inventory_raw_distribution_eda.sql)

Raw result files: [`findings/inventory_raw_distribution_results_20260626/`](inventory_raw_distribution_results_20260626/)

## Executive Summary

The inventory raw table is usable, but it is highly sparse and has a very long tail. Median stock is tiny, while a small number of DC and virtual DC rows carry very large quantities. This means downstream modeling should not treat averages as representative. Use medians, positive-only distributions, and explicit handling for `-1` sentinels, real negatives, and inbound-only rows.

| Area | Read |
|---|---|
| Total rows | 7,930,649,631 |
| Date range | 2023-01-01 to 2025-12-04 (1,069 dates) |
| Grain keys | 0 bad casts or missing keys for `SKU_ID`, `LOCATION_ID`, `DATE`, `SNAPSHOT_TIME` |
| On-hand shape | Median 1, p99 151, p99.9 1,248, max 700,024 |
| Available shape | Median 1, p99 138, p99.9 1,165, max 700,010 |
| Inbound shape | Median 0, p99 5, p99.9 28, max 111,631 |
| Strongest outlier source | Top rows are DC / virtual DC locations: 10010, 10017, 10030, 10037 |

## Sign Buckets

| Field | Negative / sentinel rows | Zero rows | Positive rows | Max |
|---|---:|---:|---:|---:|
| `UNITS_ON_HAND` | 68.3 million (0.86%) | 2.5 billion (31.73%) | 5.3 billion (67.41%) | 700.0 thousand |
| `UNITS_AVAILABLE` | 86.4 million (1.09%) | 3.0 billion (37.63%) | 4.9 billion (61.28%) | 700.0 thousand |
| `UNITS_INBOUND` | 1.5 million (0.02%) | 7.3 billion (92.09%) | 626.1 million (7.89%) | 111.6 thousand |

Interpretation: `UNITS_INBOUND` is the sparsest field: 92.09% of rows are zero. For `UNITS_ON_HAND` and `UNITS_AVAILABLE`, the negative / sentinel bucket combines the documented `-1` sentinel with real negative values below `-1`. `UNITS_INBOUND` has no `-1` sentinel in this scan, so its negative bucket is real negatives only.

## Full-Table Percentiles

| Metric | Rows | Avg | Stddev | Min | p25 | p50 | p75 | p90 | p95 | p99 | p99.9 | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `UNITS_AVAILABLE` | 7,930,649,631 | 9.16 | 180.12 | -3,704,869 | 0 | 1 | 2 | 6 | 12 | 138 | 1,165 | 700,010 |
| `UNITS_INBOUND` | 7,930,649,631 | 0.32 | 13.66 | -2,842 | 0 | 0 | 0 | 0 | 1 | 5 | 28 | 111,631 |
| `UNITS_ON_HAND` | 7,930,649,631 | 10.03 | 189.88 | -3,704,869 | 0 | 1 | 3 | 6 | 14 | 151 | 1,248 | 700,024 |

The gap between p99.9 and max is large for every unit column. That confirms a long-tail distribution rather than a smooth normal distribution.

## Sentinel-Excluded Percentiles

| Metric | Rows | Avg | Stddev | Min | p25 | p50 | p75 | p90 | p95 | p99 | p99.9 | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `UNITS_AVAILABLE_EXCL_SENTINEL` | 7,866,463,249 | 9.25 | 180.85 | -3,704,869 | 0 | 1 | 2 | 6 | 12 | 139 | 1,171 | 700,010 |
| `UNITS_INBOUND` | 7,930,649,631 | 0.32 | 13.66 | -2,842 | 0 | 0 | 0 | 0 | 1 | 5 | 28 | 111,631 |
| `UNITS_ON_HAND_EXCL_SENTINEL` | 7,877,829,852 | 10.10 | 190.51 | -3,704,869 | 0 | 1 | 3 | 6 | 14 | 153 | 1,254 | 700,024 |

Excluding `-1` changes the average only slightly. The long tail is not caused by the sentinel; it comes from true high-quantity rows.

## Positive-Only Percentiles

| Metric | Rows | Avg | Stddev | Min | p25 | p50 | p75 | p90 | p95 | p99 | p99.9 | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `UNITS_AVAILABLE_POSITIVE` | 4,859,669,261 | 15.01 | 221.90 | 1 | 1 | 2 | 4 | 9 | 26 | 240 | 1,660 | 700,010 |
| `UNITS_INBOUND_POSITIVE` | 626,116,324 | 4.09 | 48.44 | 1 | 1 | 1 | 3 | 5 | 9 | 35 | 263 | 111,631 |
| `UNITS_ON_HAND_POSITIVE` | 5,346,005,709 | 14.90 | 223.87 | 1 | 1 | 2 | 4 | 9 | 26 | 237 | 1,645 | 700,024 |

Among rows with positive stock, the median remains only 2 units for OH and AV. This confirms the table is dominated by low-unit SKU-location-day grains even before zero rows are considered.

## Relationship Checks

| Check | Rows | % of table |
|---|---:|---:|
| `UNITS_AVAILABLE > UNITS_ON_HAND` | 2,383,297 | 0.03% |
| `UNITS_AVAILABLE < UNITS_ON_HAND` | 735,475,893 | 9.27% |
| `UNITS_AVAILABLE = UNITS_ON_HAND` | 7,192,790,441 | 90.70% |
| `UNITS_ON_HAND > 0 AND UNITS_AVAILABLE = 0` | 480,224,315 | 6.06% |
| `UNITS_INBOUND > 0 AND UNITS_ON_HAND = 0` | 301,841,349 | 3.81% |
| Any real negative unit value | 23,683,022 | 0.30% |
| `ABS(UNITS_AVAILABLE - UNITS_ON_HAND) >= 100` | 9,717,954 | 0.12% |
| `ABS(UNITS_AVAILABLE - UNITS_ON_HAND) >= 1000` | 515,111 | 0.01% |
| `UNITS_INBOUND / UNITS_ON_HAND > 10` | 2,112,925 | 0.03% |

| Gap / ratio metric | p50 | p95 | p99 | p99.9 | Max |
|---|---:|---:|---:|---:|---:|
| `ABS(AV - OH)` | 0 | 1 | 10 | 118 | 700,000 |
| `INB / OH` where defined | 0.00 | 0.17 | 1.33 | 6.00 | 13,880.00 |

Most rows have AV equal to OH, but 735,475,893 rows have AV below OH and 480,224,315 rows have positive OH with zero AV. Those are likely legitimate availability constraints, not pure data errors, but they matter for allocation and ForecastSmart feature definitions.

## Channel And Location Segments

| Derived channel | Rows | OH positive | OH zero | OH sentinel | OH real negative | INB positive |
|---|---:|---:|---:|---:|---:|---:|
| `RETAIL` | 6,208,191,026 | 4,181,589,327 | 1,993,627,173 | 26,435,332 | 6,539,194 | 524,182,513 |
| `ECOMM` | 216,529,099 | 38,624,241 | 160,038,821 | 13,454,907 | 4,411,130 | 1,474,897 |
| `NON_CORE` | 1,505,929,506 | 1,125,792,141 | 362,662,896 | 12,929,540 | 4,544,929 | 100,458,914 |

Highest segment p99 values are concentrated in `VIRTUAL_DC` rows under the derived `RETAIL` channel:

| Month | Derived channel | Location type | Rows | OH p99 |
|---|---|---|---:|---:|
| 2024-11-01 | `RETAIL` | `VIRTUAL_DC` | 8,889,814 | 1,664 |
| 2024-10-01 | `RETAIL` | `VIRTUAL_DC` | 9,622,970 | 1,627 |
| 2025-05-01 | `RETAIL` | `VIRTUAL_DC` | 9,884,376 | 1,565 |
| 2025-04-01 | `RETAIL` | `VIRTUAL_DC` | 9,271,592 | 1,530 |
| 2025-12-01 | `RETAIL` | `VIRTUAL_DC` | 947,886 | 1,513 |
| 2025-02-01 | `RETAIL` | `VIRTUAL_DC` | 8,156,813 | 1,504 |
| 2025-07-01 | `RETAIL` | `VIRTUAL_DC` | 9,810,532 | 1,453 |
| 2025-01-01 | `RETAIL` | `VIRTUAL_DC` | 8,875,140 | 1,437 |

## Active Scope Comparison

| Scope | Rows | Date range | Retail rows | Ecomm rows | Non-core rows | OH p50 | OH p99 | AV p99 | INB p99 |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `full_raw` | 7,930,649,631 | 2023-01-01 to 2025-12-04 | 6,208,191,026 | 216,529,099 | 1,505,929,506 | 1 | 150 | 137 | 4 |
| `active_date_scope` | 5,624,584,333 | 2024-01-01 to 2025-12-04 | 4,424,383,459 | 161,496,636 | 1,038,704,238 | 1 | 137 | 125 | 4 |
| `active_core_scope` | 4,585,880,095 | 2024-01-01 to 2025-12-04 | 4,424,383,459 | 161,496,636 | 0 | 1 | 28 | 24 | 4 |

The current downstream core-channel scope is much less tail-heavy than the full raw table: full raw OH p99 is 150, while active core scope OH p99 is 28. The difference is driven by older history and non-core / DC-like locations in the full table.

## Top Outlier Examples

| Metric | SKU | Location | Location detail | Date | OH | AV | INB |
|---|---|---|---|---|---:|---:|---:|
| `UNITS_ON_HAND` | `132153744` | `10010` | DC_ECOM / 10010:DC LULU US ECOMM COLUMBUS | 2025-10-07 | 700,024 | 700,010 | 0 |
| `UNITS_AVAILABLE` | `132153744` | `10010` | DC_ECOM / 10010:DC LULU US ECOMM COLUMBUS | 2025-10-07 | 700,024 | 700,010 | 0 |
| `UNITS_INBOUND` | `147475064` | `10030` | DC_ECOM / 10030:DC LULU US ECOMM LA | 2025-04-08 | -1 | -1 | 111,631 |

Outlier examples are not random store rows. They map to DC or virtual DC locations, which supports treating the largest tails as a channel/location-scope issue before calling them bad data.

## Recommended Handling

| Pattern | Recommendation |
|---|---|
| `UNITS_ON_HAND = -1` or `UNITS_AVAILABLE = -1` | Treat as unknown / NULL in downstream feature logic, not as real negative stock. |
| `UNITS_ON_HAND < -1`, `UNITS_AVAILABLE < -1`, or `UNITS_INBOUND < 0` | Keep in raw, flag for business review, and exclude or cap in modeling until semantics are confirmed. |
| Zero OH / zero AV | Do not drop by default. Zero stock is a large and meaningful part of SKU-location-day availability. |
| `OH > 0 AND AV = 0` | Preserve as a meaningful availability constraint. It affects allocation and demand-feasibility features. |
| `INB > 0 AND OH = 0` | Preserve as pipeline stock signal. Consider separate inbound feature rather than folding into OH. |
| Very high OH / AV / INB values | Segment by location type. DC and virtual DC rows explain many top tails; store-only modeling should filter or model them separately. |
| Intermediate build | Current `inventory_intermediate` core-channel filter materially reduces tail heaviness; keep this explicit in stakeholder docs. |

## Reproducibility

All BigQuery work was read-only. Outputs are saved locally:

- `INV_DIST_01`: done, rows returned = 1
- `INV_DIST_02`: done, rows returned = 3
- `INV_DIST_03`: done, rows returned = 3
- `INV_DIST_04`: done, rows returned = 3
- `INV_DIST_05`: done, rows returned = 1
- `INV_DIST_06`: done, rows returned = 182
- `INV_DIST_07`: done, rows returned = 150
- `INV_DIST_08`: done, rows returned = 3

Note: the saved SQL uses p99.9 plus exact maximum and top outlier rows for the extreme tail. A p99.99 full-table percentile attempt was cancelled before billed bytes because it was too slow for interactive EDA.
