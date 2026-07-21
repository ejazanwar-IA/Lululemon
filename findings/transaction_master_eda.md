# Transaction Master - EDA Findings

| Field | Value |
|-------|-------|
| **Table** | `lululemon-01042025.lululemon_souricng_outbound.transaction_master` |
| **Total Rows** | 389,872,378 | **Size:** 73.53 GB | **Columns:** 32 |
| **Partition** | `date` | **Cluster:** `channel` |
| **Status** | ✅ Phase 1-3 Complete |
| **Owner** | Ejaz Anwar | **Last Updated** | 2026-04-20 |

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🔴 **Two P0 feed-level gaps block margin/discount modeling. Zero-qty mystery resolved (27% of rows are non-sale events).**

**TL;DR:**

1. **4 years of clean transaction history** (2021-11-20 → 2025-11-18), zero gaps, PK confirmed.
2. **27% of rows (106M) are non-sale events** — ECOMM cart/cancellation events + gift cards + virtual-store records. Filter `qty > 0 AND revenue > 0` retains 284M real sales. **Hypothesis is evidence-backed and ready for 15-min confirmation call with Sri Harsha.**
3. **`cost` and `msrp` are 100% zero** (P0). This smells like a filtered view, not missing data. **High likelihood raw source has them.** Worth checking with data-engineering team before escalating to Lululemon.
4. **All 3 discount columns are 100% zero** (P0). Discount data likely needs to be derived from `price_book` (`REGULAR_PRICE - transaction.price`).
5. **China ECOMM breakdown discovered:** 3 virtual stores = Tmall / WeChat / JD.com. Important for ECOMM strategy modeling.
6. **Channel reach:** 12 `channel_code` values across 4 geos (NA 75%, China 11%, APAC 9%, EMEA 5%), 23 countries.

**What you need to decide, Uttkarsh:**

- **Do we raise P0-1 (cost/msrp) to data engineering first, or bundle with client ask?** (My vote: DE first — likely fixable without Lululemon.)
- **Approval to bundle P0-1 and P0-2 as "rehydrate stripped fields"** — they look like one upstream fix.
- **Proceed to build `transaction_master_clean` view** with all derived filters? Unblocks all downstream modeling.

---

## 💡 My Recommendations (as analyst)

1. **Check internally before escalating.** `cost`/`msrp`/`discount` being uniformly zero across 389M rows is **not** the signature of a Lululemon feed gap — those would usually be partially populated or NULL. This pattern suggests fields were stripped during cleanup. Ask Ritik / Sri Harsha if raw `sales_transactions` has them populated before we burn a client ask.

2. **Confirm the zero-qty hypothesis in a call.** We have evidence (ECOMM-concentrated 30-52%, RETAIL 9-30%; 5 gift-card product_codes at 93-98% zero rate; 10 virtual stores matching channel_code totals). But a 15-min call with Sri Harsha or Ritik validates it faster than waiting for client. The filter is defensible either way.

3. **China ECOMM finding should reach the forecasting team.** The 3 Chinese marketplaces (Tmall, WeChat, JD.com) have wildly different zero-qty rates (31%, 31%, 62%) — suggesting different event-logging behavior per platform. Models should probably treat them as distinct channels, not aggregate as "China ECOMM."

4. **Drop `channel` in favor of `channel_code`.** `channel` is just ECOMM/RETAIL (2 values). `channel_code` has 12 values (LLL_USA_RTL, LLL_CHINA_ECOM, etc.). More granular = better modeling features. `ws_channel` is a duplicate — drop it too.

5. **`flex_status='Active'` on product_master is misleading** — 716K "Active" SKUs have zero transactions in 4 years. For "currently selling" modeling, combine with transaction recency: `EXISTS (SELECT 1 FROM transaction_master WHERE product_code = ... AND date > CURRENT_DATE - 90)`.

6. **Outliers need a separate conversation.** Max `revenue = $20,072,727` and max `qty = 31,047` on single transactions. Almost certainly wholesale/B2B or data errors. Filter at `revenue < 10,000` and `qty < 100` for EDA, but flag the underlying rows for client explanation.

7. **Build the clean view next.** Applies `qty > 0 AND revenue > 0` + outlier caps + channel normalization + unit price derivation. One-time build, all downstream uses benefit.

---

## Key Findings

### Shape & Structure

| Metric | Value | Note |
|--------|------:|------|
| Total rows | 389,872,378 | |
| **PK** | `transaction_code` | Single-column unique, zero dups |
| Date range | 2021-11-20 → 2025-11-18 | 4 full years, zero gaps |
| Distinct products | 927,565 | 47% of product_master |
| Distinct stores | 1,031 | 56% of store_master |
| Channel split | 80% RETAIL / 20% ECOMM | |

### Critical Findings

#### 🔴 The 27% zero-qty mystery — SOLVED

**106M rows have `qty=0 AND price=0 AND revenue=0`.** Evidence points to non-sale events:

| Signal | What it shows |
|--------|---------------|
| ECOMM channels 30-52% zero vs RETAIL 9-30% | ECOMM-logging artifact |
| Stable 27% across 2021-2025 | Systematic, not a recent bug |
| 10 virtual stores (9198, 9188, 45189=Tmall, 45187=WeChat, 45186=JD, ...) | Row counts match channel_code totals → digital fulfillment stores |
| 5 product_codes at 93-98% zero (3704884, 3704876, etc.) | Gift card denominations |

**Modeling filter:** `WHERE qty > 0 AND revenue > 0` → drops 106M, retains 283,959,775 valid sales.

#### 🔴 13 columns effectively useless

**100% NULL (12 columns):** `line_id`, `launch_price`, `transaction_type`, `fullfilment_location_customer` (typo preserved), `revenue_before_tax`, `ship_to_country`, `freight_cost`, `store_contribution`, `workstream`, `currency_exchange_rate`, `order_type`, `transaction_category`

**100% 0 (not null, but useless): `clearance`, `unit_discount_amount`, `total_discount_amount`, `clearance_price`, `flagged_rows`, `cost`, `msrp`**

**Effective useful columns: ~15 of 32.** All margin/discount/cost analysis is blocked until cost/msrp/discount are populated (P0-1, P0-2).

#### Date coverage (4 years, clean)

| Year | Rows | Notes |
|:----:|----:|-------|
| 2021 | 11M | Partial (Nov-Dec only, 42 days) |
| 2022 | 83M | Full year |
| 2023 | 99M | +20% YoY (post-COVID) |
| 2024 | 105M | +5% YoY, leap year |
| 2025 | 92M | Partial (through Nov 18, 322 days) |

#### Channel geography (global reach confirmed)

**`channel_code` (12 values), USA dominates:**

| channel_code | % of total |
|--------------|-----------:|
| LLL_USA_RTL | 50.7% |
| LLL_CAN_RTL | 12.5% |
| LLL_USA_ECOM | 7.5% |
| LLL_CHINA_RTL | 7.1% |
| Others (8 more) | 22.2% |

**Geography:** NA 74.8%, China 11.2%, APAC 9.4%, EMEA 4.6%. 23 countries total (matches kickoff's "~24 countries" claim).

#### Outliers to investigate

- Max `qty` = **31,047** on a single transaction
- Max `revenue` = **$20,072,727** on a single transaction
- Max `price` = **$1,077,273** per unit
- 42 rows with negative price AND cost > price (same 42 rows)

#### Cross-table integrity

- Zero orphan SKUs vs product_master ✅
- Zero orphan stores vs store_master ✅
- 10 virtual ECOMM stores formally classified (`store_format_code='E-COMMERCE'` in store_master)

---

## Action Items

### 🔴 P0 (likely Data Engineering first, then Client)
| # | Issue | Suggested Path |
|---|-------|----------------|
| T1 | `cost` and `msrp` 100% zero | Check if raw feed has them first. Escalate only if source is truly empty. |
| T2 | All 3 discount columns 100% zero | Same — and confirm `price_book` is the intended derivation source. |

### 🟡 P1 (Client)
| # | Issue | Scope | Ask |
|---|-------|-------|-----|
| T4 | Extreme outliers (qty=31K, rev=$20M, price=$1M) | <50 rows | Explain — wholesale? data error? |
| T5 | 42 negative-price rows | 42 rows | Explain |
| T6 | 12 columns 100% NULL | All rows | Populate or remove from schema |
| T9 | `clearance`, `flagged_rows` always 0 | All rows | Populate or drop |
| T10 | 9,290 rows with qty>0 but revenue=0 | 9.3K rows | Free items — keep or drop? |

### 🟢 Internal (workarounds ready)
| Issue | Workaround |
|-------|-----------|
| Zero-qty rows | Filter `qty > 0 AND revenue > 0` |
| Channel redundancy | Use `channel_code` (drop `channel`, `ws_channel`) |
| Clearance/flagged useless | Ignore |
| Brand | Filter `brand = 'lululemon'` (drop 432 ivivva rows) |
| Outlier cap (exploratory) | `qty <= 100 AND revenue <= 10000` |

---

## Next Step

Build `transaction_master_clean` view with: `qty > 0 AND revenue > 0` filter, `unit_price = revenue/qty`, `is_virtual_store` flag (10 known stores), `is_placeholder_product` flag (using product_master derivation). Materialize once, reuse everywhere.
