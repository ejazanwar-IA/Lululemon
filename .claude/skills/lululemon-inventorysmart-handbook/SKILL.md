---
name: lululemon-inventorysmart-handbook
description: Offline Inventory Smart Handbook (Confluence mirror). Use for Inventory Smart module/UI/handbook questions touching findings/ or reference_docs/Lululemon/InventorySmart_Handbook/.
---

# Inventory Smart Handbook (offline)

Confluence tree **Inventory Smart - Handbook** is mirrored locally. Search order: see the `lululemon-atlassian-mcp` skill (local mirror first, then MCP).

## Where to look

| Asset | Path |
|-------|------|
| Index | `reference_docs/Lululemon/InventorySmart_Handbook/README.md` |
| Handbook pages | `reference_docs/Lululemon/InventorySmart_Handbook/*.md` |
| User stories | `reference_docs/Lululemon/InventorySmart_Handbook/user_stories/*.md` |
| Raw JSON | `reference_docs/Lululemon/InventorySmart_Handbook/_raw/` |
| Curated summary | `findings/lululemon_knowledge_bank.md` (Handbook section) |
| Self Note | `Self Notes/inventorysmart_handbook_offline.md` |

**Parent Confluence page ID:** `2696609793`

## Refresh mirror

```bash
# Per page (stdin = getConfluencePage JSON)
python3 scripts/save_handbook_page.py < page.json

# Rebuild markdown from _raw/
python3 scripts/mirror_inventorysmart_handbook.py reference_docs/Lululemon/InventorySmart_Handbook/_pages.json
```

## External dependencies (not in mirror body)

- Module mapping Google Sheet: `1zG8WmnvqGe73dHZUI47qbh4XCavNc5csdPLcnD6yW3k`
- Main handbook Google Sheet: `1baorqNGvx3yW_z8QGKw2muupdDXu1U064rJ8F8oVunk`
- Derived-table validation Colab: linked from `2696611795_gbq_derived_tables_validation.md`

## Lululemon ingestion overlap

Handbooks describe OOTB IA Inventory Smart flows that touch Lululemon Postgres `global.*` and BQ validated/derived tables:

- **Status:** `sku_status` / `store_status` (BQ) ↔ PG `product_time_attributes` / `store_time_attributes` — back-sync before periodic ingestion → `product_attributes_filter` / `store_attributes_filter`
- **Mappings:** `product_store_mapping`, `store_dc_mapping`, `product_dc_mapping` → PG `global.product_mapping`
- **Derived:** `inventory_smart.Article_inventory_dashboard`, alert tables, `store_stock_drilldown`, `product_profile`

For Postgres procedure guards and GSM alignment, use the `lululemon-postgres-ingestion` skill.
