# GCS streaming EDA review: PO, product seasonal attributes, eligibility

`Scan date: 2026-06-29`

Scope: streaming EDA directly from GCS CSVs. No BigQuery tables were created and no GCS files were downloaded in full.

## Summary

| Requirement | Source scanned | Rows scanned | Verdict vs requested grain | What is in the data |
|---|---:|---:|---|---|
| Purchase Order | 16 shards | 10,401,503 | Partial | PO x SKU x receiving location. No PO line id column. |
| Product Time Dependent Attributes | 32 shards | 1,846,550 | Partial | Style/style-option x quarter seasonal attributes, not explicit start/end dates. |
| SKU-Store Allocation Eligibility | 64 shards | 241,782,410 | Partial | Planning style option x store x week eligibility. |
| StyleColor-Store Eligibility | style_option + 1 eligibility shard overlap | 469,512 style rows + 3,779,130 eligibility rows | Partial | Derivable through style_option mapping, not a standalone feed. |

## Purchase Order

Source: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/purchase_orders/`

| Metric | Result |
|---|---|
| Files scanned | 16 |
| Rows | 10,401,503 |
| Columns | 15: `PURCHASE_ORDER_ID, SKU_ID, LOCATION_ID_RECEIVING, UNITS_ORDERED, UNITS_SHIPPED, UNITS_RECEIVED, UNITS_ALLOCATED, UNITS_AVAILABLE, DATE_CREATED, DATE_SCHEDULED, DATE_SHIPPED, DATE_EXPECTED_DELIVERY, DATE_RECEIVED, PO_LINE_STATUS, TYPE_NAME` |
| Purchase orders | ~1,485,364 approximate distinct |
| SKUs | ~673,830 approximate distinct |
| Grain key estimate | ~10,303,255 distinct `(PURCHASE_ORDER_ID, SKU_ID, LOCATION_ID_RECEIVING)` |
| Duplicate estimate at grain | 98,248 (0.94% of rows) |
| PO line id | Not present |
| DATE_CREATED range | `2001-09-09` to `2025-11-18` |
| DATE_EXPECTED_DELIVERY range | `2016-11-01` to `2031-01-01` |
| DATE_RECEIVED range | `2016-11-01` to `2025-11-18` |
| DATE_SHIPPED range | `2016-09-28` to `2025-11-24` |
| Future expected-delivery rows | 20,155 (0.19% of rows) |

Top `PO_LINE_STATUS` values:

| Value | Rows |
|---|---:|
| `CLOSED` | 8,710,858 (83.75% of rows) |
| `CANCELLED` | 1,023,364 (9.84% of rows) |
| `APPROVED` | 493,883 (4.75% of rows) |
| `SHIPPED` | 141,679 (1.36% of rows) |
| `FULLY RECEIVED` | 23,102 (0.22% of rows) |

Unit fields:

| Field | Positive | Zero | Average | Max |
|---|---:|---:|---:|---:|
| `UNITS_ORDERED` | 9,300,838 (89.42% of rows) | 1,100,665 (10.58% of rows) | 92.12 | 142,774 |
| `UNITS_RECEIVED` | 8,681,717 (83.47% of rows) | 1,719,786 (16.53% of rows) | 87.61 | 143,254 |
| `UNITS_SHIPPED` | 644,179 (6.19% of rows) | 9,757,324 (93.81% of rows) | 5.33 | 22,205 |
| `UNITS_ALLOCATED` | 0 (0.00% of rows) | 10,401,503 (100.00% of rows) | 0.00 | 0 |
| `UNITS_AVAILABLE` | 8,665,276 (83.31% of rows) | 1,736,227 (16.69% of rows) | 86.78 | 142,774 |

Interpretation: this is a usable PO source, but it is not true SKU x PO x PO line grain because no PO line id exists in the raw header. The practical grain is PO x SKU x receiving location, with status and receive/ship/expected-delivery dates.

## Product Time Dependent Attributes

Sources:

- `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_s_seasonal/`
- `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_so_seasonal/`

| Feed | Rows | Key | Quarter range | Distinct key | Distinct key-quarter | Duplicate estimate |
|---|---:|---|---|---:|---:|---:|
| `product_attribute_s_seasonal` | 650,404 | `STYLE_ID` | `20151` to `20274` | ~83,557 | ~649,729 | 675 (0.10% of rows) |
| `product_attribute_so_seasonal` | 1,196,146 | `STYLE_OPTION_ID` | `20151` to `20273` | ~431,554 | ~1,203,251 | 0 (0.00% of rows) |

Important populated attributes:

| Feed | Attribute | Top values |
|---|---|---|
| style seasonal | `FLEX_STATUS` | `<missing>` 476,530 (73.27% of rows), `Active` 106,103 (16.31% of rows), `Drop` 67,739 (10.41% of rows) |
| style seasonal | `SEASONAL_STYLE_TYPE` | `<missing>` 477,014 (73.34% of rows), `Carryover` 95,619 (14.70% of rows), `New` 77,771 (11.96% of rows) |
| style seasonal | `GLOBAL_PRODUCT_SEASONAL_NEWNESS_STYLE` | `<missing>` 393,739 (60.54% of rows), `Existing` 135,750 (20.87% of rows), `Non Comp` 81,445 (12.52% of rows) |
| style-option seasonal | `FLEX_STATUS` | `<missing>` 586,176 (49.01% of rows), `Active` 333,860 (27.91% of rows), `Drop` 263,371 (22.02% of rows) |
| style-option seasonal | `SEASONAL_COLOURWAY_TYPE` | `<missing>` 586,199 (49.01% of rows), `New` 488,912 (40.87% of rows), `Carryover` 121,035 (10.12% of rows) |
| style-option seasonal | `PRODUCT_SEASONAL_NEWNESS` | `<missing>` 564,474 (47.19% of rows), `existing` 273,639 (22.88% of rows), `non comp` 248,989 (20.82% of rows) |

Interpretation: these feeds are time-dependent, but by fiscal quarter (`QUARTER_ID`), not explicit SKU x start date x end date. To produce the requested date range, join `QUARTER_ID` to `calendar_hierarchy` quarter start/end dates, then map style/style-option down to SKU.

## SKU-Store Allocation Eligibility

Source: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/eligibility/`

| Metric | Result |
|---|---|
| Files scanned | 64 |
| Rows | 241,782,410 |
| Columns | 7: `PLANNING_STYLE_OPTION_ID, STORE_ID, WEEK_ID, QUARTER_NAME, WP_FIRST_SELLING_WEEK_ID, WP_FIRST_SELLING_DAY_ID, WP_WEEKS_AT_REG_PRICE` |
| Planning style options | ~67,781 approximate distinct |
| Stores | ~1,194 approximate distinct |
| Weeks | ~261 approximate distinct |
| Grain key estimate | ~229,176,008 distinct `(PLANNING_STYLE_OPTION_ID, STORE_ID, WEEK_ID)` |
| Duplicate estimate at grain | 12,606,402 (5.21% of rows) |
| `WEEK_ID` range | `202201` to `202652` |
| First selling day range | `2021-01-19` to `2026-12-29` |
| Future first-selling-day rows | 9,268 (0.004% of rows) |
| `WP_WEEKS_AT_REG_PRICE` average | 10.56 weeks |

Top `WP_WEEKS_AT_REG_PRICE` values:

| Value | Rows |
|---|---:|
| `13` | 107,353,310 (44.40% of rows) |
| `6` | 29,367,665 (12.15% of rows) |
| `9` | 21,675,559 (8.96% of rows) |
| `8` | 14,552,378 (6.02% of rows) |
| `14` | 11,037,039 (4.56% of rows) |

Interpretation: this is not raw SKU-store eligibility. It is planning style option x store x week eligibility. It can become SKU-store-date eligibility only after joining to product/style-option/SKU mapping and converting week/quarter to dates.

## StyleColor-Store Eligibility

Sources: `style_option` plus `eligibility`.

| Metric | Result |
|---|---|
| `style_option` rows | 469,512 |
| Style options | ~466,199 approximate distinct |
| Styles | ~80,733 approximate distinct |
| Colourways | ~47,354 approximate distinct |
| Planning style options | ~461,044 approximate distinct |
| Primary style-option rows | 466,026 (99.26% of rows) where `IS_PRIMARY_STYLE_OPTION=true` |
| Deleted rows | 19 (0.004% of rows) where `DELETE_IND=true` |
| Placeholder rows | 9,451 (2.01% of rows) where `PLACEHOLDER_FLAG=true` |
| Eligibility overlap sample | 3,572,082 (94.52% of sampled eligibility rows) matched to `style_option` by `PLANNING_STYLE_OPTION_ID` |
| Matched PSO estimate in overlap sample | ~59,186 (98.01% of sampled eligibility PSO estimate) |
| PSOs with multiple style options | 2,331 (0.50% of style-option PSOs) |
| PSOs with multiple colourways | 102 (0.02% of style-option PSOs) |

Interpretation: there is no standalone StyleColor-store eligibility feed. It is derivable: `eligibility.PLANNING_STYLE_OPTION_ID` joins to `style_option.PLANNING_STYLE_OPTION_ID`, which supplies `STYLE_OPTION_ID`, `STYLE_ID`, and `COLOURWAY_ID`. The resulting derived grain is style color/store/week, not explicit style color/store/start/end date until weeks are mapped to dates.

## Artifacts

| Artifact | Purpose |
|---|---|
| `findings/gcs_feed_eda_purchase_orders_20260629.json` | Generated EDA metrics |
| `findings/gcs_feed_eda_product_attribute_s_seasonal_20260629.json` | Generated EDA metrics |
| `findings/gcs_feed_eda_product_attribute_so_seasonal_20260629.json` | Generated EDA metrics |
| `findings/gcs_feed_eda_eligibility_20260629.json` | Generated EDA metrics |
| `findings/gcs_feed_eda_stylecolor_overlap_20260629.json` | Generated EDA metrics |
| `findings/gcs_feed_eda_review_20260629.csv` | Generated EDA metrics |

Note: Distinct counts are approximate for memory safety on large feeds. Row counts, null counts, min/max ranges, and top-value counts are exact for the streamed rows.
