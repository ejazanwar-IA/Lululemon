# Inventory Smart Handbook — offline mirror

`Last updated: 2026-05-21.`

## Purpose

Local copy of the Impact Analytics Confluence tree **Inventory Smart- Handbook** so you can answer Inventory Smart / allocation / configuration questions without Atlassian MCP.

## Where files live

| Path | Contents |
|------|----------|
| `reference_docs/Lululemon/InventorySmart_Handbook/README.md` | Index of all 45 pages |
| `reference_docs/Lululemon/InventorySmart_Handbook/*.md` | Handbook pages (CNA, Grouping, Constraints, etc.) |
| `reference_docs/Lululemon/InventorySmart_Handbook/user_stories/*.md` | User stories (Configuration, Allocation, Reports, …) |
| `reference_docs/Lululemon/InventorySmart_Handbook/_raw/` | One JSON file per Confluence page |
| `findings/lululemon_knowledge_bank.md` | Curated summary + ingestion touchpoints |

## How to search

```bash
rg -i "sku_status" reference_docs/Lululemon/InventorySmart_Handbook/
rg -i "product_attributes_filter" reference_docs/Lululemon/InventorySmart_Handbook/
```

Or open `README.md` and follow the link for the module you need.

## Refresh (when Confluence MCP works)

1. Fetch page via MCP `getConfluencePage` (`contentFormat=markdown`, cloudId `impactanalytics.atlassian.net`).
2. Pipe JSON to `python3 scripts/save_handbook_page.py`.
3. Rebuild markdown: `python3 scripts/mirror_inventorysmart_handbook.py reference_docs/Lululemon/InventorySmart_Handbook/_pages.json`.

## Gaps

- **Module Level Table Mapping** and parent handbook page link to Google Sheets only — not exported into markdown bodies.
- **Delta Feed for DC or PO or ASN** — Confluence stub (`TODO`).
- Derived-table validation references a Colab notebook (external link in `2696611795_gbq_derived_tables_validation.md`).

## Lululemon-relevant themes (quick map)

| Handbook | Why it matters for ingestion |
|----------|------------------------------|
| Product-Store Configuration | `sku_status` / `store_status` workflow, back-sync, PAF |
| Product (Rule) Store Mapping | `product_store_mapping` → PG |
| DC-Store Policy / Constraints | RCL, module 170 / 10003 |
| GBQ Derived Tables Validation | Health checks on `article_inventory_dashboard`, etc. |
| User stories | `fc_name` / `tc_name` for UI configurator wiring |
