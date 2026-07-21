# Data Drop Brief — inventory_snapshot

`Generated: 2026-06-01 06:57 UTC.`  
`Agent run: drop-watch.`

---

## Executive summary

| Field | Value |
|-------|-------|
| **GCS view** | `inventory_snapshot` |
| **Drop folder / file** | `/Users/ejazanwarmd/Desktop/Lululemon/findings/inbound_drop_agent/test_drops/2026-06-02/inventory_snapshot_20260602140000.csv` |
| **Inferred SYNCSTARTDATETIME** | 2026-06-02 14:00:00 |
| **BQ table profiled** | `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot_cleaned` |
| **Verdict** | **RED** — BQ table not found — extraction may not have landed. |

---

## What arrived

| Check | Result |
|-------|--------|
| Table exists in BQ | No |
| Row count | — |
| Size (GB) | — |
| Last modified | — |
| Column count | 0 |

Always filter on DATE before wide scans.

---

## Schema snapshot

_No schema returned._

---

## Grain & duplicates

_Grain metrics on sample date 2025-08-28 only._

| Metric | Value |
|--------|------:|
| Rows in scope | — |
| Distinct grain (—) | — |
| Duplicate rows (total − distinct grain) | — |
| Duplicate % | — |

**Expected grain:** Configure grain_columns in view_profiles.yaml

---

## Date coverage

_No date metrics._

---

## Data quality — sentinels & nulls

_No sentinel columns configured._

---

## Join readiness (sample)

_No join checks configured._

---

## Week-over-week (optional)

| Metric | Prior drop | This drop | Delta |
|--------|----------:|----------:|------:|
| Row count | — | — | — |

_Prior drop: findings/inbound_drop_agent/briefs/inventory_snapshot_20260601_1200.md._

---

## Changes vs prior drop

| Level | Finding |
|-------|---------|
| GREEN | No material drift vs prior drop. |

---

## Anomalies & drift flags

- No threshold anomalies flagged on this run.

_Numeric z-score checks require 3+ prior runs (post-MVP)._

---

## Blockers & recommendations

### Red (do not ingest)

- BQ table not found — extraction may not have landed.

### Amber (ingest with caveats)

- _None_

### Green (cleared)

- No material drift vs prior drop.

---

## Suggested next actions

1. Share brief with DI + PL for drop sign-off
2. If Green: advance `view_mapping_table.filter_param` per periodic sourcing runbook
3. If Red/Amber: run deep EDA SQL in `queries/` before enabling DAG

---

## Reproduce

```bash
python3 scripts/inbound_drop_eda.py --view inventory_snapshot --gcs-path "/Users/ejazanwarmd/Desktop/Lululemon/findings/inbound_drop_agent/test_drops/2026-06-02/inventory_snapshot_20260602140000.csv" --write-brief
# Or via drop watcher (auto-detect new files):
python3 scripts/drop_watch.py --once --source local
```

SQL pack: [`queries/eda/inbound_drop_eda_pack.sql`](../../queries/eda/inbound_drop_eda_pack.sql)

---

## Changelog

| Date | Author | Note |
|------|--------|------|
| 2026-06-01 | inbound-drop-eda | Auto-generated metrics; narrative reviewed by _pending_ |
