# Lululemon - Project Context

> **Last Updated:** 2026-06-16 (v3 — SizeSmart out of scope; material archived)
> **Current Phase:** Data Cleaning & EDA (Forecasting)
> **Transitioned From:** Sri Harsha
> **Owner:** Ejaz Anwar
> **Company:** Impact Analytics

---

## Project Overview

Lululemon is a retail client that went through a **Proof of Concept (PC)** phase with Impact Analytics. The PC was delivered around **December 2024 / January 2025**. The project was then put on hold for ~4-5 months due to a CEO change and organizational instability at Lululemon. It has now been **revived** (as of ~April 2026) to proceed with full implementation.

Lululemon plans to use the product to operate across **~24 countries globally** (primarily US and Asian countries, with an equal spread).

---

## Products in Scope

| Product | Status | Notes |
|---------|--------|-------|
| **Size Smart** | **Out of scope** (archived 2026-06-16) | PC-era sizing work preserved in [`archive/sizesmart/`](archive/sizesmart/). Not part of revived engagement. |
| **Forecast Smart (ADA Visual)** | In scope | Demand prediction software - provides forecasting numbers (which product, which store, how much quantity for next 8 weeks). The ADA team generates the forecasting numbers; they don't work on the product itself |
| **Inventory Smart** | Declined | Lululemon's allocation method didn't fit the tool's use cases |

---

## Competitors

| Competitor | Notes |
|------------|-------|
| **Anna Plan** | Demand planning application. Built a product called **Serup/Setup** (software similar to Impact Smart Suite). Direct competitor on demand planning |
| **GDA** | Impact Analytics is actively replacing GDA's software across various clients |
| **Slalom Consulting** | Built Lululemon's current Transfer Engine models inside Anaplan |

---

## Team & Key Contacts

| Person | Role | Context |
|--------|------|---------|
| **Sri Harsha** | Former project lead, now on Data Engineering team | Point person for **product-related** issues. Involved in data ingestion planning |
| **Ritik** | Former SBA (from beginning of project) | Has **raw data context** - created raw tables. Primary contact for data questions |
| **Shrian Shara** | Former SBA (from beginning of project) | Additional raw data context |
| **Akib Khan** | Core product team - Size Smart PC | Implements Size Smart for multiple clients. Works on refreshing tables for Size Smart |
| **Anul** | Previously did forecasting for Lululemon | May no longer be on the project - check with Uttkash for current team |
| **Uttkash** | Manager/Lead | Check with him: who is implementing Forecast Smart, and what's the current plan |

**Groups:**
- **Lululemon India Team Implementation** - main group (Ritik, Shrian Shara are members)
- **Lululemon Size Smart** - Size Smart specific group (Akib Khan is here)

---

## Technical Architecture

### Data Flow
```
Lululemon (AWS S3) --> DevOps extraction --> GCP (BigQuery)
                                              |
                                    Raw tables (sourcing datasets)
                                              |
                                    Master tables (created via SQL queries)
                                              |
                                    Injection datasets (product backend tables)
                                              |
                                    PostgreSQL (Cloud SQL) -- powers the tool
```

### Key Technical Details
- **Client's data warehouse:** AWS S3 buckets
- **Impact Analytics platform:** GCP (BigQuery)
- **Raw data schema:** `sourcing_outbound` in BigQuery
- **Tool database:** PostgreSQL (Cloud SQL) - the tool is NOT directly powered by GCP tables
- **Computation:** Happens in BigQuery during ingestion, then data is copied from GCP to PostgreSQL and inserted there
- **Cost efficiency:** PostgreSQL is free for number of hits; runs on a snapshot from Cloud SQL
- **Data refresh needed:** Weekly (inventory positioning, sales data, product/store deltas)
- **Pipeline management:** Self-Help UI for operating Airflow pipelines (create tables, set execution order)

### Environments
| Environment | URL Pattern |
|-------------|-------------|
| **UAT (current)** | `lululemon-test.impactsmartsuit.com` |
| **Dev** | `lululemon-devs.impactsmartsuit.com` |
| **Prod** (future) | `lululemon.impactsmartsuit.com` |

---

## Dataset Inventory - Canonical Table Map

> **Sources:**
> - High-level inventory: [findings/dataset_inventory.md](findings/dataset_inventory.md)
> - **Full schema + samples reference:** [findings/schema_inventory.md](findings/schema_inventory.md) ⭐ (pulled 2026-04-20)
> - **Master build DDL/logic:** [findings/master_table_build_logic.md](findings/master_table_build_logic.md) ⭐ (added 2026-04-21) — explains ~70% of "anomalies"
> - **Source DDL CSV:** `reference_docs/Lululemon/Master Table Build Logic/master_table_build_queries_20251119.csv`
> - **Master table build & validation checklist:** [findings/master_table_checklist.md](findings/master_table_checklist.md) ⭐ (added 2026-04-22) — 83-check tick-sheet synthesised from IA template + Lululemon learnings; also a tab in `Lululemon_EDA_Findings.xlsx`
> - **IA canonical template:** `reference_docs/Lululemon/Project Context Docs/Data Checklist and EDA - Updated.docx` (Signet-originated, our baseline)
> - **Project / Dataset:** `lululemon-01042025.lululemon_souricng_outbound`
> - **Total Tables:** ~300 (most are backups/versions/scenarios/modeling outputs)

### ⚠️ Master Table Build Logic — CRITICAL

**Canonical sourcing intermediates (locked v2, Jul 2026):** [`findings/lululemon_intermediate_builds_v2_reference.md`](findings/lululemon_intermediate_builds_v2_reference.md) and `queries/sourcing/create_*_intermediate_historic_v2.sql`. Use that doc (not this table alone) for current build logic, wired columns, and blocked stubs. Live GSM masters may still reflect older outbound builds until v2 is promoted.

Each master table (`product_master`, `transaction_master`, `inventory_master`, `store_master`) is built from raw tables via a SQL script (see CSV above). **Many columns are hardcoded NULL/0 in these scripts**, not missing from the feed:

| Master | Source Tables | Hardcoded Stubs |
|---|---|---|
| `product_master` | `product_group_hierarchy_cleaned_20251119` + `sku_details_cleaned_20251119` + `product_attribute_s_20251119` | `article_status='ACTIVE'`, `active_flag=1`, `color_family=NULL`, `ordering=NULL`, `launch_date=NULL` |
| `transaction_master` | `sales_transactions_4y_cleaned_20251119` + `product_group_hierarchy` + CTE-averaged `sku_details` + `store_master` | 12 NULL stubs + 5 zero stubs (discount suite, line_id, transaction_type, etc.) |
| `inventory_master` | `inventory_snapshot_cleaned` + `product_group_hierarchy_cleaned` | `oo=0`, `wip=0`, `initial_oh_quantity=0`, `total_units=oh` |
| `store_master` | `location_group_hierarchy_cleaned_20251119` + `location_details_cleaned_20251119` | `location_attrib_squareft=0`, `special_classification=NULL`, `active=LOC_CLOSED_IND` ⚠️ (polarity?) |

**⚠️ Suspected logic bugs** (from master_table_build_logic.md review):
1. `store_master.active = LOC_CLOSED_IND` — if LOC_CLOSED_IND=1 means "closed", polarity is inverted
2. `transaction_master` cost/msrp via CTE `AVG(COST_PRICE)` per SKU — time-insensitive averaging
3. `sku_details_cleaned_20251119.COST_PRICE` / `SELLING_PRICE` are 0 in raw → blocks cost/msrp downstream

### Partitioned / Clustered Tables (filter for cost)

| Table | Partition | Cluster |
|-------|-----------|---------|
| `inventory_master` | **`date`** | `store_code` |
| `transaction_master` | **`date`** | `channel` |
| `anaplan_transit_calender_cleaned` | `Datestring` | — |
| `anaplan_allocation_calendar_cleaned` | — | `SKU_ID` |
| `anaplan_fdod_alloc_cleaned` | — | `SKU_ID` |
| `assortment_plan_cleaned` | — | `SKU_ID` |
| `transfer_orders_new_cleaned` | — | `sku_id` |

**Rule:** queries on `inventory_master` or `transaction_master` should always filter by `date` unless a full-history aggregate is genuinely needed.

### 🎯 Canonical Tables to Use for EDA / Joins

**Always use these. Do not use raw versions where a `_cleaned` or `_20251119` variant exists.**

| Purpose | Canonical Table | Rows | Size | Status |
|---------|-----------------|-----:|-----:|--------|
| **Product Master** | `product_master` | 1,977,528 | 1.1 GB | ✅ EDA done |
| **Transaction Master** | `transaction_master` | 389,872,378 | 73 GB | Next target |
| **Inventory Master** | `inventory_master` | 7,214,258,665 | 650 GB | ⚠️ Large — sample queries |
| **Store / Location Master** | `store_master` | 1,853 | <1 MB | Tiny |
| **Fiscal Calendar** | `calendar_hierarchy` | 4,746 | 1.5 MB | Or `fiscal_date_mapping` (identical) |
| Returns | `returns_transactions_20251119` | 733,682,768 | 79 GB | Not in Client Checklist |
| Pricing | `price_book` | 440,496,318 | 32 GB | Not in Client Checklist |
| Purchase Orders | `purchase_orders_cleaned_20251119` | 20,803,006 | 2.9 GB | |
| Transfer Orders (Receipts proxy) | `transfer_orders_cleaned_20251119` | 710,271,174 | 69 GB | |
| Transfer Orders (New) | `transfer_orders_new_cleaned` | 75,893,552 | 8 GB | |
| Promotions / Events | `promotional_events_cleaned_20251119` | 448,134 | 27 MB | |
| SKU-Store Eligibility | `eligibility_cleaned_20251119` | 2,302,517,438 | 255 GB | 10× larger than `eligibility_20251119` (242M) — investigate |
| Assortment (Store Level Buy Qty) | `assortment_plan_cleaned` | 42,594,160 | 8 GB | |
| Allocation Calendar | `anaplan_allocation_calendar_cleaned` | 39,230,138 | 7 GB | **Note: raw `anaplan_allocation_calender` is EMPTY** (and misspelled) |
| FDOD Allocation | `anaplan_fdod_alloc_cleaned` | 16,032,486 | 1.4 GB | |
| FDOD Replen | `anaplan_fdod_replen_cleaned` | 30,918,903 | 1.4 GB | |
| Min Pres | `anaplan_min_pres_cleaned` | 8,839,533 | 1.4 GB | |
| Transit Calendar | `anaplan_transit_calender_cleaned` | 51,276,624 | 4 GB | |
| DC-Store Mapping | `dc_store_mapping_cleaned_20251119` | 1,110,005 | 73 MB | Raw `dc_store_mapping` is EMPTY |
| Store Priority | `anaplan_store_priority_cleaned` | 8,828 | <1 MB | |
| Spatial (demography) | `spatial_ai_cleaned` | 22,798 | 9 MB | |
| Style Options | `style_option_20251119` | 469,512 | 47 MB | |

### ⚠️ Key Warnings

1. **Dataset is a WORKING lake, not curated.** ~40% of tables are backups/versions/intermediates (`_v2`, `_v3`, `_backup`, `_old`, `_20251119`, etc.). Always pick the latest canonical version.
2. **`_20251119` is the major refresh date.** When in doubt, use the `_20251119` suffix.
3. **Empty raw tables:** `dc_store_mapping`, `anaplan_allocation_calender`, `eligibility_new`, `TE2_0_EA_Demand_Forecast_pod*` (most variants). Always check row count before using a raw table.
4. **Spelling trap:** `anaplan_allocation_calender` (raw, empty) vs `anaplan_allocation_calendar_cleaned` (populated). Note the "e" vs "a".
5. **`inventory_snapshot` = 63.4 BILLION rows, 3.3 TB.** DO NOT full-scan. Use sampling, date partitioning, or the smaller `inventory_master` (7.2B) instead.
6. **Prior POC `master_*` tables exist** (`master_table` 49B rows, `master_input_imputed` 41B, `master_validated_table_v3` 26B). These contain known data quality issues from earlier work — **DO NOT use as inputs to new modeling**; rebuild from the canonical cleaned raw masters above.

### Tables NOT in Client Data Checklist (Need Client Clarification)

| Table | Rows | Role? |
|-------|-----:|-------|
| `returns_transactions_20251119` | 734M | Returns data — relevant for net-sales calculations per Signet SOP |
| `price_book` | 440M | Pricing data (SKU × date × price) |
| `sku_details_cleaned` | 1,977,528 | Exactly matches `product_master` row count — likely sibling / can be joined |
| `safety_stock`, `implied_service_levels`, `vmi_report` | 5M, 3M, 3M | Derived calculations from allocation logic |
| `lululemon_usa_retail_forecast`, `anaplan_demand_forecast_cleaned` | 1.3B, 2B | Client's own forecast ingested into dataset |

### Modeling Output Tables (NOT Raw Sources — Don't Use for EDA)

These are IA-derived output tables. Documented here so we don't accidentally treat them as raw:

- `master_table` / `master_input_imputed` / `master_validated_table_*` (billions of rows each) — training inputs
- `lululemon_sims_*`, `lululemon_simulations_*` (v1-v6) — simulation outputs
- `ada_visual_predictions_v1/v2` — forecast engine outputs
- `lulu_womens_size_curve_*`, `lulu_size_*` — size curve analysis
- `transfer_engine_export_*` — allocation outputs by date/scenario
- `filtered_df_*` — scenario-specific filtered dataframes
- `TE2_0_EA_Demand_Forecast_pod_*` — Transfer Engine v2.0 forecasts
- `stg_*` — staging tables (recent, Jan 2026)

---

## Data Requirements (IA Data Requirements - LL)

> **Source:** [IA Data Requirements - LL.xlsx](https://docs.google.com/spreadsheets/d/1IV3208zq-kH6oEtezAn6uxY1NPWaHt--/edit?usp=sharing)

### Full Data Catalog

| # | Data File | Time Period Required | Forecasting | Size Smart |
|---|-----------|---------------------|-------------|------------|
| 1 | **Location Master** | Latest | **Must Have** | **Must Have** |
| 2 | **Product Master** | Latest | **Must Have** | **Must Have** |
| 3 | **Fiscal Calendar** | 3 years (historic) + 5 years (future) | **Must Have** | **Must Have** |
| 4 | **Inventory Data** | 2 years + YTD | **Must Have** | **Must Have** |
| 5 | **Transaction Data** | 2 years + YTD | **Must Have** | **Must Have** |
| 6 | Discount at Transaction | 2 years + YTD | Good to Have | Good to Have |
| 7 | Holidays & Store Closure | 2 years (historic) + 2 years (future) | Good to Have | No |
| 8 | Purchase Order, ASN & Receipts | 2 years + YTD + Future | Good to Have | Good to Have |
| 9 | Location Attributes | Latest | Good to Have | Good to Have |
| 10 | Product Attributes | Latest | Good to Have | **Must Have** |
| 11 | Product Time Dependent Attributes | 2 years (historic) + Future | **Must Have** | Good to Have |
| 12 | **SKU-Store Forecast/Allocation Eligibility** | Future feed | **Must Have** | **Must Have** |
| 13 | Future Promotions Pricing | Future | Good to Have | No |
| 14 | Merchandising Financial Plan (Sales $, Units, GM, Receipt, Cost) | Future | No | Good to Have |
| 15 | Promo Calendar (Historical) | 2 years + YTD | Good to Have | No |
| 16 | Store Traffic / Web Traffic Data | 2 years + Future | Good to Have | No |
| 17 | Supersession | Latest & History | Good to Have | Good to Have |
| 18 | Store Level Buy Qty | Future | No | **Must Have** |
| 19 | Size Range Library | Future | No | **Must Have** |
| 20 | Buy Season Calendar | Future | No | **Must Have** |
| 21 | StyleColor-Store Buy Eligibility | Future | No | **Must Have** |

### Must-Haves Summary

**Common to both Forecasting & Size Smart (5):**
1. Location Master
2. Product Master
3. Fiscal Calendar
4. Inventory Data
5. Transaction Data

**Forecasting-specific Must-Haves (2):**
6. Product Time Dependent Attributes
7. SKU-Store Forecast/Allocation Eligibility

**Size Smart-specific Must-Haves (5):**
8. Product Attributes
9. SKU-Store Forecast/Allocation Eligibility (shared with Forecasting)
10. Store Level Buy Qty
11. Size Range Library
12. Buy Season Calendar
13. StyleColor-Store Buy Eligibility

### Current Data State
- ~45 raw tables received from Lululemon
- Most feeds contain data **up to September 2025** (one-time catch-up)
- Data quality issues exist: Product and Store tables have issues (products present in inventory but missing from master)
- Inventory, Transaction, and Location tables are relatively clean
- ~4 master tables created (Inventory Master, Transaction, Store, Product, Events, Fiscal Date Mapping)

### Client Data Checklist - Table Mapping (from internal checklist)

> **Source:** [Client Data Checklist - Lululemon](https://docs.google.com/spreadsheets/d/12ziZcdbYJBlmcUd6ebpLw8mHJutECxRbzpdbzX1N0-g/edit?usp=sharing)
> **BigQuery project.dataset:** `lululemon-01042025.lululemon_souricng_outbound.*` (note: typo "souricng" is intentional - actual schema name)

| # | Requested Table | In Data Dict | In Data | BigQuery Table / Notes |
|---|-----------------|:-:|:-:|------|
| 1 | Location Master | Yes | Yes | `location_group_hierarchy`, `location_details` (location_id = store_id) |
| 2 | Product Master | Yes | Yes | `preseason_product_hierarchy` |
| 3 | Fiscal Calendar | Yes | Yes | `calendar_hierarchy` |
| 4 | Inventory Data | No | Yes | (in data but not documented in dict) |
| 5 | Transaction Data | No | Yes | `sales_transactions` |
| 6 | Discount at Transaction | No | No | — MISSING |
| 7 | Holidays & Store Closure | Yes | Yes | `promotional_events` |
| 8 | Pack Configurations | No | No | N/A |
| 9 | Purchase Order | No | Yes | `purchase_orders` |
| 10 | ASN | No | No | Lululemon doesn't have ASN (confirmed) |
| 11 | Receipts | No | Yes | `transfer_orders_new`, `transfer_orders_processed` (have transfer_id, not receipt_id) |
| 12 | Location Attributes | Yes | No | — MISSING |
| 13 | Product Attributes | Yes | Yes | All product attributes data to be joined |
| 14 | Product Time Dependent Attributes | Yes | No | — MISSING (Must-Have for Forecasting) |
| 15 | SKU-Store Allocation Eligibility | Yes | Yes | `anaplan_allocation_calender1` (derived from `anaplan_allocation_calender`) |
| 16 | Location Groups | Yes | Yes | Same as Location Master |
| 17 | Allocations Constraints Data | Yes | Yes | `anaplan_fdod_alloc`, `anaplan_fdod_replen` (WOS present), `min_pres_eol` (mins); **MAX not there** |
| 18 | Allocation Transit Data | Yes | Yes | `anaplan_transit_calender` |
| 19 | Vendor Master | No | No | — MISSING |
| 20 | Vendor - DC/Store transit data | No | No | — MISSING |
| 21 | Vendor Closure Dates | No | No | — MISSING |
| 22 | Future Promotions Pricing | No | No | — MISSING |
| 23 | Merch. Financial Plan (Sales) | No | No | — MISSING |
| 24 | Promo Calendar | Yes | No | — MISSING |
| 25 | Wholesale Customer Data | No | No | — MISSING |
| 26 | Product Image Data | No | No | — MISSING (Callum to provide per on-site action items) |
| 27 | Store Traffic / Web Traffic Data | No | No | — MISSING |
| 28 | Product-Location Historic Pricing | No | No | — MISSING |
| 29 | Store-Space Data | No | No | — MISSING |
| 30 | Vendor Constraints | No | No | — MISSING |
| 31 | Competitor Pricing | No | No | — MISSING |
| 32 | Store Level Buy Quantity | Yes | Yes | `assortment_plan` |
| 33 | Pack Constraints | No | N/A | — |
| 34 | Size Range Library | Yes | No | — MISSING (Must-Have for Size Smart) |
| 35 | Buy Season Calendar | Yes | Yes | `calendar_hierarchy` |
| 36 | StyleColor-Store Eligibility | Yes | Yes | PK: `PLANNING_STYLE_OPTION_ID`, `STORE_ID`, `WEEK_ID`. `WP_FIRST_SELLING_WEEK_ID` = first week product was eligible. A product-store can have multiple first selling week ids |
| 37 | Product DC Mapping | Yes | No | — MISSING |
| 38 | Store DC Mapping | Yes | Yes | `dc_store_mapping` |
| 39 | Supersession | No | No | — MISSING |

### Extra Tables Found in Data (beyond the checklist)

| Table | Comments |
|-------|----------|
| `delivery_week_logic` | Only has one record; not specifically requested |
| `planned_sales` | Might align with forecasted sales |
| `demand_forecast` | Might align with forecasted sales |
| `spatial_ai` | Demography near stores |
| `anaplan_store_priority` | Boolean - whether store is priority for products within the division |

### Data Gaps - What's Missing

**Critical (Must-Haves not in data):**
- **Product Time Dependent Attributes** (Must-Have for Forecasting)
- **Size Range Library** (Must-Have for Size Smart)
- **Location Attributes** (Good to Have)
- **Product DC Mapping** (in dict but not in data)

**Plus ~15 other "No/No" entries** — most are good-to-haves (vendor data, promos, competitor pricing, image data, etc.)

### Update After Full Dataset Scan (2026-04-20)

After pulling the full dataset inventory (`findings/dataset_inventory.md`), several items in the Client Data Checklist appear to have newer / cleaner variants that WERE NOT previously surfaced:

| Checklist "Missing" Item | Dataset Reality | Note |
|--------------------------|-----------------|------|
| DC-Store Mapping | Raw `dc_store_mapping` is EMPTY but `dc_store_mapping_cleaned_20251119` has 1.1M rows | Update checklist to the cleaned version |
| SKU-Store Eligibility | `eligibility_cleaned_20251119` (2.3B rows) vs `eligibility_20251119` (242M) | 10× discrepancy — investigate which is canonical |
| Allocation Calendar | Raw `anaplan_allocation_calender` (misspelled) is EMPTY; use `anaplan_allocation_calendar_cleaned` (39M) | Note spelling |

**New tables surfaced that are NOT in the checklist at all** (see Dataset Inventory section for full list):
- **Returns** (`returns_transactions_20251119`, 734M rows) — should be confirmed with client
- **Pricing** (`price_book`, 440M rows) — separate pricing feed
- **SKU Details** (`sku_details_cleaned`, 1.97M rows — matches product_master exactly)
- **Client's own forecasts** (`lululemon_usa_retail_forecast` 1.3B, `anaplan_demand_forecast_cleaned` 2B) — ingested into our dataset

### Known Data Issues
- Previous team didn't follow SOPs during PC phase, leading to data anomalies
- Recommendations were found to be not 100% correct due to unclean data
- Team never went back to Lululemon to ask for corrected data (since it was just a PC)
- Full EDA needs to be re-done on all must-have datasets

### Client Data Checklist - Additional Tabs (To Be Pulled)

The [Client Data Checklist sheet](https://docs.google.com/spreadsheets/d/12ziZcdbYJBlmcUd6ebpLw8mHJutECxRbzpdbzX1N0-g/edit?usp=sharing) has many more tabs that haven't been captured yet. When you get a chance, share these tabs so we can enrich the context:

| Tab | What it likely has |
|-----|-------------------|
| `Checklist` | ✓ Captured above |
| `Questions` | Open questions/clarifications for Lululemon — consolidated in [`findings/lululemon_client_open_questions.md`](findings/lululemon_client_open_questions.md) (sheet tab not yet exported) |
| `Queries (for csv files)` | SQL queries used when data was in CSV form |
| `Queries (for csv files) using AVP` | AVP-based versions of CSV queries |
| `notes - data ingestion 20251119` | Nov 19 ingestion notes |
| `Queries (for master tables)` | SQL for building master tables |
| `Queries (for master tables 20251119)` | Nov 19 version of master queries (likely latest) |
| `Queries (for partitioned master tables)` | Partitioned table queries |
| `Unique Keys` | Primary/unique key definitions per table |
| `Redundant Tables (Exclusion list)` | Tables to exclude / deprecated |
| `Additional questions` | Further client questions — see [`findings/lululemon_client_open_questions.md`](findings/lululemon_client_open_questions.md) |
| `store_master` | Store master structure/queries |
| `product_master` | Product master structure/queries |
| `txn master` | Transaction master structure/queries |
| `inventory master` | Inventory master structure/queries |
| `fiscal master` | Fiscal master structure/queries |
| `EDA Queries` | **Existing EDA queries - directly useful for your current work** |
| `Product attributes to keep` | Which attributes matter (for joins) |

---

## Data Ingestion Challenge

**Current problem:** Lululemon shares data via AWS S3, but Impact Analytics doesn't have an automated process to extract from AWS S3 to GCS.

**During PC:** DevOps manually helped extract from AWS to GCP (not scalable for weekly refreshes).

**Options to pitch to client:**
1. Lululemon dumps data directly into Impact's GCS bucket
2. API streaming

Sri Harsha will be involved in planning the data ingestion process.

---

## Current Tool Status
- **Inventory Smart:** Dead/disabled
- **Forecast Smart:** Already built (in UAT)
- **Size Smart:** Not enabled in UAT; should be in test environment
- Tool was not demo'd to Lululemon during PC; results were shared as Excel reports instead

---

## Lululemon's Current Systems & Processes

### Transfer Engine (Allocation & Replenishment)
- **Platform:** Anaplan (models built by Slalom Consulting)
- **Process:** Inventory data fed into engine -> uses assortment eligibility, demand forecast, inventory parameters, transit calendar -> generates allocation/replenishment recommendations
- **Allocation Calendar:** 2 drops per week per DC (Week 1 Drop A, Week 1 Drop B, etc.). System decides when to allocate based on inventory and sales rate
- **First allocation:** Typically 70-80% of total buy; IA brought this down to 40-50% during PC
- **No DC-to-DC transfers** currently
- **No standard case packs** - DC sometimes breaks vendor packs and repacks into allocation case packs

### Replenishment Components (Order-Up-To Calculation)
1. **Cumulative Forecast:** All demand between today and next delivery date
2. **Safety Stock:** Uses Poisson table based on service level (91-95% for Lulu)
3. **FDOD (Forward Days of Demand):** Set at class/market/channel level - extra padding on top of forecast (6-10 days). Planners' way of maintaining high in-stock levels
4. **Presentation Minimum (Min Pres):** Usually works as a max rule (floor), can also be additive

Replenishment need = Forecast + Safety Stock + FDOD, compared against Min Pres (as max), then compared to projected store inventory to generate dispatch requirement.

### Constrained Inventory Logic
- **Store tiers:** New stores -> Priority stores -> Everyone else
- **Demand priority:** Forecast + SS first, then FDOD & Min Pres
- **Multi-DC:** Primary DC fulfills first, then secondary DC steps in. Does NOT consider future POs when switching to secondary (pain point)

### Lululemon Personas
| Persona | Scope | Focus |
|---------|-------|-------|
| **Regional Merch Planning** | Product dimension | Manage qty flow into DC and from DC to store. Set Min Pres, WOS/FDOD, safety stock. Can override demand/FDOD values |
| **NSOAR** | New Store Opening | Inventory flow to new stores. Active from -2 months to +1 month of store opening |
| **Inventory Management** | Store/sub-market level (product agnostic) | Monitor/manage inventory levels, store remodeling, closures, special events. Sits above regional merch team |
| **S&OP** | Cross-section of planning & DC teams | Operationally focused - staffing & DC ops to support outbound volumes |
| **Global Fulfilment / DC Ops** | Logistics (product agnostic) | How items are delivered, geographically organized |

### Lululemon Pain Points (from Kickoff)
1. **Scalability:** Forecast is at a higher level than desired; need granular. Can only do primary/secondary DC, want 3+ DC flexibility
2. **Explainability:** Can't see why allocation recommendations change. Demand forecast calculation is unclear. Black box issues
3. **Efficiency:** Too much manual work in Excel outside Anaplan. Want standardization across planners
4. **Reportability:** No reporting on why actual allocation differs from forecasted. Can't simulate parameter changes
5. **New store setup:** Want more flexibility, setup ahead of time rather than close to opening
6. **Excess inventory blind spot:** Often don't have enough inventory at store, but also don't monitor WOS for excess. If IA can show areas of excess and potential savings, that's a win

### Sizing - Lululemon's Current Process (SPA Tool - In-House)
- **SPA (Size-Planning Application):** In-house tool for size package selection and sizing of receipts
- **Level:** Sub-market / Channel / Style Option / Season
- **Two checkpoints:**
  1. **Sizing Pre-Buy (20-30 days):** Generate size curves, analyze with external data, select/adjust size packages
  2. **Sizing Buy (7 days):** Review sized units vs targets, validate at style-option level, check MOQ/MCQ
- **Historical data:** 8 quarters rolling, only store-days with all sizes in stock are considered
- **Size packages:** ~300,000 per season. Planners pick a subset of sizes per submarket + channel
- **Color groupings:** All, All but Black (ABB), All but Black and White (ABBNW), All Black, White
- **Global size range** comes from PLIM (tells all available sizes for a given season)

### Forecasting - Lululemon's Current State
- Uses their own internal forecasting
- Planners look at variance from sales plan and compare to LY actuals
- **Pain points:** Events not well captured, explainability issues, newness/launches not captured well, store optimization/closures/renovations not factored properly
- **ServiceNow** is used for issue tracking, or escalated to PM
- IA's approach: Cross-validation periods for last 1 year, 13/16 week buckets, only eligible items in stock

---

## Signet SOP - Data Checks & EDA Template

> **Source:** `reference_docs/Lululemon/Project Context Docs/Data Checklist and EDA - Updated.docx`
> **Original Client:** Signet (jewelry retailer: Zales, Kay, Jared). **Use as reference for Lululemon** — most checks are directly applicable.

### Global Data Checks (for EVERY master table)

Apply these to every table (Transaction, Product, Inventory, Store, Purchase Order, Receipt, MFP, Order):

1. **Row count** — total rows in the table
2. **Data dictionary** — document every column
3. **Null check** — for each column, decide: drop row or impute
4. **Outlier / abnormality check** — plus standardize all categorical columns
5. **Granularity** — document the level of the dataset (e.g., SKU-Store-Date)
6. **Duplicate rows** — identify and drop

### Table-Specific Data Checks

#### Transaction Master
- Classify transactions by type (qty, fulfillment type, shipping method, channel)
- **Qty > 0 but Retail Price or Cost Price = 0/null** (flag)
- **Qty > 0 but Net Selling Price = 0/null** (flag)
- Discount > 0 with Qty > 0 (sanity)
- Qty < 0 but Revenue > 0 (flag - return/refund logic?)
- Net Selling Price < 0 for Qty > 0 (flag)
- Discount amount not in sync with Retail Price & Net Sales Price
- **Discount Amount > Retail Unit Price** (flag)
- **Net Selling Price < Cost Price** (negative margin - validate with client)
- Retail Price < Cost Price with QTY_SOLD > 0 (valid? vendor covers?)
- Net Selling Price > Retail Unit Price with disc<0, qty>0
- Net Selling Price < Retail Unit Price and Disc > 0 with qty>0 (miscalc)
- Multiple Retail Unit Prices for: SKU / SKU-Date / SKU-Store-Date
- Range (min, max, std_dev) of Retail Unit Price for SKUs
- Range (min, max, std_dev) of Discount % for SKUs
- Min and Max Transaction Date (data coverage)
- Distribution of QTY_SOLD
- Missing dates in the transaction master
- Spread of CLEARANCE_IND ('Y' vs 'N')
- Multiple currencies present in data
- **SKUs in txn missing in Product table** (important)
- Multiple Store_Code at TransID, LineID level
- Multiple SKU at TransID, LineID level

#### Product Master
- Find column that identifies if product is active (or fall back to recent transactions)
- Dept/Class/Subclass/Vendor must have exactly **one description each**
- Sub_SKUs in txn master (BO, BR, ECom) must exist in product master
- Duplicates at attribute level for Sub_SKU (Prod Type, Color)
- Sub_SKUs in inventory master must exist in Product Master
- Multiple currencies present
- **1-to-1 mapping at every hierarchy level** (1 product → 1 Subclass, 1 Subclass → 1 Class, etc.)

#### Inventory Master
- SKU in inventory but not in Transaction master
- SKU in Transaction but not in Inventory master
- SKUs in inventory but not in Product master
- Store in inventory must exist in Store master
- **Inventory allocated to closed stores** (flag)
- On Hand inv < 0 (flag)
- On Hand inv = 0 (distribution)
- Total number of DCs available
- Min date, max date, on hand quantity for each DC
- Inventory-Transaction overlap at store-date level
- **Sales for SKU-Store > Inventory for SKU-Store on given date/week** (critical flag)

#### Store Master
- Store code format consistent across data
- Store IDs in transaction master must exist in store master
- Store IDs in inventory master must exist in store master
- Number of stores per channel
- Closed date spread in data

#### Purchase Order
- Coverage of products vs product master
- Location column valid format
- Spread of WRITTENDATE
- COMPLETEDDATE vs NOTBEFOREDATE and NOTAFTERDATE sanity
- Compare date columns with RECEIPT_DATE from Receipt data

#### Receipt
- Coverage of products vs product master
- Location column valid format
- Receipt date NOT before NOTBEFOREDATE from PO
- PO Number coverage from PO data
- PO-Store mapping matches PO data

#### MFP (Merchandising Financial Plan)
- Banner data check
- Subclass mapped to correct class
- Subclass coverage from Product Master
- Spread of year-weeks
- Ownership types properly listed

#### Order (E-commerce)
- Format of SHIP_TO_STORE_ID
- Variant column (Sub_SKU) coverage vs product master
- Brands provided
- Vendor Name ↔ Vendor ID mapping
- Spread of Demand Units across FULFILLER_LOC
- Order data ↔ Transaction data mapping via order_id (check BnM vs Ecom flow)

### Reference EDAs (Signet Findings - for inspiration)

**Store Data EDAs:**
- SKU-Store-Date: Quantity sold should NOT be greater than On-hand inventory
- Sales pattern across H1-Year
- Sales pattern across Channel-Year
- SKU count across H1
- Revenue-based SKU classification
- Age-based SKU classification (inventory + transaction)
- Hierarchy-level analysis (min/max date, category age, sales, qty, SKUs, revenue contribution)
- Promo behavior across depts
- Product lifecycle sales flow across merch categories
- Discount flow - which discounts to consider for future promos
- Multiple descriptions for same Sig Dept Code
- Range of Retail price across categories (Min, Max, mean, median)
- **COVID weeks (FY 2021 W7-19) excluded** from modeling data
- Event flag creation for anomalous departments (e.g., Signet Dept 107 - high qty, low revenue)
- Sub-Class level: high price variation → can't use for higher-level modeling
- Store clustering: DMA field insufficient (region-based only)
- 85% of SKUs have monthly ROS of 0-0.5 (Signet); 70% have ROS 1-1.5

**E-commerce Data EDAs:**
- Distribution of transacted SKUs across channels
- Does an order_id have multiple FULFILLER_LOC?
- BOPIS/SFS distribution by dept, store, channel (retail vs outlet)
- Order IDs missing in transaction — spread of FULFILLER_LOC patterns
- BOPIS orders contain only BOPIS, Donation, Service fulfillment
- Week-on-week contribution of BOPIS/SFS orders
- In SFS: is DC inventory 0? (validate SFS is DC-unfulfillable-demand)
- Drop ship / dotcom exclusive SKUs - different sales patterns?
- Does a SKU undergo BOPIS AND other fulfillment at different points?
- BOPIS % Quantity distribution by Price Range over weeks / Event weeks

### How to Use This for Lululemon

1. **Start with Global Checks** on your 5 common must-haves: Location Master, Product Master, Fiscal Calendar, Inventory Data, Transaction Data
2. **Then Table-Specific Checks** — Transaction & Inventory have the most checks and are most likely to surface issues
3. **Map Signet columns to Lululemon equivalents** — some won't exist (e.g., Signet has Retail Unit Price + Cost Price + Net Selling Price; Lululemon may have different naming)
4. **Feed this doc + actual table name + column schema into Cursor** to generate Python/SQL EDA scripts (approach Sri Harsha suggested)
5. **Document findings** in the "Comments/Status" columns of the Client Data Checklist sheet as you complete each check

---

## Current Work Status

**Phase:** Data Cleaning & EDA for Forecasting + Size Smart

**What's being done:**
- Extracting raw data from BigQuery and validating quality
- Running EDA on all must-have datasets (see table above)
- Re-validating data cleanliness flags set by previous team
- Identifying anomalies to report back to Lululemon for corrected data

**Priority order for EDA:**
1. Common must-haves first: Location Master, Product Master, Fiscal Calendar, Inventory, Transaction
2. Forecasting-specific: Product Time Dependent Attributes, SKU-Store Eligibility
3. Size Smart-specific: Product Attributes, Store Level Buy Qty, Size Range Library, Buy Season Calendar, StyleColor-Store Buy Eligibility
4. Good-to-haves as time permits

**Known clean tables:** Inventory, Transaction, Location
**Known problematic tables:** Product Master, Store Master (missing products that exist in inventory)

---

## Immediate Next Steps

### Week 1 Priority
1. Get access to all shared documents (timeline sheets, SOPs, client data checklist, competitor info)
2. Get JupyterHub instance link from Sri Harsha for running Python EDA scripts
3. Familiarize with data tables and columns in BigQuery
4. Start EDA on all must-have datasets for Size Smart and Forecast Smart

### Short-term Actions
- [ ] Re-validate data cleanliness on all must-have tables
- [ ] Perform EDA on all datasets - identify anomalies
- [ ] If anomalies found, request new data versions from Lululemon
- [ ] Check with Uttkash: who is implementing Forecast Smart?
- [ ] Sri Harsha to introduce Ejaz to Ritik and Shrian Shara in the Lululemon group
- [ ] Sri Harsha to share: competitor company name, timeline sheets, SOPs, client data checklist, JupyterHub link
- [ ] Plan data ingestion process with Sri Harsha (pitch GCS or API streaming to client)

### Key Documents

**Obtained:**
- [IA Data Requirements - LL.xlsx](https://docs.google.com/spreadsheets/d/1IV3208zq-kH6oEtezAn6uxY1NPWaHt--/edit?usp=sharing) - Client-facing data catalog with all 21 feeds, priorities per product
- `reference_docs/Lululemon/Timelines/LL - Forecasting and Sizing Timelines.xlsx` - Full implementation timelines (Feb 2026 - Oct 2027)
- `reference_docs/Lululemon/Kick Off Document/Lululemon Timelines.xlsx` - Original POC 16-week timeline
- `reference_docs/Lululemon/Project Context Docs/Lululemon Notes Aug 20 Kickoff.docx` - Detailed kickoff notes (Transfer Engine, Sizing, Forecasting processes)
- `reference_docs/Lululemon/Project Context Docs/Lululemon on-site workshop notes.docx` - On-site workshop notes with detailed pain points and action items
- `reference_docs/Lululemon/Project Context Docs/Lululemon_Sizing Engine POV Evaluation.pptx` - POV evaluation criteria for Sizing
- `reference_docs/Lululemon/Project Context Docs/Lululemon POV Kickoff vF2_notes.pptx` - POV kickoff with scope/objectives/goals
- `reference_docs/Lululemon/Output Presentation/` - Weekly output presentations (Week 4-9, Jan 6th final review)
- `reference_docs/Lululemon/Kick Off Document/Lululemon POV Kickoff v1.pptx` and `v2.pptx` - Kickoff decks
- `reference_docs/Lululemon/Kick Off Document/GMT20250820-161313_Recording_2160x1350.mp4` - Kickoff meeting recording (Aug 20, 2025)
- `reference_docs/Lululemon/Output Presentation/Levis Slide.pptx` - Levis reference (for EDA/color handling patterns)
- `reference_docs/Lululemon/Master Table Build Logic/master_table_build_queries_20251119.csv` ⭐ **DDL for product/transaction/inventory/store/events/fiscal_date_mapping masters** (added 2026-04-21)

**Still needed:**
- [Client Data Checklist - Lululemon](https://docs.google.com/spreadsheets/d/12ziZcdbYJBlmcUd6ebpLw8mHJutECxRbzpdbzX1N0-g/edit?usp=sharing) - **internal checklist** (Checklist tab captured below; other tabs still need to be pulled - see "Client Data Checklist Tabs" section)
- `reference_docs/Lululemon/Project Context Docs/Data Checklist and EDA - Updated.docx` - **SOP doc from Signet client** - reference template for data checks and EDA (see "Signet SOP - Data Checks & EDA Template" section below)
- Lululemon ingestion tables tracker (has 45 raw table names + creation timestamps)
- Weekly output presentations (Week 4–9, Jan 6th) — still unopened, likely have more table-level logic

---

## Tools & Access Needed
- [ ] BigQuery access (raw tables in `sourcing_outbound` schema)
- [ ] JupyterHub instance (for running Python EDA scripts)
- [ ] Self-Help UI (for Airflow pipeline management)
- [ ] UAT environment access (`lululemon-test.impactsmartsuit.com`)
- [x] Cursor IDE
- [x] Confluence integration (see below)

### Confluence Setup

- **Instance:** `https://impactanalytics-team-i26gzg0e.atlassian.net/wiki`
- **Target space:** Personal (`~7120208879ed2e673641b6b354fc145398edd5`, id `163842`)
- **Parent pages:**
  - `Lululemon` (id `524289`) — top-level project parent
    - `Data Cleaning & EDA` (id `557057`) — per-table EDA pages live here
      - `Product Master - EDA` (id `622593`)

**To push markdown → Confluence:**
```bash
./scripts/confluence_push.sh findings/<file>.md [--title "Optional Title"]
```
Subsequent runs update the same page. Credentials live in `.confluence_auth` (chmod 600).

---

## Implementation Timeline (Current - from LL Forecasting and Sizing Timelines.xlsx)

**Project kick-off: April 20, 2026 (Wk1)**
**Full span: Feb 2026 - Oct 2027 (88 weeks across 3 phases)**

### Phase 1 (Feb - Oct 2026, ~37 weeks): InventorySmart + Forecasting + Sizing
| Activity | Weeks |
|----------|-------|
| Steering committee kick-off | Wk1 |
| Sample data for all datasets (Lululemon) | Wk1 |
| Sample data verification & sign-off | Wk2-3 |
| Historical data transfer (Lululemon) | Wk4-5 |
| **Data checks and queries (IA)** | **Wk5-8** ← YOU ARE HERE |
| Data query resolution & sign-off | Wk7-9 |
| Sign off on transfer mechanism & frequency | Wk9 |
| Data ingestion & daily feed setup | Wk9-16 |
| InventorySmart design sessions | Wk5-10 |
| Product configuration & internal testing | Wk9-20 |
| Forecast design sessions | Wk5-6 |
| Forecast breakdown & consumption (SKU Store level) | Wk8-17 |
| SIT | Wk21-24 |
| Training super users for UAT | Wk25 |
| UAT | Wk26-29 |
| Training all users | Wk30 |
| Deployment & go live | Wk31 |
| Hypercare & handover | Wk32-37 |

### Phase 2: Supersession, Reports, PO/ASN Allocations
### Phase 3: OMS, Transfers (DC to DC, Store to Store), Service Level

### Key Assumptions
1. Current timeline reflects PSS/Store/Week forecast for NA. EMEA and APAC to follow
2. UI will come in Phase 2 for both ForecastSmart & SizeSmart
3. Size profiles shared once a quarter (4/year) for all regions globally
4. Critical milestone: data delivery and sign-off of missing data (Oct to present) + any net new data

### Forecasting & Sizing Specific Timeline (Sheet 3)
| Activity | Period |
|----------|--------|
| Discovery/Design sessions (Forecasting + Sizing) | Wk3-5 |
| Model retraining for modelled geographies | Wk5-8 |
| Readout | Wk9 |
| SIT - Integration with Lululemon | Wk10+ |
| Fine tuning of models | Wk11+ |
| Model creation for other geographies | Wk12+ |
| Final Forecast Output Handover | Mid-timeline |
| Sizing outputs for US and CA | Parallel |
| SizeSmart product config, SIT, UAT | Following sizing outputs |
| Deployment & go live | After UAT |

---

## POV Evaluation Criteria (from Sizing Engine POV Evaluation)

### Forecast Outputs Expected
- Unit-level demand forecast for all markets and all products
- Size/store/day for in-season retail
- Size/DC/day for in-season ecom (minimizing out-of-zone)
- Bias distribution & accuracy metrics (WAPE/MAPE/RMSE) by: new product, existing product, comp product, new stores, stock outs
- Confidence intervals within forecasts
- Demand simulation UI
- Ability to see forecast changes over time as new data is fed
- Visibility on drivers of predictions

### Sizing Outputs Expected
- Quarter/style option/store sales size curves (new & existing products)
- Identify comp styles used for curves and rationale
- Show how drivers (sales performance, stock outs, lost opportunity) produced the final curve
- Size curves ensuring stores receive units appropriate for local guest
- Size-level buy at sub-market/channel/DC/week using Lululemon's pre-season quantification data

### Engine (Allocation) Outputs Expected
- Allocation/replenishment plan by store/size/DC/day
- Optimize store inventory to meet demand while minimizing lost sales and excess
- Ability for plans to use either IA's demand or Lululemon's existing demand
- Multi-DC fulfillment prioritization logic (3+ DCs)
- Simulation UI for parameter manipulation
- Explainability for transfer forecast variance

---

## PC Output Highlights (from Jan 6th Final Review)

### Allocation Approach Decision
- **WOS (Weeks of Supply) approach chosen over Service Level approach** for Lululemon allocation
- Reasons: simpler/more understandable, effective for new launches (no history for std dev), handles short cycle times (~1 week), proven with most clients
- Strategy: allocate to Mins first, then fulfill demand based on WOS targets

### Forecast Accuracy (US Ecom Simulation)
- Unit deviation of 10-20 units for 79% of SKU-Store-Weeks covering 50% sales across divisions
- Period: Oct 20 - Nov 16, 2025
- Divisions measured: Mens, Womens, Accessories, Footwear

---

## POC Phase Action Items (from On-Site Workshop - Outstanding)

### Transfer Engine
- Confirm getting Lululemon's forecast data and use it for transfer engine output sooner (before IA forecast model is ready)
- Mins-driven analysis for allocation EDAs

### Clustering
- Send store cluster details by division as Excel
- Validate CC capacity by store (use instead of square footage)
- Run clustering with fewer variables and compare

### Lost Sales Imputation
- Check LSI% on bags (expected to be higher - bags sell out faster)

### Outlier Detection (Footwear)
- Validate if inventory/sales buildup in 2024 is from assortment expansion
- Get SKU/week level MSRP data on peaks
- Get SKU/Store/Week MSRP and Scan Price behind Avg Discount % graph

### Data
- Callum to provide attribute & image data
- Harshal Shah and Minkuk to provide forecast evaluation specs

---

## Project History Timeline
| Date | Event |
|------|-------|
| ~Aug 2024 | PC phase begins. Team (Ritik, Shrian Shara) starts working on data |
| Aug 20, 2025 | Kickoff meeting (recording available in reference docs) |
| ~Sep/Oct 2024 | Sri Harsha joins the project |
| Oct 1, 2025 | On-site workshop at Lululemon |
| ~Dec 2024/Jan 2025 | PC delivered (Week 7-9 outputs, Jan 6th final review) |
| ~Jan 2025 | Lululemon CEO gets fired; project goes on hold |
| Jan-Mar 2026 | Project dormant. No communication from Lululemon |
| ~Feb 2026 | SOW signed; Sri Harsha filled internal data checklist |
| ~Mar/Apr 2026 | Lululemon revives the project - proceeds with Size Smart & Forecast Smart |
| Apr 17, 2026 | Sri Harsha transitions project to Ejaz Anwar |
| Apr 20, 2026 | Planned steering committee kick-off |

---

## Notes & Gotchas
- The CS (Customer Success) team handles: raw data, EDAs, creation of masters, and client relations
- The company operates a "factory model" - people are confined to specific roles across multiple clients
- No formal KT was given when the project paused because everyone assumed it was dead
- Previous PC results/recommendations may not be 100% accurate due to data quality issues
- For EDA: can use Cursor to generate Python scripts, feed SOP doc + table names to generate EDA queries
- SQL queries for master table creation exist in shared sheets (look for latest versions)
- **WOS approach was chosen over Service Level** for allocation - important context for any allocation work
- Lululemon does NOT have standard case pack info - DC repacks into allocation case packs
- **PSO = Product Style Option** - Lululemon creates a SKU for every low-level item by manufacture (thread/button changes get new SKUs), then groups into PSOs
- Store grading reviewed quarterly but usually unchanged quarter to quarter
- FDOD settings are a major driver of inventory holding costs - showing reduction potential is a win
- Lululemon often has more "not enough inventory at store" problems than excess, due to unclear demand forecasting and FDOD buffering
- Planners rely heavily on Excel + personal judgment - change management is important
- **NA (North America) is first** for implementation. EMEA and APAC follow later
- Size profiles shared **once a quarter** for all regions

---

## Reference Documents Index

All reference documents are stored in `reference_docs/Lululemon/`:

```
reference_docs/Lululemon/
├── Kick Off Document/
│   ├── GMT20250820-161313_Recording_2160x1350.mp4    # Kickoff meeting recording
│   ├── Lululemon POV Kickoff v1.pptx                  # Kickoff deck v1
│   ├── Lululemon POV Kickoff v2.pptx                  # Kickoff deck v2
│   └── Lululemon Timelines.xlsx                        # Original 16-week POC timeline
├── Output Presentation/
│   ├── Impact Analytics-Lululemon_Week4.pptx           # Week 4 outputs
│   ├── Impact Analytics-Lululemon_Week5.pptx           # Week 5 outputs
│   ├── Impact Analytics-Lululemon_Week6.pptx           # Week 6 outputs
│   ├── Impact Analytics-Lululemon_Week7.pptx           # Week 7 outputs
│   ├── Impact Analytics-Lululemon_Week8-9.pptx         # Week 8-9 outputs
│   ├── Impact Analytics-Lululemon_Jan6th.pptx          # Jan 6 final review
│   ├── IA - Lululemon_Jan6 _Ouput Overview and Insights.pptx  # Output overview
│   ├── Levis Slide.pptx                                # Levis reference (EDA patterns)
│   └── Lululemon Transfer Engine Process Overview.pptx # Transfer Engine details
├── Project Context Docs/
│   ├── Lululemon Notes Aug 20 Kickoff.docx             # Detailed kickoff notes
│   ├── Lululemon on-site workshop notes.docx           # On-site workshop Oct 1
│   ├── Lululemon POV Kickoff vF2_notes.pptx            # POV kickoff with notes
│   ├── Lululemon_Sizing Engine POV Evaluation.pptx     # Sizing POV evaluation criteria
│   └── Data Checklist and EDA - Updated.docx           # SOP template from Signet client (data checks + EDA)
├── Output Files - Client Version/                       # (empty)
└── Timelines/
    └── LL - Forecasting and Sizing Timelines.xlsx      # Current implementation timeline
```
