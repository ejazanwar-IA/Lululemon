# ForecastSmart EDA: Req 11, 13, 14

`EDA date: 2026-06-30` · `BQ load: 2026-06-25` · `Billing: lululemon-data-scan`

Schema: `lululemon-01042025.lulu_sourcing_dev`

SQL companion: [`queries/sourcing/forecastsmart_req11_13_14_eda.sql`](../queries/sourcing/forecastsmart_req11_13_14_eda.sql)

Related: [`forecastsmart_data_requirements_coverage.md`](forecastsmart_data_requirements_coverage.md), [`gcs_feed_eda_review_20260629.md`](gcs_feed_eda_review_20260629.md), [`product_attribute_feeds_comparison.md`](product_attribute_feeds_comparison.md)

---

## Executive summary

| Req | Requirement | Table(s) | Rows | Verdict vs spec | Top client callout |
|---:|---|---|---:|---|---|
| **11** | Future Promotions Pricing | `planned_sales` | 115,687,669 | **Partial** | No price or promo columns; planned units only |
| **13** | Product Time dependent attributes | `product_attribute_s_seasonal`, `product_attribute_so_seasonal` | 650,404 + 1,196,146 | **Partial** | Quarter grain, not SKU × start/end date; attrs heavily sparse |
| **14** | SKU-Store Allocation Eligibility | `eligibility` | 241,782,410 | **Partial** | PSO × store × week grain; 4.66% duplicate rows with conflicting attrs |

All four tables loaded with a **single** `SYNCSTARTDATETIME = 2026-06-25` (no double-load smell).

---

## Requirement context

| Req | Ideal grain | Ideal horizon | What we received |
|---|---|---|---|
| 11 | Hierarchy × Week | Future | Style-option × Store × Week; numeric planned units + size range |
| 13 | SKU × Start Date × End Date | 2 yrs hist + future | Style or style-option × `QUARTER_ID` seasonal attributes |
| 14 | SKU × Store × Start × End | Future feed | Planning style option × Store × Week + reg-price weeks |

---

## Req 11: `planned_sales`

### Foundation

| Metric | Value |
|---|---|
| Rows | 115,687,669 |
| Size | 12.3 GB |
| Sync | `2026-06-25` (1 batch) |
| Columns | 8 data + `SYNCSTARTDATETIME` |

**Schema note:** BQ has **`WP_BOP_U`** (beginning-of-period units) in addition to the 7-column GCS header (`PLAN_QUARTER_ID`, `WEEK_ID`, `STYLE_OPTION_ID`, `STORE_ID`, `SUB_MARKET_CHANNEL_ID`, `WP_TOT_REG_SLS_U`, `SIZE_RANGE`). All columns are STRING.

### Grain and volume

| Metric | Value |
|---|---|
| Declared grain | `STYLE_OPTION_ID × STORE_ID × WEEK_ID` |
| Distinct grain keys | 106,895,955 |
| Duplicate rows at grain | 8,557,957 (7.40% of rows) |
| Distinct style options | 37,672 |
| Distinct stores | 1,045 |
| Distinct weeks | 105 |
| `WEEK_ID` range | `202452` to `202651` |
| `PLAN_QUARTER_ID` range | `20251` to `20263` |

Duplicates likely reflect multiple `SUB_MARKET_CHANNEL_ID` values per SO×store×week (channel is not in the base grain key).

### Completeness

| Column | Missing / `\N` | % of rows |
|---|---:|---:|
| `STYLE_OPTION_ID`, `STORE_ID`, `WEEK_ID`, `SUB_MARKET_CHANNEL_ID`, `WP_TOT_REG_SLS_U`, `WP_BOP_U` | 0 | 0.00% |
| `SIZE_RANGE` | 6,600,010 | 5.71% |

### Categorical distributions

**`SUB_MARKET_CHANNEL_ID` (top 5):**

| Value | Rows | % of rows |
|---|---:|---:|
| `LLL_USA_RTL` | 68,461,174 | 59.18% |
| `LLL_CHINA_RTL` | 13,125,747 | 11.35% |
| `LLL_CAN_RTL` | 12,944,129 | 11.19% |
| `LLL_ASIA_RTL` | 6,590,557 | 5.70% |
| `LLL_EUR_RTL` | 4,879,825 | 4.22% |

**`SIZE_RANGE` (top 5):**

| Value | Rows | % of rows |
|---|---:|---:|
| `O/S` | 16,311,558 | 14.10% |
| `XS,S,M,L,XL,XXL` | 14,244,156 | 12.31% |
| `0,2,4,6,8,10,12,14` | 11,805,334 | 10.20% |
| `0,2,4,6,8,10,12,14,16,18,20` | 11,502,530 | 9.94% |
| `\N` | 6,600,010 | 5.71% |

### Numerical behavior

**`WP_TOT_REG_SLS_U` (planned regular sales units):**

| Metric | Value |
|---|---|
| Zero | 46,890,347 (40.53% of rows) |
| Positive | 68,796,560 (59.47% of rows) |
| Negative | 762 (0.0007% of rows) |
| Mean | 1.78 |
| Median (p50) | 0.36 |
| p95 | 4.75 |
| Max | 14,238.53 |

**`WP_BOP_U`:**

| Metric | Value |
|---|---|
| Zero | 107,769,032 (93.16% of rows) |
| Positive | 7,918,623 (6.84% of rows) |
| Mean | 0.39 |
| Median | 0.0 |

### Time horizon (future)

Using fiscal week `202626` as approximate current week (Jun 2026):

| Window | Rows | % of rows |
|---|---:|---:|
| `WEEK_ID >= 202526` | 88,327,484 | 76.35% |
| `WEEK_ID > 202626` (strict future) | 11,110,486 | 9.60% |

The feed spans multiple planning horizons; only ~9.6% of rows are strictly after the current week.

### Cross-table joins

| Join | Match rate |
|---|---|
| `STYLE_OPTION_ID` → `style_option` | 37,672 / 37,672 (100.00%) |
| `STORE_ID` → `location_details.ID` | 1,045 / 1,045 (100.00%) |

No direct join to `sku_details` (that table uses numeric `STYLE_CODE`, not alphanumeric style IDs).

### Client callouts (Req 11)

| Priority | Callout | Evidence |
|---|---|---|
| **P0** | **This is not a pricing or promotions feed.** There are no price, discount, markdown, or promo-flag columns. Content is planned regular sales units (`WP_TOT_REG_SLS_U`), optional BOP units, and `SIZE_RANGE`. Req 11 ("Future Promotions **Pricing**") is not met by this table alone. | Column list; no `PRICE`, `DISCOUNT`, or promo fields |
| **P0** | **Grain mismatch:** style-option × store × week, not hierarchy × week. Confirm which hierarchy level (department, class, style) promo pricing should attach to, or whether style-option × store is acceptable. | 37,672 SO × 1,045 stores × 105 weeks |
| **P1** | **Intent clarification:** POC history debated whether `planned_sales` is MFP / buy-plan vs promo pricing ([`lululemon_poc_chat_client_questions.md`](lululemon_poc_chat_client_questions.md)). Confirm whether this is the intended Req 11 source or a separate planning feed; if pricing is required, client should specify `price_book`, `promotional_events`, or Anaplan demand columns. | No price columns; 7.4% grain dupes at SO×store×week |

---

## Req 13: `product_attribute_s_seasonal` + `product_attribute_so_seasonal`

### Foundation

| Table | Rows | Size | Sync | Cols |
|---|---:|---:|---|---:|
| `product_attribute_s_seasonal` | 650,404 | 0.08 GB | 2026-06-25 | 20 + sync |
| `product_attribute_so_seasonal` | 1,196,146 | 0.08 GB | 2026-06-25 | 9 + sync |

### Grain

| Table | Grain | Distinct keys | Duplicate rows at grain |
|---|---|---:|---:|
| `_s_seasonal` | `STYLE_ID × QUARTER_ID` | 650,404 | **0** (0.00%) |
| `_so_seasonal` | `STYLE_OPTION_ID × QUARTER_ID` | 1,196,146 | **0** (0.00%) |

GCS streaming EDA reported 675 dupes (0.10%) on `_s_seasonal`; BQ load is clean at grain (650,404 rows = 650,404 distinct keys).

| Table | Distinct styles / SO | `QUARTER_ID` range | Quarters in `calendar_hierarchy` |
|---|---:|---|---|
| `_s_seasonal` | 85,861 styles | `20151`–`20274` | 52 / 52 (100%) |
| `_so_seasonal` | 439,930 style options | `20151`–`20273` | 51 / 51 (100%) |

### Completeness (key forecasting attributes)

**`product_attribute_s_seasonal`:**

| Column | Missing / `\N` | % of rows |
|---|---:|---:|
| `PRODUCT_LIFE_STAGE_STYLE` | 640,032 | 98.41% |
| `SEASONAL_STYLE_TYPE` | 477,014 | 73.34% |
| `FLEX_STATUS` | 476,530 | 73.27% |
| `GLOBAL_PRODUCT_SEASONAL_NEWNESS_STYLE` | 393,739 | 60.54% |
| `SIZE_RANGE` | 305,805 | 47.02% |

**`product_attribute_so_seasonal`:**

| Column | Missing / `\N` | % of rows |
|---|---:|---:|
| `FLEX_STATUS` | 586,176 | 49.01% |
| `SEASONAL_COLOURWAY_TYPE` | 586,199 | 49.01% |
| `PRODUCT_SEASONAL_NEWNESS` | 564,474 | 47.19% |

When populated, **`FLEX_STATUS`** on `_s_seasonal`: `\N` 73.27%, `Active` 16.31% (106,103), `Drop` 10.41% (67,739).

When populated, **`SEASONAL_COLOURWAY_TYPE`** on `_so_seasonal`: `\N` 49.01%, `New` 40.87% (488,912), `Carryover` 10.12% (121,035).

**`GLOBAL_PRODUCT_SEASONAL_NEWNESS_STYLE`** (populated rows only): `Existing` 20.87%, `Non Comp` 12.52%, `New` 6.07%.

### Cross-table joins

| Path | Match rate |
|---|---|
| `_s_seasonal.STYLE_ID` → `style_option.STYLE_ID` | 81,800 / 85,861 styles (95.27%) |
| `_s_seasonal.STYLE_ID` → `sku_details.STYLE_CODE` | 0 / 85,861 (0.00%) — different ID systems |
| `_so_seasonal.STYLE_OPTION_ID` → `style_option` | 439,930 / 439,930 (100.00%) |
| `QUARTER_ID` → `calendar_hierarchy` | 100% of distinct quarters |

SKU roll-up path for Req 13: **`STYLE_ID` or `STYLE_OPTION_ID` → `style_option` → SKU mapping** (not direct join to `sku_details.STYLE_CODE`). Quarter → date range via `calendar_hierarchy`.

### Client callouts (Req 13)

| Priority | Callout | Evidence |
|---|---|---|
| **P0** | **Quarter grain, not SKU × start/end date.** Req 13 specifies SKU × explicit date range. These feeds are style or style-option × `QUARTER_ID`. Confirm quarter → fiscal start/end via `calendar_hierarchy` is acceptable, and provide authoritative SKU mapping from style/style-option. | 52 quarters; no row-level start/end dates |
| **P0** | **Heavy sparsity on key attrs.** `FLEX_STATUS` and `SEASONAL_STYLE_TYPE` are ~73% `\N` at style level; `PRODUCT_LIFE_STAGE_STYLE` is 98% empty. Ask client which attributes are mandatory for ForecastSmart vs optional planning metadata. | Completeness table above |
| **P1** | **Two complementary feeds at different grains.** `_s_seasonal` (style × quarter, 20 cols) and `_so_seasonal` (colourway × quarter, 9 cols) both map to Req 13. Confirm both are in scope and which model features consume which feed. | 650K vs 1.2M rows; different column sets |

---

## Req 14: `eligibility`

### Foundation

| Metric | Value |
|---|---|
| Rows | 241,782,410 |
| Size | 16.7 GB |
| Sync | `2026-06-25` (1 batch) |
| Columns | 7 + `SYNCSTARTDATETIME` (all STRING except sync) |

### Grain

| Metric | Value |
|---|---|
| Declared grain | `PLANNING_STYLE_OPTION_ID × STORE_ID × WEEK_ID` |
| Distinct grain keys | 230,521,420 |
| Duplicate rows | 11,260,990 (4.66% of rows) |
| Approx distinct PSO | 67,581 |
| Approx distinct stores | 1,195 |
| Approx distinct weeks | 261 |
| `WEEK_ID` range | `202201` to `202652` |
| `WP_FIRST_SELLING_DAY_ID` range | `2021-01-19` to `2026-12-29` |

**Duplicate quality:** among duplicate grain groups, **5,478,825** groups have conflicting `WP_WEEKS_AT_REG_PRICE`; **8,533,734** groups have conflicting `WP_FIRST_SELLING_DAY_ID`. Duplicates are not exact repeats.

### Numerical / categorical

**`WP_WEEKS_AT_REG_PRICE` (top 5):**

| Value (weeks) | Rows | % of rows |
|---:|---:|---:|
| 13 | 107,353,310 | 44.40% |
| 6 | 29,367,665 | 12.15% |
| 9 | 21,675,559 | 8.96% |
| 8 | 14,552,378 | 6.02% |
| 14 | 11,037,039 | 4.56% |

Mean reg-price weeks (GCS baseline): ~10.56.

**`QUARTER_NAME`:** roughly even spread across recent quarters (~6% each for Q1 2025, Q4 2024, Q2 2022, etc.).

### Time horizon (future feed)

| Metric | Rows | % of rows |
|---|---:|---:|
| `WP_FIRST_SELLING_DAY_ID > CURRENT_DATE()` | 8,358 | 0.0035% |

Despite `WEEK_ID` extending to `202652`, almost all first-selling days are historical or current. True "future eligibility" rows are extremely thin.

### Cross-table joins

| Join | Match rate |
|---|---|
| Distinct PSO → `style_option.PLANNING_STYLE_OPTION_ID` | 66,140 / 67,712 (97.68%) |
| Row-level → `style_option` | 228,557,490 / 241,782,410 (94.53%) |
| Unmatched distinct PSO | 1,572 |
| Distinct stores → `location_details.ID` | 1,084 / 1,195 (90.79%) |

StyleColor / SKU derivability: join `eligibility` → `style_option` on `PLANNING_STYLE_OPTION_ID` to get `STYLE_OPTION_ID`, `STYLE_ID`, `COLOURWAY_ID`; expand to SKU via product mapping (not direct in this table).

### Client callouts (Req 14)

| Priority | Callout | Evidence |
|---|---|---|
| **P0** | **Grain is PSO × store × week, not SKU × store × date range.** Req 14 asks for SKU-level eligibility with start/end dates. Confirm client accepts planning-style-option grain or will provide SKU-level eligibility. | 7 columns; no `SKU_ID` |
| **P0** | **4.66% duplicate rows with conflicting attributes** at the declared grain (11.3M extra rows). ~5.5M groups disagree on `WP_WEEKS_AT_REG_PRICE`; ~8.5M on first-selling day. Ask for authoritative dedup rule. | Grain duplicate analysis |
| **P1** | **Future horizon is very thin.** Only 8,358 rows (0.0035%) have a future first-selling day vs Req 14 "future feed". Confirm expected forward window, refresh cadence, and whether week-level planning rows substitute for explicit start/end dates. | `WP_FIRST_SELLING_DAY_ID > today` |

---

## BQ vs GCS reconciliation

| Table | GCS rows (Jun 29 EDA) | BQ rows | Notes |
|---|---:|---:|---|
| `product_attribute_s_seasonal` | 650,404 | 650,404 | Match; GCS had 675 grain dupes, BQ has 0 |
| `product_attribute_so_seasonal` | 1,196,146 | 1,196,146 | Match |
| `eligibility` | 241,782,410 | 241,782,410 | Match; 5.21% GCS dupes → 4.66% BQ |
| `planned_sales` | Not streamed in Jun 29 pass | 115,687,669 | First BQ profile |

---

## Recommended next steps

| Owner | Action |
|---|---|
| **Client** | Confirm Req 11 source: is `planned_sales` planning/MFP, or should pricing come from `price_book` / promo calendar? |
| **Client** | Confirm Req 13 mandatory seasonal attributes and accept quarter → date mapping |
| **Client** | Confirm Req 14 grain (PSO vs SKU) and dedup rule for eligibility duplicates |
| **IA** | Derive quarter start/end dates from `calendar_hierarchy` for seasonal attrs |
| **IA** | Build PSO → SKU eligibility expansion via `style_option` + product mapping |
| **IA** | Do not use `planned_sales` alone for promo pricing features without a price signal join |
