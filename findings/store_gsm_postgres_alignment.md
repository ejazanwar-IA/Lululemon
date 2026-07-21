# Store GSM ↔ Postgres alignment

`Last updated: 2026-05-20.`

Companion to [`product_gsm_postgres_alignment.md`](product_gsm_postgres_alignment.md).

## Corrected CSV (Self-Help upload)

| File | Purpose |
|------|---------|
| [`reference_docs/Lululemon/Generic Schema Mappings/store_master_columns.csv`](../reference_docs/Lululemon/Generic%20Schema%20Mappings/store_master_columns.csv) | Canonical |
| [`reference_docs/Lululemon/Generic Schema Mappings/store_master_columns_selfhelp_upload.csv`](../reference_docs/Lululemon/Generic%20Schema%20Mappings/store_master_columns_selfhelp_upload.csv) | Upload copy |

**34 rows** exported from live `lulu_dev` GSM with these corrections:

| Column | Change |
|--------|--------|
| `store_name` | `is_attribute` **true → false** (required for `sync_store_master`; `global.store_master.store_name` is NOT NULL) |
| `store_code` | `is_attribute=false`, `is_pk=true`, `is_hierarchy=true`, `unique_by=true` |
| `s3_id` | `is_attribute=false` (unchanged intent; needs DDL on `global.store_master`) |
| `s0_name`–`s4_name` | `is_hierarchy=true`, `hierarchy_level` 0–4 |

### `is_attribute = false` (sync to `global.store_master`)

`store_code`, `store_name`, `s3_id`

## Postgres DDL

[`queries/postgres_global_store_master_ddl_migration.sql`](../queries/postgres_global_store_master_ddl_migration.sql) — adds `s3_id` + backfill. Script includes a **PRE-FLIGHT** query; run it on each environment before `ALTER`.

### Pre-check result: `lulu_dev` @ `10.106.0.4` (2026-05-19)

| Check | Result |
|-------|--------|
| `global.store_master` has `s3_id` | **Yes** (DDL already applied) |
| GSM sync cols missing on PM | **0** |
| `sync_store_master` | **`end`** |

**Prod:** this repo only has MCP/credentials for **`lulu_dev`**, not a separate prod Postgres. Run the same PRE-FLIGHT on prod before deploying DDL there.

## Verification (2026-05-19 on `lulu_dev`)

| Step | Result |
|------|--------|
| DDL `s3_id` on `global.store_master` | OK |
| GSM `store_name` → `is_attribute=false` | Applied (also in CSV for Self-Help) |
| `sync_store_master()` | **`status = end`** |

## Note on `store_attributes_filter`

Live PAF has legacy Signet-style columns (`country`, `district`, `name`, …) plus Lululemon columns from GSM. GSM rows align with **validated / BQ `store_master`** (18 cols), not every legacy PAF column.

## `build_store_attributes_filter` (2026-05-20)

Airflow task `create_attributes_filter_table_postgresql_store` calls `global.build_store_attributes_filter`. Fixes on `lulu_dev`:

| Issue | Fix |
|-------|-----|
| `column "active" specified more than once` | GSM `active` → `is_attribute=false` (column on `global.store_master`, not pivoted) |
| `invalid input syntax for type integer: "false"` | 9 `store_attributes` rows had `dc_flag='false'` → normalized to `0`/`1` |
| `operator does not exist: character varying = bigint` | `loc_type_code`: SAF was legacy `bigint`; data is `S`/`W` → `ALTER … TYPE varchar` |
| `dc_flag` pivot vs SAF | GSM `generic_column_datatype` **integer → boolean** (matches SAF + BQ BOOL) |
| DBeaver `syntax error at or near "@"` | Email `current_user` in temp table name — **manual only**; use `SET ROLE "mtp-dev"` before `CALL` |

Script: [`queries/postgres_store_attributes_filter_build_fix.sql`](../queries/postgres_store_attributes_filter_build_fix.sql).

CSV updates: `active` (`is_attribute=false`, `boolean`), `dc_flag` (`boolean`).

**Verified:** `CALL global.build_store_attributes_filter('')` succeeds under role `mtp-dev`.
