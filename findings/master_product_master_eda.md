# EDA — `lulu_ingestion_dev.product_master` (canonical master)

`Last updated: 2026-05-18.` — **Health check (2026-05-20):** [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) — 1,977,528 rows; 0% null hierarchy; supersedes row counts below.

Master-level EDA. Build: `product_group_hierarchy` (pivot + channel) + `sku_details` + `product_attribute_s` → `product_intermediate` (46 cols) → GSM → `product_master` (30 cols).

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Table | `lululemon-01042025.lulu_ingestion_dev.product_master` |
| Rows | **653,366** |
| Size | 0.11 GB |
| Columns | **30** (GSM `required_in_product=true` only) |
| `product_intermediate` rows | 653,366 (1:1) |

### Ingested columns (30)

Hierarchy: `l0_name`–`l8_name`, `l0_id`, `l2_id`–`l8_id` (no `l1_id`). Product: `product_code`, `product_code_original`, `article`, `article_original`, `product_name`, `product_description`, `size`, `color_code`, `color_description`, `season_code`. Flags: `article_status`, `active_flag`, `product_bucket_code`. Meta: `channel` via `l1_name`.

### Not in live master (`required_in_product=false`)

`gender`, `silhouette`, `launch_date`, `color_family`, `ordering`, `flex_status`, `fit_classification`, `design_line`, `designed_for_activity`, `product_line`, `size_scale`, and 6 others — see GSM CSV.

## Phase 2 — Grain

| Check | Result |
|---|---|
| `product_code` unique | **653,366 = 653,366** |
| `l1_name` | RETAIL 326,683 + ECOMM 326,683 (50/50) |
| `product_code` suffix | 100% `*_RETAIL` / `*_ECOMM` aligned with `l1_name` |
| Distinct `article` | 32,764 |
| Distinct `article` + size + color + channel | 114,216 combos |

→ PK is `product_code` (`<bare_sku>_RETAIL|ECOMM`). Two rows per bare SKU when both channels exist.

## Phase 3 — Completeness

| Column | Missing | % | Notes |
|---|---:|---:|---|
| `product_name` | 581,562 | 89.0% | = missing `l8_name` |
| `l0_name` / `article` | 538,678 | 82.4% | No brand in pivot |
| `l2_name` | 563,174 | 86.1% | |
| `l5_name` | 518,160 | 79.3% | |
| `product_bucket_code` | 653,366 | **100%** | All NULL in this load |
| `size`, `color_code`, `season_code` | 0 | 0% | Populated when join hits |
| `active_flag` | 0 NULL | 0% | All `1` |

### Three disjoint cohorts (no overlap)

| Cohort | Rows | % | Pattern |
|---|---:|---:|---|
| A — hollow | 466,874 | 71.5% | No `l0_name`, no `product_name` |
| B — hierarchy only | 114,688 | 17.6% | Has `l0_name` (lululemon/ivivva) but **no** `product_name` |
| C — name only | 71,804 | 11.0% | Has `product_name` but **no** `l0_name` |

→ **Most rows are sparse.** Do not assume full hierarchy on every `product_code`.

### Hardcoded / stub columns

| Column | Value | Source |
|---|---|---|
| `article_status` | `ACTIVE` (100%) | Build stub |
| `active_flag` | `1` (100%) | Build stub |
| `product_bucket_code` | NULL (100%) | Build stub or failed hash |
| `season_code` | `25-4WI` only | Single snapshot season |

## Phase 4 — Distributions

### `l0_name` (brand)

| Value | Rows |
|---|---:|
| NULL | 538,678 |
| lululemon | 113,126 |
| ivivva | 1,562 |

### `l1_name` (channel)

RETAIL / ECOMM only — derived from `product_code` suffix, not merchandise hierarchy.

## Phase 5 — Cross-table integrity

| Check | Result |
|---|---|
| Row count vs `product_intermediate` | 653,366 = 653,366 |
| Bare SKUs in raw PGH | 988,764 |
| SKUs in master (÷2 channels) | ~326,683 (~33% of PGH universe) |
| `sku_details` join | Size/color/season present when sku row matches |
| `product_attribute_s` | Not joined into 30-col master |

## Phase 6 — Consumer guidance

### Safe filters

```sql
-- Channel-specific SKUs
WHERE l1_name = 'RETAIL'

-- Rows with usable hierarchy
WHERE l0_name IS NOT NULL

-- Rows with style-size name
WHERE product_name IS NOT NULL
```

### Do not assume

- Full `l0`–`l8` hierarchy on every row
- `active_flag` or `article_status` reflect real lifecycle (stubs)
- `product_bucket_code` is populated
- Cost/msrp from `sku_details` (100% zero in raw)

### Derived gender (when column added to GSM)

Use Section 5.1 recipe in `lululemon-bq-context.mdc` when raw `gender` is `\N`.

## Action items

1. Investigate why **71% of master rows lack both brand and product_name** — EAV dupes + join keys.
2. Fix **`product_bucket_code`** — 100% NULL in ingested master.
3. Enable GSM columns needed for modeling (`gender`, `launch_date`, etc.) if required.
4. Client: fix **`COST_PRICE` / `SELLING_PRICE`** in `sku_details` (all zero).
5. Client: dedupe **`product_group_hierarchy`** to 9 rows per `SKU_ID`.
