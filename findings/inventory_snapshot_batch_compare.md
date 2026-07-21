# Inventory snapshot batch comparison

`Analysis date: 2026-06-24. Project: lululemon-01042025.`

Comparison of the six canonical `inventory_snapshot` GCS batches vs what is loaded in `lulu_sourcing_dev.inventory_snapshot`. Unlike `sales_transactions` (full-history re-dumps), each inventory batch is a **collection of point-in-time stock snapshots** at grain `(SKU_ID, LOCATION_ID, DATE)`.

**Related:** [`gcs_eda_2026/batch_folder_report.md`](gcs_eda_2026/batch_folder_report.md), [`raw_inventory_snapshot_eda.md`](raw_inventory_snapshot_eda.md), [`raw_inventory_snapshot_dec04_eda.md`](raw_inventory_snapshot_dec04_eda.md) (DEC04 deep-dive), [`queries/inventory_snapshot_batch_compare.sql`](../queries/inventory_snapshot_batch_compare.sql)

---

## Comparison table

| Drop | Snapshot tag(s) | Files / size | Rows (CSV) | Distinct grains | Snapshot date range | Snapshot date coverage | Loaded in BQ? | Notes |
|---|---|---|---:|---:|---|---|---|---|
| AUG (2025-08-28) | 20250820 | 468 / 938.8 GB | 15,806,573,335 | 15,806,573,335 | 2016-03-01 to 2025-06-05 | 3,384 dates; dense daily history | No | Largest Aug-era historical snapshot |
| OCT re-stage (2025-10-08) | 20250820 + 20250903 | 768 / 1,597 GB | 26,885,138,706 | 16,424,321,894 | 2016-03-01 to 2025-09-02 | 3,473 dates; dense; **1.64× dupes** within CSVs | No | Re-staged Aug + Sept snapshots; not a fresh era |
| NOV (2025-11-18) | 20251118 | 64 / 10.9 GB | 182,212,699 | 182,212,699 | 2025-10-29 to 2025-11-17 | 20 dates; sparse recent-only | Partial | Core Nov content; fully contained in BQ-mix source |
| DEC (2025-12-03) | 20251202 | 64 / 14.3 GB | 238,643,392 | 238,643,392 | 2025-11-12 to 2025-12-01 | 20 dates; sparse recent-only | No | Mid-Dec snapshot era |
| DEC (2025-12-05) | 20251204 | 224 / 474 GB | 7,930,649,631 | 7,930,649,631 | 2023-01-01 to 2025-12-04 | 1,069 dates; dense multi-year | No | **Latest**; consolidated canonical pick |
| 2026-05-08 BQ loaded | 20251118 + 20251204 | 65 / 11.5 GB | 191,998,292 | 191,998,292 | 2023-02-23 to 2025-11-17 | 33 dates; sparse; **2024 gap** (2023 + 2025 only) | **Yes** | Nov re-stage + 1 stray Dec shard; see load dup below |

### BQ table vs source CSV (load duplication)

| Metric | 2026-05-08 source CSVs | `lulu_sourcing_dev.inventory_snapshot` |
|---|---:|---:|
| Rows | 191,998,292 | **403,567,770** |
| Distinct `(SKU, LOC, DATE)` grains | 191,998,292 | 191,998,292 |
| Distinct snapshot dates | 33 | 33 |
| Duplication | None in source (1.0×) | **~2.10×** introduced by Sourcing DAG load |

Source CSVs have **zero grain duplication**. The BQ table's 403.6M rows are exactly **2× the source grain count** (same pattern as PGH / product_attribute_s load bugs).

---

## How to read this table

| Column | Meaning |
|---|---|
| **Snapshot tag(s)** | Embedded `YYYYMMDD` in CSV filenames (delivery batch), not necessarily one tag per row |
| **Rows (CSV)** | Total data rows across all shards in the batch |
| **Distinct grains** | Unique `(SKU_ID, LOCATION_ID, DATE)` triples; when equal to rows, no within-batch dupes |
| **Snapshot date range** | Min/max of the `DATE` column inside the CSV data |
| **Snapshot date coverage** | Count of distinct inventory snapshot dates; inventory is **intentionally sparse** (unlike transaction daily coverage) |

Do **not** interpret inventory like sales_transactions: there is no expectation of continuous daily calendar coverage. A batch with 20 dates covering two weeks is normal for a recent-only drop; AUG/DEC04 batches carry multi-year dense history instead.

---

## NOV vs BQ-mix source overlap

The 2026-05-08 folder (what the DAG loaded) is **not** Nov-only:

| Segment | Distinct grains |
|---|---:|
| In both NOV batch and BQ-mix source | 182,212,699 |
| NOV-only (in Nov batch, not in mix) | **0** |
| Mix-only (in mix, not in Nov batch) | 9,785,593 |
| Union (deduped) | 191,998,292 |

- **100% of the Nov batch grains** are present in the BQ-mix source (Nov is a subset).
- The extra **9.8M mix-only grains** are **13 snapshot dates in 2023** (Feb–Dec 2023), embedded in the 2026-05-08 CSV set alongside the 20 Nov 2025 dates.
- **2024 has zero snapshot dates** in the loaded source (confirmed year breakdown: 2023 = 13 dates / 9.8M rows; 2025 = 20 dates / 182.2M rows).

---

## Key takeaways

1. **BQ table is not the latest batch.** Consolidated / canonical pick is DEC 20251204 (~7.9B grains, 474 GB). BQ holds a tiny Nov-era mix (~192M grains source, ~404M after load dup).

2. **Inventory batches are not interchangeable.** AUG/OCT/DEC04 are multi-year dense history; NOV/DEC02 are sparse recent-only windows. Picking "latest filename tag" without checking `DATE` column span will mislead.

3. **OCT re-stage is not a new era.** It re-stages Aug 20250820 snapshots (plus Sept 20250903) with more shards and **1.64× within-file grain duplication**.

4. **Load duplication is a platform issue, not a client CSV issue.** Source grains = 192M; BQ rows = 404M at identical 33 dates. Dedupe on `(SKU, LOC, DATE)` before downstream use, or fix the Sourcing DAG load.

5. **Live `inventory_master` does not use this table.** It was built from `inventory_snapshot_cleaned` (16.4B rows). See [`raw_sourcing_dev_7_table_eda_summary.md`](raw_sourcing_dev_7_table_eda_summary.md).

---

## Reproduce

External-table JSON defs and aggregate SQL: [`queries/inventory_snapshot_batch_compare.sql`](../queries/inventory_snapshot_batch_compare.sql)

```bash
cd /Users/ejazanwarmd/Desktop/Lululemon

# Example: Nov batch aggregate
bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
  --external_table_definition=t::/tmp/lulu_inv/nov.json \
  'SELECT COUNT(*) AS row_cnt,
          COUNT(DISTINCT FORMAT("%t|%t|%t", SKU_ID, LOCATION_ID, DATE)) AS distinct_grains,
          COUNT(DISTINCT SAFE_CAST(DATE AS DATE)) AS distinct_snapshot_dates,
          MIN(SAFE_CAST(DATE AS DATE)) AS min_snapshot_date,
          MAX(SAFE_CAST(DATE AS DATE)) AS max_snapshot_date
   FROM t'
```

Billing: scans billed to `lululemon-data-scan`. Large batches (AUG ~939 GB, OCT ~1.6 TB, DEC04 ~474 GB) are multi-dollar queries.
