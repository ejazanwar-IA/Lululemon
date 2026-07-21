# EDA — `lulu_sourcing_dev.sales_transactions` (raw)

`Last updated: 2026-05-18.`

Primary raw source for `transaction_master`. ~683M rows of sales transactions, **~11 years of history** (2015-02-02 → 2025-11-18).

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_sourcing_dev.sales_transactions` |
| Created (IST) | 2026-05-15 12:16 |
| Row count | **683,582,361** |
| Size | 90.83 GB |
| Column count | 12 (11 STRING + 1 DATETIME) |
| Date range | 2015-02-02 → 2025-11-18 (3,943 distinct dates) |
| Sync batches | 1 (`2026-05-08T00:00:00`) |

### Schema

| # | Column | Type | Nullable |
|---:|---|---|---|
| 1 | `SKU_ID` | STRING | YES |
| 2 | `LOCATION_ID_SALES` | STRING | YES |
| 3 | `DATE_TRANSACTION` | STRING | YES |
| 4 | `SALES_ORDER_ID` | STRING | YES |
| 5 | `SALES_ORDER_ITEM_ID` | STRING | YES |
| 6 | `UNITS` | STRING | YES |
| 7 | `CURRENCY_CODE` | STRING | YES |
| 8 | `PRICE_SALES_TOTAL` | STRING | YES |
| 9 | `PRICE_SALES_UNIT` | STRING | YES |
| 10 | `SALES_SERVICE_TYPE` | STRING | YES |
| 11 | `TRANSACTION_TYPE` | STRING | YES |
| 12 | `SYNCSTARTDATETIME` | DATETIME | YES |

### Notable observations from schema + sample

| # | Observation | Implication |
|---|---|---|
| 1 | `DATE_TRANSACTION` is STRING despite being a date | `SAFE_CAST(... AS DATE)` required |
| 2 | `UNITS` and prices are STRING | `SAFE_CAST` required for math |
| 3 | Sample shows `SALES_ORDER_ID = '2016-08-06\|3679159\|10110'` | **Synthetic key** — looks like `<DATE>\|<SKU>\|<LOCATION>` concatenation (verified in Phase 6) |
| 4 | `SALES_ORDER_ITEM_ID` = same format as `SALES_ORDER_ID` | Also synthetic |
| 5 | Sample shows `UNITS=0`, `PRICE=0`, `TRANSACTION_TYPE='GROSS SALE'` | Many rows are zero-qty (~26%, confirmed Phase 3) |
| 6 | Single sync batch (`2026-05-08`) | Snapshot — no incremental loads yet |

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Total rows | 683,582,361 | — |
| Distinct `SKU_ID` | 765,813 | Subset of PGH's 988K SKU universe |
| Distinct `LOCATION_ID_SALES` | 1,217 | Subset of 1,853 store_master locations |
| Distinct `DATE_TRANSACTION` | **3,943** | ~98.9% daily coverage over 10.8 years |
| Distinct `SALES_ORDER_ID` | 683,582,361 | **= total rows** (synthetic) |
| Distinct `SALES_ORDER_ITEM_ID` | 683,582,361 | **= total rows** (synthetic) |
| Distinct `(SALES_ORDER_ID, ITEM_ID)` | 683,582,361 | Same |

### The order ID is synthetic — not a real order

Phase 6 verified: **`SALES_ORDER_ID = CONCAT(DATE_TRANSACTION, '\|', SKU_ID, '\|', LOCATION_ID_SALES)`** for **all 683.6M rows** (zero mismatches). Same for `SALES_ORDER_ITEM_ID`. There is **no real order grouping** in this raw — each (date, SKU, location) is a synthetic "order line."

## Phase 3 — Completeness

| Column | Missing | Zero | Positive | Negative | Notes |
|---|---:|---:|---:|---:|---|
| `SKU_ID` | 0 | n/a | n/a | n/a | 100% populated |
| `LOCATION_ID_SALES` | 0 | n/a | n/a | n/a | 100% populated |
| `DATE_TRANSACTION` | 0 (0 unparseable) | n/a | n/a | n/a | All valid dates |
| `SALES_ORDER_ID` / `ITEM_ID` | 0 | n/a | n/a | n/a | 100% populated (but synthetic) |
| `UNITS` | 0 | **175,612,712 (25.7%)** | 507,969,298 (74.3%) | **351 (0.00005%)** | Mostly positive |
| `CURRENCY_CODE` | 0 | n/a | n/a | n/a | Only **1 distinct value** (USD) |
| `PRICE_SALES_TOTAL` | 0 | **175,665,846 (25.7%)** | 507,916,095 (74.3%) | 420 | Zeros match `UNITS=0` rows |
| `PRICE_SALES_UNIT` | 0 | **175,665,955 (25.7%)** | 507,916,406 | tiny | Same pattern |
| `SALES_SERVICE_TYPE` | 0 | n/a | n/a | n/a | 2 distinct: BNM, ECOM |
| `TRANSACTION_TYPE` | 0 | n/a | n/a | n/a | **1 distinct value** (GROSS SALE) |

### Key takeaways

- **Zero NULLs / sentinels across the board** — cleanest raw source so far.
- **25.7% of rows are zero-qty / zero-revenue** — confirms Section 3.3 of the BQ context rule. Build filters these out with `WHERE qty > 0 AND revenue > 0` for real-sales modeling.
- **Currency is uniformly USD** — `PRICE_SALES_*` values are pre-converted; no FX needed.
- **`TRANSACTION_TYPE` has only `GROSS SALE`** — no returns, no exchanges, no voids in this dataset. (Negative units (351 rows) and negative prices (420 rows) suggest some real returns exist but aren't classified separately.)

## Phase 4 — Distributions

### `CURRENCY_CODE`

| Value | Rows |
|---|---:|
| USD | 683,582,361 (100%) |

→ Single currency. `currency_exchange_rate` in master is correctly stubbed to NULL.

### `SALES_SERVICE_TYPE`

| Value | Rows | % |
|---|---:|---:|
| BNM | 567,617,110 | 83.0% |
| ECOM | 115,965,251 | 17.0% |

→ BNM = "Brick-and-Mortar" likely. Maps to RETAIL/ECOMM split in master.

### `TRANSACTION_TYPE`

| Value | Rows |
|---|---:|
| GROSS SALE | 683,582,361 (100%) |

→ Single value. **Useless as a categorization column.** `transaction_type` in master is correctly stubbed to NULL.

### Date coverage by year

| Year | Days with data | Row count |
|---|---:|---:|
| 2015 | 333 | 27.0M |
| 2016 | 366 | 32.0M |
| 2017 | 365 | 35.9M |
| 2018 | 365 | 44.2M |
| 2019 | 365 | 51.7M |
| 2020 | 366 | 44.9M |
| 2021 | 365 | 66.7M |
| 2022 | 365 | 83.0M |
| 2023 | 365 | 99.9M |
| 2024 | 366 | 105.3M |
| 2025 | 322 (partial) | 92.8M |

→ **Volume growth ~4× from 2015 to 2024** — consistent with business growth. 2025 is in-progress (Jan-Nov).

## Phase 5 — Cross-table integrity

### SKU coverage

| Set | Count |
|---|---:|
| Raw distinct `SKU_ID` | 765,813 |
| PGH distinct `SKU_ID` | 988,764 |
| sku_details distinct `ID` | 988,764 |

→ ~77% of catalog SKUs have at least one transaction. The other 23% may be never-sold styles or new arrivals.

### Location coverage

| Set | Count |
|---|---:|
| Raw distinct `LOCATION_ID_SALES` | 1,217 |
| store_master distinct `store_code` | 1,853 |

→ ~66% of stores have transactions. 636 stores never appear (likely DCs, virtual, out-of-scope).

## Phase 6 — Business-logic checks

### Synthetic order keys

Already verified — `SALES_ORDER_ID` and `SALES_ORDER_ITEM_ID` are 100% derived from `(DATE|SKU|LOCATION)`. This means:

- **No basket / multi-line order analysis possible** from this raw alone
- Each row is a (date, SKU, store) aggregate, not a true order line
- Build's `SELECT DISTINCT` on (date, SKU, store) further collapses any duplicates

### Negative qty / price

Tiny — 351 negative qty + 420 negative price rows out of 683M. Not classified as RETURN/CHARGEBACK. Worth confirming with client whether these are data errors or unflagged returns.

## Summary

| Reliable | Use with caution | Stub / Constant |
|---|---|---|
| `SKU_ID`, `LOCATION_ID_SALES`, `DATE_TRANSACTION` (100% populated, valid) | `UNITS=0` on 25.7% of rows (filter for real sales) | `CURRENCY_CODE` = USD only |
| `UNITS`, `PRICE_SALES_TOTAL`, `PRICE_SALES_UNIT` after `SAFE_CAST` | Synthetic order IDs (no basket info) | `TRANSACTION_TYPE` = GROSS SALE only |
| 11 years of history, near-daily coverage | Only 77% of catalog SKUs appear | |
| Single sync batch (no incrementals yet) | Only 66% of stores have transactions | |

## QQ's for Client

- **Why are `SALES_ORDER_ID` and `ITEM_ID` synthetic?** Real order numbers would enable basket analysis.
- **Why is `TRANSACTION_TYPE` single-valued (`GROSS SALE`)?** Are returns / voids tracked elsewhere?
- **What are the 351 negative-qty rows?** Returns? Data errors?
- **What about the 23% of catalog never-sold?** New styles or actual no-movement?
- **636 of 1,853 stores never have transactions** — DCs + virtual + out-of-scope, or any genuine retail gaps?
