# Self Notes

`Last updated: 2026-06-16.`

## Purpose

This folder stores concise personal learning notes for the Lululemon project. These are not raw transcripts. Each note should explain a topic clearly enough that it can be reused later without searching through chat history.

## Index

| Note | Topic |
|---|---|
| [`ia_platform_sourcing_dag_behavior.md`](ia_platform_sourcing_dag_behavior.md) | Where the IA Platform's Sourcing DAG lands its BigQuery output — table named after the `view` field of the Mapping table in the Data Extraction tab, materialised in `lulu_sourcing_dev`. |
| [`ia_platform_sourcing_tables_handbook.md`](ia_platform_sourcing_tables_handbook.md) | Offline mirror of IA Confluence **Sourcing Tables** — intermediate BQ build patterns (product/store/txn/inv/calendar). |
| [`postgres_ingestion_gotchas.md`](postgres_ingestion_gotchas.md) | `lulu_dev` `global.*` scope, GSM ↔ sync ↔ `build_*` procedure traps, DAG prep order (2026-05-20 ingestion debug). |
| [`../findings/lululemon_sow_prep_plan_2026.md`](../findings/lululemon_sow_prep_plan_2026.md) | **2–3 week SOW prep** — priorities, learning, automation, reference library. |
| [`../findings/fiscal_date_mapping_pipeline.md`](../findings/fiscal_date_mapping_pipeline.md) | **P0 #1** — fiscal calendar BQ sourcing → ingestion → Postgres runbook. |
| [`../findings/lululemon_knowledge_bank.md`](../findings/lululemon_knowledge_bank.md) | **Morning client context** — `/lulu-knowledge` to append or recap; visual: `lululemon_masters_reference_guide_stacked.png`. |
| [`../archive/sizesmart/README.md`](../archive/sizesmart/README.md) | **SizeSmart (archived)** — out of scope; not indexed. |
| [`../findings/assets/lululemon_product_hierarchy_summary.png`](../findings/assets/lululemon_product_hierarchy_summary.png) | L0–L8 distinct-count infographic (regen: `scripts/generate_product_hierarchy_summary_image.py`). |
| [`../findings/notion/InventorySmart_Decision_Dashboard.md`](../findings/notion/InventorySmart_Decision_Dashboard.md) | **Notion backup** — Decision Dashboard UI; live page: [Notion](https://www.notion.so/367389502e79811798dcc2896a695563). Rule: `lululemon-notion-mcp.mdc`. |

## Maintenance Rules

- Add a note only when there is genuinely useful learning to preserve.
- Before adding a new note, check this index and existing notes to avoid duplication.
- Prefer updating an existing note when the topic already exists.
- Keep formatting clean: title, purpose, short explanation, examples, pitfalls, and reusable SQL where helpful.
- Keep notes practical and project-specific.
