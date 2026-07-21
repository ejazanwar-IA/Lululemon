# EDA — `lulu_sourcing_dev.product_attribute_s` (raw)

`Last updated: 2026-05-18.`

Style-level attribute wide table — 100 columns, one row per (`STYLE_ID`, variant). LEFT JOIN to PGH on `STYLE_CODE = STYLE_ID` in canonical build. Most attribute columns are GSM-flagged `required_in_product=false`, so they're not in the 30-col live master — but they exist in raw and could be enabled.

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_sourcing_dev.product_attribute_s` |
| Row count | **258,405** |
| Size | 0.16 GB |
| Column count | **100** (all STRING) |
| Sync batches | 1 (`2026-05-08T00:00:00`) |

### Notable observations from schema + sample

| # | Observation | Implication |
|---|---|---|
| 1 | All 100 columns are STRING — including ones that look numeric/boolean | Casting needed if used in math |
| 2 | `STYLE_ID` is the join key (NOT `STYLE_CODE` as the build doc hints — that's PGH side) | Verified: PGH `STYLE_CODE` → `STYLE_ID` here |
| 3 | Build uses 14 of 100 columns (see Section 5 below) | 86 columns unused today |
| 4 | Two gender-like columns exist: `GENDER` (used by build) and `PRODUCT_GENDER` (largely empty) | **Build picks the populated one — don't swap them** |

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Total rows | 258,405 | — |
| Distinct `STYLE_ID` | 86,135 | — |
| Rows per `STYLE_ID` | **Exactly 3 for every STYLE_ID** | Uniform 3× duplication |
| Sample `STYLE_ID` dup_rows | `LM3EDCS=3`, `LM3FBAS=3`, `LM3F74S=3`, ... | Confirms 3× pattern |

### The 3-row duplication

258,405 / 86,135 = exactly 3. Need to verify if all 3 rows are identical (like `sku_details` 4×) or if they differ by some hidden dimension. Build's `LEFT JOIN` will produce up to 3× row multiplication on `product_intermediate` if not deduped — worth investigating.

## Phase 3 — Completeness (join key + 14 build-used attributes)

| Column | Missing (NULL/empty/`\N`) | % | Used in build? |
|---|---:|---:|---|
| `STYLE_ID` | 0 | 0% | Join key |
| `GENDER` | 9,552 | 3.7% | **Yes** → `gender` |
| `SILHOUETTE` | 121,602 | 47.1% | Yes → `silhouette` (`required=false`) |
| `PLANNING_PRODUCT_GROUPING` | 138,621 | 53.6% | Yes → `planning_product_grouping` (`required=false`) |
| `FLEX_STATUS` | 24,396 | 9.4% | Yes → `flex_status` (`required=false`) |
| `GLOBAL_MERCH_TEAM` | 98,259 | 38.0% | Yes → `global_merch_team` (`required=false`) |
| `FIT_CLASSIFICATION` | 168,396 | 65.2% | Yes (`required=false`) |
| `DESIGN_LINE` | 40,350 | 15.6% | Yes (`required=false`) |
| `DESIGNED_FOR_ACTIVITY` | 97,269 | 37.6% | Yes (`required=false`) |
| `PRODUCT_LINE` | 9,462 | 3.7% | Yes (`required=false`) |
| `SIZE_SCALE` | 9,630 | 3.7% | Yes (`required=false`) |
| `PRODUCT_DEVELOPMENT_POD` | 9,612 | 3.7% | Yes (`required=false`) |
| `PRODUCT_SIZE_DEFINITION` | 9,630 | 3.7% | Yes (`required=false`) |
| `GLOBAL_LINE_SEGMENT_STYLE_CATEGORY` | 10,443 | 4.0% | Yes (`required=false`) |
| `PRODUCT_GENDER` | **215,511** | **83.4%** | **No** (build uses `GENDER` instead) |

### Long-tail (86 unused columns)

The build references 14 columns; the other 86 are unused. Examples (alphabetical): `ACTIVITY`, `ACTIVITY_CATEGORY`, `ACTIVITY_LEVEL_*`, `ADJUSTABLE_STRAP`, `ANTI_STINK`, `BACK_DETAIL`, `BUILT_IN_BRA`, `CLOSURE`, `COVERAGE`, `CUP_CONSTRUCTION`, `FABRIC_FAMILY`, `FRANCHISE`, `HEMLINE`, `INSEAM`, `MATERIAL_TYPE`, `NECKLINE`, `PATTERN_ENGINEER`, `RISE`, `SLEEVE_LENGTH`, `WAISTBAND_TYPE`, etc.

→ Most are detailed style attributes (apparel taxonomy). Sparseness varies widely — `ACTIVITY` is ~3.7% missing (well-populated), most others likely much sparser.

## Phase 4 — Distributions (key attributes)

### GENDER (build → `product_master.gender` when enabled)

| Value | Rows | % |
|---|---:|---:|
| Womens | 166,971 | 64.6% |
| Mens | 51,402 | 19.9% |
| Unisex | 17,442 | 6.7% |
| Girls | 13,038 | 5.0% |
| `\N` | 9,552 | 3.7% |

→ Womens-heavy assortment (~65%). Clean 4-value taxonomy + `\N` sentinel.

### PRODUCT_GENDER (NOT used by build)

| Value | Rows | % |
|---|---:|---:|
| `\N` | 215,511 | **83.4%** |
| Womens | 25,020 | 9.7% |
| Mens | 9,762 | 3.8% |
| Unisex | 8,112 | 3.1% |

→ 83% missing. **Build correctly picks `GENDER` not `PRODUCT_GENDER`.** Don't swap.

### FLEX_STATUS (build → `flex_status`)

| Value | Rows | % |
|---|---:|---:|
| Drop | 122,271 | 47.3% |
| Active | 111,666 | 43.2% |
| `\N` | 24,396 | 9.4% |
| Inactive | 42 | 0.02% |
| Hold | 30 | 0.01% |

→ **`flex_status` is the real lifecycle field** that `product_master.article_status` (hardcoded `'ACTIVE'`) should be sourced from. 47% Drop / 43% Active split — meaningful business signal currently lost.

## Phase 5 — Cross-table integrity

### Join coverage vs PGH

| Set | Count |
|---|---:|
| PGH distinct `SKU_ID` | 988,764 |
| PGH distinct STYLE-level codes (LEVEL_NAME=STYLE) | ~43,642 (codes) / 21,741 (names) |
| product_attribute_s distinct `STYLE_ID` | 86,135 |

→ More `STYLE_ID`s here than distinct STYLE codes in PGH — possibly because PGH STYLE level uses different ID format. **JOIN key alignment needs verification** (build uses `PGH.STYLE_CODE = pa.STYLE_ID` — confirm format match).

### Build columns vs ingested master

The build emits 14 attributes from this table, but the GSM marks 13 of them as `required_in_product=false`. Only `gender` could reach the live master if its GSM flag is flipped.

## Phase 6 — Business-logic checks

### Two gender columns — which to trust?

| Column | Populated | Distinct values |
|---|---:|---:|
| `GENDER` | 96.3% | 5 (incl. `\N`) |
| `PRODUCT_GENDER` | 16.6% | 4 (incl. `\N`) |

→ Build uses `GENDER`. Keep it that way.

### `article_status` stub vs `FLEX_STATUS`

Currently `product_master.article_status = 'ACTIVE'` on every row (hardcoded in build). **`FLEX_STATUS` is the real lifecycle field** and shows 47% Drop, 43% Active — a major business signal currently lost. **Recommend wiring `FLEX_STATUS` into `article_status`** in the build.

## Summary

| Reliable | Use with caution | Avoid |
|---|---|---|
| `STYLE_ID` (join key, 100% populated) | 3× row duplication (verify if identical) | `PRODUCT_GENDER` (83% missing) |
| `GENDER` (4-value clean taxonomy) | Sparse attribute columns (47%+ missing on some) | Numeric casting without `SAFE_CAST` |
| `FLEX_STATUS` (real lifecycle signal) | 86 unused columns (long tail) | |

## QQ's for Client

- **Are the 3 rows per `STYLE_ID` identical, or do they encode an extra dimension?** (Currently undocumented.)
- **Should `article_status` be sourced from `FLEX_STATUS` instead of hardcoded `'ACTIVE'`?** Drop/Active split is meaningful (47/43).
- **Which of the 86 unused columns are useful for modeling?** (e.g., `FABRIC_FAMILY`, `ACTIVITY`, `INSEAM`, `FIT`)
- **Which gender field is canonical?** (`GENDER` populated 96%; `PRODUCT_GENDER` empty 83%.)
- **`STYLE_ID` vs PGH `STYLE_CODE` alignment** — confirm format/cardinality match for the LEFT JOIN.
