# Consolidated Data Quality Issues — All Tables

> **Purpose:** Single source of truth for all open issues across the 5 master tables EDA'd, now **reclassified by root cause** using the master-table build scripts (see `master_table_build_logic.md`).
> **Date:** 2026-04-21 (v2 — post build-logic reclassification) | **Owner:** Ejaz Anwar

---

## 🔄 What changed in v2

Previously we treated every zero/NULL column as a potential "data missing from feed" issue. After reviewing the **actual DDL/SELECT** used to build each master table (`reference_docs/Lululemon/Master Table Build Logic/master_table_build_queries_20251119.csv`), we now know:

- **~30 columns are hardcoded NULL/0** in the build scripts — not feed gaps, but intentional stubs
- **~8 columns are derived duplicates** (e.g., `total_units = oh`, `channel = s1_name`) — schema noise
- **Only 3 items are genuine upstream data gaps** that need client action
- **2 items look like logic bugs** in the build script itself

**Net effect:** the "5 P0 blockers" become 3 real blockers + 1 internal DE question + 1 suspected bug.

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🟡 **3 genuine source-data blockers. ~30 "anomalies" are PC-era schema stubs we need to decide on.**

**TL;DR in 5 bullets:**

1. **Phase 1 EDA is COMPLETE** across all 5 master tables (~7.6B rows / 725 GB). Referential integrity is clean; PKs confirmed.
2. **We were misreading the data.** Most "100% NULL" / "100% zero" columns are **hardcoded stubs** in the master build (`NULL AS launch_date`, `0 AS clearance`, `'ACTIVE' AS article_status`, etc.) — not missing feed data. 
3. **Only 3 items are real source-data blockers**: (a) cost/msrp from `sku_details` are 0, (b) inventory history starts 2023-01 (14mo gap), (c) product_master is a current-season snapshot.
4. **2 items are logic bugs to verify in the PC build script**: `store_master.active = LOC_CLOSED_IND` (polarity?), and `transaction_master`'s CTE that averages cost across a SKU's history.
5. **We self-resolved 3 items** (gender derivation, active-product filter, color family grouping).

**What I need from you, Uttkarsh:**

- **Internal call with Ritik/DE** on ~20 stubbed columns → do we populate or drop? (No client wait needed.)
- **Approve 3-item bundle to client** (cost/msrp source, inventory history, product_master history).
- **Verify the 2 build-script logic questions** with whoever wrote the PC scripts.

---

## 💡 Recommendations (as analyst)

1. **Split the client ask.** Originally we bundled 5 P0s as "upstream feed issue." Build-logic review shows only 3 are real client-side. Don't send 5 when 3 is the correct number — it weakens credibility.
2. **Run an internal DE review first.** Hit Ritik/Shrian/Sri Harsha with the ~30 stubbed columns — half of them might be populatable from raw tables in an afternoon (e.g., discount suite likely joins to `price_book`).
3. **Verify `store_master.active` polarity before using it.** Column named "active" but sourced from `LOC_CLOSED_IND`. If flipped, every store-level filter we've applied is wrong.
4. **Zero-qty mystery is solved.** 106M rows = ECOMM non-sale events + gift cards + virtual stores. Filter: `qty > 0 AND revenue > 0` drops 27%, retains 284M valid sales.
5. **China granularity worth surfacing.** 3 "China ECOMM virtual stores" are actually **Tmall (45189), WeChat (45187), JD.com (45186)** — three platforms, not one.
6. **Build clean views now.** Enough EDA + logic clarity to materialize `transaction_master_clean` and `inventory_master_clean`. Don't wait on the 3 remaining P0s — ship modeling on filtered data.
7. **`launch_date` workaround:** Since it's hardcoded NULL in the build (not missing from source), ask DE first if `product_group_hierarchy.FIRST_SELLING_DATE` or similar exists before assuming we need a first-txn proxy.

---

## 🔴 P0 Items — Reclassified by Root Cause

### Root Cause A: Genuine Source-Data Issue (3 items) — Escalate to client

| # | Issue | Table | Scope | Ask |
|:-:|-------|-------|-------|-----|
| **A-1** | `cost` and `msrp` = 0 in 100% of rows. Traces to `sku_details_cleaned_20251119.COST_PRICE` / `SELLING_PRICE` being 0/NULL in the raw source. | `transaction_master` via `sku_details` | 389M rows | Confirm raw `sku_details` state; populate or provide alt. source |
| **A-2** | Inventory history starts 2023-01-01; transactions go back to 2021-11. 14+ months missing. | `inventory_master` | — | Provide pre-2023 snapshots from `inventory_snapshot` source |
| **A-3** | Only current season (`25-4WI`) in product master; no historical snapshots. | `product_master` | 1.97M rows | Provide historical product_master snapshots (per-season or append log) |

### Root Cause B: Build-Script Stub (ask Ritik/DE, not client) — 1 bundle

| # | Issue | Table | Scope | Ask |
|:-:|-------|-------|-------|-----|
| **B-1** | ~22 columns hardcoded NULL in build scripts (discount suite, transaction metadata, `launch_date`, `color_family`, `ordering`, `location_attrib_squareft`, `special_classification`, etc.) | `product_master`, `transaction_master`, `store_master` | varies | Can these be sourced from raw tables? (see list in `master_table_build_logic.md`) |

### Root Cause C: Build-Script Logic Questions (internal code review) — 2 items

| # | Issue | Table | Ask |
|:-:|-------|-------|-----|
| **C-1** | `store_master.active = LOC_CLOSED_IND`. Column name suggests "active" but source is "closed indicator." **Polarity may be inverted.** | `store_master` | Verify `LOC_CLOSED_IND` meaning (1=closed or 1=open?) |
| **C-2** | `transaction_master` cost/msrp use `AVG(COST_PRICE)` per SKU via a CTE. Is SKU-average the right semantics for per-transaction cost, or should it be point-in-time? | `transaction_master` | Decide whether AVG is acceptable or we need a time-aware price snapshot |

### Root Cause D: Real Business Anomalies — Discuss with client / business

| # | Issue | Table | Scope | Ask |
|:-:|-------|-------|-------|-----|
| **D-1** | 64M rows (0.89%) have `oh < 0`; min = -3,704,869 | `inventory_master` | 64M rows | Legitimate (oversold/shrinkage) or data bug? |
| **D-2** | Extreme outliers: max qty=31,047, max revenue=$20M, max price=$1.07M | `transaction_master` | <50 rows | Wholesale/B2B or data error? |
| **D-3** | 42 rows with negative price AND cost > price | `transaction_master` | 42 rows | Drop, or real returns? |
| **D-4** | Max `oh` = 700,024 at single SKU/store/date | `inventory_master` | 1 row | DC aggregate / wholesale? |
| **D-5** | 8M `ivivva` inventory rows for deprecated brand (4.5M units on-hand across 1,312 stores) | `inventory_master` | 8M rows | Legacy/stranded or active? Exclude from modeling? |

---

## 🟡 P1 Items — Reclassified

### Build-Script Stubs (discovered via logic review — NOT data issues)

These are listed for completeness; they were previously treated as data gaps but are hardcoded in the DDL. **Action: include in Root Cause B bundle to DE.**

| Column(s) | Table | Hardcoded As |
|---|---|---|
| `line_id`, `launch_price`, `transaction_type`, `fullfilment_location_customer`, `revenue_before_tax`, `ship_to_country`, `freight_cost`, `store_contribution`, `workstream`, `currency_exchange_rate`, `order_type`, `transaction_category` | `transaction_master` | `NULL` |
| `clearance`, `unit_discount_amount`, `total_discount_amount`, `clearance_price`, `flagged_rows` | `transaction_master` | `0` |
| `active_flag` | `product_master` | `1` |
| `article_status` | `product_master` | `'ACTIVE'` |
| `color_family`, `ordering`, `launch_date` | `product_master` | `NULL` |
| `oo`, `wip`, `initial_oh_quantity` | `inventory_master` | `0` |
| `location_attrib_squareft` | `store_master` | `0` |
| `special_classification` | `store_master` | `NULL` |

### Derived / Duplicate Columns (drop from schema)

| Column | Table | Why |
|---|---|---|
| `total_units` | `inventory_master` | Identical to `oh` (both from `UNITS_ON_HAND`) |
| `like_store_id` | `store_master` | Same as `store_code` (self-reference) |
| `company_name`, `company_code` | `store_master` | Same as `s0_name`, brand fields |
| `district_name`, `region` | `store_master` | Duplicates of `s3_name`, `s4_name` |
| `channel` | `store_master` | Same expression as `s1_name` |

### Real Quality Issues Remaining (still valid P1s)

| # | Issue | Table | Scope |
|---|-------|-------|-------|
| T10 | 9,290 rows with qty > 0 but price/revenue = 0 (free items?) | `transaction_master` | 9.3K rows |
| PM-4 | Placeholder SKUs (1,248 short-code articles like HX, MV, NK) | `product_master` | ~55K rows |
| PM-7 | `fit_classification` 24.7% NULL (source = `product_attribute_s`) | `product_master` | 489K rows |
| PM-9 | `flex_status='Drop'` semantics — sell-down vs discontinuing | `product_master` | 572K rows |
| PM-11 | `size_scale` coded letters (B, E, I, WA, J2…) need lookup | `product_master` | 1.9M rows |
| S1 | `CMNTY` vs `COMMUNITY` — two spellings of same channel | `store_master` | 39 stores |
| S3 | `store_format_code` 21% NULL | `store_master` | 392 stores |
| S4 | `active` flag 11% NULL | `store_master` | 199 stores (see also C-1) |
| S5 | 21 channel_codes exist but have zero transactions | `store_master` | — |
| C-cal | Calendar goes only to FY27; spec requires 5 years future (FY2030) | `calendar_hierarchy` | — |

### Internal Workarounds (no client wait)

| # | Issue | Workaround |
|---|-------|-----------|
| W1 | `flex_status='Active'` is weak filter (716K "Active" never sold) | Combine with "txn in last 90d" |
| W2 | 106M zero-qty transactions | `WHERE qty > 0 AND revenue > 0` (drops 27%, retains 284M) |

---

## ✅ Self-Resolved (3) — No Client Wait Needed

1. **Gender derivation** → parse `l5_name` prefix. **99.96% coverage.**
2. **Active-product filter** → `flex_status IN ('Active', 'Drop')` gives 95.6% of sell-cycle products.
3. **Color family** → parse `color_description` (100% populated, perfect 1:1 with `color_code`). Note: `color_family` in master is a build stub, so our parse IS the canonical derivation.

---

## 🟢 P2 Items — Cosmetic

- Redundant columns (see Derived/Duplicate table above)
- Typos preserved in schema (`fullfilment_location_customer`)
- STRING-typed lat/long in `store_master` (source is also STRING)
- Minor naming inconsistency (260K l8_ids with multiple names)
- Geographic mismatches in virtual store addresses (KR ECOMM city=Hong Kong)

---

## Status Scoreboard (v2)

| Root Cause | Items | Action |
|---|---:|---|
| **A. Source data gap (client)** | 3 | Escalate via Uttkarsh |
| **B. Build-script stubs (DE)** | ~22 cols in one bundle | Internal ask to Ritik |
| **C. Logic bugs (code review)** | 2 | Verify with PC author |
| **D. Real anomalies (business)** | 5 | Discussion |
| **P1 real quality** | 10 | Some fix, some accept |
| **Workarounds in place** | 2 | Implemented |
| **Self-resolved** | 3 | Done |
| **Deferred** | 1 (launch_date) | Per user — revisit for new-product forecasting |

---

## Recommended Next Actions

### Track A: Escalate to client (needs Uttkarsh sign-off) — 3 items only

> "Phase 1 EDA complete across 5 master tables. After reviewing the PC-era build scripts, we have 3 genuine source-data gaps: (1) `sku_details.COST_PRICE`/`SELLING_PRICE` are 0 in the raw feed → blocks cost/msrp, (2) inventory history starts Jan 2023 while transactions go back Nov 2021, (3) product_master is a single-season snapshot with no history. Can we validate the raw source and rehydrate these?"

### Track B: Internal DE bundle (Ritik/Shrian/Sri Harsha)

Share `master_table_build_logic.md`. Ask: "~22 columns are stubbed as NULL/0 in the build scripts. Are any of these available in raw tables and populatable cheaply? Specifically the discount suite (likely from `price_book`) and `launch_date` / `ordering` / `color_family` (likely from `product_group_hierarchy` or `sku_details`)."

### Track C: Build-script code review (2 questions)

1. `store_master.active = LOC_CLOSED_IND` — confirm polarity
2. `transaction_master` CTE `AVG(COST_PRICE)` — confirm acceptable semantics

### Track D: Internal progress (parallel — no wait)

1. Build `transaction_master_clean` view with `qty > 0 AND revenue > 0`, `is_placeholder`, `is_virtual_store`, `primary_color` flags
2. Build `inventory_master_clean` view — drop `oo`, `wip`, `initial_oh_quantity`, `total_units`; filter `brand='lululemon'`; flag `oh < 0`
3. Transaction × Inventory reconciliation (Signet SOP)

### Track E: Still unexplored

- `returns_transactions_20251119` (734M rows) — sample looks zero-heavy, worth 15 min
- `price_book` (440M rows) — critical for discount workaround
- `eligibility_cleaned_20251119` (2.3B rows) — 10× bigger than its sibling

---

## References

- **NEW:** `master_table_build_logic.md` — full DDL/SELECT breakdown of each master, with column-origin classification
- **NEW:** `reference_docs/Lululemon/Master Table Build Logic/master_table_build_queries_20251119.csv` — source of truth
- Per-table detail: Product Master EDA, Transaction Master EDA, Store Master EDA, Fiscal Calendar EDA, Inventory Master EDA
- Schema Inventory (26 canonical tables) • Dataset Inventory (300-table lake view)
