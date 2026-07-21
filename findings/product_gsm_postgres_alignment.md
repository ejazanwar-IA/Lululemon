# Product GSM ↔ Postgres alignment

`Last updated: 2026-05-20.`

Documents reconciliation of Lululemon `product_generic_schema_mapping` (GSM) with live `lulu_dev` Postgres and BQ `product_master`, driven by DI team rules and `sync_product_master()` failures.

## DI rules (applied)

| Flag | Postgres target |
|------|-----------------|
| `is_attribute = false` | `global.product_master` (+ copied to `product_attributes_filter`) |
| `is_attribute = true` | `global.product_attributes_filter` only |
| `required_in_product = true` | Must exist on **both** PG tables (except PM columns with server defaults) |

`sync_product_master()` only upserts columns where `required_in_product = true` **and** `is_attribute = false`.

## Architecture (before fix)

| Object | Role | Row/column notes |
|--------|------|------------------|
| BQ `lulu_ingestion_dev.product_master` | Analytics master | ~1.98M rows; 29 business columns |
| `public.product_validated_table` | PG staging | Full Lululemon shape from Dataflow |
| `global.product_master` | PG sync target | **16 generic cols only** — missing `article`, `l0_name`, `product_bucket_code` |
| `global.product_attributes_filter` | PG attributes | **61 cols** — client DDL; matches almost all GSM rows |
| Live GSM (pre-upload) | 46 rows | `l0_id`–`l8_id` wrongly `is_attribute=false` → sync referenced missing PM columns |

**Sync error:** `column "article" does not exist` on `global.product_master` (last attempts 2026-05-15, 2026-05-19). Last successful `sync_product_master` **end** status: **2025-11-24**.

## Corrected GSM CSV (repo)

| File | Purpose |
|------|---------|
| [`reference_docs/Lululemon/Generic Schema Mappings/product_master_columns.csv`](../reference_docs/Lululemon/Generic%20Schema%20Mappings/product_master_columns.csv) | Canonical |
| [`reference_docs/Lululemon/Generic Schema Mappings/product_master_columns_selfhelp_upload.csv`](../reference_docs/Lululemon/Generic%20Schema%20Mappings/product_master_columns_selfhelp_upload.csv) | Self-Help upload copy |

**51 rows** (was 46): added formula rows for `active`, `clearance`, `price`, `cost`, `original_price`.

### Material flag changes (vs export / live GSM)

| Column | Change |
|--------|--------|
| `l0_name` | `is_attribute` **true → false**; `is_hierarchy` **false → true**; `hierarchy_level` **0** |
| `l0_id`, `l2_id`–`l8_id` | `is_attribute` **false → true** (stay on PAF only) |
| `product_name`, `product_description` | `is_attribute` **true → false** (generic PM shell) |
| `active_flag` | `required_in_product` **true → false** (PAF attribute; BQ source only) |
| `active` | **New** formula row: `CASE WHEN active_flag = 1 THEN TRUE ELSE FALSE END`, `is_attribute=false` |
| `clearance`, `price`, `cost`, `original_price` | **New** formula rows on PM shell (`required_in_product=false`) |
| `ordering` | `generic_column_datatype` **integer → varchar** (matches PAF) |
| `article`, `product_code` | `hierarchy_level` set to **9** and **10** |

### `is_attribute = false` columns (sync to `global.product_master`)

`product_code`, `product_name`, `product_description`, `article`, `l0_name`, `product_bucket_code`, `active`, `clearance`, `price`, `cost`, `original_price`

### Postgres DDL still required

After GSM upload, **`global.product_master`** must gain (see [`queries/postgres_global_product_master_ddl_migration.sql`](../queries/postgres_global_product_master_ddl_migration.sql)):

| Column | In corrected GSM `is_attribute=false`? | On PM today? |
|--------|--------------------------------------|--------------|
| `article` | Yes | **No** |
| `l0_name` | Yes | **No** |
| `product_bucket_code` | Yes | **No** |
| `product_name`, `product_description`, `active`, … | Yes | **Yes** (generic shell) |

### PAF-only extras (not in GSM)

`rcl_hash`, `style_name`, `color_name` — present in PAF DDL only; omit from GSM unless added to BQ intermediate later.

### BQ `product_master` columns (29)

All `required_in_product=true` GSM source columns exist on BQ except formula-only PM shell fields (`active`, `clearance`, `price`, `cost`, `original_price`).

## Upload order

1. Platform runs DDL on `lulu_dev` (then prod via `mtp-database` PR).
2. Self-Help upload `product_master_columns_selfhelp_upload.csv`.
3. Clear Airflow from `Read_Mapping_Data_product` onward.
4. Re-run `create_master_table_postgresql_product`.
5. Re-run diagnostics in [`queries/postgres_lulu_dev_diagnostics.sql`](../queries/postgres_lulu_dev_diagnostics.sql) (sections 6–8).

## Verification status (2026-05-19)

| Check | Pre-DDL / pre-upload (live DB) | After user DDL + GSM upload |
|-------|--------------------------------|-----------------------------|
| Live GSM `is_attribute=false` missing on PM | **10** (`article`, `l0_id`–`l8_id`, `product_bucket_code`) | N/A — replace GSM |
| **Corrected CSV** `is_attribute=false` + `required` missing on PM | **3** (`article`, `l0_name`, `product_bucket_code`) | Expect **0** after DDL |
| `sync_product_master` latest status | `pm delta calculate` — `column "article" does not exist` | Expect `end` |

**Corrected CSV sync targets (`is_attribute=false`, `required_in_product=true`):**  
`product_code`, `product_name`, `product_description`, `article`, `l0_name`, `product_bucket_code`, `active`

Agent re-check (2026-05-19): After DDL on `global.product_master` + GSM upload, `sync_product_master` failed on `column "active" does not exist` because `public.product_validated_table` had `active_flag` only. Fix: `ALTER` + backfill `active` from `active_flag` on validated table → **`status = end`** in ~123s (log_code `21944ed9-...`).

**Permanent fix:** ensure BQ→Postgres Dataflow or validated build writes `active` (bool) per GSM formula row, or keep validated-table backfill in migration script.

## `build_product_attributes_filter` — missing `l0_name` in EAV (2026-05-20)

Airflow task `create_attributes_filter_table_postgresql_product` failed:

```text
Ingestion needs attention: 71356 products without attributes.
```

**Cause:** `global.build_product_attributes_filter()` gates on every `product_master` row having `attribute_name = 'l0_name'` in **`global.product_attributes`** (EAV). GSM now has `l0_name` as `is_attribute=false`, so `sync_product_master` writes `global.product_master.l0_name` but does **not** insert EAV rows. **71,356** products had `l0_name` on PM only (all with populated `l0_name`).

**Fix (dev applied):** backfill EAV from PM — [`queries/postgres_product_attributes_l0_name_backfill.sql`](../queries/postgres_product_attributes_l0_name_backfill.sql). Then `CALL global.build_product_attributes_filter('')` → **SUCCESS** (2,618,116 PAF rows).

**DAG order:** run backfill after `sync_product_master` / before `create_attributes_filter_table_postgresql_product`, until platform or `build_product_attributes` also writes `l0_name` EAV for PM-only hierarchy cols.

## `build_product_hierarchies_filter` — duplicate `(path, level)` (2026-05-20)

Airflow task `create_hierarchies_filter_table_postgresql_product` failed:

```text
duplicate key value violates unique constraint "product_hierarchies_filter_un"
```

**Cause:** ~2.55M SKUs had **two active** `product_hierarchies_filter` rows at the same `level` with the same `path->>'product_code'` but different `path` JSON (legacy path included `product_code_original`; new PAF path does not). `build_product_hierarchies_filter` UPDATE sets both to the same new `path` → violates `UNIQUE (path, level)`.

**Fix:** deactivate duplicate actives per `(product_code, level)` — [`queries/postgres_product_hierarchies_filter_dedupe.sql`](../queries/postgres_product_hierarchies_filter_dedupe.sql). Dev: deactivated **2,546,760** rows; then `build_product_hierarchies_filter` + `_flattern` **succeeded** (~8–9 min).

**DAG order:** run dedupe after `create_attributes_filter_table_postgresql_product` (PAF rebuild) and before `create_hierarchies_filter_table_postgresql_product`.

## `ordering` type (product_anomaly_data_persist)

| Layer | Type | Notes |
|-------|------|--------|
| BQ `product_master` / QC / `product_anomaly` | **INT64** | GSM `generic_column_datatype=bigint` (reverted from `varchar`) |
| Postgres `product_attributes_filter.ordering` | **varchar** | Unchanged; load casts INT → text |
| `product_anomaly_all` (history) | **INT64** | Option B migration in [`queries/product_anomaly_all_ordering_type_fix.sql`](../queries/product_anomaly_all_ordering_type_fix.sql) |

Re-upload [`product_master_columns_selfhelp_upload.csv`](../reference_docs/Lululemon/Generic%20Schema%20Mappings/product_master_columns_selfhelp_upload.csv) so Self-Help matches `bigint`. If persist fails on `ordering` again, run PRE-FLIGHT in the fix SQL (source and target must match).

## Store master sync (2026-05-19)

| Step | Result |
|------|--------|
| DDL `s3_id` on `global.store_master` + backfill | 1,741 rows updated |
| First `sync_store_master` | Failed — `store_name` NOT NULL; GSM had `store_name` as `is_attribute=true` (sync only sent `store_code`, `s3_id`) |
| GSM fix: `store_name` → `is_attribute=false` | Applied on `lulu_dev` |
| Second `sync_store_master` | **`status = end`** (~0.5s) |

See [`queries/postgres_global_store_master_ddl_migration.sql`](../queries/postgres_global_store_master_ddl_migration.sql). Mirror `store_name` flag in Self-Help store GSM upload so it persists.
