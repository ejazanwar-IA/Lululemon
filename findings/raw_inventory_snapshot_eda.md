# EDA — `lulu_sourcing_dev.inventory_snapshot` (raw)

`Last updated: 2026-05-18.`

Primary raw source for `inventory_master` (current/intended). Daily fact-style: one row per (`SKU_ID`, `LOCATION_ID`, `DATE`). Note: the live `inventory_master` was actually built from the older `inventory_snapshot_cleaned` (16.4B rows) — see Section 5.

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot` |
| Created (IST) | 2026-05-08 19:10 |
| Last modified (IST) | 2026-05-14 15:33 |
| Row count | **403,567,770** |
| Size | 25.87 GB |
| Column count | 8 (7 STRING + 1 DATETIME) |

### Schema

| # | Column | Type | Nullable |
|---:|---|---|---|
| 1 | `SKU_ID` | STRING | YES |
| 2 | `LOCATION_ID` | STRING | YES |
| 3 | `DATE` | STRING | YES |
| 4 | `UNITS_ON_HAND` | STRING | YES |
| 5 | `UNITS_AVAILABLE` | STRING | YES |
| 6 | `UNITS_INBOUND` | STRING | YES |
| 7 | `SNAPSHOT_TIME` | STRING | YES |
| 8 | `SYNCSTARTDATETIME` | DATETIME | YES |

### Notable observations from schema + sample

| # | Observation | Implication |
|---|---|---|
| 1 | All 7 raw fields are STRING incl. `DATE` and `UNITS_*` | Cast required for partitioning and math |
| 2 | Sample shows `UNITS_ON_HAND = -1` | Sentinel for "unknown" — not zero |
| 3 | `SNAPSHOT_TIME` is full ISO datetime + `Z` (e.g. `2023-02-24T12:02:09Z`) | Differs from DATE — capture moment, not partition key |
| 4 | `DATE` format is `YYYY-MM-DD` string | Parseable via `SAFE_CAST(... AS DATE)` |

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Total rows | 403,567,770 | — |
| Distinct `SKU_ID` | 851,314 | |
| Distinct `LOCATION_ID` | 1,568 | More than `store_master.store_code` (1,853 stores) — subset |
| Distinct `DATE` | **33** | Sparse — not daily |
| Distinct `(SKU, LOC, DATE)` | 191,998,292 | |
| **Row duplication ratio** | 403.6M / 192.0M ≈ **2.1× duplicated** | Significant — see Phase 6 |

### Date distribution

| Period | Distinct dates | Total rows |
|---|---:|---:|
| 2023 (Feb–Dec) | 13 dates | ~41M |
| 2024 | **0 dates** | — |
| 2025-10-29 → 2025-11-17 | 20 dates | ~360M |

### Notable date spikes

| Date | Rows | Why interesting |
|---|---:|---|
| 2025-11-02 | 26.7M | ~2× normal day |
| 2025-11-09 | **50.7M** | ~4× normal day — duplicate load? |
| 2025-11-16 | **54.2M** | ~4× normal day — duplicate load? |
| All other Nov 2025 dates | 13–14M | Normal daily volume |

→ The three "spike" dates correlate with multi-load events. **Build/consumers should dedup on (SKU, LOC, DATE)** or pick latest `SNAPSHOT_TIME`.

## Phase 3 — Completeness + sentinels

| Column | NULL | Empty/`\N` | Special values | Notes |
|---|---:|---:|---|---|
| `SKU_ID` | 0 | 0 | — | 100% populated |
| `LOCATION_ID` | 0 | 0 | — | 100% populated |
| `DATE` | 0 | 0 | — | 100% populated |
| `UNITS_ON_HAND` | 0 | 0 | **`-1` on 1.36M (0.3%)** | Negative sentinel |
| `UNITS_ON_HAND` | — | — | 357K with other negatives | Real negative stock counts |
| `UNITS_ON_HAND` | — | — | 140.9M = 0 (34.9%) | Zero stock |
| `UNITS_ON_HAND` | — | — | 260.9M > 0 (64.7%) | Positive stock |
| `UNITS_AVAILABLE` | 0 | 0 | 1.84M = -1 (0.46%) | Same sentinel pattern |
| `UNITS_AVAILABLE` | — | — | 153.8M = 0 (38%) | |
| `UNITS_INBOUND` | 0 | 0 | **376.9M = 0 (93.4%)** | Most rows have no inbound |
| `UNITS_INBOUND` | — | — | 26.7M > 0 (6.6%) | Inbound shipments |
| `SNAPSHOT_TIME` | 0 | 0 | — | 100% populated |
| `SYNCSTARTDATETIME` | 0 | 0 | Single value `2026-05-08T00:00:00` | Snapshot |

### Big takeaways

- **`-1` is a sentinel for "unknown"** on `UNITS_ON_HAND` and `UNITS_AVAILABLE`. Cleaning must treat `-1` as NULL.
- **Real negative stock counts exist** (357K rows < -1 on OH; max negative is **-6,508**) — actual oversell / data correction artifacts. Distinct from the `-1` sentinel.
- **`UNITS_INBOUND = 0` on 93% of rows** — most days/SKUs have no shipments. Sparse.
- **Zero NULLs, zero sentinels** for identity columns — clean keys.

## Phase 4 — Distributions

### UNITS_ON_HAND quartiles

| Stat | Value |
|---|---:|
| Min | **-6,508** |
| Max | 195,493 |
| Q1 (25th %ile) | 0 |
| Median | 1 |
| Q3 (75th %ile) | 3 |

→ **Half of all rows have OH ≤ 1**. Tail is very long.

### UNITS_AVAILABLE range

Min `-6,508`, Max `185,293` — same negative tail as OH.

### UNITS_INBOUND range

Min `-2,842`, Max `25,412` — negative inbound (returns? cancellations?) on a small fraction.

## Phase 5 — Cross-table integrity

### Critical: master built from a different source

| Check | Result |
|---|---|
| Master `inventory_master` covers date | **2025-08-28** only |
| 2025-08-28 in `inventory_snapshot` (raw)? | **NO** (dates: 2023-02-23 → 2025-11-17 with gap) |
| 2025-08-28 in `inventory_snapshot_cleaned` (old 16.4B table)? | **YES — 5,539,053 rows = exact master row count** |

→ **The live `inventory_master` was built from the OLD `inventory_snapshot_cleaned` (16.4 B rows, 1.3 TB), NOT from this `inventory_snapshot`.** The new raw + intermediate pipeline is set up but hasn't been used for a master build yet.

### LOCATION_ID coverage vs store_master

- 1,568 distinct LOCATION_IDs here vs 1,853 stores in master → 285 stores never appear in this inventory raw. Likely warehouses + virtual stores without per-day snapshots.

## Phase 6 — Business-logic checks

### 2× row duplication

403.6M rows / 192.0M distinct (SKU, LOC, DATE) ≈ **2.10× duplication**. Concentrated on the three spike dates (Nov 2, 9, 16). Causes:

1. **Multi-load on same date** — the `SNAPSHOT_TIME` differs across copies, but DATE collapses them.
2. **Build implication** — INNER JOIN to PGH (after pivot) will multiply rows by 2× before dedup. Must `DISTINCT` or pick latest `SNAPSHOT_TIME`.

### -1 vs real negative stock

| Pattern | Rows | Interpretation |
|---|---:|---|
| `UNITS_ON_HAND = -1` | 1,363,252 | **Sentinel** = "unknown / no data" |
| `UNITS_ON_HAND < -1` (e.g. -6,508) | 357,280 | Real oversell / data correction |

→ Build should treat `-1` as NULL but preserve other negatives as real values. **Currently the canonical build does not distinguish.**

## Summary — what to expect downstream

| Reliable | Use with caution | Broken / Missing |
|---|---|---|
| `SKU_ID`, `LOCATION_ID`, `DATE` identity (100% populated) | 2× row duplication (3 spike dates) | 2024 has zero data |
| 33 dates spanning 2023-02-23 → 2025-11-17 | Negative units (real vs `-1` sentinel) | 2025-08-28 (master's date) not in this table |
| Single sync batch | `UNITS_INBOUND = 0` on 93% rows | |
| 1,568 LOCATION_IDs (subset of stores) | | |

## QQ's for Client

- **Why is the date coverage so sparse?** 33 dates over 33 months with a 2024 gap.
- **What causes the 2025-11-09 / 2025-11-16 spike loads?** (50M+ rows = 4× normal)
- **Should the new pipeline include 2025-08-28** (master's only date)?
- **Confirm `-1` semantics** — sentinel for "unknown" vs real negative stock?
- **Why does `UNITS_INBOUND` have negatives?** Returns? Reversals?
