# Historic s3_to_gcs batch folder report

`Scan date: 2026-06-23. Prefix: gs://client_data_lululemon/Historic/s3_to_gcs/. Project: lululemon-01042025.`

Method: metadata-only inventory via `gcloud storage ls -l` per batch (`scripts/historic_batch_inventory.py`). No full file downloads, no hash compare.

Machine-readable outputs:

| File | Contents |
|---|---|
| [`batch_inventory_detail.csv`](batch_inventory_detail.csv) | One row per (batch, feed): files, size, snapshot dates, path pattern, sample URI |
| [`batch_feed_matrix.csv`](batch_feed_matrix.csv) | Feed rows x 8 batch columns |
| [`catalog_historic.csv`](catalog_historic.csv) | Refreshed catalog (includes 2026-05-08) |

---

## Executive summary

| Metric | Value |
|---|---|
| Date folders | **8** (2025-08-28 through 2025-12-05, plus **2026-05-08** sample) |
| Total files | **3,342** |
| Total size | **~4.42 TB** |
| Distinct logical feeds | **47** across all batches |
| Standard layout | 7 batches use `outbound/<feed>/[new\|processed\|temp]/` (+ Anaplan `pod_id=N` nesting) |
| Flat layout | **2026-05-08 only**: CSVs at batch root (no `outbound/` tree) |

### Batch roles

| Batch | Role | Feeds | Files | Size |
|---|---|---|---|---|
| 2025-08-28 | **Full IA backfill** (largest catalog breadth) | 31 | 1,262 | 1.65 TB |
| 2025-09-18 | Single-feed drop | 1 | 64 | 32 GB |
| 2025-10-06 | Single-feed drop | 1 | 8 | 40 MB |
| 2025-10-08 | **Inventory-heavy re-stage** (+ eligibility) | 4 | 837 | 1.61 TB |
| 2025-11-18 | **Broad refresh** (transactions, masters, pricing) | 26 | 664 | 354 GB |
| 2025-12-03 | Anaplan demand forecast + inventory | 4 | 97 | 183 GB |
| 2025-12-05 | Inventory snapshot only | 2 | 225 | 474 GB |
| 2026-05-08 | **Sample subset** (flat layout; copied from Nov 2025 drop) | 7 | 185 | 107 GB |

**Key takeaway:** The 8 date folders are **not** copies of the same full drop. Each batch delivers a different feed mix. Where the same logical feed appears in multiple batches, embedded snapshot timestamps in filenames tell you whether it is a **re-staged copy** (same date) or a **new drop** (different date).

---

## Per-batch inventory

### 2025-08-28 (full backfill)

**Structure:** `outbound/<feed>/new/` (standard) + `outbound/anaplan/<subfeed>/new/pod_id=N/` + one feed in `processed/`.

| Feed | Files | Size (GB) | Snapshot date(s) | Path pattern |
|---|---|---|---|---|
| inventory_snapshot | 468 | 938.8 | 20250820 | outbound/inventory_snapshot/new |
| sku_details | 177 | 329.8 | 20250807, 20250905 | outbound/sku_details/new |
| TE2.0_EA_Demand_Forecast | 33 | 170.2 | n/a (Anaplan) | outbound/anaplan/demand_forecast/pod_id=N |
| sales_transactions | 47 | 83.7 | 20250822 | outbound/sales_transactions/new |
| returns_transactions | 48 | 82.8 | 20250903 | outbound/returns_transactions/new |
| transfer_orders | 16 | 24.9 | 20250814 | outbound/transfer_orders/new\|processed |
| planned_sales | 32 | 9.8 | 20250819 | outbound/planned_sales/new |
| + 24 more feeds | | | | see detail CSV |

**Notable:** Only batch with full Anaplan TE2.0 set, spatial_ai, purchase_orders, calendar_hierarchy, and Aug-era sku_details (priced per prior EDA on 20250807 shards).

---

### 2025-09-18 (price_book only)

**Structure:** standard outbound.

| Feed | Files | Size (GB) | Snapshot date(s) |
|---|---|---|---|
| price_book | 64 | 32.4 | 20250917 |

Batch-specific delivery; no other feeds.

---

### 2025-10-06 (class_location_attribute_seasonal only)

| Feed | Files | Size (GB) | Snapshot date(s) |
|---|---|---|---|
| class_location_attribute_seasonal | 8 | 0.04 | 20251001 |

Batch-specific delivery.

---

### 2025-10-08 (inventory re-stage)

**Structure:** standard outbound.

| Feed | Files | Size (GB) | Snapshot date(s) | Notes |
|---|---|---|---|---|
| inventory_snapshot | 768 | 1,597.0 | **20250820**, 20250903 | Dominant; includes Aug snapshot |
| eligibility20251002 | 29 | 14.4 | n/a | Oct eligibility variant |
| eligibility20250818 | 32 | 1.4 | n/a | **Same feed name as 2025-08-28 batch** |
| cc_target | 8 | 0.002 | 20251008 | |

**Overlap flag:** `inventory_snapshot` filenames include **20250820**, matching the Aug 2025 backfill snapshot (likely re-staged copy, not a new extract). `eligibility20250818` also appears in 2025-08-28 with identical file count (32) and size (1.4 GB).

---

### 2025-11-18 (broad refresh)

**Structure:** standard outbound; 26 feeds.

| Feed | Files | Size (GB) | Snapshot date(s) |
|---|---|---|---|
| sales_transactions | 64 | 94.1 | 20251118 |
| returns_transactions | 48 | 87.0 | 20251118 |
| inseason_demand_forecast20251118 | 49 | 71.6 | n/a |
| price_book | 64 | 33.9 | 20251118 |
| transfer_orders | 64 | 26.4 | 20251118 |
| eligibility20251118 | 64 | 14.6 | n/a |
| planned_sales | 32 | 11.1 | 20251118 |
| inventory_snapshot | 64 | 10.9 | 20251118 |
| sku_details | 21 | 0.3 | 20251118 |
| + 17 more master/planning feeds | | | |

**Notable:** Canonical Nov 2025 drop for transactions, returns, pricing, and masters. sku_details here is a small shard set (21 files) vs 177 in Aug backfill.

---

### 2025-12-03 (Anaplan + inventory)

| Feed | Files | Size (GB) | Snapshot date(s) | Path pattern |
|---|---|---|---|---|
| TE2.0_EA_Demand_Forecast_pod | 31 | 162.1 | n/a | outbound/anaplan/demand_forecast |
| inventory_snapshot | 64 | 14.3 | **20251202** | outbound/inventory_snapshot/new |
| TE2.0_EA_Demand_Forecast_pov | 1 | 6.7 | n/a | outbound/anaplan/demand_forecast |
| TE20_EA_Demand_Forecast_pod | 1 | 0.4 | n/a | outbound/anaplan/demand_forecast/**temp** |

**Notable:** Demand forecast pod/pov variants; one file in `temp/` subfolder.

---

### 2025-12-05 (inventory only)

| Feed | Files | Size (GB) | Snapshot date(s) | Notes |
|---|---|---|---|---|
| inventory_snapshot | 224 | 474.0 | **20251204** | Dec snapshot |
| nohup.out | 1 | 0.0 | n/a | **Stray log file** in inventory_snapshot/new |

---

### 2026-05-08 (sample subset, flat layout)

**Structure:** **flat** - all CSVs directly under `2026-05-08/` (no `outbound/` tree). User-generated sample copied from 2025-11-18 drop.

| Feed | Files | Size (GB) | Snapshot date(s) | Path pattern |
|---|---|---|---|---|
| sales_transactions | 64 | 94.1 | 20251118 | flat |
| inventory_snapshot | 65 | 11.5 | 20251118, 20251204 | flat |
| product_group_hierarchy | 16 | 0.5 | 20251118 | flat |
| sku_details | 21 | 0.3 | 20251118 | flat |
| product_attribute_s20251118 | 16 | 0.07 | 20251118 | flat |
| location_group_hierarchy | 1 | 0.001 | 20251118 | flat |
| location_details | 2 | 0.0 | 20251118 | flat |

**Overlap with 2025-11-18:** For shared feeds, file counts and snapshot dates match the Nov batch (e.g. sales_transactions 64 files / snap 20251118 / 94.1 GB). This batch is a **partial re-stage** of the Nov drop, not a new extract. One extra inventory shard uses snap **20251204** (from Dec drop).

---

## Feed coverage matrix (summary)

47 logical feeds; full matrix in [`batch_feed_matrix.csv`](batch_feed_matrix.csv).

| Feed family | Batches present |
|---|---|
| **Full catalog (Aug)** | 2025-08-28 only (31 feeds) |
| **Transactions** | sales/returns in 2025-08-28 (Aug), 2025-11-18 (Nov), 2026-05-08 (sample) |
| **inventory_snapshot** | All batches except 2025-09-18 and 2025-10-06 |
| **sku_details** | 2025-08-28 (177 files), 2025-11-18 (21), 2026-05-08 (21) |
| **price_book** | 2025-09-18, 2025-11-18 |
| **Anaplan TE2.0** | 2025-08-28 (full set), 2025-12-03 (demand forecast pod/pov) |
| **Single-feed drops** | price_book (Sep), class_location_attribute_seasonal (Oct 6) |

---

## Duplicate / overlap findings (metadata)

Interpretation uses embedded `YYYYMMDD` in shard filenames. "Likely same source drop" = same feed + same snapshot date + similar file count/size across batches.

| Finding | Batches | Evidence |
|---|---|---|
| **inventory_snapshot Aug snapshot re-staged** | 2025-08-28, 2025-10-08 | Both include snap **20250820**; Oct batch is 768 files vs Aug 468 (superset / more shards, same timestamp prefix) |
| **eligibility20250818 duplicated** | 2025-08-28, 2025-10-08 | Identical: 32 files, 1.4 GB |
| **2026-05-08 mirrors 2025-11-18** | 2026-05-08, 2025-11-18 | Shared feeds match on file count, size, and snap **20251118** |
| **inventory_snapshot refreshed over time** | 2025-08-28 (20250820), 2025-11-18 (20251118), 2025-12-03 (20251202), 2025-12-05 (20251204) | Same feed name, **different snapshot dates** = different drops |
| **sku_details: Aug vs Nov are different drops** | 2025-08-28 vs 2025-11-18 | Aug: 177 files, snaps 20250807/20250905; Nov: 21 files, snap 20251118 |
| **price_book: Sep vs Nov** | 2025-09-18 vs 2025-11-18 | Same feed, different snaps (20250917 vs 20251118) |

No byte-level hash confirmation was run (metadata-only per plan).

---

## Implications for ingestion

| Feed | Recommended canonical batch | Caveat |
|---|---|---|
| sku_details (priced) | **2025-08-28** (snap 20250807) | Nov/2026-05-08 drops historically zeroed COST_PRICE/SELLING_PRICE |
| sales_transactions / returns | **2025-11-18** | Fresher Nov snapshot; Aug has older snap 20250822 |
| inventory_snapshot (latest) | **2025-12-05** (snap 20251204) | Largest Dec shard set |
| price_book | **2025-11-18** (or Sep if only pricing needed) | Confirm prices populated before load |
| Full master/planning set | **2025-08-28** or **2025-11-18** | Aug = breadth + Anaplan; Nov = refreshed txn/pricing |
| Dev / sample testing | **2026-05-08** | Flat layout; subset only; not IA-standard paths |

---

## Consolidated feed folder (2026-06-23)

A **copy-only** feed-centric layout now lives alongside the 8 date batches:

`gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/`

| Metric | Value |
|---|---|
| Feeds | **35** (canonical pick per feed from batch report) |
| Files | **1,182** CSVs |
| Size | **~1.32 TB** |
| Layout | Flat `consolidated/<feed>/*.csv`; Anaplan keeps `consolidated/anaplan/<subfeed>/new/pod_id=N/` |
| Manifest | [`consolidated/_manifest/feed_sources.csv`](consolidated/_manifest/feed_sources.csv) on GCS; local [`feed_sources.csv`](feed_sources.csv) |

**Validation:** all 35 feeds PASS file-count check; all 8 date batches unchanged (see [`consolidated_validation.md`](consolidated_validation.md)).

**Era mix:** inventory from Dec 2025, sku_details from Aug 2025 (priced), transactions/masters from Nov 2025, demand forecast from Dec 2025. Sign off before repointing IA connectors.

Scripts: `scripts/historic_consolidated_manifest.py`, `scripts/historic_consolidated_copy.py`

---

## Reproduce

```bash
cd /Users/ejazanwarmd/Desktop/Lululemon
python3 scripts/historic_batch_inventory.py --all-batches
python3 scripts/historic_consolidated_manifest.py
python3 scripts/historic_consolidated_copy.py --verify-batches \
  --pre-totals findings/gcs_eda_2026/pre_copy_batch_totals.csv
```
