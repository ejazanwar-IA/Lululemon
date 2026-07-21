# EDA — `lulu_ingestion_dev.transaction_master` (canonical master)

`Last updated: 2026-05-18.` — **Health check (2026-05-20):** [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) — 354.1M rows (was 87.3M); grain PASS.

Master-level EDA. Built from `sales_transactions` + `sku_details` + `product_intermediate` + `store_intermediate`. 32-column wide table, 4-year window, post-aggregation grain.

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_ingestion_dev.transaction_master` |
| Created (IST) | 2026-05-15 15:36 |
| Row count | **87,347,072** |
| Size | 15.82 GB |
| Column count | **32** |
| Date range | 2022-05-15 → 2025-11-18 (1,284 distinct dates ≈ 3.5 years) |

### Row-count drop from raw

| Source | Rows | % vs raw |
|---|---:|---:|
| `sales_transactions` (raw) | 683.6M | 100% |
| `sales_transactions` ≥ 2022-05-15 (4-year filter) | 354.97M | 51.9% |
| `transaction_master` | **87.35M** | **24.6% of 4-year window** |

→ **~75% collapse** within the 4-year window. The `SELECT DISTINCT` on (date, store, product) and the post-aggregation grain (one row per (date, store, product), not per order line) explain the drop.

### Schema

| # | Column | Type | Status |
|---:|---|---|---|
| 1 | `channel` | STRING | Populated |
| 2 | `line_id` | FLOAT64 | **100% NULL stub** |
| 3 | `brand` | STRING | 86% NULL (Nov 2025 slice) |
| 4 | `launch_price` | FLOAT64 | **100% NULL stub** |
| 5 | `clearance` | FLOAT64 | **100% = 0 stub** |
| 6 | `unit_discount_amount` | FLOAT64 | **100% = 0 stub** |
| 7 | `total_discount_amount` | FLOAT64 | **100% = 0 stub** |
| 8 | `qty` | FLOAT64 | Populated, 27% = 0 |
| 9 | `transaction_type` | STRING | **100% NULL stub** |
| 10 | `store_code` | STRING | Populated |
| 11 | `fullfilment_location_customer` | STRING | **100% NULL stub** (preserved typo) |
| 12 | `flagged_rows` | INT64 | **100% = 0 stub** |
| 13 | `transaction_code` | STRING | **Synthetic** = `DATE\|SKU\|STORE` |
| 14 | `channel_code` | STRING | Populated |
| 15 | `date` | DATE | Populated |
| 16 | `product_code` | STRING | Populated |
| 17 | `revenue_before_tax` | FLOAT64 | **100% NULL stub** |
| 18 | `ship_to_country` | STRING | **100% NULL stub** |
| 19 | `freight_cost` | FLOAT64 | **100% NULL stub** |
| 20 | `ws_channel` | STRING | Populated |
| 21 | `geography` | STRING | Populated |
| 22 | `clearance_price` | FLOAT64 | **100% = 0 stub** |
| 23 | `store_contribution` | FLOAT64 | **100% NULL stub** |
| 24 | `workstream` | STRING | **100% NULL stub** |
| 25 | `ecomm_country` | STRING | Populated |
| 26 | `revenue` | FLOAT64 | Populated, 27% = 0 |
| 27 | `cost` | FLOAT64 | **100% = 0** (from `sku_details.COST_PRICE`) |
| 28 | `currency_exchange_rate` | FLOAT64 | **100% NULL stub** |
| 29 | `order_type` | STRING | **100% NULL stub** |
| 30 | `transaction_category` | STRING | **100% NULL stub** |
| 31 | `msrp` | FLOAT64 | **100% = 0** (from `sku_details.SELLING_PRICE`) |
| 32 | `price` | FLOAT64 | Populated when qty > 0 |

### 17 columns are 100% stubs (verified)

NULL stubs (12): `line_id`, `launch_price`, `transaction_type`, `fullfilment_location_customer`, `revenue_before_tax`, `ship_to_country`, `freight_cost`, `store_contribution`, `workstream`, `currency_exchange_rate`, `order_type`, `transaction_category`

Zero stubs (5): `clearance`, `unit_discount_amount`, `total_discount_amount`, `flagged_rows`, `clearance_price`

→ **17 of 32 columns (53%) carry zero information.** Documented in `findings/raw_to_master_lineage.md` Section 4.

## Phase 2 — Grain & uniqueness

| Check | Result |
|---|---|
| Row count | 87,347,072 |
| Distinct `transaction_code` | 87,347,072 |
| Verdict | **Perfect PK** (no dupes) |
| Distinct dates | 1,284 (~3.5 years) |
| Distinct stores | 1,041 (of 1,853 in `store_master`) |
| Distinct products | 227,186 |

### Synthetic `transaction_code`

Sample shows `transaction_code = '2025-11-01|136553389|110'` — exactly **`DATE|SKU|STORE`** concatenation, inherited from raw `SALES_ORDER_ID`. Confirms post-aggregation grain.

## Phase 3 — Completeness (date-filtered slice: Nov 2025)

| Column | Missing/Zero | % of 1.87M slice rows | Notes |
|---|---:|---:|---|
| `channel` | 0 | 0% | Always populated |
| `brand` | 1,616,346 | **86.4%** | NULL on most rows — concerning |
| `qty = 0` | 504,508 | 27.0% | Same zero-qty pattern as raw |
| `qty > 0` | 1,366,806 | 73.0% | |
| `revenue = 0` | 504,532 | 27.0% | Matches qty=0 |
| `price = 0` | 504,532 | 27.0% | Matches qty=0 |
| `cost = 0` | **1,871,314** | **100%** | All zeros (raw `COST_PRICE` issue) |
| `msrp = 0` | **1,871,314** | **100%** | All zeros (raw `SELLING_PRICE` issue) |

## Phase 4 — Distributions

### `channel` × `ws_channel`

| channel | ws_channel | Rows | % |
|---|---|---:|---:|
| RETAIL | RETAIL | 70,348,521 | 80.5% |
| ECOMM | ECOM | 16,998,551 | 19.5% |

→ **Only 2 channels.** This aligns with `product_master` (also RETAIL/ECOMM only) → 0 product orphans.

→ **vs inventory:** transaction_master has 2 channels, `inventory_master` has 6 (FO, STRAT, COMMUNITY, CMNTY don't appear in transactions). The cross-master channel mismatch is structural.

### `geography`

| Value | Rows | % |
|---|---:|---:|
| NA | 65,039,353 | 74.5% |
| CHINA | 9,940,644 | 11.4% |
| APAC | 8,422,065 | 9.6% |
| EMEA | 3,945,010 | 4.5% |

→ Heavily NA-weighted, consistent with store_master and product distribution.

### `qty` distribution (Nov 2025, qty > 0)

| Stat | Value |
|---|---:|
| Min | 1.0 |
| Q1 | 1.0 |
| Median | 1.0 |
| Q3 | 1.0 |
| Max | 568.0 |

→ **Median = 1**, **Q3 = 1** — the **overwhelming majority of rows have qty = 1**. Outliers go up to 568 units (likely B2B bulk orders or aggregation artifact).

### `revenue` distribution (Nov 2025, qty > 0)

| Stat | Value |
|---|---:|
| Min | -147.93 |
| Q1 | 68.00 |
| Median | 128.00 |
| Q3 | 393.30 |
| Max | **3,741,039.00** |

→ Long heavy tail. Max revenue $3.74M on a single line — investigate (likely aggregation artifact or wholesale order).

## Phase 5 — Cross-table integrity (Nov 2025 slice, 1.87M rows)

| Check | Result |
|---|---:|
| Distinct stores in master | 1,041 |
| Store orphans (Nov 2025) | **0** |
| Product orphans (Nov 2025) | **0** |

→ **Perfect integrity in November 2025.** Both store and product joins resolve 100%, very different from `inventory_master`'s 67.6% product orphan rate. Why?

1. `transaction_master` only has RETAIL/ECOMM channels → matches `product_master`'s 2-channel universe.
2. Build filters likely drop SKUs not in `product_intermediate`.
3. Stores are all 1,041 active retail/ECOMM locations.

## Phase 6 — Business-logic checks

### Real-sales filter (Section 5.3 recipe)

```sql
WHERE qty > 0 AND revenue > 0
-- excludes the ~27% zero-qty/zero-revenue rows
```

Confirmed 27% zero-qty in Nov 2025 — matches the BQ context rule's documented 27%. Filter works as expected.

### `cost` and `msrp` are 100% zero

Inherited from `sku_details.COST_PRICE` / `SELLING_PRICE` being 100% zero. **No profitability or margin analysis possible** until source prices are fixed (see `findings/raw_sku_details_eda.md`).

### `brand = NULL` on 86% of rows

Even basic dimensions are mostly missing. Likely from `product_intermediate` joins where `l0_name` is NULL (we saw earlier `l0_name` 82% NULL in `product_master`). **Brand-level analytics blocked for most rows.**

### Large revenue outlier

Max revenue $3.74M on a single (date, SKU, store) row. Either a B2B sale or an aggregation that should have been split. Worth investigating with client.

## Summary

| Reliable | Use with caution | Avoid |
|---|---|---|
| `(date, store_code, product_code, transaction_code)` PK | `qty` (27% zero — filter `> 0`) | `cost`, `msrp` (100% zero) |
| `store_code` joins (0 orphans) | `revenue` (heavy tail, max $3.74M) | 12 NULL stub columns |
| `product_code` joins (0 orphans) | `brand` (86% NULL) | 5 zero stub columns |
| `channel`, `ws_channel`, `geography` | `transaction_code` (synthetic, not a real order) | Basket / multi-line order analysis |

## Action items

1. **Fix `cost` / `msrp`** — depends on `sku_details.COST_PRICE` / `SELLING_PRICE` being populated. Currently 100% zero.
2. **Fix `brand` coverage** — 86% NULL traces back to `product_master.l0_name` 82% NULL. Same root cause as PGH pivot gaps.
3. **Drop or fix 17 stub columns** — `line_id`, `launch_price`, `transaction_type`, etc. They occupy schema slots and confuse consumers.
4. **Document `transaction_code` as synthetic** in any consumer doc — it's not an order ID.
5. **Investigate the $3.74M revenue outlier** — B2B sale or aggregation artifact?
6. **Add real `TRANSACTION_TYPE` handling** — raw only has `GROSS SALE`; if returns/voids exist they're hidden.
