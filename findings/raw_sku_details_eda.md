# EDA — `lulu_sourcing_dev.sku_details` (raw)

`Last updated: 2026-05-18.`

LEFT JOIN source for `size`, `color_code`, `color_description`, `season_code`, `product_description` on `product_master` (via `sku_id_code`). Build joins after stripping `COST_PRICE` and `SELLING_PRICE` because they're zero (see Phase 3).

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_sourcing_dev.sku_details` |
| Row count | **3,955,056** |
| Size | 1.09 GB |
| Column count | 22 (21 STRING + 1 DATETIME) |
| Sync batches | 1 (`2026-05-08T00:00:00` for every row) |

### Schema

22 columns covering: SKU identity (`ID`, `ITEM_ID`, `DESCRIPTION`), pricing (`PRICE_CURRENCY`, `COST_PRICE`, `SELLING_PRICE`), style (`STYLE_NAME`/`CODE`), color (`COLOR_NAME`/`CODE`), season (`SEASON_NAME`/`YEAR`/`CODE`), size (`SIZE_NAME`/`CODE`/`RANK`), brand (`BRAND_NAME`/`CODE`), segment (`SEGMENT_NAME`/`CODE`), `IMAGE_URL`, `SYNCSTARTDATETIME`.

### Notable observations from schema + sample

| # | Observation | Implication |
|---|---|---|
| 1 | All 21 raw fields are STRING (only `SYNCSTARTDATETIME` is typed) | Canonical pattern; cleaning casts downstream |
| 2 | `PRICE_CURRENCY = 'DUMMY_CURRENCY'` on every row | **Placeholder data — real currency never landed** |
| 3 | `COST_PRICE = '0'` and `SELLING_PRICE = '0'` on every row | **No pricing data ever loaded** (see Phase 3) |
| 4 | `SIZE_CODE` format is `<STYLE>-<COLOR>-<SIZE>` (e.g. `LW9634S-0001-XS`) | Composite key derivable from style+color+size |
| 5 | `SIZE_RANK` exists as numeric string (e.g. `490`) | Useable for size ordering — currently ignored by build |
| 6 | Single sync batch | Snapshot — no history |

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Total rows | 3,955,056 | — |
| Distinct `ID` | 988,764 | Matches PGH SKU universe exactly |
| Rows per `ID` | **Exactly 4 for every SKU** | Perfect uniform duplication |
| Distinct `ITEM_ID` | 149,089 | Style-color-level grain (~6.6 sizes per ITEM_ID on average) |
| Distinct `STYLE_CODE` | 16,156 | Matches PGH MASTER_STYLE cardinality |
| Distinct `COLOR_CODE` | 26,480 | |
| Distinct `SIZE_CODE` | 963,021 | Matches PGH PLANNING_STYLE_SIZE cardinality |

### The 4-row duplication

Sampled rows for a single `ID` — **all 4 rows are byte-identical** (same ITEM_ID, DESCRIPTION, prices, style, color, season, size, brand, segment, image_url, syncdate). Pure row duplication. Build's `SELECT DISTINCT *` collapses them to 1 row, so downstream is correct, but **storage cost is 4× what it should be**.

## Phase 3 — Completeness

| Column | NULL | Empty | `\N` | Zero | Total missing | % |
|---|---:|---:|---:|---:|---:|---:|
| `ID` | 0 | 0 | 0 | n/a | 0 | 0% |
| `ITEM_ID` | 0 | 0 | 0 | n/a | 0 | 0% |
| `DESCRIPTION` | 0 | 0 | 0 | n/a | 0 | 0% |
| `PRICE_CURRENCY` | 0 | 0 | 0 | n/a | 0 (but all `DUMMY_CURRENCY`) | 0% |
| `COST_PRICE` | 0 | 0 | 0 | **3,955,056** | 3,955,056 | **100%** |
| `SELLING_PRICE` | 0 | 0 | 0 | **3,955,056** | 3,955,056 | **100%** |
| `STYLE_NAME` / `STYLE_CODE` | 0 | 0 | 0 | n/a | 0 | 0% |
| `COLOR_NAME` / `COLOR_CODE` | 0 | 0 | 0 | n/a | 0 | 0% |
| `SEASON_NAME` / `YEAR` / `CODE` | 0 | 0 | 0 | n/a | 0 | 0% |
| `SIZE_NAME` / `CODE` / `RANK` | 0 | 0 | 0 | n/a | 0 | 0% |
| `BRAND_NAME` / `CODE` | 0 | 0 | 0 | n/a | 0 | 0% |
| `SEGMENT_NAME` / `CODE` | 0 | 0 | 0 | n/a | 0 | 0% |
| `IMAGE_URL` | 0 | **1,309,788** | 0 | n/a | 1,309,788 | **33.1%** |

### Big takeaways

- **Zero sentinels** — `\N` does not appear anywhere. Empty strings only on `IMAGE_URL`.
- **`COST_PRICE` and `SELLING_PRICE` are 100% zero** — placeholder data, never overwritten. Critical for `transaction_master` cost/msrp lineage (also broken).
- **`PRICE_CURRENCY = 'DUMMY_CURRENCY'`** — same root cause as zero prices.
- **33% of rows lack `IMAGE_URL`** (empty string, not NULL) — `IS NULL` check would miss this.

## Phase 4 — Distributions

### PRICE_CURRENCY

| Value | Rows |
|---|---:|
| `DUMMY_CURRENCY` | 3,955,056 (100%) |

→ Placeholder. Downstream currency conversions blocked.

### SEASON_YEAR / SEASON_CODE

| YEAR | CODE | Rows |
|---|---|---:|
| 2025 | 25-4WI | 3,955,056 (100%) |

→ Single-season snapshot (2025 Winter). Explains `product_master.season_code` being uniform.

### BRAND_NAME

| Value | Rows |
|---|---:|
| (2 distinct — same as PGH: `lululemon` + `ivivva`) | 3,955,056 |

→ Aligned with PGH BRAND. Cross-source consistency confirmed.

### SEGMENT_NAME

11 distinct (e.g. `lulu Womens`, `lulu Mens`, etc.) — finer split than gender alone.

## Phase 5 — Cross-table integrity

### Bijection with PGH SKU_ID

| Set | Count |
|---|---:|
| PGH distinct `SKU_ID` | 988,764 |
| sku_details distinct `ID` | 988,764 |
| Overlap | 988,764 (expected — same numeric universe) |

→ **1:1 SKU coverage** with PGH. The 4× duplication is internal to this table only.

### Join role for `product_master`

- Join key: PGH `SKU_ID` × channel → `sku_id_code` = `CONCAT(SKU_ID, '_', channel)`.
- LEFT JOIN, but distinct SKU universe matches, so practically inner.
- Build does `SELECT DISTINCT * EXCEPT(COST_PRICE, SELLING_PRICE)` — explicitly drops the zero prices.

## Phase 6 — Business-logic checks

### Are the 4 rows ever different?

Sampled — all 4 rows are identical. Likely a sourcing artifact (4× CSV append or 4× channel-segment Cartesian collapsed). **Build correctness depends on `DISTINCT` continuing to collapse all 4 to 1**.

### What downstream lineage uses

| Master column | Source field | Status |
|---|---|---|
| `product_master.size` | `SIZE_NAME` | 100% populated |
| `product_master.color_code` | `COLOR_CODE` | 100% populated |
| `product_master.color_description` | `COLOR_NAME` | 100% populated |
| `product_master.season_code` | `SEASON_CODE` | Single value (`25-4WI`) |
| `product_master.product_description` | `DESCRIPTION` | 100% populated |
| `transaction_master.cost` / `msrp` | `COST_PRICE` / `SELLING_PRICE` | **100% zero — broken** |

## Summary

| Reliable | Use with caution | Broken |
|---|---|---|
| `ID` (bijection with PGH) | 4× row duplication (storage cost) | `COST_PRICE` (100% zero) |
| `STYLE_CODE`, `COLOR_CODE`, `SIZE_CODE` | `IMAGE_URL` (33% empty string, not NULL) | `SELLING_PRICE` (100% zero) |
| `SIZE_NAME`, `SEASON_CODE`, `DESCRIPTION` | Single season (`25-4WI`) — no history | `PRICE_CURRENCY` (placeholder string) |
| `BRAND_NAME` (matches PGH) | | |

## QQ's for Client

- **Why is `COST_PRICE` and `SELLING_PRICE` 100% zero?** Are these supposed to come from a separate pricing feed?
- **Why `PRICE_CURRENCY = 'DUMMY_CURRENCY'`?** Same root cause as zero prices?
- **Why 4 identical rows per `ID`?** Sourcing append issue, or 4 expected variants that should differ?
- **Single season (`25-4WI`) only** — do we need historical season data for trend modeling?
- **33% of SKUs have no `IMAGE_URL`** — should we expect this, or is it a load gap?
