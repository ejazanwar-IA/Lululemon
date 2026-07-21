# Dataset Inventory - `lululemon_souricng_outbound`

> Reference catalog of all ~300 tables. **Updated 2026-04-20** via `queries/list_all_tables.sql`.

| Field | Value |
|-------|-------|
| **Project / Dataset** | `lululemon-01042025.lululemon_souricng_outbound` |
| **Total Tables** | ~300 |
| **Biggest Table** | `inventory_snapshot` — 63.4B rows, 3.3 TB |
| **Total Storage** | Multi-PB range |

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🟡 **Dataset is a working lake, not curated. Need discipline to avoid using wrong versions.**

**TL;DR:**

1. **~300 tables total**, of which **only ~26 are canonical masters** we should work with. The rest are backups, versions, scenarios, and prior POC modeling outputs.
2. **4 "expected" tables are empty** in their raw form (`dc_store_mapping`, `anaplan_allocation_calender`, `eligibility_new`, `TE2_0_*_pod`). Use their `_cleaned` or `_20251119` siblings.
3. **5 non-checklist tables found** that matter: `returns_transactions_20251119` (734M), `price_book` (440M), `sku_details_cleaned`, `safety_stock`, client's own `anaplan_demand_forecast` (2B). Worth confirming with client.
4. **Prior POC modeling outputs** (`master_table`, `master_input_imputed`, `master_validated_table_*` — 20-48B rows each) contain known data quality issues from earlier work. **Do not use as inputs** — rebuild from clean masters.

**What you need to decide, Uttkarsh:**

- **Cleanup of the lake.** Many redundant versions. Worth asking data-engineering team to set up a curated "canonical" dataset.
- **Client confirmation** on the 5 non-checklist tables — intentional or test data?

---

## 💡 My Recommendations (as analyst)

1. **Always cross-check against `findings/schema_inventory.md`** before writing queries — it lists the 26 canonical tables with partition/cluster info.
2. **Never use a raw table without checking row count first.** Several are EMPTY (0 rows) — a silent-fail trap.
3. **Spelling matters:** `anaplan_allocation_calender` (misspelled, empty) vs `anaplan_allocation_calendar_cleaned` (correct, 39M). Pay attention.
4. **Prior POC modeling tables should not be touched.** The kickoff transcript warned about data quality issues in earlier work — those `master_table` outputs reflect that. We need to rebuild.

---

## Canonical Tables (what to use for EDA / joins)

| Purpose | Canonical Table | Rows | Size | Notes |
|---------|-----------------|-----:|-----:|-------|
| **Product Master** | `product_master` | 1,977,528 | 1.1 GB | ✅ EDA done |
| **Transaction Master** | `transaction_master` | 389,872,378 | 73 GB | Cleaned, named master |
| Transaction (4y cleaned) | `sales_transactions_4y_cleaned_20251119` | 392,172,507 | 56 GB | Near-identical to master |
| Transaction (raw) | `sales_transactions_20251119` | 683,582,361 | 79 GB | Raw Nov 19 refresh |
| **Inventory Master** | `inventory_master` | 7,214,258,665 | 650 GB | **Very large — sample queries** |
| Inventory (raw) | `inventory_snapshot` | 63,454,067,681 | **3.3 TB** | Do NOT full-scan |
| **Store / Location Master** | `store_master` | 1,853 | <1 MB | Cleaned location data |
| Location raw | `location_details_cleaned_20251119`, `location_group_hierarchy_cleaned_20251119` | 1,853 | | |
| **Fiscal Calendar** | `calendar_hierarchy` | 4,746 | 1.5 MB | Or `fiscal_date_mapping` (identical) |
| **Returns** | `returns_transactions_20251119` | 733,682,768 | 79 GB | Not in Client Checklist — flag |
| **Pricing** | `price_book` | 440,496,318 | 32 GB | Not in Client Checklist — flag |
| **Purchase Orders** | `purchase_orders_cleaned_20251119` | 20,803,006 | 2.9 GB | |
| **Transfer Orders (Receipts proxy)** | `transfer_orders_cleaned_20251119` | 710,271,174 | 69 GB | |
| **Transfer Orders (New)** | `transfer_orders_new_cleaned` | 75,893,552 | 8 GB | Or dated version |
| **Promotions/Events** | `promotional_events_cleaned_20251119` | 448,134 | 27 MB | |
| **SKU-Store Eligibility** | `eligibility_20251119` or `eligibility_cleaned_20251119` | 242M / 2.3B | 14 GB / 255 GB | 10× size diff — investigate |
| **Assortment / Store Level Buy Qty** | `assortment_plan_cleaned` | 42,594,160 | 8 GB | Or `_20251119` variant (8.6M) |
| **Allocation Calendar** | `anaplan_allocation_calendar_cleaned` | 39,230,138 | 7 GB | Raw is EMPTY |
| **FDOD Allocation** | `anaplan_fdod_alloc_cleaned` | 16,032,486 | 1.4 GB | |
| **FDOD Replen** | `anaplan_fdod_replen_cleaned` | 30,918,903 | 1.4 GB | |
| **Min Pres** | `anaplan_min_pres_cleaned` | 8,839,533 | 1.4 GB | |
| **Transit Calendar** | `anaplan_transit_calender_cleaned` | 51,276,624 | 4 GB | |
| **DC-Store Mapping** | `dc_store_mapping_cleaned_20251119` | 1,110,005 | 73 MB | Raw is EMPTY |
| **Store Priority** | `anaplan_store_priority_cleaned` | 8,828 | <1 MB | |
| **Spatial (demography)** | `spatial_ai_cleaned` | 22,798 | 9 MB | |
| **Style Options** | `style_option_20251119` | 469,512 | 47 MB | |

---

## Empty / Problematic Tables

| Table | Rows | Alternative |
|-------|-----:|-------------|
| `dc_store_mapping` (raw) | 0 | Use `dc_store_mapping_20251119` (1.1M) |
| `anaplan_allocation_calender` (raw) | 0 | Use `anaplan_allocation_calendar_cleaned` (39M) — note spelling difference (`calender` vs `calendar`) |
| `eligibility_new` | 0 | Use `eligibility_20251119` (242M) |
| `TE2_0_EA_Demand_Forecast_pod` (+ 4 variants) | 0 | Use `TE2_0_EA_Demand_Forecast_pod_combined_v1_table` (1.2B) |
| `delivery_week_logic` | 1 | Sentinel record only |
| `fdod_alloc_ext`, `transit_calendar_ext`, `allocation_product_filters` | 0 | Empty placeholders |

---

## Tables NOT in Client Data Checklist (Not Previously Flagged)

These exist in the dataset but weren't in the Client Data Checklist we have. Worth asking client whether these are intentional or internal-only:

| Table | Rows | Likely Role |
|-------|-----:|-------------|
| `returns_transactions` / `returns_transactions_20251119` | 711M / 734M | Returns (net-sales calculation) |
| `price_book` | 440M | Pricing data (SKU × date × price) |
| `sku_details` / `sku_details_cleaned` | 1B / 1.97M | SKU-level attributes (1.97M matches product_master) |
| `safety_stock` / `safety_stock_calculated_daily_sku` / `safety_stock_simple` | 5M / 1.4M / 1.4M | Derived from allocation logic |
| `implied_service_levels` | 3M | Derived |
| `vmi_report` | 3M | Vendor-managed inventory |
| `article_demand_df` / `article_demand_df_ranked` | 15M / 148M | Demand data |
| `lululemon_usa_retail_forecast` | 1.3B | Client forecast ingested |
| `anaplan_demand_forecast` / `anaplan_demand_forecast_cleaned` | 1.2B / 2B | Client's Anaplan forecast |
| `price_book`, `price_book_old` | 440M / 421M | |
| `product_group_hierarchy` | 11.5M | Additional hierarchy data |

---

## Modeling Output Tables (Not Raw Sources)

These are Impact Analytics's derived/output tables — **do not confuse with raw data**:

- `master_table`, `master_table_1`, `master_table_2` — 49B / 4.4B / 466M rows (SKU × store × week training inputs)
- `master_input_imputed`, `master_input_imputed_1`, `master_input_imputed_table_*` — imputed training data (multi-billion rows)
- `master_validated_table`, `master_validated_table_v2`, `v3`, `v4`, `_backup` — validated training sets (all ~21-26B rows)
- `lululemon_sims_out_*`, `lululemon_simulations_*` (v1-v6) — simulation outputs
- `ada_visual_predictions_v1`, `ada_visual_predictions_v2` — forecast engine outputs (~464M / 546M rows)
- `lulu_womens_size_curve_*`, `lulu_size_*` — size curve analysis
- `transfer_engine_export_*` — allocation outputs for specific dates/scenarios
- `filtered_df_*` — scenario-specific filtered dataframes
- `TE2_0_EA_Demand_Forecast_pod_*` — Transfer Engine v2.0 forecasts
- `stg_*` — staging tables (recent, Jan 11 2026)
- `allocation_*_v3` — latest allocation outputs
- `pack_details_df`, `pack_qty_df` — pack configuration outputs

---

## Version Proliferation Examples (Pick the Latest)

**Product Master:**
- `product_master` (2025-11-21, **canonical**, 1.97M)
- `product_master_v2` (2025-11-24, 1.97M) — identical size, unclear what changed
- `product_master_old` (2025-11-21, 2.55M — but "old"?)
- `product_master_ritik`, `product_master_ritik_v1`, `product_master_SC` — user-tagged variants

**Inventory Master:**
- `inventory_master` (2025-12-05, **canonical**, 7.2B)
- `inventory_master_v2` (2025-10-29, 10.7B)
- `inventory_master_dummy`, `_old`, `_temp` (2025-11-17 — all 15.3B)
- `inventory_master_partitioned` (2025-09-18, 5.2B)

**Master Validated:**
- `master_validated_table_v3` (Oct 23, 26B)
- `master_validated_table_v4` (Nov 14, 9B — much smaller)
- `master_validated_table_v3_backup`, `v2`, original — multi-billion rows

This is a **cleanup debt signal** — the team has iterated heavily. Picking the wrong version will give wrong results.

---

## Recommendations

### For Our EDA Plan

1. **Transaction Master → `transaction_master`** (389M). Cross-check against `sales_transactions_4y_cleaned_20251119` in Phase 1 to confirm they're equivalent.
2. **Inventory Master → `inventory_master`** (7.2B). Always add sampling/partitioning clauses.
3. **Store Master → `store_master`** (1,853). Trivial EDA.
4. **Fiscal Calendar → `calendar_hierarchy`** (4,746). Trivial EDA.
5. **Returns / Price Book** — surface as action items for client to confirm role.

### New Action Items for Lululemon / Internal

| # | Issue | Severity |
|---|-------|----------|
| N1 | `returns_transactions_20251119` (734M rows) exists but wasn't in the Client Data Checklist. Is this data intended for modeling? How should returns be reconciled against sales? | 🟡 P1 |
| N2 | `price_book` (440M) exists. Should pricing be a separate feature in the Transaction Master EDA, or is it already joined? | 🟡 P1 |
| N3 | `sku_details_cleaned` has exactly 1,977,528 rows (same as `product_master`). What's the difference between these two? Are they joined / can one be derived from the other? | 🟡 P1 |
| N4 | Raw tables `dc_store_mapping`, `anaplan_allocation_calender`, `eligibility_new` are EMPTY. The `_cleaned` and `_20251119` versions have data. Confirm whether we should standardize on the `_20251119` / `_cleaned` variants for all downstream work. | 🟡 P1 |
| N5 | Note: `calender` (with "e") vs `calendar` (with "a") — both spellings exist as separate tables. Confirm canonical spelling. | 🟢 P2 |
| N6 | Multiple `master_*` modeling output tables (20-48B rows) exist from prior POC work. These were created with known data quality issues per the kickoff transcript. **These should NOT be used as inputs** — rebuild from cleaned raw masters. | 🟡 P1 |

---

## Reference

- Client Data Checklist mapping confirmed: ~20 raw tables match the checklist table names
- Full raw query result: `queries/list_all_tables.sql`
