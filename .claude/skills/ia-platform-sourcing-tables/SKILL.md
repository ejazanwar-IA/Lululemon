---
name: ia-platform-sourcing-tables
description: Offline IA Sourcing Tables handbook (Confluence "Sourcing Tables" tree, mirrored locally). Use for sourcing/intermediate build lineage questions on findings/, queries/, or reference_docs/IA_Platform/.
---

# IA Platform — Sourcing Tables (offline)

Confluence tree **Sourcing Tables** (IA space): `https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966393875/Sourcing+Tables`. Search order: see the `lululemon-atlassian-mcp` skill.

## Local mirror

| Asset | Path |
|-------|------|
| Index | `reference_docs/IA_Platform/Sourcing_Tables/README.md` |
| Pages | `reference_docs/IA_Platform/Sourcing_Tables/*.md` |
| Self Note | `Self Notes/ia_platform_sourcing_tables_handbook.md` |
| Lululemon periodic SQL | `queries/sourcing/create_*_intermediate_periodic.sql` |

**Child page IDs:** 966295603 (Product), 966361118 (Location), 966557729 (Transaction), 966328366 (Inventory), 966459429 (Fiscal Calendar)

## Lululemon mapping

| Handbook intermediate | Lululemon dataset.table |
|----------------------|-------------------------|
| `*_sourcing_dev.product_intermediate` | `lulu_sourcing_dev` product path → `product_master` |
| `store_intermediate` | store path → `store_master` |
| `transaction_intermediate` | `create_transaction_intermediate_periodic.sql` |
| `inventory_intermediate` | `create_inventory_intermediate_periodic.sql` |
| `fiscal_calendar_intermediate` | `calendar_hierarchy` |

Examples in Confluence use **Victoria's Secret** (`vs_sourcing_dev`); apply **patterns**, not literal table names.

## Core patterns to preserve

- Inner join product + store universe before masters
- `SYNCSTARTDATETIME` lineage column on intermediate builds
- Channel/workstream flags (`transaction_type`, `inventory_type`, `WS_CHANNEL`)
- Periodic: `mapping.filter_param` → temp → MERGE (see `ia_platform_sourcing_dag_behavior.md`)

For master-table BQ rules and partition filters, use the `lululemon-bq-context` skill.
