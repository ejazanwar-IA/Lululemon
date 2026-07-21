# Fiscal date mapping — end-to-end pipeline

`Last updated: 2026-05-25.`

**P0 #1 deliverable:** wire `fiscal_date_mapping` from raw calendar through BQ sourcing → ingestion master → Postgres `global.fiscal_date_mapping`.

**Why it matters for SOW:** PSS × Store/DC × **Week** and × **Day** forecasts require fiscal week/day grains; WTD KPIs and sizing weekly curves join on `fiscal_date_mapping.date`.

---

## Pipeline diagram

```mermaid
flowchart LR
  RAW["calendar_hierarchy\n(souricng_outbound)"]
  INT["fiscal_calendar_intermediate\n(lulu_sourcing_dev)"]
  BQ["fiscal_date_mapping\n(lulu_ingestion_dev)"]
  VAL["public.fiscal_*_validated_table\n(Dataflow)"]
  PG["global.fiscal_date_mapping\n(lulu_dev)"]

  RAW --> INT
  INT --> BQ
  BQ --> VAL
  VAL --> PG
```

---

## Layer status (2026-05-25)

| Step | Layer | Status | Script / doc |
|------|-------|--------|--------------|
| 0 | Raw `calendar_hierarchy` | ✅ 4,746 rows | [`fiscal_calendar_eda.md`](fiscal_calendar_eda.md) |
| 1 | Sourcing intermediate | ✅ **4746 rows** (2026-05-25) | [`create_fiscal_calendar_intermediate_full.sql`](../queries/sourcing/create_fiscal_calendar_intermediate_full.sql) |
| 1b | Platform mapping row | ✅ registered 2026-05-25 | [`register_fiscal_calendar_mapping.sql`](../queries/sourcing/register_fiscal_calendar_mapping.sql) |
| 2 | Ingestion master | ✅ exists (4746 rows) | [`build_fiscal_date_mapping.sql`](../queries/build_fiscal_date_mapping.sql) |
| 3 | Validation gates | ✅ read-only SQL | [`fiscal_date_mapping_validation_gates.sql`](../queries/fiscal_date_mapping_validation_gates.sql) |
| 4 | `generic_master_mapping` | 🟡 CSV ready — upload in Self-Help | [`ia_platform_generic_master_mapping_lulu_dev.csv`](../reference_docs/Lululemon/ia_platform_generic_master_mapping_lulu_dev.csv) (export 18 + fiscal row) |
| 4b | Fiscal GSM | 🟡 re-upload to **correct table** | [`fiscal_date_generic_schema_mapping_selfhelp_upload.csv`](../reference_docs/Lululemon/Generic%20Schema%20Mappings/fiscal_date_generic_schema_mapping_selfhelp_upload.csv) → `global.fiscal_date_generic_schema_mapping` |
| 5 | Dataflow → validated table | 🔲 platform | DI ingestion DAG |
| 6 | `CALL sync_fiscal_date_mapping()` | 🔲 after step 5 | Same setup script Section C |
| 7 | PG row parity | ✅ 4746 rows (pre-existing) | re-verify after pipeline run; 0 PK dupes |

---

## Execution order

### Step 1 — Bootstrap sourcing intermediate (BQ)

```bash
# DDL: bill via lululemon-data-scan (you lack jobs.create on lululemon-01042025)
bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
  < queries/sourcing/create_fiscal_calendar_intermediate_full.sql
```

Verify:

```bash
bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
  < queries/fiscal_date_mapping_validation_gates.sql
```

### Step 2 — Register platform mapping (BQ)

```bash
bq query --project_id=lululemon-data-scan --use_legacy_sql=false \
  < queries/sourcing/register_fiscal_calendar_mapping.sql
```

Wire periodic SQL in Self-Help:

- Query file: [`create_fiscal_calendar_intermediate_periodic.sql`](../queries/sourcing/create_fiscal_calendar_intermediate_periodic.sql)
- Cadence: **full replace** on each run (table is tiny)

### Step 3 — Ingestion master (only if rebuild needed)

Already verified 2026-05-21. Re-run only after `calendar_hierarchy` refresh:

```bash
bq query --project_id=lululemon-01042025 --use_legacy_sql=false \
  < queries/build_fiscal_date_mapping.sql
```

### Step 4 — Generic master mapping + GSM (Self-Help upload)

**Generic master mapping** (Step 3/4 Product Integration config):

- Upload [`export (18).csv`](/Users/ejazanwarmd/Downloads/export%20(18).csv) or repo copy [`ia_platform_generic_master_mapping_lulu_dev.csv`](../reference_docs/Lululemon/ia_platform_generic_master_mapping_lulu_dev.csv)
- **Only new row:** fiscal → `fiscal_calendar_intermediate` / **`fiscal_date_generic_schema_mapping`** / `fiscal_date_mapping`
- Key flags vs txn/inv: `persist_to_db=true`, `cross_validations` **blank**, no attributes/hierarchies

**GSM** (Self-Help → Generic Schema Mapping):

- Upload [`fiscal_date_generic_schema_mapping_selfhelp_upload.csv`](../reference_docs/Lululemon/Generic%20Schema%20Mappings/fiscal_date_generic_schema_mapping_selfhelp_upload.csv)
- Target table: **`fiscal_date_generic_schema_mapping`** — this is what the DAG reads (not `fiscal_generic_schema_mapping`)
- Also update export (18): `generic_mapping_table` = **`fiscal_date_generic_schema_mapping`**
- Fixes vs OOTB: `date` → `unique_by=true`, `is_null_allowed=false`; `fiscal_day_name_abb` → not an attribute
- **Datatypes:** use **`integer`** for all numeric cols (former OOTB `int2`/`smallint` **and** `int4`) — **not** `int2`/`int4`/`smallint`. Validation accepts `integer`; Dataflow `BqToDbPipeline` **cannot** bind BQ INT64 to PG `smallint` (`No value specified for parameter 25`). See `queries/postgres_fiscal_gsm_dataflow_smallint_fix.sql`.
- Do **not** include `syncstartdatetime` (DI rule)
- After upload: **start a new** `data_ingestion` run (retries on the old run may still see stale GSM)

### Step 5 — Postgres (manual, with approval)

1. Open [`postgres_fiscal_date_mapping_setup.sql`](../queries/postgres_fiscal_date_mapping_setup.sql) in DBeaver/psql
2. Run Section A pre-flight
3. Work with DI to insert `generic_master_mapping` row (Section B template)
4. Trigger ingestion DAG / Dataflow for fiscal
5. `SET ROLE "mtp-dev";` then `CALL public.sync_fiscal_date_mapping();`
6. Re-run Section A counts — expect **4746** rows

Local gate (no MCP required):

```bash
./scripts/postgres_ingestion_preflight.sh
```

---

## Known caveats (flag to IA)

| Topic | Detail |
|-------|--------|
| **Future calendar gap** | Raw ends **2028-01-30** (~2 FY forward). Spec wanted 5 years — request FY2030 extension before long-horizon forecast. |
| **53-week years** | FY2018, FY2024 (next FY2030). Week-level models must handle. |
| **Week-day numbering** | Lululemon `DAY_NUMBER`: **Mon=1 … Sun=7**. IA Confluence OOTB example uses **Sun=1**. Wide intermediate uses `day_of_week` = `ROW_NUMBER()` over `WEEK_ID` (Mon-first). Confirm with IA at design sign-off. |
| **`ADJUSTED_LY_WEEK_ID`** | 371 rows have sentinel `201401` — treat as NULL for YoY. |
| **Hardcoded NULL cols** | ~13 columns stubbed in master build — see [`master_table_build_logic.md`](master_table_build_logic.md) Section 6. |

---

## IA intermediate column map

**Ingestion (2026-05-26):** `fiscal_calendar_intermediate` is **wide** (63 cols incl. `syncstartdatetime`) — column names match `fiscal_date_generic_schema_mapping` / `fiscal_date_mapping` master. Sourcing SQL: `create_fiscal_calendar_intermediate_*.sql`.

Legacy IA Confluence narrow shape (for reference only):

| IA / narrow intermediate | Lululemon source (`calendar_hierarchy`) |
|-------------------|----------------------------------------|
| `DATE` | `DAY_ID` |
| `FISCAL_YEAR_NUM` | `YEAR_ID` |
| `FISCAL_QUARTER_NUM` | `QUARTER_NUMBER` |
| `FISCAL_MONTH_NUM` | `MONTH_NUMBER` |
| `FISCAL_WEEK_NUM` | `WEEK_NUMBER` |
| `FISCAL_DAY_NUM` | `DAY_NUMBER` |
| `FISCAL_YEAR_WEEK` | `WEEK_ID` |
| `FISCAL_YEAR_QTR` | `YEAR_ID * 100 + QUARTER_NUMBER` |
| `FISCAL_WEEK_DAY_NUM` | `ROW_NUMBER()` over `WEEK_ID` |
| `season_code` | `SEASON_CODE` (extra — not in VS minimal schema) |

Full wide master (`fiscal_date_mapping` 62 cols) remains in `lulu_ingestion_dev` for ingestion/postgres sync.

---

## Related docs

- Prep plan: [`lululemon_sow_prep_plan_2026.md`](lululemon_sow_prep_plan_2026.md)
- Periodic sourcing pattern: [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md)
- IA Confluence mirror: [`reference_docs/IA_Platform/Sourcing_Tables/966459429_fiscal_calendar.md`](../reference_docs/IA_Platform/Sourcing_Tables/966459429_fiscal_calendar.md)
- Postgres traps: [`Self Notes/postgres_ingestion_gotchas.md`](../Self Notes/postgres_ingestion_gotchas.md)
