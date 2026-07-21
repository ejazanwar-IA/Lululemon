# SKU details GCS batch pricing scan

`Last updated: 2026-06-16.`

One representative shard per batch scanned from `gs://client_data_lululemon/` (streamed via `gcloud storage cat`, no full download). Full bucket has **3 batches / 219 shards** total.

## Results

| Batch (filename date) | Shards in bucket | Rows scanned (1 shard) | cost > 0 | sell > 0 | Season | Loaded by May DAG? |
|----------------------|------------------:|-----------------------:|---------:|---------:|--------|--------------------|
| **20250807** | 161 | 1,638,151 | **99.93%** | **99.99%** | 25-3FA | No |
| **20250905** | 16 | 118,776 | **0%** | **0%** | 25-3FA | No |
| **20251118** | 42 | 14,243 | **0%** | **0%** | 25-4WI | **Yes** (`2026-05-08/` folder) |

All batches: `PRICE_CURRENCY = DUMMY_CURRENCY` on every row.

## Shard scanned per batch

| Batch | GCS URI |
|-------|---------|
| 20250807 | `gs://client_data_lululemon/Historic/s3_to_gcs/2025-08-28/outbound/sku_details/new/sku_details_20250807_125510_0_0_0.csv` |
| 20250905 | `gs://client_data_lululemon/Historic/s3_to_gcs/2025-08-28/outbound/sku_details/new/sku_details_20250905_183826_0_0_0.csv` |
| 20251118 | `gs://client_data_lululemon/2026-05-08/sku_details_20251118_153905_0_1_0.csv` |

## Takeaways

1. **Not random:** Aug 7 drop is ~100% priced; Sep 5 drop (same season 25-3FA) is 100% zero. Client changed or stripped pricing between drops.
2. **May sourcing extraction** reloaded the **Nov 18 / zero** batch (`2026-05-08/` paths), not the Aug priced batch.
3. **BQ `outbound.sku_details` append** likely mixed Aug (priced) + Sep+ (zero) loads, which explains priced rows in BQ but zeros in later files and in `lulu_sourcing_dev.sku_details`.
4. **DUMMY_CURRENCY** is a separate issue from zero numeric prices; priced Aug rows still use dummy currency.

## Re-run

```bash
python3 scripts/sku_details_price_scan.py \
  --gcs-prefix gs://client_data_lululemon/Historic/s3_to_gcs/2025-08-28/outbound/sku_details/new/ \
  --one-per-batch
```

Machine-readable output: [`sku_details_gcs_batch_pricing_scan.csv`](sku_details_gcs_batch_pricing_scan.csv).

## Client ask

- Why did **20250905** zero out `COST_PRICE` / `SELLING_PRICE` while **20250807** (same season) had real values?
- Which batch should be the **canonical** product master source going forward?
- Will a future drop restore pricing, or is **`price_book`** the intended source?
