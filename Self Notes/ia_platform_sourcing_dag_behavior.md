# IA Platform — Sourcing DAG Behaviour

`Last updated: 2026-05-14.`

## Purpose

Clarify where the IA Platform's **Sourcing DAG** materialises its output when sourcing from BigQuery, and where to look for the resulting table after a successful run.

## Core rule

When you source anything from BigQuery via the IA Platform and run the **Sourcing DAG**, the DAG creates a table in the **`lulu_sourcing_dev`** schema (in the `lululemon-01042025` project).

The destination table name comes from the **`view`** field of the **Mapping table** in the **Data Extraction** tab of the platform — *not* from the source table name, and *not* from a hardcoded convention.

```
IA Platform → Data Extraction tab → Mapping table → "view" column
                                                      │
                                                      └─ becomes the table name in:
                                                         lululemon-01042025.lulu_sourcing_dev.<view>
```

## Why this matters

| Situation | What to do |
|---|---|
| Sourcing DAG run "succeeded" but you can't find the output | Look in `lululemon-01042025.lulu_sourcing_dev.<view_value>`, not in the source dataset |
| You want to rename the destination table | Edit the `view` field in the Mapping table — don't try to rename the BQ table directly |
| You need to point a downstream query at the freshly-sourced data | Reference `lulu_sourcing_dev.<view_value>` |
| You're chasing a "where did this table come from" question on something in `lulu_sourcing_dev` | First suspect: it was produced by a Sourcing DAG run; look up the `view` field in the Mapping table for that name |

## Pitfalls

1. **The field is called "view" but the artifact is a TABLE in BQ, not a view.** Just naming convention from the platform UI — don't assume read-through-to-source semantics. It's a materialised table.
2. **`lulu_sourcing_dev` ≠ `lululemon_sourcing_dev`.** The pipeline datasets use the 4-letter `lulu_` prefix; the full `lululemon_` prefix is reserved for the raw `lululemon_souricng_outbound` dataset (which has the `souricng` typo). Mixing them produces "Dataset not found" — see workspace gotcha G11.
3. **Each Sourcing DAG run overwrites** the destination table. If you've manually edited `lulu_sourcing_dev.<view>` between runs, those edits will be lost on the next run.
4. **The Mapping table in the Data Extraction tab is the source of truth** for which BQ source maps to which destination view. If you change the source SQL/view-definition there but forget to re-run the DAG, the BQ table will be stale.

## Related context

- **Workspace gotcha G11:** Lululemon mapping/orchestration config lives in `lulu_sourcing_dev` (this is the same dataset Sourcing DAG outputs land in — both kinds of data co-exist there).
- **Workspace gotcha G15:** Saving generic-master mappings via `data_platform.save_generic_master_mapping(jsonb)` requires every Mapping-table row to have a non-null `view` / template / query value. A Sourcing DAG run will fail if `view` is NULL or blank.
- **Confluence handbook (offline):** [`ia_platform_sourcing_tables_handbook.md`](ia_platform_sourcing_tables_handbook.md) — OOTB intermediate build patterns (Product/Location/Transaction/Inventory/Fiscal Calendar) with full reference SQL under `reference_docs/IA_Platform/Sourcing_Tables/`.

## Origin

Captured 2026-05-14 from working session — Ejaz noted this behaviour while sourcing tables for the inventory_master / product_master pipeline.
