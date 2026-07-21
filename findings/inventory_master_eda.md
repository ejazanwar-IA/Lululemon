# Inventory Master - EDA Findings

| Field | Value |
|-------|-------|
| **Table** | `lululemon-01042025.lululemon_souricng_outbound.inventory_master` |
| **Total Rows** | 7,214,258,665 (7.2 BILLION) | **Size:** 650.48 GB | **Columns:** 10 |
| **Partition** | `date` | **Cluster:** `store_code` |
| **Status** | ✅ Phase 1 Complete |
| **Owner** | Ejaz Anwar | **Last Updated** | 2026-04-20 |

**Raw-source companion:** [`inventory_snapshot_cleaned_eda.md`](inventory_snapshot_cleaned_eda.md) documents the upstream raw table that feeds this master, including pre-2023 raw history, `UNITS_AVAILABLE`, `SNAPSHOT_TIME` backfill behavior, and raw key/channel quality.

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🔴 **Two P0 issues block proper modeling. Schema is simpler than it looks — only 3 of 10 columns are actually useful.**

**TL;DR:**

1. **4 of 10 columns are useless or redundant** — `oo`, `wip`, `initial_oh_quantity` are 100% zero, and `total_units` is 100% identical to `oh`. Effective schema is 6 columns.
2. **Missing 2022 history (P0)** — inventory starts Jan 2023 but transactions go back to Nov 2021. **14+ months gap** blocks multi-year forecast backtesting.
3. **64M negative on-hand rows (P0)** — 0.89% of rows with `oh < 0`, min = -3.7M units. Could be legitimate (oversold / shrinkage reconciliation) or a bug. Needs a call, not an email.
4. **Perfect referential integrity** — zero orphan products, zero orphan stores vs masters.
5. **High SKU coverage:** 99.3% of product_master SKUs have inventory records (vs 47% with transactions) — makes sense, inventory tracks unsold stock too.

**What you need to decide, Uttkarsh:**

- **Escalate P0-4 (missing 2022 history) as highest-priority client ask** — it's the biggest modeling blocker.
- **15-min call to confirm negative on-hand is legitimate** vs feed bug (hard to tell from data alone).
- **Approve schema simplification** — drop `oo`/`wip`/`initial_oh_quantity`/`total_units` from downstream use. They add nothing.

---

## 💡 My Recommendations (as analyst)

1. **This table is secretly simpler than it looks.** 10 columns sounds rich but 4 are useless. We effectively have: `date`, `store_code`, `product_code`, `oh`, `it`, `brand`. That's it. Design downstream schemas accordingly.

2. **Always use the date partition filter.** A single unfiltered scan = 650 GB = ~$3.25. With `WHERE date BETWEEN ...`, cost drops linearly with date range. At-cluster (`store_code IN (...)`) filter adds further pruning.

3. **The 14-month history gap is the #1 item to escalate.** Without pre-2023 inventory, we cannot validate forecasts against historical ground-truth stock — critical for ForecastSmart backtesting.

4. **Negative on-hand needs human context.** 64M rows (0.89%) and min -3.7M can mean:
   - **Legitimate**: oversold units (shipped but not yet fulfilled), unpicked returns offsetting stock, shrinkage reconciliation entries
   - **Bug**: bad pipeline writes, DC-level sign-flip, duplicate-decrement error
   Worth a 15-min call with the inventory-ops team. Meanwhile, safe workaround: `GREATEST(oh, 0)` for "available to sell" metrics.

5. **Sparse 1% density is interesting signal.** Table has 7.2B rows but only covers ~1% of possible (date × store × product) combinations. This tells us inventory is **only written when stocked** — absence of a row ≠ zero inventory, it means "never stocked here." Important for modeling "store doesn't carry SKU" vs "SKU sold out at store."

6. **Drop ivivva in every query.** 8M inventory rows for a brand with 0 transactions in 4 years. Pure dead weight.

7. **For cross-table "sales exceeding inventory" check (Signet SOP)**, limit to 2023+ since inventory doesn't exist before then. Use the clean-view filters on both sides.

---

## Key Findings

### Shape & Structure

| Metric | Value | Note |
|--------|------:|------|
| Total rows | 7,214,258,665 | 7.2 BILLION |
| Date range | 2023-01-01 → 2025-12-04 | 3 years, **zero gaps** |
| **PK / Grain** | `(date, store_code, product_code)` | Unique |
| Distinct stores | 1,386 | 74.8% of store_master |
| Distinct products | 1,964,039 | **99.3% of product_master** |
| Data density | ~1% | Sparse — only stocked combos have rows |

Full schema → [`schema_inventory.md`](schema_inventory.md)

### The Useful vs Useless Column Split

**Effective useful (3 data + 3 identifiers):**
- `oh` — on-hand (can be negative, watch for outliers)
- `it` — in-transit (92% zero, 7.6% positive)
- `brand` — filter for lululemon only
- `date`, `store_code`, `product_code` — identifiers

**Useless (4 columns):**
- `oo` (on-order) — 100% zero across 7.2B rows
- `wip` (work-in-progress) — 100% zero
- `initial_oh_quantity` — 100% zero
- `total_units` — 100% identical to `oh` (redundant)

### Quantity Distribution

**`oh` (on-hand):**

| Bucket | Count | % |
|--------|------:|---:|
| `oh < 0` | **64,279,970** | 0.89% |
| `oh = 0` | 2,227,208,169 | 30.9% |
| `oh > 0` | 4,922,770,526 | 68.2% |

Min: **-3,704,869** | Max: **700,024** | P50: 1 | P90: 6

### Cross-Table Comparison

| Master | Products | Stores |
|--------|---------:|-------:|
| `product_master` (catalog) | 1,977,528 | — |
| `store_master` (catalog) | — | 1,853 |
| **`inventory_master`** | **1,964,039** (99.3%) | **1,386** (74.8%) |
| `transaction_master` | 927,565 (46.9%) | 1,031 (55.6%) |

**Inventory has MUCH better SKU/store coverage than transactions** — tracks unsold stock too.

### Integrity Results

- ✅ Zero orphan products (every SKU in inventory exists in product_master)
- ✅ Zero orphan stores (every store in inventory exists in store_master)
- 23,782 SKUs in product_master never had inventory (likely new launches / placeholders)
- 467 stores in store_master never had inventory (inactive / closed / out-of-scope)
- 8M ivivva inventory rows despite 0 ivivva transactions (legacy stock)

### Yearly Distribution

| Year | Rows | Avg rows/day |
|:----:|----:|--------:|
| 2023 | 2,125,243,048 | 5.8M |
| 2024 | 2,508,375,784 | 6.9M |
| 2025 | 2,580,639,833 | 7.6M |

Row count growing ~15-20% YoY (more SKUs, more stores, or more granular tracking).

---

## Action Items

### 🔴 P0 (Client)
| # | Issue | Ask |
|---|-------|-----|
| I5 | Missing 2022 history (inv starts 2023-01; txn goes back to 2021-11) | Provide pre-2023 inventory snapshots (14+ months) |
| I3 | 64M negative on-hand rows, min -3.7M | Explain — legitimate oversold/shrinkage, or bug? |

### 🟡 P1 (Client)
| # | Issue | Ask |
|---|-------|-----|
| I1 | `oo`, `wip`, `initial_oh_quantity` 100% zero | Populate in next feed or confirm deprecation |
| I4 | Max `oh` = 700,024 at one SKU-store-date | Explain — wholesale? DC aggregate? |

### 🟢 P2 (Cosmetic)
| # | Issue |
|---|-------|
| I2 | `total_units` redundant to `oh` (100% identical) — drop from schema |
| I6 | 23,782 SKUs never had inventory |
| I7 | 467 stores never had inventory |
| I8 | 8M ivivva inventory for deprecated brand |

---

## Ready-to-Use Query Pattern

```sql
-- Standard inventory read (cost-efficient)
SELECT date, store_code, product_code, oh, it
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
WHERE date BETWEEN @start_date AND @end_date   -- partition pruning
  AND brand = 'lululemon'                      -- drop ivivva (0.11%)
  -- Optional: cluster pruning
  AND store_code IN (...)
-- Optional: exclude negative-on-hand edge cases
  AND oh >= 0
```

---

## Next Step

Build `inventory_master_clean` view that:
- Drops 4 useless columns
- Filters `brand = 'lululemon'`
- Flags `has_negative_oh` for investigation set-aside
- Adds `available_qty = GREATEST(oh, 0) + GREATEST(it, 0)` derived column

Will be reusable for Forecast Smart safety-stock calculations + Signet SOP "sales > inventory" reconciliation.
