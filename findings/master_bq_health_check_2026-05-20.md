# BQ master tables health check — 2026-05-20

`Last updated: 2026-05-20.`

Post–ingestion DAG baseline for four canonical masters in `lululemon-01042025.lulu_ingestion_dev`. SQL: [`queries/bq_master_tables_health_check.sql`](../queries/bq_master_tables_health_check.sql). Billing: `lululemon-data-scan`.

---

## Executive summary

| Table | Rows | Size (GB) | Last modified (UTC) | Grain | Verdict |
|-------|-----:|----------:|---------------------|-------|---------|
| `product_master` | 1,977,528 | 0.824 | 2026-05-20 06:22:58 | `product_code` unique | **PASS** |
| `store_master` | 1,853 | ~0 | 2026-05-20 06:23:54 | `store_code` unique | **PASS** |
| `transaction_master` | 354,138,091 | 66.781 | 2026-05-20 06:25:28 | `(date, store_code, product_code)` unique | **PASS** (stubs documented) |
| `inventory_master` | 5,539,053 | 0.676 | 2026-05-20 06:22:07 | `(date, store_code, product_code)` unique | **PASS** (single-date POC) |

| Cross-check | Result | Verdict |
|-------------|--------|---------|
| X1 Txn → PM product | 0 orphan SKUs / 0 rows | **PASS** |
| X2 Txn → SM store | 0 orphan stores / 0 rows | **PASS** |
| X3 Inv → PM product (strict `product_code`) | 138,036 SKUs / 364,543 rows | **INFO** — channel-suffix mismatch, not missing products |
| X3b Inv bare SKU → `product_code_original` | 0 true missing bare SKUs | **PASS** |
| X4 Inv → SM store | 0 orphan stores / 0 rows | **PASS** |
| X5 PM never sold (real sales) | 1,252,166 SKUs (63.32% of PM) | **INFO** |
| X6 PM `l1_name` vs txn `channel` | RETAIL/ECOMM aligned on sold SKUs | **PASS** |

---

## Delta vs 2026-05-18 EDA

| Table | Prior baseline | Now | Notes |
|-------|----------------|-----|-------|
| `product_master` | 653,366 rows; ~86% null `l2_name` | 1,977,528 rows; **0%** null `l0_name`/`l2_name`/`product_name` | Hierarchy rebuild + GSM alignment |
| `transaction_master` | 87,347,072 rows | **354,138,091** rows | ~4× row growth; grain still clean |
| `inventory_master` | 5,539,053 rows, 1 date | Same count/date | Still single snapshot `2025-08-28` |
| `store_master` | 1,853 rows | 1,853 rows | Unchanged grain |

---

## Tier 0 — Metadata

All four tables present, non-zero `row_count`. `product_master` now has **30 columns** (includes `active` BOOL, `article`, `l0_name`, `product_bucket_code`; no `active_flag`).

---

## Tier 1 — Per-table

### `product_master`

| Metric | Value |
|--------|------:|
| Total rows | 1,977,528 |
| PK duplicates | 0 |
| RETAIL / ECOMM | 988,764 / 988,764 |
| % null `l0_name` | 0.0 |
| % null `l2_name` | 0.0 |
| % null `product_name` | 0.0 |
| % null `article` | 0.0 |
| % null `product_bucket_code` | 0.0 |
| Cohort hollow / hierarchy-only / name-only | 0 / 0 / 0 |
| `active` TRUE rows | 1,977,528 (100%) |
| Distinct `article` | 298,178 |
| `l0_name` values | lululemon 1,914,438; ivivva 63,090 |
| `article_status` | 1 distinct value |
| `season_code` | 1 distinct value |

**Checklist:** G1, G5, P2 — pass. P1 (`active`) now populated as BOOL `active`, not stub `active_flag`.

**Hierarchy distinct counts (L0–L8):** 2 / 2 / 11 / 27 / 55 / 102 / 16,028 / 21,741 / 169,031 — see [`assets/lululemon_product_hierarchy_summary.png`](assets/lululemon_product_hierarchy_summary.png).

### `store_master`

| Metric | Value |
|--------|------:|
| Total rows | 1,853 |
| PK duplicates | 0 |
| `dc_flag` store / DC | 1,724 / 129 |
| Channel RETAIL / ECOMM | 1,531 / 114 |
| In-scope retail (`dc_flag=0`, `channel=RETAIL`) | 1,501 |
| `loc_type_code` distinct | 2 |
| `active` distinct values | 2 |

**Checklist:** G1, G5, S* — pass.

### `transaction_master`

| Metric | Value |
|--------|------:|
| Total rows | 354,138,091 |
| Date range | 2022-05-19 → 2025-11-18 |
| Distinct dates | 1,280 |
| Grain duplicates | 0 |
| Real sales (`qty>0`, `revenue>0`) | 258,045,615 (72.87%) |
| Zero qty/rev/price slice | 96,083,329 (27.13%) |
| Distinct products / stores | 864,767 / 1,043 |
| `line_id` NULL | 100% (stub) |
| `transaction_type` NULL | 100% (stub) |

**Checklist:** G1, G5, G6, T2, T3, T18, T20, T23 — pass. T1, T4, T7, T8, T11, T12, T17, T21 — **dead checks** (stub columns per [`master_table_checklist.md`](master_table_checklist.md)).

### `inventory_master`

| Metric | Value |
|--------|------:|
| Total rows | 5,539,053 |
| Distinct dates | **1** (`2025-08-28`) |
| Grain duplicates (global) | 0 |
| Per-date grain duplicates | 0 |
| Distinct stores / products | 1,073 / 487,587 |
| % `product_code_was_derived` | 2.17% |
| % `channel_was_derived` | 2.17% |
| Rows with `oh > 0` | 4,612,156 |

**Checklist:** G1, G5, I* grain — pass. **Open:** multi-date history not loaded (still POC single snapshot).

---

## Tier 2 — Cross-master

### X3 — Inventory `product_code` vs product_master (INFO, not data loss)

**Strict join (health-check default):** **138,036** distinct suffixed `product_code` values and **364,543** rows (~6.6% of inventory) have no exact row in `product_master`. **X1 txn → PM remains 0 orphans** because `transaction_master` uses only `_RETAIL` / `_ECOMM` suffixes (0 txn rows with FO/STRAT/COMMUNITY/CMNTY suffixes).

**Root cause — channel-encoded SKU suffix, not missing assortment**

| Inv suffix | Orphan SKUs | Orphan rows | Rows with `oh > 0` | `store_master.channel` |
|------------|------------:|------------:|-------------------:|------------------------|
| FO | 111,390 | 328,911 | 262,180 | FO (mostly OUTLET) |
| STRAT | 17,319 | 25,937 | 19,479 | STRAT |
| COMMUNITY | 6,431 | 6,768 | 6,707 | COMMUNITY |
| CMNTY | 2,896 | 2,927 | 2,927 | CMNTY |

- `product_master` is **100%** `_RETAIL` / `_ECOMM` on `product_code`; `l1_name` is only RETAIL or ECOMM.
- Inventory encodes **store channel in the SKU suffix** (`{bare_sku}_{channel}`), matching `store_master.channel` on every orphan row.
- **RETAIL and ECOMM inventory rows strict-join to PM at 100%** (4,579,346 + 595,164 rows, 0 orphans) after the 2026-05-20 PM rebuild. The May-18 EDA “67% orphan” figure reflected the old ~653k PM, not current state.

**Reconciled join (bare SKU):**

- Orphan suffixed codes decompose to `bare_sku = SPLIT(product_code, '_')[OFFSET(0)]`.
- **138,036 / 138,036** orphan SKUs match `product_master.product_code_original`; **0** bare SKUs are absent from PM.
- All **364,543** orphan rows have both `{bare_sku}_RETAIL` and `{bare_sku}_ECOMM` PM rows available for attribute lookup.

**Example:** `155864036_STRAT` in inventory at a STRAT store; PM has `155864036_RETAIL` and `155864036_ECOMM`, not `*_STRAT`.

**Analytics join options (pick one policy):**

1. **Strict** — keep `inv.product_code = pm.product_code` for RETAIL/ECOMM-only reporting (exclude ~6.6% of inv rows or accept X3 INFO).
2. **Bare SKU + channel map** — join `product_code_original` and map store channel → RETAIL vs ECOMM (e.g. FO/OUTLET → RETAIL, STRAT virtual/e-comm → ECOMM); document mapping in the model layer.
3. **Expand PM build** — add `_FO`, `_STRAT`, etc. channel rows to `product_master` if the platform should mirror inventory suffix grain (larger PM; only needed if strict join is a hard requirement).

**Suggested follow-up for DE:** confirm intended channel→RETAIL/ECOMM mapping for FO/STRAT/COMMUNITY/CMNTY in downstream apps; no PM rebuild required unless strict suffixed join is mandatory everywhere.

**Reference visuals:** combined PDF [`assets/lululemon_masters_reference_guide.pdf`](assets/lululemon_masters_reference_guide.pdf) (page 1 = designed hierarchy infographic, page 2 = channel suffix full forms). PNGs: [`lululemon_product_hierarchy_summary_designed.png`](assets/lululemon_product_hierarchy_summary_designed.png), [`lululemon_channel_suffix_reference.png`](assets/lululemon_channel_suffix_reference.png). BQ-regenerated chart (matplotlib): [`lululemon_product_hierarchy_summary.png`](assets/lululemon_product_hierarchy_summary.png). Regenerate PDF: `python3 scripts/combine_lululemon_reference_pdf.py`.

### X5 — Never sold in PM (INFO)

- **63.32%** of `product_master` rows have no real-sales row in `transaction_master`.
- Expected for dual-channel assortment (988k per channel) vs 725k sold distinct products in txn.

### X6 — Channel alignment (PASS)

Sold SKUs: `l1_name` RETAIL ↔ txn RETAIL (341,112); ECOMM ↔ ECOMM (384,250). No cross-channel mismatch on joined set.

---

## Open issues (routed)

| Priority | Issue | Owner |
|----------|-------|-------|
| P1 | Inv X3 channel-suffix join policy (FO/STRAT/COMMUNITY/CMNTY) | DE / analytics consumers |
| P2 | `inventory_master` single date only | DE / sourcing cadence |
| P3 | Txn stub columns (discount, clearance, etc.) | DE — dead-check register |
| INFO | 63% PM never sold | Merchandising / expected |

---

## References

- Prior per-master EDA: [`master_product_master_eda.md`](master_product_master_eda.md), [`master_store_master_eda.md`](master_store_master_eda.md), [`master_transaction_master_eda.md`](master_transaction_master_eda.md), [`master_inventory_master_eda.md`](master_inventory_master_eda.md)
- Checklist: [`master_table_checklist.md`](master_table_checklist.md)
- Postgres alignment (separate): [`product_gsm_postgres_alignment.md`](product_gsm_postgres_alignment.md)
