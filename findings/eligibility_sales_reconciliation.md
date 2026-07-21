# Sales vs Eligibility Reconciliation (PSO x Store x Week)

`Run date: 2026-07-06 (raw sources)`

**Question:** When a real sale happened at PSO x store x fiscal week, did a matching eligibility row exist for that same key?

**SQL:** [`queries/sourcing/eligibility_sales_reconciliation.sql`](../queries/sourcing/eligibility_sales_reconciliation.sql)

## Method

All sources are **raw / sourcing-dev tables** in `lulu_sourcing_dev` (no master tables).

| Role | Table |
|---|---|
| Sales | `sales_transactions` |
| SKU to PSO | `product_group_hierarchy` (`LEVEL_NAME = 'PLANNING_STYLE_OPTION'`) |
| Calendar | `calendar_hierarchy` |
| Eligibility | `eligibility` |
| Store type (K5) | `location_details` |

| Step | Detail |
|---|---|
| Sales grain | Roll `sales_transactions` to PSO x store x `WEEK_ID` via `SKU_ID` -> PGH -> PSO |
| Calendar | `SAFE_CAST(DATE_TRANSACTION AS DATE)` joined to `calendar_hierarchy.DAY_ID` |
| Store join | `TRIM(LTRIM(CAST(LOCATION_ID_SALES AS STRING), '0'))` vs eligibility `STORE_ID` |
| Real sales filter | `SAFE_CAST(UNITS AS FLOAT64) > 0 AND SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64) > 0` |
| Eligibility dedup | `GROUP BY (pso, store_id, week_id)` on raw eligibility |
| Window | 2025-01-01 to 2025-12-31 |

**Eligibility semantics assumed:** a row at `(PLANNING_STYLE_OPTION_ID, STORE_ID, WEEK_ID)` means eligible for that planning week. No boolean flag in the feed.

**Note on master vs raw:** Metrics below were re-run on raw `sales_transactions` + raw `eligibility`. Results match the prior `transaction_master` + `product_master` run exactly, which validates that the master build preserves the sales signal for this reconciliation.

## K0 sanity check

Top 5 sales keys by units in 2025; calendar week from txn date always matches aggregated `week_id`.

| PSO | Store | Week | Sample date | Units | Eligibility match |
|---|---:|---:|---|---:|---|
| `150052382-1426` | 45187 | 202526 | 2025-07-31 | 11,600 | No |
| `CAAAL` | 9198 | 202526 | 2025-07-28 | 11,021 | Yes |
| `LW4CGVS-042797` | 45189 | 202534 | 2025-09-22 | 10,889 | Yes |
| `LW4CGVS-042797` | 45189 | 202533 | 2025-09-15 | 10,152 | Yes |
| `CAAAL` | 9198 | 202527 | 2025-08-04 | 9,844 | Yes |

Calendar alignment is correct. The largest single violation (`150052382-1426` at store 45187, week 202526) is a real ineligible sale, not a week-mapping bug.

## K1 headline summary (2025)

| Metric | Total | Eligible | Ineligible | % eligible |
|---|---:|---:|---:|---:|
| Distinct PSO x store x week keys | 24,694,787 | 20,029,646 (81.11% of keys) | 4,665,141 (18.89% of keys) | 81.11% |
| Units | 104,465,869 | 91,743,146 (87.82% of units) | 12,722,723 (12.18% of units) | 87.82% |
| Revenue | $210.75B | $188.87B (89.61% of revenue) | $21.89B (10.39% of revenue) | 89.61% |

**Takeaway:** Most sales volume sits on eligible keys, but nearly **1 in 5 distinct sales keys** (18.89%) has no matching eligibility row for that week. Unit and revenue shares are lower (12 to 13% ineligible) because high-volume keys tend to be eligible.

## K2 top violations (by units)

Largest ineligible sales keys cluster on a small set of stores (`45185`, `45187`, `45189`, `9188`, `9198`) and short PSO codes (`CAAAL`, `SAACZ`, `RAAAW`, etc.) alongside regular `LW*` style options.

| PSO | Store | Week | Units | Revenue |
|---|---:|---:|---:|---:|
| `150052382-1426` | 45187 | 202526 | 11,600 | $4.80M |
| `SAACL` | 9188 | 202538 | 7,221 | $1.07M |
| `LW4CGVS-070108` | 45185 | 202529 | 5,662 | $4.91M |
| `SAACZ` | 9188 | 202501 | 4,521 | $0.51M |
| `RAAAW` | 45185 | 202532 | 3,838 | $8.76M |

Full top-25 list: run K2 in the SQL file.

## K3 reverse coverage (eligibility with no sales)

| Metric | Value |
|---|---:|
| Distinct eligibility keys in 2025 fiscal weeks | 57,041,037 |
| Keys with at least one sale | 20,029,646 (35.11% of elig keys) |
| Keys with zero sales | 37,011,391 (64.89% of elig keys) |

Eligibility is a much wider planning superset than the sold set. Most eligible combinations never transact in a given week, which is expected.

## K4 week-level match rate

Key-level eligibility match rate by fiscal week ranges from **71.7%** (week `202540`) to **85.1%** (week `202539`). Unit-level match is consistently higher (roughly 80 to 90%).

Weakest weeks for key match:

| Week | Sales keys | % keys eligible | % units eligible |
|---:|---:|---:|---:|
| 202540 | 520,823 | 71.69% | 80.58% |
| 202527 | 562,443 | 72.73% | 81.72% |
| 202514 | 594,047 | 73.59% | 83.05% |
| 202541 | 522,180 | 73.16% | 82.37% |
| 202501 | 474,109 | 75.29% | 83.82% |

Full week table: run K4 in the SQL file.

## K5 ineligible sales by store type

Joined to `location_details.TYPE_CODE`.

| Store type | Ineligible keys | % of ineligible keys | Ineligible units | % of ineligible units |
|---|---:|---:|---:|---:|
| RETAIL | 4,170,423 (89.40% of ineligible keys) | 89.40% | 7,210,340 (56.67% of ineligible units) | 56.67% |
| ECOM | 494,718 (10.60% of ineligible keys) | 10.60% | 5,512,383 (43.33% of ineligible units) | 43.33% |

Most ineligible *keys* are RETAIL, but ECOM carries a disproportionate share of ineligible *units* (43.33% of ineligible units from 10.60% of ineligible keys).

## Interpretation

1. **The analysis works on raw feeds.** No master-table dependency; bridge is `sales_transactions.SKU_ID` -> PGH -> PSO.
2. **Raw and master paths agree.** Identical counts confirm `transaction_master` does not materially change eligibility reconciliation for 2025.
3. **~81% of sales keys are eligible; ~88% of units/revenue are.** The gap is material enough to investigate before using eligibility as a hard forecast filter.
4. **Ineligible sales are not automatically bad data.** Likely drivers: planning assortment scope, stores outside eligibility universe, ECOM/wholesale paths, or timing lag.

## Client callouts

| Priority | Ask |
|---|---|
| **P0** | Confirm row presence at `(PSO, store, WEEK_ID)` means "allowed to sell that week" for ForecastSmart / IA modeling |
| **P0** | Confirm dedup rule for 4.66% duplicate eligibility rows at declared grain |
| **P1** | Explain high-volume ineligible stores (`45185`, `45187`, `45189`, `9188`, `9198`) |
| **P1** | ECOM stores: should eligibility cover all channels that appear in `sales_transactions`? |

## Ad-hoc spot check

Use K6 in the SQL file with parameterized `(pso, store_id, week_id)` for a single key lookup.
