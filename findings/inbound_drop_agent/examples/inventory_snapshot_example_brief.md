# Data Drop Brief — inventory_snapshot

`Generated: 2026-05-28 14:00 UTC.`  
`Agent run: inbound-drop-eda (Phase 1 — example / structure reference).`

> **Note:** Metrics below are **illustrative** for forum/demo. Run `python3 scripts/inbound_drop_eda.py --view inventory_snapshot --write-brief` for live numbers.

---

## Executive summary

| Field | Value |
|-------|-------|
| **GCS view** | `inventory_snapshot` |
| **Drop folder / file** | `gs://<client-bucket>/2026-05-28/inventory_snapshot_20260528143000.csv` |
| **Inferred SYNCSTARTDATETIME** | 2026-05-28 14:30:00 |
| **BQ table profiled** | `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned` |
| **Verdict** | **AMBER** — Single-date POC in raw; join orphans expected until channel policy confirmed |

---

## What arrived

| Check | Result |
|-------|--------|
| Table exists in BQ | Yes |
| Row count | 16,400,000,000+ (full history) |
| Size (GB) | ~multi-TB |
| Last modified | 2026-05-20 |
| Column count | 12 |

Always filter on `DATE` before wide scans (table may be very large).

---

## Grain & duplicates

| Metric | Value |
|--------|------:|
| Total rows (sample `2025-08-28`) | 4,579,346 |
| Distinct grain (SKU_ID_CHANNEL, LOCATION_ID, DATE) | 4,579,346 |
| Duplicate rows | 0 |
| Duplicate % | 0.0 |

**Expected grain:** SKU × location × business date

---

## Date coverage

- Business date range (since 2024-01-01): sparse — **POC single date `2025-08-28`** dominates practical use
- Sample 2025-08-28: **4,579,346** rows

---

## Data quality — sentinels & nulls

- Rows on sample: **4,579,346**
- `CHANNEL` null/\N/blank: low
- `SKU_ID_CHANNEL` null/\N/blank: low

---

## Join readiness (sample)

| Check | Feed keys | Matched | Orphans | Orphan % |
|-------|----------:|--------:|--------:|---------:|
| sku_in_product_master | 45,000 | 30,000 | 15,000 | 33.33 |

Channel-suffix join policy may affect orphan % — not a raw-feed defect alone.

---

## Week-over-week (optional)

| Metric | Prior drop | This drop | Delta |
|--------|----------:|----------:|------:|
| Row count | — | 4,579,346 (sample) | first run |

---

## Blockers & recommendations

### Red (do not ingest)

- _None for sample date grain_

### Amber (ingest with caveats)

- Full table is multi-date in schema but **only one business date** used in POC — confirm multi-date landing before periodic DAG
- PM join orphans — document X3/channel policy for IA

### Green (cleared)

- Grain unique on sample date
- Sentinels acceptable on sample

---

## Suggested next actions

1. Share brief with DI + PL for drop sign-off
2. Enable periodic intermediate only after multi-date inventory landing confirmed
3. Re-run brief with `--gcs-path` on each new folder date; compare `metrics_history.json`

---

## Reproduce

```bash
python3 scripts/inbound_drop_eda.py --view inventory_snapshot \
  --gcs-path "gs://<bucket>/2026-05-28/inventory_snapshot_20260528143000.csv" \
  --write-brief
```
