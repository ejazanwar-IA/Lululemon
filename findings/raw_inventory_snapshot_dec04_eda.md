# EDA — DEC04 inventory_snapshot GCS batch (20251204)

`Analysis date: 2026-06-24. Project: lululemon-01042025.`

Standalone profile of the **latest** `inventory_snapshot` GCS batch (tag `20251204`, drop folder `2025-12-05`). Source is GCS only; this batch is **not** loaded in `lulu_sourcing_dev.inventory_snapshot` today (that table holds a Nov-era mix from `2026-05-08`).

**Related:** [`inventory_snapshot_batch_compare.md`](inventory_snapshot_batch_compare.md), [`raw_inventory_snapshot_eda.md`](raw_inventory_snapshot_eda.md) (Nov BQ mix), [`queries/inventory_snapshot_dec04_eda.sql`](../queries/inventory_snapshot_dec04_eda.sql)

---

## Batch identity

| Attribute | Value |
|---|---|
| Drop folder | `2025-12-05` |
| Snapshot tag | `20251204` |
| GCS path | `gs://client_data_lululemon/Historic/s3_to_gcs/2025-12-05/outbound/inventory_snapshot/new/inventory_snapshot*.csv` |
| Consolidated | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/inventory_snapshot/` |
| Shards | 224 CSV files (~474 GB) |
| Stray file | `nohup.out` in folder (excluded from `inventory_snapshot*.csv` URI pattern) |

---

## Phase 0 — File layer

| Check | Result |
|---|---|
| CSV shard count | **224** |
| Total size | **474.0 GB** (min shard 500 MB, median 2.1 GB, max 4.3 GB) |
| Header | 7 columns per [`headers_historic.txt`](gcs_eda_2026/headers_historic.txt): `SKU_ID`, `LOCATION_ID`, `DATE`, `UNITS_ON_HAND`, `UNITS_AVAILABLE`, `UNITS_INBOUND`, `SNAPSHOT_TIME` |
| vs `inventory_snapshot_cleaned` | No `CHANNEL` / `SKU_ID_CHANNEL`; grain is bare `(SKU_ID, LOCATION_ID, DATE)` |
| Sharding pattern | Sample shards hold **one business `DATE`** per file group (location/SKU subsets within date) |

Sample row (shard `..._0_0_0.csv`):

| SKU_ID | LOCATION_ID | DATE | OH | AV | INB | SNAPSHOT_TIME |
|---|---|---|---:|---:|---:|---|
| 145350546 | 22501 | 2023-09-03 | 0 | 0 | 9 | 2023-09-04T07:11:42Z |

---

## Phase 1 — Foundation

BQ external-table scan (`lululemon-data-scan`, ~474 GB source):

| Metric | Value |
|---|---:|
| Total rows | **7,930,649,631** |
| Distinct `(SKU_ID, LOCATION_ID, DATE)` grains | **7,930,649,631** |
| Dup ratio | **1.0** (zero within-batch duplication) |
| Distinct `SKU_ID` | **980,523** |
| Distinct `LOCATION_ID` | **1,574** |
| Snapshot date range | **2023-01-01 → 2025-12-04** |
| Distinct snapshot dates | **1,069** |
| Calendar days in range | **1,069** |
| Full daily continuity | **Yes** (no missing calendar days) |

---

## Phase 2 — Temporal profile

### Year rollup

| Year | Rows | Distinct grains | Dates | Distinct SKU | Distinct LOC |
|---:|---:|---:|---:|---:|---:|
| 2023 | 2,306,065,298 | 2,306,065,298 | 365 | 646,142 | 1,316 |
| 2024 | 2,787,396,633 | 2,787,396,633 | 366 | 852,571 | 1,436 |
| 2025 | 2,837,187,700 | 2,837,187,700 | 338 | 980,512 | 1,574 |

Assortment and location coverage **grow over time** (646K → 981K SKUs; 1,316 → 1,574 locations).

### Daily row volume

| Stat | Rows per snapshot date |
|---|---:|
| Min | 1,928,460 |
| Median | 5,987,041 |
| Average | 7,418,756 |
| Max | 76,563,656 |

### Outliers (>3σ from mean daily row count)

| Snapshot date | Rows | Ratio to avg | Notes |
|---|---:|---:|---|
| 2025-08-17 | 25,547,373 | 3.44× | Assortment spike, not grain dupes |
| 2025-11-09 | 25,331,917 | 3.41× | Same pattern as Nov-era BQ mix spike dates |
| 2025-10-12 | 25,141,453 | 3.39× | |

These are **volume outliers** on specific calendar dates (likely wider SKU/location coverage that day), not duplicate grains (dup ratio remains 1.0 batch-wide).

---

## Phase 3 — Completeness and sentinels

| Check | Count | % of 7.93B |
|---|---:|---:|
| NULL/empty keys (`SKU`, `LOC`, `DATE`, `SNAPSHOT_TIME`) | **0** | 0% |
| `UNITS_ON_HAND = -1` (sentinel) | 52,819,779 | 0.67% |
| `UNITS_ON_HAND < -1` (real negative) | 15,495,253 | 0.20% |
| `UNITS_ON_HAND = 0` | 2,516,328,890 | 31.7% |
| `UNITS_ON_HAND > 0` | 5,346,005,709 | 67.4% |
| `UNITS_AVAILABLE = -1` | 64,186,382 | 0.81% |
| `UNITS_AVAILABLE` real negative | 22,196,239 | 0.28% |
| `UNITS_INBOUND = 0` | 7,303,064,414 | 92.1% |
| `UNITS_INBOUND > 0` | 626,116,324 | 7.9% |
| `UNITS_INBOUND < 0` | 1,468,893 | 0.02% |

Extremes: OH/AV min **-3,704,869**, max **700,024**; INB max **111,631**.

**Sentinel policy:** treat `-1` on OH/AV as NULL downstream (same as [`raw_inventory_snapshot_eda.md`](raw_inventory_snapshot_eda.md)).

---

## Phase 4 — Distributions

| Metric | OH | AV | INB |
|---|---:|---:|---:|
| p25 | 0 | — | — |
| p50 (median) | **1** | **1** | **0** |
| p75 | 3 | — | — |
| p99 | 147 | — | 5 |

Half of all rows have OH ≤ 1; inbound is zero on >90% of grains.

---

## Phase 5 — Business logic

| Rule | Rows | % |
|---|---:|---:|
| `UNITS_AVAILABLE > UNITS_ON_HAND` | 2,383,297 | 0.03% |
| `OH > 0` AND `AV = 0` | 480,224,315 | 6.1% |
| `INB > 0` AND `OH = 0` (pipeline stock) | 301,841,349 | 3.8% |

### SNAPSHOT_TIME vs business DATE

| Lag (days) | Rows | % |
|---|---:|---:|
| +1 day (capture next calendar day) | 5,637,138,499 | **71.1%** |
| Same day (0) | 2,256,690,601 | 28.5% |
| +2 to +3 | 7,836,799 | 0.10% |
| Negative (SNAPSHOT_TIME before DATE) | 26,557,407 | 0.33% |
| > +3 | 2,426,325 | 0.03% |

`SNAPSHOT_TIME` range: **2019-09-23** to **2025-12-04** (historical backfill rows can have capture timestamps predating business DATE).

---

## Phase 6 — Referential integrity (sample date 2025-12-04)

Distinct `(SKU_ID, LOCATION_ID)` pairs on latest date: **1,928,460** (367 locations, 109,099 SKUs).

| Join target | Orphan rate | Notes |
|---|---:|---|
| `product_master` (bare SKU via `SPLIT(product_code,'_')[0]`) | **0%** | 109,099 / 109,099 SKUs matched |
| `location_details.id` | **0%** | 367 / 367 locations matched |
| `store_master.store_code` | **100%** | `LOCATION_ID` does not match `store_code` format on this join key; use `location_details` for raw inventory joins |

---

## Summary verdict

| Area | Status |
|---|---|
| Grain uniqueness | **Pass** (1.0×) |
| Key completeness | **Pass** |
| Date continuity (2023–2025) | **Pass** (1,069/1,069 days) |
| Sentinels / negatives | **Known pattern** (document `-1` handling) |
| Join readiness | **Pass** for bare SKU + `location_details`; **do not** join `store_master` on raw `LOCATION_ID` without mapping |
| BQ load status | **Not loaded**; recommend reload from consolidated DEC04 path with dedupe guard |

---

## Reproduce

External table JSON (explicit STRING schema — required; autodetect types unit columns as INT64 and breaks sentinel checks):

```json
{
  "sourceFormat": "CSV",
  "sourceUris": ["gs://client_data_lululemon/Historic/s3_to_gcs/2025-12-05/outbound/inventory_snapshot/new/inventory_snapshot*.csv"],
  "schema": {
    "fields": [
      {"name": "SKU_ID", "type": "STRING"},
      {"name": "LOCATION_ID", "type": "STRING"},
      {"name": "DATE", "type": "STRING"},
      {"name": "UNITS_ON_HAND", "type": "STRING"},
      {"name": "UNITS_AVAILABLE", "type": "STRING"},
      {"name": "UNITS_INBOUND", "type": "STRING"},
      {"name": "SNAPSHOT_TIME", "type": "STRING"}
    ]
  },
  "csvOptions": {"skipLeadingRows": 1, "quote": "\""}
}
```

SQL workbook: [`queries/inventory_snapshot_dec04_eda.sql`](../queries/inventory_snapshot_dec04_eda.sql)
