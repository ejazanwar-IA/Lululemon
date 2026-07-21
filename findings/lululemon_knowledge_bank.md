# Lululemon — Knowledge bank (morning revision)

`Last updated: 2026-07-21 (product_intermediate.color_family wired into v2, validated on _tmp_, not yet live).`

**Purpose:** Single curated client-context doc for daily revision. Append-only when you ask the agent to add facts. No duplicate bullets for the same fact.

**Slash command:** `/lulu-knowledge` — append facts in the same message, or invoke alone for a morning recap.

**Visual go-to (open first):**

| Asset | Path |
|-------|------|
| Stacked infographic (7 panels) | [`assets/lululemon_masters_reference_guide_stacked.png`](assets/lululemon_masters_reference_guide_stacked.png) |
| PDF (7 pages) | [`assets/lululemon_masters_reference_guide.pdf`](assets/lululemon_masters_reference_guide.pdf) — product L0–L8 → store S0–S5 → channels → four-masters health → raw→master lineage → sourcing pipeline → Decision Dashboard |
| Regenerate v2 panels | `python3 scripts/generate_masters_v2_infographics.py` then `python3 scripts/combine_lululemon_reference_pdf.py` |
| Page panels (individual) | `lululemon_store_hierarchy_summary_designed.png`, `lululemon_four_masters_summary.png`, `lululemon_raw_to_master_lineage.png`, `lululemon_sourcing_pipeline_flow.png` |

**Deeper refs (not duplicated here unless you add them):** [`lululemon_sow_prep_plan_2026.md`](lululemon_sow_prep_plan_2026.md), [`fiscal_date_mapping_pipeline.md`](fiscal_date_mapping_pipeline.md), [`lululemon_impact_analytics_sow_2026-05-04_summary.md`](lululemon_impact_analytics_sow_2026-05-04_summary.md) + PDF [`reference_docs/Lululemon/Contract/`](../reference_docs/Lululemon/Contract/), [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md), [`product_master_hierarchy_decoded.md`](product_master_hierarchy_decoded.md), [`reference_docs/Lululemon/Decision_Dashboard_handbook.pdf`](../reference_docs/Lululemon/Decision_Dashboard_handbook.pdf), [`reference_docs/Lululemon/InventorySmart_Handbook/README.md`](../reference_docs/Lululemon/InventorySmart_Handbook/README.md) (45 Confluence pages, offline), [`reference_docs/IA_Platform/Sourcing_Tables/README.md`](../reference_docs/IA_Platform/Sourcing_Tables/README.md) (IA intermediate builds), `.cursor/rules/lululemon-bq-context.mdc`, `.cursor/rules/lululemon-postgres-ingestion.mdc`, `.cursor/rules/lululemon-atlassian-mcp.mdc`, `.cursor/rules/lululemon-inventorysmart-handbook.mdc`, `.cursor/rules/ia-platform-sourcing-tables.mdc`.

---

## Environment and scope

- **GCP project:** `lululemon-01042025` — masters in `lulu_ingestion_dev`; raw/sourcing typo dataset `lululemon_souricng_outbound`; mapping tables in `lulu_sourcing_dev`.
- **Postgres (ingestion):** `lulu_dev` @ dev only unless you name another host. Schema `global` is **tenant-local**, not cross-client.
- **BQ job billing:** `lululemon-data-scan` (not the data project).

---

## Contract scope — IA SOW (Jun 24 2026 redlines) + Timelines v3

**Latest references:**

| Doc | Path |
|-----|------|
| **SOW (Jun 24 redlines)** | [`reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.docx`](../reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.docx) |
| **SOW extract** | [`reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.md`](../reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.md) |
| **Timelines v3** | [`reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.xlsx`](../reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.xlsx) |
| **Timeline extract** | [`reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.md`](../reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.md) |

**Engagement:** demand forecasting (+ sizing in workplan sheets) — data science service only; **no IA UI/workflow** in this SOW. Term starts **Jul 6, 2026**; ~6.5 months. Scope: Global (NA, EMEA, APAC, China), ~800 stores, Retail + Ecommerce, all categories/SKUs.

| Deliverable grain | Notes |
|-------------------|-------|
| 52-week Style-Color × Submarket Channel × Week | Independently inferenced; Phase 1 readouts (Intl then US/CA) |
| 52-week SKU × Store/DC × Week | Independently inferenced (original SOW language) |
| **26-week SKU × Store × Week eligibility** | **Revised SOW (Jul 2026):** SKU-store-week eligibility horizon is **current week + 26 forward weeks**, not 52. Use for `sku_store_eligibility` build and forecast alignment. |
| 17-week SKU × Store/DC × Day | Disaggregated from first 17 weeks of 52-week forecast |
| Outbound refresh | 3× per region/day (APAC/China, NAM, EMEA); delta minimum; full re-inference on request |
| Go-live target | Q1 (per SOW Section 6) |

**Milestone Tracker (Timelines v3):**

| Date | Milestone |
|------|-----------|
| **2026-05-16** | Complete historical data transfer (LL) |
| **2026-06-06** | Historical data sign-off + discovery/design complete |
| **2026-06-13** | Transfer mechanism / periodic frequency sign-off |
| **2026-07-04** | US/CA model retraining + sizing outputs prep complete |
| **2026-07-11** | US/CA forecasting readout + SIT complete |
| **2026-07-25** | Data ingestion + daily feed setup complete |
| **2026-08-08** | Model fine-tuning + sizing product config complete |
| **2026-08-22** | Other geographies model + sizing SIT/UAT complete |
| **2026-08-29** | Final forecast handover all regions; sizing go-live all regions |

**Historical:** May 4 redline summary [`lululemon_impact_analytics_sow_2026-05-04_summary.md`](lululemon_impact_analytics_sow_2026-05-04_summary.md); old timeline chart [`assets/lululemon_ia_sow_timeline_2026.png`](assets/lululemon_ia_sow_timeline_2026.png).

---

## SizeSmart — archived (out of scope)

`Archived 2026-06-16.` PC-era process flow and prep docs: [`archive/sizesmart/README.md`](../archive/sizesmart/README.md). Not indexed (`.cursorignore`).

---

## Four masters — baseline (2026-05-20)

| Table | Rows | Grain | Verdict |
|-------|-----:|-------|---------|
| `product_master` | 1,977,528 | `product_code` unique | PASS — 0% null l0/l2/product_name |
| `store_master` | 1,853 | `store_code` unique | PASS |
| `transaction_master` | 354,138,091 | (date, store, product) unique | PASS |
| `inventory_master` | 5,539,053 | (date, store, product) unique | PASS — **single date** `2025-08-28` (POC) |

**Cross-master:** X1/X2/X4 PASS (0 txn/inv store orphans). X6 channel aligned on sold SKUs. X5 INFO — ~63% of PM never had real sales.

---

## Product hierarchy (L0–L8 distinct counts)

2 / 2 / 11 / 27 / 55 / 102 / 16,028 / 21,741 / 169,031 — see designed infographic in assets PDF page 1.

- **L2–L5:** stable category segmentation.
- **L6–L8:** style / article / size detail; counts explode after L5.
- **Grain caution:** At `product_code_original`, channel fields can double-count — use `product_code` for channel-specific cuts.

**Identifiers:**

- `product_code_original` = bare SKU
- `product_code` = `{bare_sku}_{CHANNEL}` (PM only `_RETAIL` / `_ECOMM`)
- `article` / `article_original` = style-color (with / without channel suffix)

---

## Channel codes (store + inventory suffix)

| Code | Full form | In `product_master`? |
|------|-----------|----------------------|
| RETAIL | Brick-and-mortar retail | Yes — `*_RETAIL` |
| ECOMM | E-commerce | Yes — `*_ECOMM` |
| FO | Factory outlet | No — join via bare SKU |
| STRAT | Strategic accounts | No |
| COMMUNITY | Community (APAC/China label) | No — same type as CMNTY |
| CMNTY | Community (NAM/EMEA abbrev.) | No |

**X3 (inv → PM strict join):** 138,036 SKUs / 364,543 inv rows “orphan” — **not missing products**. Inv uses store channel in suffix; PM only RETAIL/ECOMM. **All** orphan bare SKUs exist in PM. **RETAIL/ECOMM inv rows = 100% strict match.** Txn uses RETAIL/ECOMM only (X1 = 0 orphans).

---

## Postgres ingestion (manual order on dev)

After GSM + DDL: `sync_*_master` → l0_name backfill → PAF/SAF → store SAF fix if needed → PHF dedupe → hierarchy build. `SET ROLE "mtp-dev"` before `CALL` in DBeaver.

---

## IA Platform — Sourcing Tables (intermediate builds)

**Local mirror (6 pages):** [`reference_docs/IA_Platform/Sourcing_Tables/`](../reference_docs/IA_Platform/Sourcing_Tables/) — [Confluence source](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966393875/Sourcing+Tables).

| Page | What it documents |
|------|-------------------|
| Product Master | `product_intermediate` — SKU/article grain, attribute cleanup, `SYNCSTARTDATETIME` |
| Location Master | `store_intermediate` — store/DC universe, active/status, geo tags |
| Transaction Master | `transaction_intermediate` — union retail + ecomm + partner; join product/store intermediate |
| Inventory Master | `inventory_intermediate` — OH/IT/OO at store-SKU-date; retail/ecomm flag |
| Fiscal Calendar | `fiscal_calendar_intermediate` — fiscal week/month/qtr fields |

**Lululemon:** Examples use VS `vs_sourcing_dev`; we use `lulu_sourcing_dev` with periodic MERGE SQL in `queries/sourcing/create_*_intermediate_periodic.sql`. Sourcing DAG lands raw sourced tables per `mapping.view` — see Self Note `ia_platform_sourcing_dag_behavior.md`.

**Platform habits worth copying:** inner-join product/store universe; `\N`/`NONE` sentinel casts; `SYNCSTARTDATETIME`; channel discriminator columns; aggregate to target grain before master build.

---

## InventorySmart — Handbook (offline mirror)

**Local mirror (45 pages):** [`reference_docs/Lululemon/InventorySmart_Handbook/`](../reference_docs/Lululemon/InventorySmart_Handbook/) — search here when Confluence MCP is unavailable.

| What | Where |
|------|--------|
| Index | [`README.md`](../reference_docs/Lululemon/InventorySmart_Handbook/README.md) |
| Raw JSON | `_raw/*.json` + `_pages.json` |
| Refresh | MCP `getConfluencePage` → `scripts/save_handbook_page.py` → `scripts/mirror_inventorysmart_handbook.py` |

**External-only (not in mirror body):** [Module mapping sheet](https://docs.google.com/spreadsheets/d/1zG8WmnvqGe73dHZUI47qbh4XCavNc5csdPLcnD6yW3k/) and [main handbook sheet](https://docs.google.com/spreadsheets/d/1baorqNGvx3yW_z8QGKw2muupdDXu1U064rJ8F8oVunk/) — Confluence pages link out only.

### Handbook → ingestion touchpoints (Lululemon-relevant)

| Topic | BQ / PG tables | Notes |
|-------|----------------|-------|
| Product status | `sku_status` → `productseason_validated_table` → PG `product_time_attributes`, `aggregation_time_attributes` | Back-sync PG→BQ before periodic ingestion; PAF uses current-date window; PM `active` wins on conflict |
| Store status | `store_status` → `storetime_validated_table` → PG `store_time_attributes` | Same back-sync pattern as product |
| Product–store mapping | `product_store_mapping` → PG `global.product_mapping` | Module 101 |
| Store–DC / product–DC | `store_dc_mapping`, `product_dc_mapping` | Via `sync_*` SPs |
| RCL / constraints | `rcl_priority_mapping`, `inventory_smart.rcl_*` | Module 170 (store allocation constraints) |
| DC–store policy | `inventory_smart` policy tables | Module 10003 |
| Derived tables | `article_inventory_dashboard`, `store_stock_drilldown`, `product_profile`, alert tables | Validate via [`2696611795_gbq_derived_tables_validation.md`](../reference_docs/Lululemon/InventorySmart_Handbook/2696611795_gbq_derived_tables_validation.md) + Colab notebook |
| User stories | `user_stories/*.md` | Include `fc_name` / `tc_name` for Agentic Application Configurator |

**Stub page:** `Delta Feed for DC or PO or ASN` — Confluence body is `TODO`.

---

## InventorySmart — Decision Dashboard

**Handbook:** [`reference_docs/Lululemon/Decision_Dashboard_handbook.pdf`](../reference_docs/Lululemon/Decision_Dashboard_handbook.pdf) (14 slides).

**Training UI examples (cross-client):** [`inventorysmart_decision_dashboard_uat_example.png`](assets/inventorysmart_decision_dashboard_uat_example.png) (VS UAT); [`inventorysmart_decision_dashboard_tapestry_test_example.png`](assets/inventorysmart_decision_dashboard_tapestry_test_example.png) (Tapestry TEST — Coach / Retail-Store, 2026-05-21); forecast/allocation tab screenshots in assets folder. Same IA Smart Platform V3 shell — Lululemon filters/data differ.

**Notion walkthrough (live):** [Decision Dashboard](https://www.notion.so/367389502e79811798dcc2896a695563) · [Inventory Smart hub](https://www.notion.so/367389502e7981af959bd4eb1d05db4b) · local backup [`findings/notion/InventorySmart_Decision_Dashboard.md`](../findings/notion/InventorySmart_Decision_Dashboard.md)

**What it is:** Main **landing page** in InventorySmart — high-level KPIs plus two **exception-management** alert families (forecasting + allocation); choice-level detail below.

**Data refresh (typical):** Dashboard KPIs refresh **daily** after ingestion; some forecast-alert elements may refresh **weekly**. UI shows per-feed dates (e.g. Inventory refresh, Transaction refresh, MFP refresh).

### KPI cards (dashboard top row)

Top-row KPI cards; **scoped by dashboard filters** (brand, category, class, etc.).

| KPI area | What it shows |
|----------|----------------|
| **Store inventory** | OH; **OH + in-transit (IT)**; **OH + IT + on-order (OO)** |
| **DC inventory** | Same three states at the **distribution center**: OH; OH + IT; OH + IT + OO |
| **Sales performance** | Filtered sales for **last week**, **last 4 weeks**, **last 8 weeks** |
| **Weeks of supply (store)** | How long current **store** inventory lasts (WOS variants tied to OH / IT / OO combos) |
| **Size integrity** | **Full size-range** availability — tracked separately for **store** and **DC** (% integrity metrics) |
| **Forecast accuracy buckets** | Choice counts in **High / Medium / Low** buckets (from forecast accuracy or deviation vs actuals) |

**Handbook shorthand (may appear on other slides):** OH units, Store WOS (OH), In-Stock %, DC WOS (OH), DC available-to-allocate.

**Filters:** Brand, category, class (and related hierarchy) — scope KPIs, alerts, and details.

### Alerts UI layout

- **Tabs:** **FORECAST** | **ALLOCATION** — separate exception lists per family.
- **Alert table columns:** Action Item, Description, **# of Choices**, Action.
- **Row action:** **Review Recommendation >** — drill into flagged choices for that alert type.
- **Forecast source in copy:** **IA** (Impact Analytics) forecast vs MFP or vs past actuals.
- **Table controls (right rail):** Columns, Table Actions, Format — on alerts and details tables.

### Forecasting alerts (exception management)

Identify forecasts that deviate from expectations, MFP, or recent actuals:

| Alert | Rule (summary) |
|-------|----------------|
| **Recently Launched Choices** | Launched in last **4 weeks**; forecast accuracy **< 50%** |
| **Allocate and Replenishment Choices** | Past **4-week** forecast accuracy below **60%** or **85%** thresholds |
| **MFP Deviation** | **IA** forecast vs **MFP** deviates by **± 30%** in the **next 4 weeks** |
| **Recent Deviation** | **Next 4-week** IA forecast deviates by **± 50%** from **past 4-week actuals** |

Handbook also lists: Demand Forecast is 0; Article/Store Level Inaccurate Forecast (may overlap client config).

### Allocation alerts (exception management)

Focus on inventory positioning and distribution actions. **UI labels** may differ slightly from training names (see Description column).

| Alert (training name) | UI / description (VS UAT example) | Rule (summary) |
|-----------------------|-----------------------------------|----------------|
| **Auto Allocation Review** | _(not in visible tab slice — may appear per client/config)_ | Automated recommendations — **manual approval** before release |
| **Stock Out or Shortfall** | **Stockout and Shortfall** — stockouts/shortfalls in **most eligible stores** | Majority of eligible stores affected |
| **New Choices** | Pre-allocation for **upcoming floorsets** | New master-file products **launching within next 4 weeks** |
| **Choices Below Mins** | **≥ 20% of stores** with inventory **below minimum** | Fashion choices; inventory = **OH + OO + in-transit** at store level |
| **ASN to Allocate** | Pre-allocation from **Advanced Shipping Notices** (new + existing choices) | ASNs with delivery within **next 3 weeks** |
| **New/Remodeled Stores** | _(not in visible tab slice — may appear per client/config)_ | Pre-allocate for **new or remodeled** store locations |

Handbook also names: PO to Allocate, Overstock; **OMS family:** Expedite Orders, Need Before Next ROQ, Recommended Orders.

### View allocation plans

Separate **allocation plans** panel on the dashboard (not the same as alert drill-down). Draft / unfinalized plans created during the day; user can **edit → finalize** or **delete**. Unfinalized plans may be **purged** per config if not finalized. Columns include allocation ID, plan name, choices, inventory type, created by/on, status (e.g. Draft).

### Direct actions (alerts + details table)

Users manage exceptions without leaving the Decision Dashboard flow:

| Action | Where | What it does |
|--------|-------|--------------|
| **Create New Allocation** | Most alert screens + details table | Select choices → opens allocation module with products **pre-selected** |
| **Review & approve auto-allocations** | **Auto Allocation Review** alert | Review system recommendations → **manual approve** before release to stores |
| **Review Recommendation >** | Any alert row | Drill into flagged choices for that alert (entry point to actions above) |
| **Search & filter** | Alert tables + details table | Find specific styles/choices; hierarchy filters scope the page |
| **Download to Excel** | Details table + most alert summaries | Offline reporting/analysis |
| **Forecast adjustments** | Forecasting alerts (e.g. **MFP Deviation**, **Recent Deviation**) | Select choices → navigate to **forecasting dashboard** to adjust forecast quantity |
| **Customize & save table view** | Details table (Columns / Table Actions / Format) | Show/hide metrics; **save personal configuration** |

### Details table (metrics)

**Columns (visible in UI):** Choice, Choice Description, Choice Status, Store OH, Store IT, Store OO, Total Inv, WIP, Initial OH (plus DC/sales/WOS fields per handbook).

- **Choice-level** metrics for all eligible products.
- **Inventory positioning (detail tables):** per-store status counts / **Choice Status** — **Excess**, **Normal**, **Shortfall**, **Stock out** (handbook also names Overstock).

**Terminology:** UI often says **choice** (style-color / planning choice); maps loosely to Lululemon **`article`** / hierarchy — not the same grain as `product_code` (SKU + channel).

### Backend tables (daily after ingestion; BQ + PG unless noted)

| Table | Role |
|-------|------|
| `inventory_smart.Article_inventory_dashboard` | Main dashboard feed |
| `inventory_smart.Alert_product_store_level` | Allocation alerts |
| `inventory_smart.Article_forecast_alerts_demand_zero` | Forecasting alerts |
| `Store_stock_drilldown` (BQ prerequisite) | Drilldown source |

**Link to Lululemon ingestion:** Dashboard is **downstream** of `inventory_master`, `product_master`, `store_master`, and txn feeds. X3 channel-suffix join policy matters for article/choice views if joins use strict suffixed `product_code`.

---

## Entries log (append below)

_New facts the agent adds appear here with `Added: YYYY-MM-DD`. Older sections above may be updated in place when facts are superseded._

<!-- append zone -->

### 2026-07-21: `product_intermediate.color_family` found, validated, and wired into v2 (not yet live)

- **Resolved:** `color_family` (was hardcoded `NULL`/`INT64`) now sources from `product_attribute_so.COLOUR_FAMILY` (text: Black/Blue/Grey/...), bridged through `style_option` (`IS_PRIMARY_STYLE_OPTION = 'true'`) to the PSO grain. Type changed `INT64` → `STRING` — no integer lookup ever existed; matches the IA platform's OOTB `Color_Family` string convention.
- **Wired into:** `queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql` and `queries/sourcing/create_product_intermediate_periodic.sql`. Validated via `_tmp_20260721`: 0 other columns drifted, `color_family` 0% → 92.18% fill, 0 conflicts. **Not yet promoted to the live table** — pending explicit go-ahead.
- **Superseded an old, never-implemented plan:** `findings/lululemon_client_open_questions.md` had a note to derive `color_family` by parsing `color_description` instead — confirmed never built (`product_master_clean_view.sql` excludes it); real attribute data was used instead.
- **Platform gap (separate, still open):** `product_attribute_so` base table wasn't in BQ (only `_seasonal` was) — loaded it manually via `LOAD DATA INTO ... FROM FILES(...)` (472,141 rows). One-time snapshot, no `SYNCSTARTDATETIME`; getting it into the real Sourcing DAG is still outstanding. Full write-up: [`product_intermediate_color_family_source_found.md`](product_intermediate_color_family_source_found.md).

### 2026-07-14: SKU×store×week eligibility horizon revised to 26 weeks

- **SOW change (user-confirmed Jul 2026):** SKU × store × week eligibility / forecast alignment horizon is **26 forward weeks** (not 52). Update `sku_store_eligibility` builds accordingly (`forward_weeks = 26`).
- **`lulu_sourcing_dev.eligibility` coverage vs 26w horizon (verified 2026-07-14, current week 202624):** all **27 fiscal weeks** in the horizon (current + 26 forward) have native `eligibility` rows; **no gap-fill / snapshot cross-join needed** for week coverage.
- **Density is week-varying:** PSO×store pairs range from **1,299** (week 202624) down to **3** (weeks 202649–202650). Strong in weeks 202624–202638 (~223–1,299); thin tail in last ~8 weeks (~3–51 pairs). Use **week-native** `(PSO, store, week_id)` from feed, not a single snapshot.
- **Build pattern:** intersect week-native `eligibility` with assortment SKU gate → `product_code × store × week_id`. Assortment remains time-blind (quarterly); true SKU-level eligibility feed still P0 client ask.

### 2026-06-30: Kickoff slide 20 design sessions Planned Activities draft

- Paste-ready column 3 text (7 IA deliverable blocks): [`findings/lululemon_kickoff_slide20_planned_activities_draft.md`](lululemon_kickoff_slide20_planned_activities_draft.md)
- Optional Topics column tidy (forecasting-first) included in same file.

### 2026-06-30: Kickoff slide 19 Engagement Plan redesign

- **Live deck:** [Cursor Copy of Lululemon May 2026 - Project Kickoff v2](https://docs.google.com/presentation/d/15aYGFZb2OZc3jCdSer9jg_8EKzpHuKWK0HemyZuQ-PE/edit?usp=sharing), slide 19 replaced per [`findings/lululemon_kickoff_slide19_redesign_guide.md`](lululemon_kickoff_slide19_redesign_guide.md).
- **IA PPTX:** `~/Documents/Lululemon_Engagement_Plan_Slide19_20260630.pptx`, regenerate via `node scripts/build_lululemon_engagement_slide.js`.
- **Dates on slide 19:** Timelines v3 (May 16 – Aug 29); kickoff slide 17 Jul–Nov table is stale.

### 2026-06-30: Latest SOW + Forecasting Timelines v3 ingested

- **SOW:** Jun 24 2026 redlines (`reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.docx`) is now the authoritative contract reference; supersedes Jun 25 draft and May 4 redlines.
- **Timelines:** `reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.xlsx` is the authoritative milestone/workplan reference; supersedes May 4 timeline chart PNG.
- Cursor rules updated: `lululemon-final-sow.mdc`, `lululemon-forecasting-timelines.mdc`.

### 2026-05-20 — Decision Dashboard handbook ingested

- Source PDF: `reference_docs/Lululemon/Decision_Dashboard_handbook.pdf`; CSM demo link in handbook slide 4.
- Page 3 morning PDF: `assets/lululemon_decision_dashboard_reference.png`.

### 2026-05-21 — InventorySmart training batch 1 (Decision Dashboard video + screenshot)

- Video notes: KPI refresh cadence (daily dashboard / weekly forecast alerts); forecasting alert thresholds (4-week windows, 50%/60%/85%, MFP 30%, recent deviation 50%).
- Video notes: allocation alerts (auto-allocation review, below mins 20%, stockout/shortfall majority stores, new choices 4-week launch, ASN 3-week).
- Video notes: details table filters, Excel export, create allocation from alerts/details.
- Screenshot saved: `assets/inventorysmart_decision_dashboard_uat_example.png` (VS UAT — platform UI reference only).

### 2026-05-21 — InventorySmart training batch 2 (alert definitions refined)

- Framing: dashboard alerts = **exception management** (forecasting vs allocation).
- **Updated in place:** MFP Deviation → upcoming **4 weeks**; Recent Deviation → vs **actual sales**, previous **4 weeks**; Choices Below Mins → **OH + OO + in-transit** (not OH + IT only).
- **Added:** **New/Remodeled Stores** allocation alert (pre-allocate for new/remodeled locations).

### 2026-05-21 — InventorySmart training batch 3 (FORECAST tab screenshot)

- Screenshot: `assets/inventorysmart_decision_dashboard_alerts_forecast_tab.png`.
- **Added:** Alerts UI — FORECAST | ALLOCATION tabs; columns Action Item / Description / # of Choices / Action; **Review Recommendation >** drill-down.
- **Updated in place:** MFP and Recent Deviation use **±** deviation wording (IA forecast vs MFP / vs past actuals).
- **Added:** Details table column list (Choice, Description, Status, Store OH/IT/OO, Total Inv, WIP, Initial OH).

### 2026-05-21 — InventorySmart training batch 4 (ALLOCATION tab screenshot)

- Screenshot: `assets/inventorysmart_decision_dashboard_alerts_allocation_tab.png`.
- **Added:** Allocation UI labels — Stockout and Shortfall; New Choices tied to **floorsets**; table rail controls (Columns / Table Actions / Format).
- **Added:** Choice Status **Excess** in details table.
- **Note:** Auto Allocation Review and New/Remodeled Stores not in visible VS tab slice — client/config may control which rows appear.

### 2026-05-21 — InventorySmart training batch 5 (KPI definitions)

- **Updated in place:** KPI section — split **Store inventory** vs **DC inventory** (OH / OH+IT / OH+IT+OO each); sales filter-scoped timeframes; WOS store-only; size integrity = full size range at store + DC; forecast buckets from accuracy/deviation vs actuals.
- **Updated in place:** Details — **inventory positioning** statuses: Excess, Normal, Shortfall, Stock out.

### 2026-05-21 — InventorySmart training batch 6 (direct actions)

- **Added:** Direct actions table — Create New Allocation (pre-selects choices), auto-allocation approve, forecast adjustments from MFP/Recent Deviation alerts, save customized details-table views.
- **Merged:** Search/filter, Excel download (was scattered); **Review Recommendation >** linked as alert drill-down entry point.

### 2026-05-21 — Inventory Smart Handbook Confluence mirror (45 pages)

- **Added:** Offline mirror at `reference_docs/Lululemon/InventorySmart_Handbook/` — 16 handbook pages + 29 user stories; `_raw/` JSON + `README.md` index.
- **Added:** Cursor rule `.cursor/rules/lululemon-inventorysmart-handbook.mdc`; Self Note `Self Notes/inventorysmart_handbook_offline.md`.
- **Refresh:** `python3 scripts/save_handbook_page.py` (stdin JSON) then `python3 scripts/mirror_inventorysmart_handbook.py reference_docs/Lululemon/InventorySmart_Handbook/_pages.json`.
- **Gap:** Module Level Table Mapping + parent handbook link to Google Sheets only; Delta Feed page is TODO in Confluence.

### 2026-05-21 — Atlassian MCP rule (Confluence search strategy)

- **Added:** `.cursor/rules/lululemon-atlassian-mcp.mdc` — local-first search order, tool picker, known mirrors, read-only guardrails.
- **Strategy:** knowledge bank + offline mirrors → repo search → MCP `search` / `getConfluencePage` / descendants for unknown or stale content. If MCP is down: offline only, no fake lookups — ask user to enable/reload `atlassian-mcp` in Cursor Settings.

### 2026-05-21 — Notion page location (user moved)

- User moved **Inventory Smart -Tool** to **top-level** in Notion (no longer under Lululemon EDA). Page IDs unchanged.
- **Canonical map:** `findings/notion/notion_workspace_map.md` — Decision Dashboard writes → `367389502e79811798dcc2896a695563`; new IS pages → hub `367389502e7981af959bd4eb1d05db4b`.
- **Added:** `findings/notion/InventorySmart_Decision_Dashboard.md` — full UI section guide (chrome, filters, KPIs, plans, allocation alerts row-by-row, forecast tab reference, details table, data links).
- **Screenshot:** `assets/inventorysmart_decision_dashboard_tapestry_test_example.png` (Coach / Retail-Store, Tapestry TEST env).

### 2026-05-21 — IA Sourcing Tables Confluence mirror (6 pages)

- **Added:** Offline mirror at `reference_docs/IA_Platform/Sourcing_Tables/` — Product, Location, Transaction, Inventory, Fiscal Calendar + parent index.
- **Added:** Cursor rule `.cursor/rules/ia-platform-sourcing-tables.mdc`; Self Note `Self Notes/ia_platform_sourcing_tables_handbook.md`; generic script `scripts/mirror_confluence_pages.py`.
- **Source:** [Sourcing Tables](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966393875/Sourcing+Tables) — VS reference SQL; Lululemon analogues in `queries/sourcing/create_*_intermediate_periodic.sql`.

### 2026-05-22 — Impact Analytics SOW (May 4 2026 redlines)

- **Added:** PDF → `reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-05-04_redlines.pdf`; agent summary → `findings/lululemon_impact_analytics_sow_2026-05-04_summary.md`.
- **Scope anchor:** offline forecasting + size curves (PSS/PSO grains), explainability, daily regional refresh.
- **Draft gaps:** unsigned; Section 6 Product Details + Schedule 1A fees missing from PDF extract.

### 2026-05-25 — IA SOW timeline chart (supersedes PDF Section 12 dates)

- **Added:** `findings/assets/lululemon_ia_sow_timeline_2026.png` — Apr–Dec 2026 Gantt (forecast + sizing tracks).
- **Key dates:** kick-off **Jun 8** · data sign-off **Jun 29** · daily feed live **Aug 17** · Phase 1 go-live **Oct 12**.
- PDF Apr/May data milestones retained for contract traceability only.

### 2026-05-25 — SOW prep plan + fiscal pipeline (P0 #1)

- **Added:** [`lululemon_sow_prep_plan_2026.md`](lululemon_sow_prep_plan_2026.md) — 2–3 week prep reference.
- **Added:** [`fiscal_date_mapping_pipeline.md`](fiscal_date_mapping_pipeline.md) + SQL: `queries/sourcing/create_fiscal_calendar_intermediate_*.sql`, `register_fiscal_calendar_mapping.sql`, `postgres_fiscal_date_mapping_setup.sql`, `fiscal_date_mapping_validation_gates.sql`.
- **BQ master:** ✅ 4746 rows · **sourcing intermediate + PG sync:** scripts ready — run in BQ + DBeaver with DI approval.

### 2026-05-27 — SizeSmart planned process flow (archived 2026-06-16)

- **Was:** [`archive/sizesmart/findings/lululemon_sizesmart_process_flow.md`](../archive/sizesmart/findings/lululemon_sizesmart_process_flow.md) — out of scope.
- **Roles:** client implementation agrees rules with lululemon; sizing team validates + generates curves; Steps 1–3 inputs are static once agreed.
