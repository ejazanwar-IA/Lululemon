# EDA — `lulu_ingestion_dev.inventory_master` (canonical master)

`Last updated: 2026-05-18.` — **Health check (2026-05-20):** [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) — still 1 date; X3 strict orphan is **channel-suffix mismatch** (FO/STRAT/COMMUNITY/CMNTY), not missing bare SKUs. After PM rebuild, **RETAIL/ECOMM inv rows join PM 100%**; see X3 section in health check (May-18 “67% orphan” below is pre-rebuild).

Master-level EDA for the IA Platform–ingested inventory fact. **Single-date POC sample** for 2025-08-28. Built from the older `inventory_snapshot_cleaned` (16.4B rows) — not from the new `inventory_snapshot` pipeline.

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_ingestion_dev.inventory_master` |
| Created (IST) | 2026-05-15 15:39:23 |
| Row count | **5,539,053** (matches old `inventory_snapshot_cleaned` for date 2025-08-28 exactly) |
| Size | 0.68 GB |
| Column count | **15** |

### Schema (IA Platform shape — different from intermediate)

| # | Column | Type | Source/meaning |
|---:|---|---|---|
| 1 | `display_product_code` | STRING | Bare SKU (channel stripped, e.g. `3833936`) |
| 2 | `product_code` | STRING | Full SKU with channel (e.g. `3833936_ECOMM`) |
| 3 | `store_code` | STRING | LPAD-10 store id |
| 4 | `date` | DATE | Snapshot date (proper DATE type) |
| 5 | `channel` | STRING | RETAIL / ECOMM / FO / STRAT / COMMUNITY / CMNTY |
| 6 | `source_product_code` | STRING | Original SKU before IA Platform derivation |
| 7 | `source_channel` | STRING | Original channel before IA derivation |
| 8 | `product_code_was_derived` | BOOL | TRUE if IA Platform imputed product_code |
| 9 | `channel_was_derived` | BOOL | TRUE if IA Platform imputed channel |
| 10 | `oh` | FLOAT64 | Units on hand |
| 11 | `it` | FLOAT64 | Units in-transit (formerly UNITS_INBOUND) |
| 12 | `oo` | FLOAT64 | On-order — 100% zero in this load |
| 13 | `oh_it_qty` | FLOAT64 | Derived = `oh - it` (mostly negative when inbound > on-hand) |
| 14 | `syncstartdatetime` | TIMESTAMP | `2025-08-29 10:05:00` |
| 15 | `created_timestamp` | TIMESTAMP | Same as syncstartdatetime |

### Schema differs from intermediate

Live master has 15 cols (with IA Platform metadata columns); the user-built `inventory_intermediate` has 10 cols. **Master is platform-managed, not user-built.**

## Phase 2 — Grain

| Check | Result |
|---|---|
| Row count | 5,539,053 |
| Distinct `(date, store_code, product_code)` | 5,539,053 |
| Verdict | **Perfect grain** — no duplicates |
| Distinct dates | **1** (`2025-08-28`) |
| Distinct stores | 1,073 (of 1,853 in store_master = 57.9%) |
| Distinct products | 487,587 |

## Phase 3 — Completeness

| Column | Missing | % | Notes |
|---|---:|---:|---|
| Identity (`display_product_code`, `product_code`, `store_code`, `date`, `channel`) | 0 | 0% | Fully populated |
| `source_product_code` | **120,222** | 2.2% | NULL = IA Platform derived |
| `source_channel` | **120,222** | 2.2% | Same rows |
| `product_code_was_derived` | 0 NULL | 0% | TRUE on those same 120K rows |
| `channel_was_derived` | 0 NULL | 0% | Same |
| `oh`, `it`, `oo`, `oh_it_qty` | 0 NULL | 0% | All numeric populated |

### Derived-flag mechanics

| `product_code_was_derived` | `channel_was_derived` | Rows | `source_product_code` |
|---|---|---:|---|
| FALSE | FALSE | 5,418,831 (97.8%) | = `product_code` |
| TRUE | TRUE | 120,222 (2.2%) | NULL |

→ **120K rows are IA Platform reconciled** — original source had inconsistent or missing product/channel; platform mapped them to canonical values.

## Phase 4 — Distributions

### Channel split

| Channel | Rows | % |
|---|---:|---:|
| RETAIL | 4,579,346 | 82.7% |
| ECOMM | 595,164 | 10.7% |
| FO | 328,911 | 5.9% |
| STRAT | 25,937 | 0.5% |
| COMMUNITY | 6,768 | 0.1% |
| CMNTY | 2,927 | 0.05% |

→ **6 channels**, but `product_master` only has 2 (RETAIL / ECOMM). Critical join consequence — see Phase 5.

### `display_product_code` vs `product_code`

| Check | Value |
|---|---:|
| Exact equal | 0 |
| Differs (by channel suffix) | 5,539,053 |
| Distinct `display_product_code` | 278,761 |
| Distinct `product_code` | 487,587 |

→ `display_product_code` = `product_code` with channel suffix stripped. `product_code` cardinality is larger because same bare SKU appears across multiple channels.

### Numeric distributions

| Field | Min | Max | = 0 | > 0 | < 0 |
|---|---:|---:|---:|---:|---:|
| `oh` (on-hand) | -1,190 | 69,729 | 893K (16.1%) | 4.61M (83.3%) | 33,774 (0.6%) |
| `it` (in-transit) | 0 | 21,029 | 5.03M (90.8%) | 508K (9.2%) | 0 |
| `oo` (on-order) | 0 | 0 | **5.54M (100%)** | 0 | 0 |
| `oh_it_qty` (derived) | -21,029 | 69,369 | 1.07M (19.3%) | 4.43M (79.9%) | 42K (0.8%) |

→ **`oo` is 100% zero** — column exists but never populated.
→ **`oh_it_qty` ≈ `oh - it`** but doesn't perfectly match either `oh - it` or `oh + it` (because zero `oh`/`it` makes both formulas give same result for ~85% of rows). Likely **`oh - it`** with rounding.
→ **Negative on-hand on 33K rows (0.6%)** — propagated through from raw (oversell / data corrections).

## Phase 5 — Cross-table integrity (critical)

### Store join — clean

| Check | Result |
|---|---:|
| Distinct stores in master | 1,073 |
| Orphan stores (not in `store_master`) | **0** |

→ **100% of stores resolve.** All 1,073 are valid.

### Product join — **disaster on multi-channel rows**

| Channel | Orphan rows | Total rows | Orphan % |
|---|---:|---:|---:|
| RETAIL | 2,968,921 | 4,579,346 | **64.8%** |
| ECOMM | 410,498 | 595,164 | **69.0%** |
| FO | 328,911 | 328,911 | **100%** |
| STRAT | 25,937 | 25,937 | **100%** |
| COMMUNITY | 6,768 | 6,768 | **100%** |
| CMNTY | 2,927 | 2,927 | **100%** |
| **Total orphan** | **3,743,962** | 5,539,053 | **67.6%** |

### Root causes

1. **FO / STRAT / COMMUNITY / CMNTY channels don't exist in `product_master`** — product universe only covers RETAIL + ECOMM. 100% of those inventory rows have no product match.
2. **65–69% of RETAIL/ECOMM rows also fail** — explained by `product_master` covering only 33% of the raw SKU universe (from earlier PGH EDA).
3. Net result: **only 32.4% of inventory rows can resolve to a product** for analytics. **This is a blocking issue for any product-attributed inventory analysis.**

## Phase 6 — Business-logic checks

### `display_product_code` derivation

Sample confirms: `display_product_code = SPLIT(product_code, '_')[OFFSET(0)]`. Useful as a bare-SKU join key against `product_master.product_code_original` (which is also bare).

### Date is for 2025-08-28 only — POC sample

Single date load from the OLD `inventory_snapshot_cleaned` table. New `inventory_snapshot` raw doesn't yet contain 2025-08-28; refresh will need a backfill or pipeline rerun.

### `oo` (on-order) is always zero

Never populated by this build. Either:
- IA Platform shape includes `oo` placeholder
- Source data has no on-order signal

Either way, **don't model on `oo`** until clarified.

## Summary — what consumers can rely on

| Reliable | Use with caution | Avoid |
|---|---|---|
| `(date, store_code, product_code)` PK | `product_code` joins (67% orphan!) | `oo` (100% zero) |
| Store-side joins (100% match) | Negative `oh` (real, not sentinel) | Multi-channel analysis without product_master expansion |
| `oh`, `it` from raw | `product_code_was_derived` rows (2.2% imputed) | |
| 6-channel resolution | `oh_it_qty` (derived, unclear formula) | |

## Action items

1. **Fix product_master channel coverage** — extend pipeline to include FO, STRAT, COMMUNITY, CMNTY channels (currently only RETAIL/ECOMM). Without this, **67% of inventory cannot be analyzed by product attributes**.
2. **Refresh inventory_master from new raw** — current master uses old `_cleaned` table for one date; needs migration to `inventory_intermediate` pipeline.
3. **Clarify `oo` and `oh_it_qty` semantics** — confirm `oh_it_qty = oh - it` formula and why `oo` is always zero.
4. **Document `-1` sentinel handling** — raw has `-1` for "unknown", master shows real negatives — confirm cleaning rules.
5. **Add multi-date load** — single-date sample is insufficient for trend modeling.
