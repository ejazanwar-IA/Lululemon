# EDA — `lulu_sourcing_dev.product_group_hierarchy` (raw)

`Last updated: 2026-05-18.`

Primary spine for `product_master`. Long-format EAV table pivoted + channel-expanded in the build. Feeds via:

```
PGH (long EAV) -> pivot (9 levels) -> CROSS JOIN UNNEST(['ECOMM','RETAIL']) -> product_intermediate -> product_master
```

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_sourcing_dev.product_group_hierarchy` |
| Created (IST) | 2026-05-11 17:34 |
| Row count | **18,249,385** |
| Size | 1.11 GB |
| Column count | 6 (5 STRING + 1 DATETIME) |
| Sync batches | 1 (`2026-05-08T00:00:00` for every row) |

### Schema

| # | Column | Type | Nullable |
|---:|---|---|---|
| 1 | `SKU_ID` | STRING | YES |
| 2 | `LEVEL_NUMBER` | STRING | YES |
| 3 | `LEVEL_NAME` | STRING | YES |
| 4 | `VALUE_NAME` | STRING | YES |
| 5 | `VALUE_CODE` | STRING | YES |
| 6 | `SYNCSTARTDATETIME` | DATETIME | YES |

### Notable observations from schema + 5-row sample

| # | Observation | Implication |
|---|---|---|
| 1 | Pure EAV long format — 5 string cols hold the entire merchandise hierarchy | Pivot is mandatory before downstream use; `MAX(CASE WHEN ...)` recipe in cleaned build |
| 2 | `LEVEL_NUMBER` stored as STRING despite being 1–9 | `SAFE_CAST(LEVEL_NUMBER AS INT64)` if you need numeric ordering |
| 3 | `SKU_ID` is numeric string, 1–9 chars (max value 159,018,638) | Bare SKU — channel suffix is added in the build (`CONCAT(SKU_ID, '_', channel)`) |
| 4 | Sample shows `BRAND_NAME = 'ivivva'` with code `200` | Sub-brand exists alongside `lululemon` (code `100`); two-brand table |
| 5 | Single `SYNCSTARTDATETIME` value | Snapshot table — no history retained |
| 6 | All STRING (canonical Lululemon raw pattern) | Type/sentinel cleaning happens downstream |

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Total rows | 18,249,385 | — |
| Distinct `SKU_ID` | 988,764 | ~18.5 rows per SKU on average |
| Distinct `SKU_ID` + `LEVEL_NAME` | 8,898,876 | Expected ~989K × 9 = 8.9M (matches!) |
| Distinct `LEVEL_NUMBER` | 9 | Clean 1–9 mapping |

### Rows per SKU_ID distribution

| Rows per SKU | SKU count | % |
|---:|---:|---:|
| 18 | 662,081 | 66.9% |
| 19 | 259,077 | 26.2% |
| 20 | 10,262 | 1.0% |
| 21 | 57,344 | 5.8% |

→ Expected pattern is **9 rows per SKU** (one per level). Actual is 18–21. This is **massive duplication** of EAV rows.

### Duplicate (SKU_ID, LEVEL_NAME) pairs

| Dup count | Pair count |
|---:|---:|
| 2 | 8,447,243 |
| 3 | 451,633 |

→ **Almost every pair is duplicated 2×**, with 451K triplicated. Build's `MAX(CASE WHEN ...)` survives but the table is structurally doubled.

## Phase 3 — Completeness

| Column | NULL | Empty | `\N` | `\\N` | Total missing | % |
|---|---:|---:|---:|---:|---:|---:|
| `SKU_ID` | 0 | 0 | 0 | 0 | 0 | 0% |
| `LEVEL_NUMBER` | 0 | 0 | 0 | 0 | 0 | 0% |
| `LEVEL_NAME` | 0 | 0 | 0 | 0 | 0 | 0% |
| `VALUE_NAME` | 0 | 0 | 0 | 0 | 0 | 0% |
| `VALUE_CODE` | 0 | 0 | 0 | 0 | 0 | 0% |

→ **No sentinels, no nulls, no double-backslash issues.** Cleanest of the three product raw sources.

## Phase 4 — Distributions

### LEVEL_NAME × LEVEL_NUMBER (canonical hierarchy)

| LEVEL_NUMBER | LEVEL_NAME | Rows | Distinct VALUE_NAME | Distinct VALUE_CODE |
|---:|---|---:|---:|---:|
| 1 | BRAND | 2,034,872 | **2** | **2** |
| 2 | DIVISION | 2,022,624 | 11 | 11 |
| 3 | DEPARTMENT | 2,030,775 | 27 | 27 |
| 4 | CLASS | 2,034,872 | 55 | 55 |
| 5 | SUBCLASS | 2,045,131 | 102 | 104 |
| 6 | MASTER_STYLE | 2,002,033 | 16,028 | 16,156 |
| 7 | STYLE | 2,030,776 | 21,741 | 43,642 |
| 8 | PLANNING_STYLE_OPTION | 2,034,872 | 24,293 | 149,089 |
| 9 | PLANNING_STYLE_SIZE | 2,013,430 | **169,031** | **963,021** |

### Key observations

- **BRAND has only 2 values** (`lululemon` / `ivivva`) — drives `l0_name` cardinality in master.
- **VALUE_NAME and VALUE_CODE cardinalities differ at SUBCLASS, STYLE, PLANNING_STYLE_OPTION, PLANNING_STYLE_SIZE** — meaning the same display name maps to multiple codes (e.g. STYLE has 21,741 names but 43,642 codes — ~2× codes per name, lines up with the ECOMM/RETAIL channel duplication seen elsewhere).
- **PLANNING_STYLE_SIZE** is the only level with near-uniqueness (963K codes / 989K SKUs) — it's what becomes `product_name` in master and explains why `product_name` is the hardest column to populate (~13K SKUs lack this level entirely).

## Phase 5 — Cross-table integrity (downstream impact)

| Stage | Rows | Notes |
|---|---:|---|
| Raw PGH | 18,249,385 | EAV long format |
| Distinct `SKU_ID` (bare) | 988,764 | |
| Expected after pivot × 2 channels | ~1,977,528 | Full universe |
| `product_intermediate` actual | 653,366 | |
| `product_master` | 653,366 | 1:1 with intermediate |

→ **Only 33% of SKU universe reaches master.** Drop happens in the build's `WHERE sku_id_code IS NOT NULL` + join survivorship. Worth verifying whether this is intentional (e.g. filter on active SKUs) or a bug.

## Phase 6 — Business-logic checks

### EAV duplication signature

The 18.2M-row count and 2× pair multiplicity suggests **the raw load is appending without dedup** — same EAV rows landing twice per sync. Build's pivot uses `MAX()` so values resolve consistently, but:

- **2× storage cost** for no information gain
- **Risk** if a future change adds `GROUP BY` of EAV rows without dedup first

### BRAND vs other levels

`BRAND` populates 2.03M rows for 989K SKUs — that's ~2.06 rows per SKU. Other levels match similar 2× pattern. The duplication is **uniform across levels**.

## Summary — what `product_master` inherits from this table

| Reliable for downstream | Use with caution | Action items |
|---|---|---|
| `SKU_ID` (numeric, never null) | Duplicate EAV rows (~2× source bloat) | **Ask client** if PGH load should dedup |
| Clean 9-level hierarchy (BRAND → PLANNING_STYLE_SIZE) | Some SKUs missing MASTER_STYLE / PLANNING_STYLE_SIZE rows | Document missing-level SKUs as a build filter |
| No sentinels, no NULLs | VALUE_CODE has channel-suffix-like doubling at deep levels | — |
| Single sync batch (snapshot) | No history | If history needed, change Sourcing DAG to incremental |

## QQ's for Client

- **Why ~2× duplication of EAV rows?** Is PGH source already deduped or appended-only?
- **Why ~13K SKUs lack PLANNING_STYLE_SIZE?** Are these placeholders / not-yet-released SKUs?
- **`BRAND` has only `lululemon` and `ivivva`** — any third brand expected in future feeds?
- **Why does master ingest only 33% of SKUs from this table?** Intentional filter or join loss?
