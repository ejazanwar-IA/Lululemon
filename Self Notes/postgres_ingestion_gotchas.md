# Postgres ingestion gotchas (Lululemon dev)

`Last updated: 2026-05-26.`

## Purpose

Short personal reference from debugging `data_ingestion` on `lulu_dev` — so we do not re-discover the same GSM ↔ procedure mismatches.

## `global` ≠ shared data

`global.product_master` means “master table in the **Lululemon** Postgres DB,” not “all clients.” Always confirm `current_database()` before running fixes.

## Product: three layers

1. **`product_validated_table`** — staging from BQ/Dataflow  
2. **`product_master`** — skinny sync target (`is_attribute=false` GSM cols)  
3. **`product_attributes`** — EAV for `is_attribute=true`  

`sync_product_master` does **not** replace `build_product_attributes`. After moving `l0_name` to PM, still need EAV backfill for `build_product_attributes_filter` gate.

## Store: BOOL vs integer

- `store_master.dc_flag` is **boolean** in Postgres.  
- EAV may still have `'0'/'1'` (or bad `'false'` strings).  
- SAF `loc_type_code` was legacy **bigint** but Lululemon values are **'S'/'W'** → varchar.

## Manual testing in DBeaver

```sql
SET ROLE "mtp-dev";
CALL global.build_store_attributes_filter('');
```

Email username breaks temp table names (`@` in `current_user`).

## Fiscal GSM: use `integer`, not `int2` / `int4` / `smallint`

**Errors:**
- `KeyError: 'int2'` in `generate_transformed_validated_query_fiscal_date`
- Dataflow: `fieldType SMALLINT did not match` → `No value specified for parameter 25` (`fiscal_day`)

**Cause:** OOTB GSM uses `int2`/`int4`/`smallint`. Validation accepts `integer`; Dataflow `BqToDbPipeline` binds BQ **INT64** only to PG **`integer`**, not `smallint`.

**Also:** DAG reads **`fiscal_date_generic_schema_mapping`**, not `fiscal_generic_schema_mapping`.

**Fix:** Re-upload CSV with all numeric cols as **`integer`**. Scripts: `postgres_fiscal_gsm_int2_datatype_fix.sql`, `postgres_fiscal_gsm_dataflow_smallint_fix.sql`.

| Don't | Do |
|---|---|
| `int2`, `smallint`, `int4` | `integer` |

**Burned on:** fiscal_date_mapping DAG, 2026-05-26.

## Fiscal GSM: intermediate must be WIDE (62 master columns)

**Error:** `Column fiscal_day_name in SELECT * EXCEPT list does not exist` in `create_transformation_and_validation_fiscal_date_table`.

**Cause:** OOTB `fiscal_date_generic_schema_mapping` is pass-through — `source_column_name` = master column name. Ingestion reads `fiscal_calendar_intermediate` and expects all GSM columns to exist. The IA Confluence **14-col narrow** intermediate (`DATE`, `fiscal_year_num`, …) is for sourcing joins only, not ingestion.

**Fix:** Rebuild `fiscal_calendar_intermediate` using wide SQL (`create_fiscal_calendar_intermediate_full.sql` / periodic) — same logic as `build_fiscal_date_mapping.sql` + PG stub cols. Re-upload periodic query in Self-Help.

**Burned on:** fiscal_date_mapping DAG validation step, 2026-05-26.

## Fiscal Dataflow: GSM `smallint` breaks BQ→Postgres copy

**Error (Dataflow worker):** `fieldType SMALLINT did not match with any given types` → `No value specified for parameter 25` (`fiscal_day`).

**Cause:** BQ validated table stores all numeric cols as **INT64**. `BqToDbPipeline` builds `dbTableSchema` from GSM `generic_column_datatype`. Beam JDBC cannot bind INT64 to PG **SMALLINT** — parameters stay unset and batch insert fails.

**Fix:** Set GSM numeric cols to **`integer`**, not `smallint`, for fiscal (24 cols). Validation DAG accepts `integer`. `global.fiscal_date_mapping` keeps OOTB smallint DDL; `sync_fiscal_date_mapping` casts on INSERT.

Script: `queries/postgres_fiscal_gsm_dataflow_smallint_fix.sql`  
CSV: re-upload `fiscal_date_generic_schema_mapping_selfhelp_upload.csv` (all former smallint → integer).

**Burned on:** `lulu-dev-di-df-copy-validated-table-warehouse-to-postgresql-fiscal_date`, 2026-05-26.

## DAG one-off checklist

1. DDL migrations (PM/SM)
2. GSM Self-Help upload  
3. `sync_*_master`  
4. Product `l0_name` EAV backfill  
5. PAF/SAF build tasks  
6. Product hierarchy **dedupe** then hierarchy build  

Scripts live under `queries/postgres_*` — see [`findings/postgres_ingestion_platform_patterns.md`](../findings/postgres_ingestion_platform_patterns.md).

**Preflight (before manual CALL / DAG):** `./scripts/postgres_ingestion_preflight.sh` — gates in `queries/postgres_ingestion_preflight_gates.sql`. Requires `psql` and `.cursor/secrets/lulu_dev_postgres.env`.

**Cursor hook:** `.cursor/hooks.json` warns when a shell command runs `CALL global.build_*` / `public.sync_*` without `SET ROLE "mtp-dev"` in the same command.

## Pitfalls

| Symptom | Likely cause |
|---------|----------------|
| N products without attributes | Missing EAV `l0_name` |
| `product_hierarchies_filter_un` | Duplicate active PHF rows per SKU+level |
| `active` specified more than once | Col on PM and in attribute pivot |
| `varchar = bigint` on store SAF | GSM pivot type ≠ SAF column type |
| `Column X in SELECT * EXCEPT list does not exist` (fiscal validation) | Intermediate still narrow — rebuild wide `fiscal_calendar_intermediate` |
| `No value specified for parameter 25` (fiscal Dataflow) | GSM `smallint` in dbTableSchema — BQ INT64 can't bind to JDBC SMALLINT; use `integer` in GSM |
