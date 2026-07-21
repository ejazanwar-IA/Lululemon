# Cleaned Table Builds

`Last updated: 2026-05-13.`

Canonical reference for the build SQL that produces each `_cleaned` raw table in `lululemon_souricng_outbound`. Recovered from `INFORMATION_SCHEMA.JOBS_BY_PROJECT` on 2026-05-13 by [`queries/get_jobs_by_user_list.sql`](../../../queries/get_jobs_by_user_list.sql) (Query B), filtered to 6 known authors over a 365-day window. The full job-history CSV that backs every file in this folder is `bquxjob_578a087_19e218df505.csv` (in user Downloads on 2026-05-13).

## Index

| File | Author | Built | Pattern | Bytes processed | Build count (365d) |
|---|---|---|---|---:|---:|
| [`inventory_snapshot_cleaned.sql`](inventory_snapshot_cleaned.sql) | ejaz.anwar | 2026-05-07 | Sync copy across datasets | 1.4 TB | 1 |
| [`product_group_hierarchy_cleaned.sql`](product_group_hierarchy_cleaned.sql) | ritik.prakash | 2025-11-21 | BQ table CLONE of `_20251119` | 0 B | 1 |
| [`product_group_hierarchy_cleaned_20251119.sql`](product_group_hierarchy_cleaned_20251119.sql) | aniket.nichat | 2025-11-24 | EAV pivot + channel expansion | 485 MB | 2 |
| [`sales_transactions_4y_cleaned_20251119.sql`](sales_transactions_4y_cleaned_20251119.sql) | aniket.nichat | 2025-11-20 | Type-cleaning transform | 85 GB | 2 |
| [`store_master.sql`](store_master.sql) | aniket.nichat | 2025-12-15 | Environment promotion (test → uat) | 598 KB | 3 |
| [`location_group_hierarchy_cleaned_20251119.sql`](location_group_hierarchy_cleaned_20251119.sql) | aniket.nichat | 2025-11-20 | Canonical cleaning recipe | 708 KB | 6 |
| [`location_details_cleaned_20251119.sql`](location_details_cleaned_20251119.sql) | aniket.nichat | 2025-11-20 | Canonical cleaning recipe | 230 KB | 2 |
| [`promotional_events_cleaned_20251119.sql`](promotional_events_cleaned_20251119.sql) | aniket.nichat | 2025-11-24 | LOC_ID padding only | 27 MB | 1 |

## Missing (build SQL not yet recovered)

| Table | Reason | Suggested next move |
|---|---|---|
| `calendar_hierarchy` | No build job in the 6-month window. Either built > 365 days ago or by a 7th author / service account we didn't query. | Re-run Query B with `INTERVAL 1825 DAY` and `dest_table = 'calendar_hierarchy'`. If still empty, check stored procedures (`INFORMATION_SCHEMA.ROUTINES`) and scheduled queries (`bq ls --transfer_config`). |

## Patterns observed across these builds

These patterns are repeated enough across the 8 files to count as the "Lululemon canonical cleaning idiom". Worth applying to any new cleaning work in the same dataset.

### 1. ID padding

```sql
LPAD(CAST(LOC_ID AS STRING), 10, '0') AS LOC_ID
```

Used on: `LOC_ID`, `ID`, `LOCATION_ID_SALES`, `STORE_ID`, etc. Reason: source columns are typed as INTEGER but downstream consumers expect 10-character zero-padded STRING (so that `'0000000123'` joins cleanly to other padded columns). Failure to pad is the root cause of many of the 43 schema-coercion errors observed in the same job history.

### 2. Sentinel scrubbing

```sql
NULLIF(TRIM(<col>), '\\N') AS <col>
```

Used on every STRING column. Strips the `\N` sentinel and any whitespace, replacing with proper NULL. Aligns with workspace gotcha G2 / Section 3.5.

### 3. EAV pivot

For `product_group_hierarchy_cleaned_20251119`:

```sql
MAX(CASE WHEN LEVEL_NAME = 'BRAND' THEN VALUE_NAME END) AS BRAND_NAME
```

One `MAX(CASE ...)` per (LEVEL_NAME, NAME/CODE) pair. Pivots the long-format raw EAV file into a wide table with one row per SKU.

### 4. Channel expansion

For `product_group_hierarchy_cleaned_20251119`:

```sql
CROSS JOIN UNNEST(['ECOMM','RETAIL']) AS channel
```

Doubles the row count by emitting one row per (bare SKU, channel) combination. The downstream key `sku_id_code` is then `CONCAT(SKU_ID, '_', channel)`. This is the source of the channel suffix every master build joins on — and the answer to the previously-mysterious `channel` column in our column-mapping work.

### 5. CLONE for snapshot pointers

For `product_group_hierarchy_cleaned`:

```sql
CREATE TABLE <new>
CLONE <suffixed_snapshot>
```

Zero-byte BQ table clone — the no-suffix and `_20251119` variants share underlying storage. This is why their row counts and content are byte-identical despite "different" build dates.

### 6. SELECT-DISTINCT-* for environment promotion

For `store_master`:

```sql
SELECT DISTINCT * FROM <test_dataset>.store_master
```

Used to copy a master between environments (`lulu_ingestion_test` → `lulu_ingestion_uat`). The DISTINCT is defensive against any duplicates in the upstream test data.

## How to refresh this folder

If the cleaning logic is updated upstream and these files need a refresh:

1. Re-run [`queries/get_jobs_by_user_list.sql`](../../../queries/get_jobs_by_user_list.sql) Query B (give to DevOps if you don't have `bigquery.jobs.listAll` yourself).
2. Save results to CSV.
3. Re-run the extraction script (an inline Python block — see chat history for 2026-05-13, or ask the assistant to re-run the same script with the new CSV path).
4. Verify the diffs against the existing files before committing.
