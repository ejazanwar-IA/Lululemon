# EDA — `product_attribute_s` (Req 12: Product attributes)

`Prepared: 2026-07-02` · `Sync batch: 2026-07-02 reload from GCS 2026-07-02/`

Related: [`product_attribute_feeds_comparison.md`](product_attribute_feeds_comparison.md) · [`raw_product_attribute_s_eda.md`](raw_product_attribute_s_eda.md) (May 2025, superseded) · [`queries/sourcing/product_attribute_s_eda.sql`](../queries/sourcing/product_attribute_s_eda.sql)

---

## Executive summary

| Item | Verdict |
|---|---|
| **Req 12 coverage** | **Partial** — wide static style attributes loaded and joinable at `STYLE_ID` grain |
| **Grain** | 1 row per `STYLE_ID` (86,135 rows; 0 duplicates after Jul 2 reload) |
| **PGH spine** | 100% of PGH styles and SKUs map to PA; PA is a **style superset** (+42,493 styles not in PGH) |
| **Downstream** | `product_intermediate` still has 0% `flex_status` populated (built before PA reload) |

---

## Foundation

Schema: `lulu_sourcing_dev.product_attribute_s`

| Metric | Value |
|---|---|
| Rows | 86,135 |
| Distinct `STYLE_ID` | 86,135 |
| Columns | 102 (all STRING; includes `WATERPROOF`, `WEIGHT`) |
| Size | 58.18 MB |
| Last modified | 2026-07-02 07:38 UTC |
| `SYNCSTARTDATETIME` | **Absent** on current load |

### Grain

| Check | Result |
|---|---|
| Duplicate rows at `STYLE_ID` | 0 (0.00%) |
| Prior May load | 258,405 rows with uniform 3× triplication (fixed) |

---

## Completeness (build-used + sample long-tail)

Sentinel treated as missing: NULL, empty, `\N`, `\\N`.

| Column | Missing | % missing | Build use |
|---|---:|---:|---|
| `STYLE_ID` | 0 | 0.00% | Join key |
| `PRODUCT_LINE` | 3,154 | 3.66% | Build |
| `GENDER` | 3,184 | 3.70% | Build → `gender` |
| `FLEX_STATUS` | 8,132 | 9.44% | Build → `flex_status` |
| `DESIGN_LINE` | 13,450 | 15.62% | Build |
| `DESIGNED_FOR_ACTIVITY` | 32,423 | 37.64% | Build |
| `GLOBAL_MERCH_TEAM` | 32,753 | 38.03% | Build |
| `SILHOUETTE` | 40,534 | 47.06% | Build |
| `PLANNING_PRODUCT_GROUPING` | 46,207 | 53.64% | Build |
| `FABRIC_FAMILY` | 52,758 | 61.25% | Long-tail |
| `FIT_CLASSIFICATION` | 56,132 | 65.17% | Build |
| `PRODUCT_GENDER` | 71,837 | 83.40% | Not used (build uses `GENDER`) |
| `ACTIVITY` | 85,902 | 99.73% | Long-tail |

---

## Key distributions

### `FLEX_STATUS` (all styles)

| Value | Styles | % |
|---|---:|---:|
| Drop | 40,757 | 47.32% |
| Active | 37,222 | 43.21% |
| `\N` | 8,132 | 9.44% |
| Inactive | 14 | 0.02% |
| Hold | 10 | 0.01% |

### `GENDER`

| Value | Styles | % |
|---|---:|---:|
| Womens | 55,657 | 64.62% |
| Mens | 17,134 | 19.89% |
| Unisex | 5,814 | 6.75% |
| Girls | 4,346 | 5.05% |
| `\N` | 3,184 | 3.70% |

---

## Cross-table match (bidirectional)

Join key: `TRIM(STYLE_ID)` unless noted.

| Comparison | Left | Right | Overlap | % left in right | % right in left |
|---|---:|---:|---:|---:|---:|
| `product_attribute_s` → PGH STYLE | 86,135 | 43,642 | 43,642 | 50.67% | 100% |
| `product_attribute_s` → `style_option` | 86,135 | 82,473 | 82,466 | 95.74% | 99.99% |
| `product_attribute_s` → `product_attribute_s_seasonal` | 86,135 | 85,861 | 85,179 | 98.89% | 99.21% |
| `product_attribute_s` → `product_attribute_so_seasonal` (via `style_option`) | 86,135 | 75,761 | 75,761 | 87.96% | 100% |
| `product_attribute_s` → `planned_sales` (via `style_option`) | 86,135 | 7,818 | 7,818 | 9.08% | 100% |

### Orphan counts

| Bucket | Count | Notes |
|---|---:|---|
| PA-only (not in PGH STYLE) | 42,493 | 49.33% of PA styles |
| PGH-only (not in PA) | 0 | Every PGH style has PA row |
| `style_option`-only (not in PA) | 7 | Negligible |

### SKU rollup (via PGH STYLE join)

| Metric | Value |
|---|---:|
| PGH distinct SKUs | 988,764 |
| SKUs with PA via STYLE | 988,764 (100.00%) |

---

## PA-only styles (42,493 not in PGH)

| Metric | Value |
|---|---:|
| Also in `style_option` | 38,824 (91.37% of PA-only) |
| Also in `product_attribute_s_seasonal` | 41,539 (97.75% of PA-only) |

### `FLEX_STATUS` for PA-only styles

| Value | Styles | % of PA-only |
|---|---:|---:|
| Drop | 31,789 | 74.81% |
| Active | 8,024 | 18.88% |
| `\N` | 2,660 | 6.26% |

PA-only styles skew heavily **Drop** (74.81% vs 47.32% overall), consistent with historical/out-of-assortment styles absent from the current PGH spine.

---

## Static vs seasonal `FLEX_STATUS` alignment

At quarter **20233** (most distinct styles in seasonal feed: 66,482 paired):

| Metric | Value |
|---|---:|
| Paired styles | 66,482 |
| `FLEX_STATUS` match | 10,010 (15.06%) |
| Mismatch | 56,472 (84.94%) |

Do not use `MAX(QUARTER_ID)` for alignment checks; future quarters (e.g. 20274) have only 51 styles.

---

## BQ vs GCS reconciliation

| Source | Rows |
|---|---:|
| BQ `product_attribute_s` | 86,135 |
| GCS `2026-07-02/` (16 shards, streamed sum) | 86,135 |

Match confirmed. Reload source: `gs://client_data_lululemon/2026-07-02/product_attribute_s20251118_153511_*.csv`

---

## Downstream note

`product_intermediate` (1,977,528 rows) has **0%** populated `flex_status` because it was built while `product_attribute_s` was empty. Rebuild `product_intermediate` / `product_master` after PA reload to surface attributes.

---

## Client callouts

| Priority | Callout | Evidence |
|---|---|---|
| **P0** | **PA is a style superset of PGH.** 42,493 styles (49.33% of PA) have no PGH STYLE row; 74.81% of those are `FLEX_STATUS = Drop`. Confirm whether these are historical/Drop styles outside current assortment spine or a feed-scope difference. | Cross-table match; PA-only FLEX_STATUS |
| **P1** | **`FLEX_STATUS` should drive lifecycle**, not hardcoded `article_status = ACTIVE`. Overall split: Drop 47.32%, Active 43.21%. Rebuild product intermediate/master to propagate. | Distribution; `product_intermediate` 0% flex_status |
| **P1** | **Jul 2 reload fixed 3× duplication** (258K → 86K rows) but dropped `SYNCSTARTDATETIME`. Confirm ingestion dedup + sync metadata on future loads. | Grain check; schema |
| **P2** | **Static vs seasonal `FLEX_STATUS` disagree** at representative quarter 20233 (15.06% match). Clarify which feed is authoritative for lifecycle by quarter. | Section 6 alignment query |

---

## Recommended next steps

| Owner | Action |
|---|---|
| **IA** | Rebuild `product_intermediate` with current PA join |
| **IA / Platform** | Add `SYNCSTARTDATETIME` to PA load DDL |
| **Client** | Confirm PA-only style universe (historical Drop vs scope gap) |
| **IA** | Use PA for Req 12 static attrs; use `_s_seasonal` for quarter-varying attrs (Req 13) |
