# Consolidated feed validation

`Validation date: 2026-06-23. Prefix: gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/. Project: lululemon-01042025.`

Copy-only consolidation from 8 date batches into feed-centric `consolidated/` per [`consolidated_feed_rules.csv`](consolidated_feed_rules.csv) and [`consolidated_manifest.csv`](consolidated_manifest.csv).

## Verdict: PASS

| Check | Result |
|---|---|
| Feeds copied | **35 / 35** |
| CSV object count | **1,182** (matches manifest) |
| Total size | **~1.32 TB** |
| Date batch integrity (8 folders) | **PASS** (file count + bytes unchanged vs pre-copy snapshot) |
| Anaplan `store_priority` pods | **3 / 3** (`pod_id=18`, `68`, `88`) |
| Anaplan `demand_forecast` | **32 / 32** (31 pod + 1 pov) |

Manifest uploaded to GCS: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/_manifest/feed_sources.csv`

Local mirror: [`feed_sources.csv`](feed_sources.csv)

---

## Layout

```
Historic/s3_to_gcs/consolidated/
  inventory_snapshot/*.csv
  sku_details/*.csv
  sales_transactions/*.csv
  ...
  anaplan/<subfeed>/new/pod_id=N/*.csv   (Anaplan exception only)
  _manifest/feed_sources.csv
```

Standard feeds are flat (no `outbound/` or `new/` wrapper). Anaplan TE2.0 feeds preserve `new/pod_id=N/` under `consolidated/anaplan/<subfeed>/`.

**Source date batches were not modified.** All copies used `gcloud storage cp` only.

---

## Per-feed file counts

| Feed | Source batch | Layout | Files | Size (GB) | Status |
|---|---|---|---:|---:|---|
| inventory_snapshot | 2025-12-05 | flat | 224 | 474.0 | PASS |
| sku_details | 2025-08-28 | flat | 177 | 329.8 | PASS |
| sales_transactions | 2025-11-18 | flat | 64 | 94.1 | PASS |
| returns_transactions | 2025-11-18 | flat | 48 | 87.0 | PASS |
| price_book | 2025-11-18 | flat | 64 | 33.9 | PASS |
| transfer_orders | 2025-11-18 | flat | 64 | 26.4 | PASS |
| planned_sales | 2025-11-18 | flat | 32 | 11.1 | PASS |
| assortment_plan | 2025-11-18 | flat | 32 | 1.2 | PASS |
| purchase_orders | 2025-11-18 | flat | 16 | 1.3 | PASS |
| product_group_hierarchy | 2025-11-18 | flat | 16 | 0.5 | PASS |
| location_details | 2025-11-18 | flat | 2 | 0.0 | PASS |
| location_group_hierarchy | 2025-11-18 | flat | 1 | 0.0 | PASS |
| dc_store_mapping | 2025-11-18 | flat | 10 | 0.1 | PASS |
| calendar_hierarchy | 2025-11-18 | flat | 1 | 0.0 | PASS |
| product_attribute_s | 2025-11-18 | flat | 16 | 0.1 | PASS |
| product_attribute_s_seasonal | 2025-11-18 | flat | 16 | 0.1 | PASS |
| product_attribute_so | 2025-11-18 | flat | 16 | 0.1 | PASS |
| product_attribute_so_seasonal | 2025-11-18 | flat | 16 | 0.1 | PASS |
| inseason_demand_forecast | 2025-11-18 | flat | 49 | 71.6 | PASS |
| promotional_events | 2025-11-18 | flat | 5 | 0.0 | PASS |
| spatial_ai | 2025-11-18 | flat | 2 | 0.0 | PASS |
| style_option | 2025-11-18 | flat | 5 | 0.1 | PASS |
| cc_target | 2025-11-18 | flat | 16 | 0.0 | PASS |
| class_location_attribute_seasonal | 2025-11-18 | flat | 16 | 0.0 | PASS |
| eligibility | 2025-11-18 | flat | 64 | 14.6 | PASS |
| preseason_product_hierarchy | 2025-11-18 | flat | 8 | 0.1 | PASS |
| delivery_week_logic | 2025-08-28 | flat | 1 | 0.0 | PASS |
| min_pres_eol | 2025-08-28 | flat | 1 | 0.0 | PASS |
| TE2.0_EA_Assortment_Parameters | 2025-08-28 | anaplan | 33 | 0.7 | PASS |
| TE2.0_EA_FDOD_Alloc | 2025-08-28 | anaplan | 33 | 0.1 | PASS |
| TE2.0_EA_FDOD_Replen | 2025-08-28 | anaplan | 33 | 1.9 | PASS |
| TE2.0_EA_Minimum_Presentation | 2025-08-28 | anaplan | 33 | 1.3 | PASS |
| TE2.0_EA_Transit_Calendar | 2025-08-28 | anaplan | 33 | 4.2 | PASS |
| Inventory_Parameters_Store_Priority | 2025-08-28 | anaplan | 3 | 0.0 | PASS |
| TE2.0_EA_Demand_Forecast | 2025-12-03 | anaplan | 32 | 168.8 | PASS |

---

## Era mix (intentional)

Consolidated picks the best canonical source per feed, not a single snapshot date:

| Feed | Batch | Snapshot / note |
|---|---|---|
| inventory_snapshot | 2025-12-05 | snap 20251204 (latest) |
| sku_details | 2025-08-28 | snaps 20250807 / 20250905 (priced Aug shards) |
| TE2.0 demand forecast | 2025-12-03 | pod + pov from Dec batch |
| Most txn / master feeds | 2025-11-18 | snap 20251118 |
| Other Anaplan TE2.0 | 2025-08-28 | Aug pod partitions |

Sign off on era mix before repointing IA dev/prod connectors at `consolidated/`.

---

## Date batch integrity

Compared post-copy listing to [`pre_copy_batch_totals.csv`](pre_copy_batch_totals.csv):

| Batch | Files | Bytes | Status |
|---|---:|---:|---|
| 2025-08-28 | 1,262 | 1,654,064,674,596 | PASS |
| 2025-09-18 | 64 | 32,406,911,612 | PASS |
| 2025-10-06 | 8 | 36,520,078 | PASS |
| 2025-10-08 | 837 | 1,612,814,487,814 | PASS |
| 2025-11-18 | 665 | 353,651,812,303 | PASS |
| 2025-12-03 | 101 | 183,442,673,214 | PASS |
| 2025-12-05 | 225 | 473,996,764,143 | PASS |
| 2026-05-08 | 185 | 106,497,159,041 | PASS |

---

## Reproduce

```bash
cd /Users/ejazanwarmd/Desktop/Lululemon

# Regenerate manifest from rules + inventory
python3 scripts/historic_consolidated_manifest.py

# Copy all feeds (copy-only; optional batch integrity check)
python3 scripts/historic_consolidated_copy.py --verify-batches \
  --pre-totals findings/gcs_eda_2026/pre_copy_batch_totals.csv

# Upload manifest
gcloud storage cp findings/gcs_eda_2026/feed_sources.csv \
  gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/_manifest/feed_sources.csv \
  --project=lululemon-01042025
```

Copy log: [`consolidated_copy.log`](consolidated_copy.log)
