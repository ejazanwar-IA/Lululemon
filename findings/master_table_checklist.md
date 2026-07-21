# Lululemon — Master Table Build & Validation Checklist

> **Purpose:** Single tick-sheet tracking every check we should perform on each master table, synthesised from the IA internal template (`Data Checklist and EDA - Updated.docx`, originally authored for Signet) and enhanced with lessons learned from the Lululemon build (hardcoded-stub classification, lineage, build-script review).
>
> **Scope in this project:** 5 masters — `product_master`, `transaction_master_20251119`, `inventory_master`, `store_master_20251119`, `fiscal_date_mapping`. (`events_master` is trivial; PO/Receipt/MFP/Order are out-of-scope for now.)
>
> **Status legend:** ✅ Done &nbsp;|&nbsp; 🟡 WIP &nbsp;|&nbsp; 🔲 Open &nbsp;|&nbsp; ➖ N/A for this master
>
> **Owner:** Ejaz Anwar &nbsp;|&nbsp; **Last updated:** 2026-05-20 (BQ health check: [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md))

---

## At-a-glance summary

| Stage | Checks | Done | WIP | Open | N/A |
|---|---:|---:|---:|---:|---:|
| 0 — Pre-build planning | 4 | 4 | 0 | 0 | 0 |
| 1 — Build-script review | 7 | 7 | 0 | 0 | 0 |
| 2 — Global G1–G6 | 6 | 6 | 0 | 0 | 0 |
| 3 — Per-table checks | 46 | 28 | 4 | 14 | 0 |
| 4 — Lineage documentation | 3 | 3 | 0 | 0 | 0 |
| 5 — Layer-3 EDA | 17 | 0 | 0 | 17 | 0 |
| **Total** | **83** | **48** | **4** | **31** | **0** |

**Overall progress: 58% complete.** Stage 3 remaining gaps and all of Stage 5 are the open work.

---

## Stage 0 — Pre-build planning

Must be done before writing the master-table SQL. For Lululemon we're auditing tables that already exist — these are back-filled from the DDL the PC team shared.

| # | Check | Status | Evidence / Comment |
|---|---|---|---|
| S0.1 | Grain documented up-front | ✅ | All 5 masters — see `master_table_build_logic.md` |
| S0.2 | Source tables listed with alias convention | ✅ | Listed per master in `master_table_build_logic.md` |
| S0.3 | Column inventory with origin intent (source / derived / hardcoded) | ✅ | Column-origin tables in `master_table_build_logic.md` |
| S0.4 | Join keys identified + cardinality expectation | ✅ | Primary keys confirmed via grain check in `consolidated_p0_p1_issues.md` |

---

## Stage 1 — Build-script review

Catches issues **in the SQL that builds the master**, not in the data. This stage isn't in the original IA template — it's the layer we added on Lululemon after discovering ~70% of anomalies were script artifacts.

| # | Check | product | txn | inv | store | fiscal | Evidence |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| S1.1 | Hardcoded `NULL`/`0`/constants enumerated & justified | ✅ | ✅ | ✅ | ✅ | ✅ | `master_table_build_logic.md` Section  1–6 |
| S1.2 | CASE/IF polarity vs source field verified | ✅ | ➖ | ➖ | 🟡 | ➖ | `store_master.active = LOC_CLOSED_IND` — **Awaiting DE** (see `de_review_stage1_wip.md` Q1) |
| S1.3 | String manipulation NULL-safety (SPLIT/CONCAT) | ✅ | ✅ | ➖ | ✅ | ➖ | `l1_name`, `article`, `l8_id` (product); store channel split |
| S1.4 | CTE aggregation semantics reviewed | ➖ | 🟡 | ➖ | ➖ | ➖ | `all_skus AS AVG(cost_price)` + `CAST(selling_price AS INT)` — **Awaiting DE** (see `de_review_stage1_wip.md` Q2) |
| S1.5 | `DISTINCT` / `GROUP BY` usage justified | ✅ | 🟡 | ✅ | ✅ | ✅ | `transaction_master` blanket `SELECT DISTINCT` — 660K gap — **Awaiting DE** (see `de_review_stage1_wip.md` Q3) |
| S1.6 | Source-snapshot consistency across joined raw tables | ✅ | ✅ | 🟡 | ✅ | ✅ | `inventory_master` joins unsuffixed `product_group_hierarchy_cleaned` — **Awaiting DE** (see `de_review_stage1_wip.md` Q4) |
| S1.7 | Partition & cluster keys aligned with query patterns | ➖ | ➖ | ✅ | ➖ | ➖ | `inventory_master` PARTITION BY date, CLUSTER BY store_code — correct for expected access |

**Stage 1 open items** — all four are packaged for DE in [`de_review_stage1_wip.md`](de_review_stage1_wip.md) (2026-04-22) with verification SQL documented on the [DE Review — Stage 1 Queries](queries/de_review_stage1_queries.md) page. Awaiting Ritik's reply.
- S1.2 — Confirm `LOC_CLOSED_IND` polarity (1=closed or 1=active?) — **Awaiting DE**
- S1.4 — Confirm `AVG(cost_price)` semantics + `CAST(selling_price AS INT)` intent — **Awaiting DE**
- S1.5 — Confirm whether `sales_transactions` is genuinely duplicated (explaining DISTINCT) — **Awaiting DE**
- S1.6 — Confirm equivalence of `product_group_hierarchy_cleaned` vs `..._20251119` — **Awaiting DE**

---

## Stage 2 — Global checks (IA template Layer 1)

Applies to every master.

| # | Check | product | txn | inv | store | fiscal | Evidence |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| G1 | Total row count | ✅ | ✅ | ✅ | ✅ | ✅ | `consolidated_p0_p1_issues.md` |
| G2 | Column-level data dictionary (name, type, null%, distinct, samples) | ✅ | ✅ | ✅ | ✅ | ✅ | `schema_inventory.md` + per-master EDA files |
| G3 | Null % per column + decision (drop / impute / stub) | ✅ | ✅ | ✅ | ✅ | ✅ | Merged with S1.1 — every null decision is either "stub, keep" or "open with DE" |
| G4 | Outliers + categorical standardization | ✅ | ✅ | ✅ | ✅ | ✅ | Per-master EDA consolidated SQL |
| G5 | Grain documented & confirmed by `COUNT DISTINCT(pk) = COUNT(*)` | ✅ | ✅ | ✅ | ✅ | ✅ | Per-master EDA Q1/Q2 |
| G6 | Row-level duplicate check | ✅ | ✅ | ✅ | ✅ | ✅ | Per-master EDA — `transaction_master` has 660K near-dupes |

---

## Stage 3 — Per-table checks (IA template Layer 2)

### 3A. Transaction master (22 checks from IA template)

| # | Check | Status | Evidence / Comment |
|---|---|---|---|
| T1 | Classify txns by type (qty / fulfilment / shipping / channel) | 🔲 | `transaction_type`, `order_type` are all hardcoded NULL — blocker; see build logic |
| T2 | Qty > 0 when Retail Price or Cost Price = 0/null | ✅ | D-series queries — cost=0 for ~54% of rows (sku_details source issue) |
| T3 | Qty > 0 when Net Selling Price = 0/null | ✅ | Covered in txn EDA — flagged |
| T4 | Discount > 0 with Qty > 0 | 🔲 | Can't check — all discount cols hardcoded to 0 in master |
| T5 | Qty < 0 but revenue > 0 | ✅ | Returns analysis — present, documented |
| T6 | Net Selling Price < 0 for Qty > 0 | ✅ | Included in D-series |
| T7 | Discount amt not in sync with Retail / Net Sales | 🔲 | Same as T4 — discount cols hardcoded |
| T8 | Discount Amt > Retail Unit Price | 🔲 | Same as T4 |
| T9 | Net selling price < cost price (negative margin) | ✅ | Flagged; distorted by cost=0 issue |
| T10 | Retail Price < Cost Price with qty > 0 | ✅ | Subset of T9 analysis |
| T11 | Net Selling Price > Retail Unit Price with disc < 0 & qty > 0 | 🔲 | Can't check — disc hardcoded |
| T12 | Net Selling Price < Retail Unit Price & Disc > 0 with qty > 0 | 🔲 | Can't check — disc hardcoded |
| T13 | Multiple Retail Unit Price for a given SKU | 🟡 | Price variation analysis — partial (needs SKU-level) |
| T14 | Multiple Retail Unit Price for SKU-Date | 🔲 | Not yet run |
| T15 | Multiple Retail Unit Price for SKU-Store-Date | 🔲 | Not yet run |
| T16 | Range (min/max/stddev) of Retail Unit Price for SKUs | ✅ | D-series |
| T17 | Range (min/max/stddev) of Discount % for SKUs | 🔲 | Disc cols hardcoded — dead check |
| T18 | Min & max txn date | ✅ | Q1 — 4 years confirmed |
| T19 | Distribution of qty_sold | ✅ | D-series histogram |
| T20 | Missing dates in txn master | ✅ | Date-gap check done; no gaps |
| T21 | CLEARANCE_IND spread (Y/N) | 🔲 | `clearance` hardcoded to 0 — dead check |
| T22 | Multi-currency | 🔲 | `currency_exchange_rate` hardcoded NULL — open with DE |
| T23 | SKUs in txn missing from product master | ✅ | Cross-master integrity check done |
| T24 | Multiple store_code at TransID-LineID | 🔲 | Not yet run |
| T25 | Multiple SKU at TransID-LineID | 🔲 | Not yet run |

**Txn open items:** T14, T15, T24, T25 are genuine open checks. T1, T4, T7, T8, T11, T12, T17, T21, T22 are **dead checks** because the column is hardcoded — document them as "cannot be validated from master; needs source populated first" and re-run once DE fixes the build.

### 3B. Product master (8 checks from IA template)

| # | Check | Status | Evidence / Comment |
|---|---|---|---|
| P1 | Active-flag source / fallback via recent txn | 🟡 | `active_flag = 1` hardcoded; `flex_status` from `product_attribute_s` is the usable fallback |
| P2 | Dept/Class/Subclass/Vendor → one description each | ✅ | Hierarchy integrity check done |
| P3 | Sub-SKUs in txn (BO/retail) present in product master | ✅ | Coverage analysis |
| P4 | Sub-SKUs in txn (BR/outlet) present in product master | ✅ | Coverage analysis |
| P5 | Sub-SKUs in txn (ECom) present in product master | ✅ | Coverage analysis |
| P6 | Duplicates at attribute level for Sub-SKU (prod type, color) | 🔲 | Not yet run |
| P7 | Sub-SKU in inventory present in product master | ✅ | Cross-master check — 23,782 product SKUs not in inventory (explainable via build) |
| P8 | Multi-currency handling | 🔲 | Out-of-scope for product master |
| P9 | 1:1 hierarchy integrity (1 product → 1 subclass → 1 class, etc.) | ✅ | Hierarchy check done |

### 3C. Inventory master (11 checks from IA template)

| # | Check | Status | Evidence / Comment |
|---|---|---|---|
| I1 | SKU in inv but not in txn (dead stock) | ✅ | Cross-master integrity |
| I2 | SKU in txn but not in inv | ✅ | Cross-master integrity |
| I3 | SKUs in inv not in product master | ✅ | Cross-master integrity |
| I4 | Store in inv present in store master | ✅ | Cross-master integrity |
| I5 | Inventory allocated to closed stores | 🔲 | Depends on S1.2 resolution (store.active polarity) |
| I6 | On-hand < 0 | ✅ | Negative OH flagged as P0 |
| I7 | On-hand = 0 | ✅ | Zero-OH concentration by channel |
| I8 | Total DC count | ✅ | Store audit — DCs identified |
| I9 | DC min/max dates + DC on-hand | 🟡 | Partial — needs DC-specific slice |
| I10 | Inv/txn overlap (flow check) | 🔲 | Requires joint SKU-store-date aggregation, not yet run |
| I11 | Sales ≤ inventory per SKU-store-date | 🔲 | **Critical for Sizesmart** — highest priority open check |

### 3D. Store master (5 checks from IA template)

| # | Check | Status | Evidence / Comment |
|---|---|---|---|
| S1 | Store code format consistent | ✅ | `location_audit.md` |
| S2 | Store IDs in txn present in store master | ✅ | `location_audit.md` |
| S3 | Store IDs in inv present in store master | ✅ | `location_audit.md` |
| S4 | Store count by channel | ✅ | `location_audit.md` |
| S5 | Closed-date spread | ✅ | `location_audit.md` — 3 stores with close dates, plus polarity issue |

### 3E. Fiscal date mapping (bespoke — not in IA template)

| # | Check | Status | Evidence / Comment |
|---|---|---|---|
| F1 | Calendar continuity (no missing days) | ✅ | Fiscal EDA Q1 |
| F2 | Week/month/quarter/year hierarchy 1:1 | ✅ | Fiscal EDA Q2 |
| F3 | Season coverage | ✅ | Fiscal EDA Q3 |
| F4 | Hardcoded NULL columns enumerated | ✅ | 13 cols — `master_table_build_logic.md` Section  6 |
| F5 | Prior-period window functions sanity check | ✅ | Fiscal EDA Q4 |
| F6 | Holiday/trend columns — populate plan | 🔲 | Hardcoded NULL — need business rules if Forecast needs them |

---

## Stage 4 — Lineage & documentation

| # | Check | Status | Evidence |
|---|---|---|---|
| L1 | Raw → master column-level lineage diagram | ✅ | `raw_to_master_lineage.md` (Mermaid + matrix) |
| L2 | Every column tagged by origin bucket (real / hardcoded / derived / duplicated / buggy) | ✅ | `master_table_build_logic.md` column-origin tables |
| L3 | Open questions tagged to owner (DE / client / internal review) | ✅ | Per-master "Open questions" blocks |

---

## Stage 5 — Layer 3 EDA (from IA template)

Not yet started on Lululemon — this is the Phase 2 work once the Phase 1 data-quality picture is locked in.

### 5A. Store data EDA (~12 checks)

| # | EDA | Status | Notes |
|---|---|---|---|
| SD1 | For SKU-Store-Date, qty_sold > on-hand inv (backlog of I11) | 🔲 | Data-quality check for forecasting inputs |
| SD2 | Sales pattern across H1 / Year | 🔲 | |
| SD3 | Sales pattern across Channel × Year | 🔲 | |
| SD4 | SKU count across H1 | 🔲 | |
| SD5 | Revenue-based SKU classification (ABC) | 🔲 | |
| SD6 | Age-based SKU classification (inv + txn) | 🔲 | |
| SD7 | L1/L2 hierarchy × min/max date × age × sales × qty × new-SKU × revenue contribution | 🔲 | |
| SD8 | Promo behavior by dept | 🔲 | Blocked by discount cols being hardcoded 0 |
| SD9 | Product life-cycle on sales flow × merch category | 🔲 | |
| SD10 | Sales > inventory investigation (TY) — top SKU / top dept | 🔲 | |
| SD11 | Discount flow EDA + discounts to consider for future promos | 🔲 | Blocked by hardcoded 0 |
| SD12 | Retail price range across class / sub-class / dept (min/max/mean/median) | 🔲 | |

### 5B. Ecom EDA (~5 checks)

Lululemon has `channel = 'ECOMM'` rows in txn; BOPIS/SFS signals aren't in the current master (out-of-scope unless feed is extended).

| # | EDA | Status | Notes |
|---|---|---|---|
| ED1 | Distribution of transacted SKUs across channels (RETAIL / ECOMM / OUTLET) | 🔲 | |
| ED2 | Ecom-only vs retail-only SKU overlap | 🔲 | |
| ED3 | Price / discount variation Ecom vs BnM | 🔲 | Discount blocked |
| ED4 | Drop-ship / dotcom-exclusive SKU sales pattern | 🔲 | If feed includes indicator |
| ED5 | Channel × dept × season contribution | 🔲 | |

---

## Dead-check register (for the client/DE handoff)

Checks in the IA template that **cannot be run against the current master** because the column is hardcoded. Document these explicitly so the client knows we didn't skip them — they're blocked upstream.

| Check IDs | Column(s) | Blocker | Unblock action |
|---|---|---|---|
| T1, T22 | `transaction_type`, `order_type`, `transaction_category`, `currency_exchange_rate` | Hardcoded NULL | DE to populate from `sales_transactions` fields |
| T4, T7, T8, T11, T12, T17, T21, SD8, SD11, ED3 | `clearance`, `unit_discount_amount`, `total_discount_amount`, `clearance_price`, `launch_price` | Hardcoded 0 / NULL | DE to join `price_book` / discount source |
| P1 (partial) | `active_flag` | Hardcoded 1 | Use `flex_status` from product_attribute_s; DE to source true activity flag |
| I10, I11 | `oo`, `wip`, `initial_oh_quantity` | Hardcoded 0 | DE to source transfer / PO joins |
| F6 | `holiday`, `trend` | Hardcoded NULL | Business to provide holiday calendar |

---

## Recommended enhancements for the IA internal template

Based on what we learned on this engagement, these classes of check should be added to the canonical IA checklist so the next client's team isn't caught off-guard:

1. **Stage 1 entirely** — Build-script review before Stage 2 data checks.
2. Column-origin classification (real / hardcoded / derived / duplicated / buggy).
3. Semantic-name vs logic check (polarity bugs like `active = CLOSED_IND`).
4. Cross-table snapshot consistency (all joined raws from same date-stamp).
5. CTE/alias verification (case-insensitive name collisions).
6. Partition / cluster alignment with query patterns.
7. Explicit `SELECT DISTINCT` justification.
8. Dead-check register as a first-class artifact (client visibility).

---

## References

- IA source template: `reference_docs/Lululemon/Project Context Docs/Data Checklist and EDA - Updated.docx`
- Build logic analysis: [`master_table_build_logic.md`](master_table_build_logic.md)
- **DE review package (Stage 1 WIP):** [`de_review_stage1_wip.md`](de_review_stage1_wip.md) + [queries page](queries/de_review_stage1_queries.md) (raw SQL: `queries/de_review_stage1_verification.sql`)
- Consolidated EDA findings: [`consolidated_p0_p1_issues.md`](consolidated_p0_p1_issues.md)
- Lineage diagrams: [`raw_to_master_lineage.md`](raw_to_master_lineage.md)
- Location deep-dive: [`location_audit.md`](location_audit.md)
- Project context: `PROJECT_CONTEXT.md`
