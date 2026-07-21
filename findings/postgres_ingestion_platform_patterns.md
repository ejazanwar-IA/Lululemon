# Postgres ingestion platform patterns (Lululemon `lulu_dev`)

`Last updated: 2026-05-20.`

Reference for IA **data_ingestion** DAG steps that touch Postgres. All objects below live in the **Lululemon** database (`lulu_dev` on dev) unless stated otherwise. Schema name **`global`** = tenant master tables, not cross-client shared data.

Related: [`product_gsm_postgres_alignment.md`](product_gsm_postgres_alignment.md), [`store_gsm_postgres_alignment.md`](store_gsm_postgres_alignment.md), [`lululemon_ingestion_end_to_end.md`](lululemon_ingestion_end_to_end.md).

---

## 1. Schema map

| Schema | Role | Examples |
|--------|------|----------|
| `global` | Masters, GSM, filters, EAV attributes | `product_master`, `product_attributes`, `product_attributes_filter`, `product_hierarchies_filter`, `*_generic_schema_mapping` |
| `public` | Validated staging from Dataflow | `product_validated_table`, `store_validated_table` |
| `public` | Sync procedures | `sync_product_master()`, `sync_store_master()` |

**BQ masters** are separate: `lululemon-01042025.lulu_ingestion_dev.*` — do not confuse with Postgres `global.*`.

---

## 2. Core tables (product)

| Table | Grain / keys | Fed by |
|-------|----------------|--------|
| `public.product_validated_table` | 1 row / `product_code` | Dataflow from BQ |
| `global.product_master` | 1 row / `product_code` | `sync_product_master` (GSM `is_attribute=false`) |
| `global.product_attributes` | EAV: (`product_code`, `attribute_name`) → `attribute_value` | `build_product_attributes` (GSM `is_attribute=true` or `is_pk`) |
| `global.product_attributes_filter` | 1 row / `product_code`; PK with `l0_name` in DDL | `build_product_attributes_filter` |
| `global.product_hierarchies_filter` | 1 row / (`path` jsonb, `level`); `hierarchy_code` PK | `build_product_hierarchies_filter` |

**Store analogs:** `store_master`, `store_attributes`, `store_attributes_filter`, `store_generic_schema_mapping`.

---

## 3. Procedures ↔ Airflow tasks

| Airflow task (typical) | Postgres `CALL` | Duration (dev, order of magnitude) |
|------------------------|-----------------|-------------------------------------|
| (upstream) | `public.sync_product_master()` | ~2 min |
| `create_attributes_filter_table_postgresql_product` | `global.build_product_attributes_filter('')` | minutes |
| `create_hierarchies_filter_table_postgresql_product` | `global.build_product_hierarchies_filter()`; `..._flattern()` | ~8–9 min + seconds |
| (upstream) | `public.sync_store_master()` | sub-second (small store count) |
| `create_attributes_filter_table_postgresql_store` | `global.build_store_attributes_filter('')` | seconds |

**Also used (not always separate Airflow task):** `global.build_product_attributes()` — rebuilds EAV from `product_validated_table` per GSM column loop.

---

## 4. Procedure behavior (traps)

### 4.1 `build_product_attributes_filter`

1. **Gate:** `COUNT(*)` from `product_master` where no EAV row `attribute_name = 'l0_name'` → `RAISE` if > 0.
2. Builds column list: GSM `required_in_product` ∪ all `global.product_master` columns.
3. Pivots GSM `is_attribute=true` from `product_attributes` with `attribute_value::<datatype>`.
4. Upserts `product_attributes_filter`.

**Trap:** GSM `l0_name` as `is_attribute=false` → PM has column, EAV may not → gate fails. **Fix:** [`queries/postgres_product_attributes_l0_name_backfill.sql`](../queries/postgres_product_attributes_l0_name_backfill.sql).

**Trap:** Duplicate column in dynamic SELECT if same name on PM and pivot (store `active` pattern on product if misconfigured).

### 4.2 `build_product_attributes`

- Iterates GSM: `required_in_product AND (is_attribute OR is_pk)`.
- Upserts EAV from `product_validated_table` per column.
- **Does not** process `is_attribute=false` columns (e.g. `l0_name` on PM only).

### 4.3 `build_product_hierarchies_filter`

- For each GSM `is_hierarchy` column (ordered by `hierarchy_level`), builds cumulative `jsonb` path from `product_attributes_filter`, `UNION ALL` per level, then `GROUP BY path, level`.
- **Updates** existing rows where `path->>'product_code'` matches but `path` json changed.
- **Inserts** with `ON CONFLICT (path, level)`.

**Trap:** Two **active** rows same `product_code` + `level` with different `path` (legacy vs new JSON) → UPDATE makes duplicate `(path, level)`. Dev had **2,546,760** such duplicates at level 10.

**Fix:** [`queries/postgres_product_hierarchies_filter_dedupe.sql`](../queries/postgres_product_hierarchies_filter_dedupe.sql).

**GSM quirk:** `l0_id` and `l0_name` both `hierarchy_level = 0` → two level-0 branches in union (paths differ by keys).

### 4.4 `build_store_attributes_filter`

- Same pattern as product: GSM + `store_master` column union + attribute pivots.
- Temp table name uses `current_user` → breaks for email logins (`@` in name). Airflow uses `mtp-dev`.

**Traps fixed 2026-05-20:**

| Issue | Fix |
|-------|-----|
| `active` on PM + pivot | GSM `active` → `is_attribute=false` |
| `dc_flag='false'` in EAV | Normalize to `0`/`1`; GSM `dc_flag` → `boolean` |
| `loc_type_code` SAF `bigint` vs `'S'/'W'` | `ALTER` SAF column to `varchar` |

Script: [`queries/postgres_store_attributes_filter_build_fix.sql`](../queries/postgres_store_attributes_filter_build_fix.sql).

---

## 5. GSM alignment mistakes we hit

| Change | Unintended consequence | Detection |
|--------|------------------------|-----------|
| `l0_name` → `is_attribute=false` | No EAV `l0_name`; filter build gate fails | Error: N products without attributes |
| `store_name` → was `is_attribute=true` | `sync_store_master` omitted NOT NULL `store_name` | NOT NULL violation |
| `ordering` → `varchar` in GSM | BQ anomaly persist INT64 mismatch | Schema/type error on persist |
| `ordering` → `bigint` in GSM | Matches BQ; PG PAF stays varchar | OK if load casts |
| Legacy PHF paths include `product_code_original` | Duplicate active hierarchy rows | `product_hierarchies_filter_un` |

---

## 6. One-off scripts index

| Script | When |
|--------|------|
| [`postgres_global_product_master_ddl_migration.sql`](../queries/postgres_global_product_master_ddl_migration.sql) | Before first sync after product GSM fix |
| [`postgres_global_store_master_ddl_migration.sql`](../queries/postgres_global_store_master_ddl_migration.sql) | Before store sync (`s3_id`, etc.) |
| [`postgres_product_attributes_l0_name_backfill.sql`](../queries/postgres_product_attributes_l0_name_backfill.sql) | After `sync_product_master`, before PAF build |
| [`postgres_store_attributes_filter_build_fix.sql`](../queries/postgres_store_attributes_filter_build_fix.sql) | Store SAF GSM + SAF DDL fixes |
| [`postgres_product_hierarchies_filter_dedupe.sql`](../queries/postgres_product_hierarchies_filter_dedupe.sql) | After PAF rebuild, before hierarchy build |
| [`postgres_lulu_dev_diagnostics.sql`](../queries/postgres_lulu_dev_diagnostics.sql) | Read-only health checks |

---

## 7. Logs

```sql
SELECT created_at, target_table_sp, status, error_message
FROM global.data_ingestion_logs
WHERE target_table_sp ILIKE '%sync%' OR target_table_sp ILIKE '%build%'
ORDER BY created_at DESC
LIMIT 30;
```

Sync procedures log as `public.sync_product_master` / `public.sync_store_master` with `status = 'end'` on success.

---

## 8. Open platform follow-ups (for DI/platform team)

1. **`build_product_attributes_filter`:** gate should use `product_master.l0_name` OR EAV, not hardcoded EAV-only.
2. **`build_product_attributes`:** optionally mirror PM-only hierarchy cols into EAV when filter gate requires it.
3. **`build_product_hierarchies_filter`:** deactivate/supersede old path rows in UPDATE path to avoid unique violations without manual dedupe.
4. **Self-Help GSM upload:** keep CSV in repo aligned with live GSM after SQL hotfixes (`active`, `dc_flag`, `store_name`, `l0_name`).
