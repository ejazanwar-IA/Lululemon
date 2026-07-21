# Data Drop Brief — inventory_snapshot

`Generated: 2026-05-28 03:23 UTC.`  
`Agent run: inbound-drop-eda (Phase 1 — manual trigger).`

---

## Executive summary

| Field | Value |
|-------|-------|
| **GCS view** | `inventory_snapshot` |
| **Drop folder / file** | `— (not supplied; run with --gcs-path)` |
| **Inferred SYNCSTARTDATETIME** | — |
| **BQ table profiled** | `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot_cleaned` |
| **Verdict** | **RED** — Grain duplicates 2.17% — investigate before ingest. |

---

## What arrived

| Check | Result |
|-------|--------|
| Table exists in BQ | Yes |
| Row count | 16,424,322,768 |
| Size (GB) | 1299.052 |
| Last modified | 2026-05-07 08:13:19 |
| Column count | 9 |

Always filter on DATE before wide scans.

---

## Schema snapshot

| Column | Type | Nullable |
|--------|------|----------|
| SKU_ID | INT64 | YES |
| LOCATION_ID | STRING | YES |
| DATE | DATE | YES |
| UNITS_ON_HAND | INT64 | YES |
| UNITS_AVAILABLE | INT64 | YES |
| UNITS_INBOUND | INT64 | YES |
| SNAPSHOT_TIME | TIMESTAMP | YES |
| CHANNEL | STRING | YES |
| SKU_ID_CHANNEL | STRING | YES |

---

## Grain & duplicates

| Metric | Value |
|--------|------:|
| Total rows | 16,424,322,768 |
| Distinct grain (SKU_ID_CHANNEL, LOCATION_ID, DATE) | 5,418,855 |
| Duplicate rows (total − distinct grain) | 120,198 |
| Duplicate % | 2.17 |

**Expected grain:** SKU_ID_CHANNEL, LOCATION_ID, DATE

---

## Date coverage

- Business date range (since 2024-01-01): **2024-01-01** → **2025-09-02** (611 distinct dates)
- Sample 2025-08-28: **5,539,053** rows

---

## Data quality — sentinels & nulls

- `CHANNEL` null/\N/blank: **120,222**
- `SKU_ID_CHANNEL` null/\N/blank: **120,222**

---

## Join readiness (sample)

| Check | Feed keys | Matched | Orphans | Orphan % |
|-------|----------:|--------:|--------:|---------:|
| sku_in_product_master | 483457 | 347278 | 136179 | 28.17 |

_Channel-suffix join policy may affect orphan %._

---

## Week-over-week (optional)

| Metric | Prior drop | This drop | Delta |
|--------|----------:|----------:|------:|
| Row count | — | 16,424,322,768 | — |

_Prior drop: findings/inbound_drop_agent/briefs/inventory_snapshot_20260528.md. Populate after second automated run._

---

## Blockers & recommendations

### Red (do not ingest)

- Grain duplicates 2.17% — investigate before ingest.

### Amber (ingest with caveats)

- _None_

### Green (cleared)

- _None_

---

## Suggested next actions

1. Share brief with DI + PL for drop sign-off
2. If Green: advance `view_mapping_table.filter_param` per periodic sourcing runbook
3. If Red/Amber: run deep EDA SQL in `queries/` before enabling DAG

---

## Reproduce

```bash
python3 scripts/inbound_drop_eda.py --view inventory_snapshot --gcs-path "— (not supplied; run with --gcs-path)" --write-brief
```

SQL pack: [`queries/eda/inbound_drop_eda_pack.sql`](../../queries/eda/inbound_drop_eda_pack.sql)

---

## Changelog

| Date | Author | Note |
|------|--------|------|
| 2026-05-28 | inbound-drop-eda | Auto-generated metrics; narrative reviewed by _pending_ |
