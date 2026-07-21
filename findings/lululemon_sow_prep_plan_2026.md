# Lululemon × IA SOW — 2–3 week prep plan

`Last updated: 2026-05-25.`

**Purpose:** Personal reference for Ejaz — what to focus on, learn, automate, and which docs to open first ahead of **kick-off (Jun 8)**, **data checks (Jun 22)**, and **data sign-off (Jun 29)**.

**Timeline chart:** [`assets/lululemon_ia_sow_timeline_2026.png`](assets/lululemon_ia_sow_timeline_2026.png)  
**SOW summary:** [`lululemon_impact_analytics_sow_2026-05-04_summary.md`](lululemon_impact_analytics_sow_2026-05-04_summary.md)  
**Fiscal pipeline (P0 #1):** [`fiscal_date_mapping_pipeline.md`](fiscal_date_mapping_pipeline.md)

---

## North star

By **Jun 29 data transfer sign-off**, hand IA a **stable, documented, refreshable data package** at SOW grains:

| SOW grain | Your data dependency |
|-----------|---------------------|
| PSS × Store/DC × **Week** + **Day** | `transaction_master`, `fiscal_date_mapping`, `product_master`, `store_master` |
| PSO × Submarket Channel × **Week** | Above + size columns (`size_scale`, L8, `product_size_definition`) |
| ≥3 inference cycles/day | Incremental feeds — not single-date POC snapshots |
| Explainability / audit | Mostly IA-side; your job is **trustworthy inputs** |

**Your role:** data/integration owner — not the forecasting data scientist.

---

## Priority stack

### P0 — before Jun 22

| # | Work | Status | Artifact |
|---|------|--------|----------|
| 1 | **`fiscal_date_mapping` end-to-end** | 🟡 SQL ready — run BQ + PG steps | [`fiscal_date_mapping_pipeline.md`](fiscal_date_mapping_pipeline.md) |
| 2 | **Multi-date `inventory_master`** | 🔲 | [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md) gap #3 |
| 3 | **Postgres four-masters sync health** | 🟡 run preflight | [`scripts/postgres_ingestion_preflight.sh`](../scripts/postgres_ingestion_preflight.sh) |
| 4 | **IA sample + historical transfer pack** | 🔲 | Data dictionary + grain doc (automate export) |

### P1 — by Jun 29 sign-off

| # | Work |
|---|------|
| 5 | Periodic transaction intermediate steady-state |
| 6 | Channel join policy (X3) documented for IA |
| 7 | Chase 4 DE open items — [`master_table_checklist.md`](master_table_checklist.md) Stage 1 |
| 8 | Regional daily refresh design (NAM / EMEA / APAC+China) |

### Archived — sizing track (out of scope 2026-06-16)

SizeSmart / size-curve prep moved to [`archive/sizesmart/`](../archive/sizesmart/). Former P2 items (I11 sales≤inv check, submarket mapping) may still matter for **forecasting data quality** — track under master checklist, not sizing deliverables.

### P3 — deprioritize next 2–3 weeks

- Deep Inventory Smart UI / Notion doc work
- Master checklist Stage 5 (Layer-3 EDA)
- Postgres PHF edge cases unless sync fails

---

## Week-by-week

### Week 1 (~now → May 31)

| Block | Actions |
|-------|---------|
| Daily (15 min) | Masters infographic PDF + SOW timeline; `./scripts/postgres_ingestion_preflight.sh` if touching PG |
| Mon–Tue | Re-run [`queries/bq_master_tables_health_check.sql`](../queries/bq_master_tables_health_check.sql); compare to [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) |
| Wed–Thu | **P0 #1:** fiscal intermediate SQL + mapping registration (see pipeline runbook) |
| Fri | Postgres fiscal setup script review; draft **known data caveats** one-pager for IA |

**Exit:** Fiscal BQ sourcing scripts ready; PG preflight green; caveats drafted.

### Week 2 (Jun 1–7)

| Block | Actions |
|-------|---------|
| Mon–Tue | Inventory multi-date scope with DE; test periodic inventory MERGE on 2nd date |
| Wed | Wire inventory periodic → ingestion master (DI/platform ask) |
| Thu | Build IA transfer checklist; export column dictionary from `INFORMATION_SCHEMA` |
| Fri | Kick-off prep notes; chase DE Stage-1 open items |

**Exit:** Inventory plan signed or dated; transfer pack ready.

### Week 3 (Jun 8–22)

| Cadence | Actions |
|---------|---------|
| Jun 8 | Kick-off — confirm instance model, GCS transfer, regional refresh times |
| Daily | Combined health check; log in single table |
| Jun 8–15 | IA data + design sessions — grain confirmation (PSS, PSO, submarket) |
| Jun 15–22 | IA query log — 24h turnaround; append SQL errors to BQ context G-section |
| Jun 22 | Data checks milestone |
| Jun 29 | Data transfer sign-off target |

---

## Learning curriculum

### Tier 1 — know cold (4–6 h)

| Topic | Where |
|-------|-------|
| SOW scope + timeline | [`lululemon_impact_analytics_sow_2026-05-04_summary.md`](lululemon_impact_analytics_sow_2026-05-04_summary.md) |
| Four masters + channels + X3 | [`lululemon_knowledge_bank.md`](lululemon_knowledge_bank.md) |
| IA sourcing pipeline | [`Self Notes/ia_platform_sourcing_dag_behavior.md`](../Self Notes/ia_platform_sourcing_dag_behavior.md) |
| Postgres ingestion traps | [`Self Notes/postgres_ingestion_gotchas.md`](../Self Notes/postgres_ingestion_gotchas.md) |
| GSM → PM/PAF rules | `.cursor/rules/lululemon-postgres-ingestion.mdc` P2 |

### Tier 2 — answer IA confidently (3–4 h)

| Topic | Where |
|-------|-------|
| Product hierarchy L0–L8 | [`product_master_hierarchy_decoded.md`](product_master_hierarchy_decoded.md) |
| Fiscal calendar | [`fiscal_calendar_eda.md`](fiscal_calendar_eda.md) |
| Periodic MERGE pattern | [`ia_bq_patterns.md`](ia_bq_patterns.md) |
| Real-sales filter | BQ context Section 5.3 |

### Tier 3 — skim only

| Topic | When |
|-------|------|
| Decision Dashboard UI | If IA asks about downstream consumption |
| Tapestry TEST screenshots | UI vocabulary only |

---

## Automation

| Tool | Use | Status |
|------|-----|--------|
| [`scripts/postgres_ingestion_preflight.sh`](../scripts/postgres_ingestion_preflight.sh) | Daily before PG `CALL` | ✅ exists |
| [`queries/bq_master_tables_health_check.sql`](../queries/bq_master_tables_health_check.sql) | Weekly BQ baseline | ✅ exists |
| [`scripts/build_findings_workbook.py`](../scripts/build_findings_workbook.py) | Checklist tracking | ✅ exists |
| `/lulu-knowledge` | Morning recap | ✅ exists |
| `scripts/daily_readiness.sh` | PG + BQ one-shot | 🔲 proposed |
| `scripts/export_master_data_dictionary.py` | IA transfer pack CSV | 🔲 proposed |

---

## Reference library

### Contract & timeline

| Doc | Path |
|-----|------|
| SOW PDF | [`reference_docs/Lululemon/Contract/`](../reference_docs/Lululemon/Contract/) |
| Timeline PNG | [`assets/lululemon_ia_sow_timeline_2026.png`](assets/lululemon_ia_sow_timeline_2026.png) |

### Data platform (daily)

| Doc | Path |
|-----|------|
| Knowledge bank | [`lululemon_knowledge_bank.md`](lululemon_knowledge_bank.md) |
| Masters infographic | [`assets/lululemon_masters_reference_guide.pdf`](assets/lululemon_masters_reference_guide.pdf) |
| BQ health | [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) |
| Master checklist | [`master_table_checklist.md`](master_table_checklist.md) |
| Periodic sourcing | [`lululemon_periodic_sourcing_setup.md`](lululemon_periodic_sourcing_setup.md) |
| Build logic / lineage | [`master_table_build_logic.md`](master_table_build_logic.md), [`raw_to_master_lineage.md`](raw_to_master_lineage.md) |

### Confluence mirrors (local-first)

| Space | Path | Pages |
|-------|------|------:|
| IA Sourcing Tables | [`reference_docs/IA_Platform/Sourcing_Tables/`](../reference_docs/IA_Platform/Sourcing_Tables/) | 6 |
| Inventory Smart Handbook | [`reference_docs/Lululemon/InventorySmart_Handbook/`](../reference_docs/Lululemon/InventorySmart_Handbook/) | 45 |

### Other-client reference codebase

| Pattern | Path |
|---------|------|
| VS fiscal intermediate MERGE | `insideinsight-mtp-bigquery-3df90a9e5596/vs/sourcing/create_fiscal.sql` |
| Signet txn → fiscal join | `signet/sourcing/create_transaction.sql` |
| DI ingestion training | [`reference_docs/Training/DI_Course_3_Ingestion_Basics_for_Analytics_Teams.md`](../reference_docs/Training/DI_Course_3_Ingestion_Basics_for_Analytics_Teams.md) |

### Cursor rules

- `lululemon-bq-context.mdc`, `lululemon-postgres-ingestion.mdc`, `lululemon-atlassian-mcp.mdc`, `ia-platform-sourcing-tables.mdc`

---

## Risks

| Risk | Mitigation |
|------|------------|
| Inventory single-date at Jun 22 | Escalate Week 1; IA needs store-SKU-day |
| Postgres VPN drops | DBeaver + `SET ROLE "mtp-dev"`; local preflight.sh |
| DE unanswered on DISTINCT / active polarity | Consolidated ask by Jun 1 |
| X3 channel suffix confusion | Pre-write explainer for IA |
| Scope creep into IS UI | SOW = offline forecast + size curves |
| Nov blackout | No heavy PG migrations in Nov |

---

## Daily habit (15 min)

1. Check SOW timeline — milestone ≤2 weeks out?
2. Run preflight if touching Postgres
3. Check `global.data_ingestion_logs` for last sync success
4. Append new facts via `/lulu-knowledge`
