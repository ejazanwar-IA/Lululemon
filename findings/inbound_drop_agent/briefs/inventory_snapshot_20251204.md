# Data Drop Brief — inventory_snapshot (DEC04)

`Generated: 2026-06-24.`  
`Agent run: DEC04 inventory EDA plan (GCS external-table profile).`

---

## Executive summary

| Field | Value |
|-------|-------|
| **GCS view** | `inventory_snapshot` |
| **Drop folder / file** | `gs://client_data_lululemon/Historic/s3_to_gcs/2025-12-05/outbound/inventory_snapshot/new/` (224 shards, tag `20251204`) |
| **Inferred SYNCSTARTDATETIME** | `20251204` (from filename tag) |
| **BQ table profiled** | GCS external table only (not loaded in `lulu_sourcing_dev`) |
| **Verdict** | **GREEN** — 1.0× grain, full 2023–2025 daily continuity, clean keys; ingest with documented sentinel and join caveats |

---

## What arrived

| Check | Result |
|-------|--------|
| Table exists in BQ | No (GCS-only profile via external table) |
| Row count | **7,930,649,631** |
| Size (GB) | **~474** |
| Column count | **7** |

All 7 raw fields are STRING in CSV. Cast required for math and date parsing.

---

## Schema snapshot

| Column | Type (CSV) | Notes |
|--------|------------|-------|
| SKU_ID | STRING | Bare numeric SKU |
| LOCATION_ID | STRING | Matches `location_details.id` |
| DATE | STRING | Business snapshot date `YYYY-MM-DD` |
| UNITS_ON_HAND | STRING | `-1` sentinel = unknown |
| UNITS_AVAILABLE | STRING | Same sentinel pattern |
| UNITS_INBOUND | STRING | 92% zero |
| SNAPSHOT_TIME | STRING | ISO timestamp with `Z` suffix |

No `CHANNEL` / `SKU_ID_CHANNEL` (unlike `inventory_snapshot_cleaned`).

---

## Grain & duplicates

Full-batch scope (all 1,069 snapshot dates).

| Metric | Value |
|--------|------:|
| Rows in scope | 7,930,649,631 |
| Distinct grain `(SKU_ID, LOCATION_ID, DATE)` | 7,930,649,631 |
| Duplicate rows | **0** |
| Duplicate % | **0.00%** |

**Expected grain:** `SKU_ID`, `LOCATION_ID`, `DATE`

---

## Date coverage

| Metric | Value |
|--------|-------|
| Min snapshot date | 2023-01-01 |
| Max snapshot date | 2025-12-04 |
| Distinct dates | 1,069 |
| Calendar continuity | **Full** (1,069 calendar days, no gaps) |
| 2024 coverage | **366 days** (full leap year) |

Year split: 2023 = 365 dates; 2024 = 366; 2025 = 338 (through Dec 4).

---

## Data quality — sentinels & nulls

| Signal | Count | Rate |
|--------|------:|-----:|
| Key NULLs | 0 | 0% |
| OH = `-1` sentinel | 52.8M | 0.67% |
| AV = `-1` sentinel | 64.2M | 0.81% |
| Real negative OH (< -1) | 15.5M | 0.20% |
| INB = 0 | 7.30B | 92.1% |

Treat `-1` as NULL in downstream cleaning. Real negatives are a separate bucket from sentinel.

---

## Join readiness (sample date 2025-12-04)

| Join | Orphan % | Verdict |
|------|--------:|---------|
| Bare SKU → `product_master` | **0%** | Pass |
| `LOCATION_ID` → `location_details.id` | **0%** | Pass |
| `LOCATION_ID` → `store_master.store_code` | **100%** | Fail on this key (format mismatch; not a data gap) |

Use `location_details` for location validation on raw inventory, not direct `store_master.store_code` match.

---

## Anomalies & drift flags

| Flag | Severity | Detail |
|------|----------|--------|
| Daily row spikes (Aug/Oct/Nov 2025) | Amber | 3 dates at ~3.4× median volume; grain still unique |
| OH > 0, AV = 0 | Amber | 480M rows (6.1%); expected retail hold pattern |
| Negative SNAPSHOT_TIME lag | Amber | 26.6M rows (0.33%); historical backfill artifact |
| Not in BQ sourcing table | Red (process) | `lulu_sourcing_dev.inventory_snapshot` is Nov-era mix, ~40× smaller |

---

## Blockers & recommendations

### Red (do not ingest without action)

- **BQ table stale:** Current `lulu_sourcing_dev.inventory_snapshot` does not reflect this batch. Reload from consolidated DEC04 path before downstream use.

### Amber (ingest with caveats)

- Map `-1` sentinels to NULL on OH/AV.
- Do not join `store_master` on raw `LOCATION_ID` without an explicit mapping layer.
- Expect ~3× daily row spikes on a handful of dates (assortment expansion, not dupes).
- Add dedupe guard on Sourcing DAG load (Nov mix showed ~2× load duplication despite clean source CSVs).

### Green (cleared)

- 1.0× grain across 7.93B rows.
- Full daily continuity 2023-01-01 through 2025-12-04.
- Zero key NULLs.
- SKU and location_details join clean on latest date sample.

---

## Suggested next actions

1. Point Sourcing DAG at `gs://.../consolidated/inventory_snapshot/` (DEC04) for `lulu_sourcing_dev.inventory_snapshot` reload.
2. Apply `-1` → NULL cleaning in intermediate build; preserve real negatives separately.
3. Validate post-load grain dup ratio = 1.0 (guard against known ~2× DAG duplication bug).

---

## Reproduce

```bash
# Save external table JSON to /tmp/lulu_inv/dec04_eda.json (see findings/raw_inventory_snapshot_dec04_eda.md)

bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
  --external_table_definition=t::/tmp/lulu_inv/dec04_eda.json \
  "$(sed -n '/^-- PHASE1:/,/^-- END PHASE1/p' queries/inventory_snapshot_dec04_eda.sql | grep -v '^--')"
```

Full workbook: [`queries/inventory_snapshot_dec04_eda.sql`](../queries/inventory_snapshot_dec04_eda.sql)  
EDA doc: [`findings/raw_inventory_snapshot_dec04_eda.md`](../raw_inventory_snapshot_dec04_eda.md)

---

## Changelog

| Date | Author | Note |
|------|--------|------|
| 2026-06-24 | DEC04 EDA plan | GCS external-table profile; narrative pending reviewer sign-off |
