# Lululemon periodic sourcing setup

`Last updated: 2026-05-25.`

Periodic intermediate builds for **product**, **store**, **inventory**, **transaction**, and **fiscal calendar**, modelled on Signet `create_*` scripts (filter_param → temp → MERGE → DROP, or full replace for fiscal).

---

## SQL artifacts

| Feed | Periodic script | Historic rebuild (canonical v2) |
|---|---|---|
| Fiscal calendar | [`queries/sourcing/create_fiscal_calendar_intermediate_periodic.sql`](../queries/sourcing/create_fiscal_calendar_intermediate_periodic.sql) | [`queries/sourcing/create_fiscal_calendar_intermediate_full.sql`](../queries/sourcing/create_fiscal_calendar_intermediate_full.sql) |
| Product | [`queries/sourcing/create_product_intermediate_periodic.sql`](../queries/sourcing/create_product_intermediate_periodic.sql) | [`queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql) |
| Store | [`queries/sourcing/create_store_intermediate_periodic.sql`](../queries/sourcing/create_store_intermediate_periodic.sql) | [`queries/Intermediate_table_builds/create_store_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_store_intermediate_historic_v2.sql) |
| Inventory | [`queries/sourcing/create_inventory_intermediate_periodic.sql`](../queries/sourcing/create_inventory_intermediate_periodic.sql) | [`queries/Intermediate_table_builds/create_inventory_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_inventory_intermediate_historic_v2.sql) |
| Transaction | [`queries/sourcing/create_transaction_intermediate_periodic.sql`](../queries/sourcing/create_transaction_intermediate_periodic.sql) | [`queries/Intermediate_table_builds/create_transaction_intermediate_historic_v2.sql`](../queries/Intermediate_table_builds/create_transaction_intermediate_historic_v2.sql) |

**Locked reference:** [`lululemon_intermediate_builds_v2_reference.md`](lululemon_intermediate_builds_v2_reference.md). v1 `create_*_historic.sql` and legacy workbench scripts (`store_master_intermediate_build.sql`, etc.) are baseline/diff only. Periodic scripts may lag v2 until promoted.

---

## Platform config (`lulu_sourcing_dev`)

### Active mapping rows (2026-05-20)

All four intermediates are registered with `is_deleted = FALSE`:

| `table` | `intermediate_table` | `dataingestion_filterparam` | `filter_param` |
|---|---|---|---|
| product | product_intermediate | 2026-05-01 | null |
| store | store_intermediate | 2026-05-01 | null |
| inventory | inventory_intermediate | 2026-05-01 | null |
| transaction | transaction_intermediate | 2026-05-01 | null |

Periodic SQL uses `COALESCE(filter_param, TIMESTAMP(dataingestion_filterparam))` when `filter_param` is null (G11 — mapping lives in `lulu_sourcing_dev`, not `lulu_ingestion_dev`).

### Active extraction rows (`view_mapping_table`)

| `table` | `view` | `filter_param` | `pull_type` |
|---|---|---|---|
| inventory | inventory_snapshot | 2026-05-08 | full |
| transaction | sales_transactions | 2026-05-19 | full |
| product | product_attribute_s, product_group_hierarchy, sku_details | 2026-05-19 | full |
| store | location_details, location_group_hierarchy | 2026-05-19 | full |

**Note:** extraction `pull_type = full` on dev does not block incremental intermediate builds — the periodic SQL filters on lineage timestamps (`SNAPSHOT_TIME` / `SYNCSTARTDATETIME`) after `filter_param`.

---

## Incremental logic

### Inventory

- **Raw:** `lulu_sourcing_dev.inventory_snapshot_cleaned` (+ `location_group_hierarchy`, `location_details` for channel derivation). All intermediate inputs stay in `lulu_sourcing_dev` — never `souricng_outbound`.
- **Incremental predicate:** `SNAPSHOT_TIME > filter_param`
- **MERGE key:** `product_code`, `store_code`, `date`, `channel`
- **Live table:** `lulu_sourcing_dev.inventory_intermediate` (5,539,053 rows for POC date 2025-08-28)

Channel derivation for null `SKU_ID_CHANNEL` / `CHANNEL` uses location hierarchy joins (same as stepwise Section 2).

### Transaction

- **Raw DAG table:** `lulu_sourcing_dev.sales_transactions`
- **Incremental predicate:** `SYNCSTARTDATETIME > filter_param` plus 4-year business-date floor (matches full rebuild)
- **MERGE key:** `transaction_code`, `product_code`, `store_code`, `date` (0 duplicate groups verified on live table)
- **Dependencies:** run **product** and **store** intermediate builds before transaction periodic

### Store

- **Raw:** `lulu_sourcing_dev.location_group_hierarchy`, `location_details`
- **Incremental predicate:** `SYNCSTARTDATETIME > filter_param` on either feed; union affected `LOC_ID`s, rebuild those stores
- **MERGE key:** `store_code` (1,853 rows; 1:1 grain verified)
- **Live table:** `lulu_sourcing_dev.store_intermediate`

### Product

- **Raw:** `lulu_sourcing_dev.product_group_hierarchy`, `sku_details`, `product_attribute_s`
- **Incremental predicate:** `SYNCSTARTDATETIME > filter_param` on any feed; union affected `SKU_ID`s (attribute changes expand via `STYLE` rows in PGH)
- **Build:** PGH EAV pivot + channel expansion inlined (not static `product_group_hierarchy_cleaned`)
- **MERGE key:** `product_code` (1,977,528 rows; 1:1 grain verified)
- **Live table:** `lulu_sourcing_dev.product_intermediate`

---

## DAG prep order (sourcing layer)

1. **Product periodic** — `create_product_intermediate_periodic.sql`
2. **Store periodic** — `create_store_intermediate_periodic.sql`
3. **Inventory periodic** — `create_inventory_intermediate_periodic.sql`
4. **Transaction periodic** — `create_transaction_intermediate_periodic.sql`

Inventory does not depend on product/store intermediates for the build itself; transaction does.

### Fiscal calendar

- **Raw:** `lulu_sourcing_dev.calendar_hierarchy` (4,746 rows; no incremental lineage column). Bootstrap once from `souricng_outbound.calendar_hierarchy` if the sourcing DAG has not materialised it yet.
- **Strategy:** **full replace** each run (table is tiny)
- **Target:** `lulu_sourcing_dev.fiscal_calendar_intermediate`
- **Mapping registration:** [`queries/sourcing/register_fiscal_calendar_mapping.sql`](../queries/sourcing/register_fiscal_calendar_mapping.sql)
- **Extraction DAG:** do **not** register `calendar` in `view_mapping_table` — no GCS connector; NULL `schedule_interval` breaks `sourcing_extraction_*` at `fetch_the_sourcing_params`. Fix: [`queries/sourcing/fix_sourcing_extraction_calendar_mapping.sql`](../queries/sourcing/fix_sourcing_extraction_calendar_mapping.sql)
- **Runbook:** [`findings/fiscal_date_mapping_pipeline.md`](fiscal_date_mapping_pipeline.md)

---

## First-run vs steady-state

| Table | First run | Steady-state |
|---|---|---|
| `inventory_intermediate` | Initialize once via stepwise Section 4A (or `CREATE TABLE … AS SELECT * FROM temp`) | Periodic MERGE only |
| `transaction_intermediate` | Already populated via full rebuild (~354M rows) | Periodic MERGE |

After each successful periodic run, platform ops should advance `mapping.filter_param` (and matching `view_mapping_table.filter_param`) to the max lineage timestamp processed — same as other IA clients.

---

## Pre-flight checks

```sql
-- Mapping checkpoint
SELECT intermediate_table,
       filter_param,
       dataingestion_filterparam,
       COALESCE(filter_param, TIMESTAMP(dataingestion_filterparam)) AS active_checkpoint
FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
WHERE is_deleted = FALSE
ORDER BY inter_query_exec_order;

-- Inventory incremental row count (cheap gate before MERGE)
DECLARE fp TIMESTAMP DEFAULT (
  SELECT COALESCE(MAX(COALESCE(filter_param, TIMESTAMP(dataingestion_filterparam))), TIMESTAMP('1900-01-01'))
  FROM `lululemon-01042025.lulu_sourcing_dev.mapping`
  WHERE is_deleted = FALSE AND intermediate_table = 'inventory_intermediate'
);
SELECT COUNT(*) AS incremental_raw_rows
FROM `lululemon-01042025.lulu_sourcing_dev.inventory_snapshot_cleaned`
WHERE SNAPSHOT_TIME > fp
LIMIT 1;  -- remove if running count only

-- Transaction incremental row count
SELECT COUNT(*) AS incremental_txn_rows
FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
WHERE SYNCSTARTDATETIME > fp;  -- reuse fp from above with transaction mapping row
```

Post-MERGE validation (inventory): re-use stepwise Section 3A–3C against a rebuilt temp before dropping, or compare `COUNT(*)` / merge-key dup check on live for affected dates.

---

## Self-Help checklist (platform UI)

- [ ] Confirm `mapping` rows for all four intermediates with correct `inter_query_exec_order`
- [ ] Upload periodic SQL paths to Bitbucket / query registry per IA convention
- [ ] Wire query names in Self-Help for **periodic** mode (not historic)
- [ ] Set `view_mapping_table` extraction sync after first successful landing
- [ ] Advance `filter_param` after each successful run
- [ ] Register ingestion `generic_master_mapping` on Postgres (`lulu_dev`) once intermediates are steady — Wave 2

---

## Known gaps / follow-ups

1. **`pull_type` null** on mapping rows — confirm with DI whether periodic DAG expects `incremental` vs `full`.
2. **Historic SQL** — author `create_inventory_intermediate_historic.sql` / `create_transaction_intermediate_historic.sql` when backfill scope is signed off.
3. **Multi-date inventory master** — `lulu_ingestion_dev.inventory_master` is still single-date POC; periodic inventory intermediate must feed a periodic **ingestion** master build next.
4. **Postgres MCP** — retry `generic_master_mapping` read on `lulu_dev` when connection is restored.

---

## Related docs

- [`findings/ia_bq_patterns.md`](ia_bq_patterns.md) — temp + MERGE + filter_param pattern
- [`findings/master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) — cross-master integrity baseline
- [`.cursor/rules/lululemon-bq-context.mdc`](../.cursor/rules/lululemon-bq-context.mdc) — G11 mapping dataset, G12 souricng typo
