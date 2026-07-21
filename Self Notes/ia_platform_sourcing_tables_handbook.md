# IA Platform — Sourcing Tables (Confluence mirror)

`Last updated: 2026-05-21.`

## Purpose

Offline reference for the IA Confluence tree [**Sourcing Tables**](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966393875/Sourcing+Tables) — platform OOTB patterns for building **intermediate** BQ tables before master ingestion.

## Where files live

| Path | Contents |
|------|----------|
| [`reference_docs/IA_Platform/Sourcing_Tables/README.md`](../reference_docs/IA_Platform/Sourcing_Tables/README.md) | Index (6 pages) |
| `reference_docs/IA_Platform/Sourcing_Tables/*.md` | Full page bodies incl. reference SQL |
| `reference_docs/IA_Platform/Sourcing_Tables/_raw/` | JSON per page |

## Page tree

| Page | Confluence ID | Intermediate table (VS example) | Lululemon analogue |
|------|---------------|----------------------------------|-------------------|
| Sourcing Tables | 966393875 | _(index only)_ | — |
| Product Master | 966295603 | `product_intermediate` | product intermediate / `product_master` build |
| Location Master | 966361118 | `store_intermediate` | store intermediate / `store_master` build |
| Transaction Master | 966557729 | `transaction_intermediate` | `queries/sourcing/create_transaction_intermediate_periodic.sql` |
| Inventory Master | 966328366 | `inventory_intermediate` | `queries/sourcing/create_inventory_intermediate_periodic.sql` |
| Fiscal Calendar | 966459429 | `fiscal_calendar_intermediate` | `calendar_hierarchy` sourcing |

**Note:** Confluence examples use **Victoria's Secret** project/dataset (`victorias-secret-393308.vs_sourcing_dev`). Lululemon uses `lululemon-01042025.lulu_sourcing_dev` — same *patterns*, different source tables and column names.

## Platform patterns (from handbook)

1. **Universe filter:** Intermediate builds **inner join** `product_intermediate` and `store_intermediate` so only mapped SKUs/stores flow through (Lululemon equivalents may use enriched snapshot + hierarchy joins instead).
2. **`SYNCSTARTDATETIME`:** Every intermediate `CREATE` adds a lineage timestamp (max source date or `CURRENT_DATETIME()`).
3. **Union of channels:** Transaction example unions domestic retail, partner/intl, ecomm sales/returns with a `transaction_type` discriminator.
4. **Inventory bifurcation:** Retail vs ecomm inventory feeds unioned; `inventory_type` flag (`RETAIL` / `ECOMM`) on grain `(sku, store, date)`.
5. **Sentinel cleanup:** VS SQL uses `LIKE '%N'` / `'NONE'` → cast/null patterns — same class as Lululemon `\N` / blank string handling (see BQ context G2/G5).
6. **Periodic incremental:** Live intermediate maintained via `mapping.filter_param` + temp table + MERGE (see Lululemon periodic SQL + [`ia_platform_sourcing_dag_behavior.md`](ia_platform_sourcing_dag_behavior.md)).

## How to search

```bash
rg -i "SYNCSTARTDATETIME" reference_docs/IA_Platform/Sourcing_Tables/
rg -i "product_intermediate" reference_docs/IA_Platform/Sourcing_Tables/
```

## Refresh

```bash
# Per page (stdin = getConfluencePage JSON)
python3 scripts/mirror_confluence_pages.py save \
  --mirror-dir reference_docs/IA_Platform/Sourcing_Tables --page-id <ID> < page.json

python3 scripts/mirror_confluence_pages.py build \
  --mirror-dir reference_docs/IA_Platform/Sourcing_Tables \
  --title "Sourcing Tables" \
  --source-url "https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966393875/Sourcing+Tables" \
  --page-ids 966393875 966557729 966328366 966361118 966295603 966459429
```

## Related

- [`ia_platform_sourcing_dag_behavior.md`](ia_platform_sourcing_dag_behavior.md) — where Sourcing DAG lands tables (`lulu_sourcing_dev.<view>`)
- [`../findings/lululemon_periodic_sourcing_setup.md`](../findings/lululemon_periodic_sourcing_setup.md) — Lululemon periodic intermediate builds
- `.cursor/rules/lululemon-bq-context.mdc` — partition/cost rules on masters
