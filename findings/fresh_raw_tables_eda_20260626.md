# Fresh Raw Tables EDA Findings

Date: 2026-06-26  
Schema: `lulu_sourcing_dev`  
Scope: fresh read-only EDA on the latest raw sourcing tables. This report does not reuse historical EDA artifacts.

## Executive Summary

Overall readiness is amber. The refreshed raw tables are internally consistent at the ingestion batch level, with all seven tables showing `SYNCSTARTDATETIME = 2026-06-25T00:00:00` and one sync timestamp per table. Key castability is strong for the fields needed in intermediate builds, and the current 2 full prior years plus YTD fact window has continuous daily coverage for both inventory and transactions.

Main flags:

| Status | Area | Finding |
|---|---|---|
| Green | Ingestion batch | All seven raw tables have one sync timestamp: `2026-06-25T00:00:00`. |
| Green | Store masters | `location_details.ID` and `location_group_hierarchy.LOC_ID` are unique and match 1,853 to 1,853 after zero-padding. |
| Green | Product hierarchy | `product_group_hierarchy` has exactly 9 hierarchy rows per SKU and no duplicate `SKU_ID, LEVEL_NAME` groups. |
| Green | Fact grain | In the current 2024-to-YTD scope, inventory has no duplicate `SKU_ID, LOCATION_ID, DATE` groups and transactions have no duplicate transaction-product-store-date groups. |
| Amber | Inventory coverage | Inventory has 169 SKUs and 3 locations in the current scope that do not match the raw product/location masters. |
| Amber | Product attributes | `sku_details.STYLE_CODE` has zero direct matches to `product_attribute_s.STYLE_ID`; this needs mapping clarification before using style attributes downstream. |
| Amber | Prices | `sku_details.COST_PRICE` and `SELLING_PRICE` are both zero for all 988,764 rows, so raw SKU pricing is not usable as-is. |
| Amber | Inventory units | Inventory includes negative quantities and cases where available inventory exceeds on-hand. These are valid to retain only if business semantics confirm them. |
| Amber | Sales shape | `sales_transactions` has a large zero-unit and zero-revenue population; downstream sales logic should explicitly preserve or filter it by business intent. |

Detailed inventory numeric distributions and outlier checks: [`inventory_raw_distribution_eda_20260626.md`](inventory_raw_distribution_eda_20260626.md).

## Raw Table Summary

| Raw table (`lulu_sourcing_dev`) | Columns | Rows | Size GiB | Latest modified | Sync timestamp |
|---|---:|---:|---:|---|---|
| `inventory_snapshot` | 8 | 7,930,649,631 | 507.918 | 2026-06-25 09:48:57 | 2026-06-25T00:00:00 |
| `sales_transactions` | 12 | 683,582,361 | 90.828 | 2026-06-25 09:44:52 | 2026-06-25T00:00:00 |
| `product_group_hierarchy` | 6 | 8,898,876 | 0.542 | 2026-06-25 09:42:37 | 2026-06-25T00:00:00 |
| `sku_details` | 22 | 988,764 | 0.273 | 2026-06-25 09:42:33 | 2026-06-25T00:00:00 |
| `product_attribute_s` | 103 | 86,135 | 0.055 | 2026-06-25 09:42:31 | 2026-06-25T00:00:00 |
| `location_group_hierarchy` | 44 | 1,853 | 0.001 | 2026-06-25 09:42:22 | 2026-06-25T00:00:00 |
| `location_details` | 15 | 1,853 | 0.000 | 2026-06-25 09:42:16 | 2026-06-25T00:00:00 |

## Product Tables

### `sku_details`

`sku_details` has 988,764 rows and 988,764 distinct `ID` values, so `ID` is unique. Required descriptive keys are populated: `ID` and `STYLE_CODE` have no blank or `\N` values.

Useful product counts:

| Metric | Value |
|---|---:|
| Distinct SKUs (`ID`) | 988,764 |
| Distinct items (`ITEM_ID`) | 149,089 |
| Distinct styles (`STYLE_CODE`) | 16,156 |
| Distinct colors (`COLOR_CODE`) | 26,480 |
| Distinct seasons (`SEASON_CODE`) | 1 |
| Distinct size codes (`SIZE_CODE`) | 963,021 |

Pricing is the main issue. `COST_PRICE` casts cleanly, but every row has `COST_PRICE = 0`; every row also has `SELLING_PRICE = 0`. This means SKU pricing should not be treated as populated in the raw master.

### `product_group_hierarchy`

`product_group_hierarchy` has 8,898,876 rows and 988,764 distinct SKUs. It has exactly 9 hierarchy levels per SKU and no duplicate `SKU_ID, LEVEL_NAME` groups, so it can be pivoted safely by SKU and hierarchy level.

| Level | Level name | Rows | Distinct SKUs | Distinct value codes |
|---:|---|---:|---:|---:|
| 1 | `BRAND` | 988,764 | 988,764 | 2 |
| 2 | `DIVISION` | 988,764 | 988,764 | 11 |
| 3 | `DEPARTMENT` | 988,764 | 988,764 | 27 |
| 4 | `CLASS` | 988,764 | 988,764 | 55 |
| 5 | `SUBCLASS` | 988,764 | 988,764 | 104 |
| 6 | `MASTER_STYLE` | 988,764 | 988,764 | 16,156 |
| 7 | `STYLE` | 988,764 | 988,764 | 43,642 |
| 8 | `PLANNING_STYLE_OPTION` | 988,764 | 988,764 | 149,089 |
| 9 | `PLANNING_STYLE_SIZE` | 988,764 | 988,764 | 963,021 |

`sku_details.ID` and `product_group_hierarchy.SKU_ID` have complete 988,764 to 988,764 coverage.

### `product_attribute_s`

`product_attribute_s` has 86,135 rows and 86,135 distinct `STYLE_ID` values, so `STYLE_ID` is unique. The table is wide, with 103 columns, and appears to be a style-level attribute source.

The main gap is joinability. `sku_details` has 16,156 distinct `STYLE_CODE` values, but zero of those match `product_attribute_s.STYLE_ID` directly. Before using this table in a product intermediate build, we need confirm whether a different style key should be used or whether formatting differs between the two sources.

## Store Tables

### `location_details`

`location_details` has 1,853 rows and 1,853 distinct `ID` values. Date and coordinate fields are castable for populated values:

| Check | Bad rows |
|---|---:|
| Missing or bad `ID` | 0 |
| Bad `FIRST_OPEN_DATE` cast | 0 |
| Bad `PERMANANENT_CLOSE_DATE` cast | 0 |
| Bad latitude cast | 0 |
| Bad longitude cast | 0 |

Top location type/channel combinations show that raw locations include both core and non-core locations:

| `TYPE_CODE` | `CHANNEL_CODE` | Rows |
|---|---|---:|
| `RETAIL` | `LLL_NAM_RTL` | 937 |
| `RETAIL` | `LLL_CHINA_RTL` | 279 |
| `RETAIL` | `LLL_APAC_RTL` | 196 |
| `RETAIL` | `LLL_EMEA_RTL` | 89 |
| `OUT_OF_SCOPE` | `LLL_NAM_FO` | 67 |
| `ECOM` | `LLL_EMEA_ECOM` | 30 |
| `DC_ECOM` | `LLL_NAM_ECOM` | 28 |
| `OUT_OF_SCOPE` | `LLL_NAM_STRAT` | 28 |

### `location_group_hierarchy`

`location_group_hierarchy` has 1,853 rows and 1,853 distinct `LOC_ID` values. It has no duplicate location groups. It matches `location_details` 1,853 to 1,853 after zero-padding IDs with `LPAD(..., 10, '0')`.

This table gives richer channel, market, region, area, and format fields. It also confirms that the raw location universe includes retail, ecomm, outlet, strategic, community, virtual, and DC-like locations.

## Inventory Fact

### Full Raw Coverage

`inventory_snapshot` has 7,930,649,631 rows. Full raw business date coverage is from 2023-01-01 to 2025-12-04, with 1,069 distinct dates.

Key castability is strong:

| Field | Bad cast rows |
|---|---:|
| `DATE` to date | 0 |
| `SNAPSHOT_TIME` to timestamp | 0 |
| `UNITS_ON_HAND` to integer | 0 |
| `UNITS_AVAILABLE` to integer | 0 |
| `UNITS_INBOUND` to integer | 0 |

Inventory quantity flags:

| Check | Rows |
|---|---:|
| Negative `UNITS_ON_HAND` | 68,315,032 |
| Negative `UNITS_AVAILABLE` | 86,382,621 |
| Negative `UNITS_INBOUND` | 1,468,893 |
| `UNITS_AVAILABLE > UNITS_ON_HAND` | 2,383,297 |

### Current Downstream Scope

Using the dynamic current scope of 2 full prior years plus YTD, currently `DATE >= 2024-01-01`, inventory retains 5,624,584,333 rows. That is about 70.92% of the full raw table.

Scope coverage:

| Metric | Value |
|---|---:|
| Min date | 2024-01-01 |
| Max date | 2025-12-04 |
| Distinct dates | 704 |
| Missing dates inside range | 0 |
| Duplicate `SKU_ID, LOCATION_ID, DATE` groups | 0 |

Corrected derived channel split in scope:

| Derived channel | Rows | Distinct SKUs | Distinct locations |
|---|---:|---:|---:|
| `RETAIL` | 4,424,383,459 | 980,511 | 1,283 |
| `ECOMM` | 664,754,806 | 973,508 | 103 |
| `NON_CORE` | 535,446,068 | 978,970 | 188 |

The `NON_CORE` inventory rows should be excluded or handled explicitly depending on downstream scope. They represent about 9.52% of current-scope inventory rows.

## Transaction Fact

### Full Raw Coverage

`sales_transactions` has 683,582,361 rows. Full raw transaction date coverage is from 2015-02-02 to 2025-11-18, with 3,943 distinct dates.

Key castability is strong:

| Field | Bad cast rows |
|---|---:|
| `DATE_TRANSACTION` to date | 0 |
| `UNITS` to numeric | 0 |
| `PRICE_SALES_TOTAL` to numeric | 0 |
| `PRICE_SALES_UNIT` to numeric | 0 |

Transaction quantity and revenue shape:

| Metric | Rows |
|---|---:|
| Positive units | 507,969,298 |
| Zero units | 175,612,712 |
| Negative units | 351 |
| Positive revenue | 507,916,095 |
| Zero revenue | 175,665,846 |
| Negative revenue | 420 |

### Current Downstream Scope

Using the dynamic current scope of 2 full prior years plus YTD, currently `DATE_TRANSACTION >= 2024-01-01`, transactions retain 198,154,856 rows. That is about 28.99% of the full raw transaction table.

Scope coverage:

| Metric | Value |
|---|---:|
| Min date | 2024-01-01 |
| Max date | 2025-11-18 |
| Distinct dates | 688 |
| Missing dates inside range | 0 |
| Duplicate transaction-product-store-date groups | 0 |

`SALES_ORDER_ID` and `SALES_ORDER_ITEM_ID` match the synthetic pattern `DATE_TRANSACTION | SKU_ID | LOCATION_ID_SALES` for all 198,154,856 rows in the current scope.

Current-scope transaction split:

| `TRANSACTION_TYPE` | `SALES_SERVICE_TYPE` | Currency | Rows | Distinct SKUs | Distinct locations | Total units | Total revenue |
|---|---|---|---:|---:|---:|---:|---:|
| `GROSS SALE` | `BNM` | `USD` | 158,103,608 | 314,437 | 929 | 139,323,621 | 274,763,918,033.04 |
| `GROSS SALE` | `ECOM` | `USD` | 40,051,248 | 296,637 | 49 | 89,319,355 | 126,666,239,788.34 |

## Cross-Table Coverage

Current-scope inventory and transaction coverage against raw product and location masters:

| Coverage check | Fact distinct keys | Matched keys | Missing keys |
|---|---:|---:|---:|
| Inventory SKUs to `sku_details.ID` | 980,523 | 980,354 | 169 |
| Inventory SKUs to `product_group_hierarchy.SKU_ID` | 980,523 | 980,354 | 169 |
| Inventory locations to `location_details.ID` | 1,574 | 1,571 | 3 |
| Inventory locations to `location_group_hierarchy.LOC_ID` | 1,574 | 1,571 | 3 |
| Transaction SKUs to `sku_details.ID` | 352,250 | 352,250 | 0 |
| Transaction SKUs to `product_group_hierarchy.SKU_ID` | 352,250 | 352,250 | 0 |
| Transaction locations to `location_details.ID` | 978 | 978 | 0 |
| Transaction locations to `location_group_hierarchy.LOC_ID` | 978 | 978 | 0 |

Time alignment:

| Metric | Inventory | Transactions |
|---|---:|---:|
| Min date in current scope | 2024-01-01 | 2024-01-01 |
| Max date in current scope | 2025-12-04 | 2025-11-18 |
| Distinct dates in current scope | 704 | 688 |
| Overlapping dates | 688 | 688 |

Inventory extends 16 days beyond transactions in the current raw data. The two fact tables fully overlap for the transaction date window.

## Readiness Notes

Recommended downstream handling:

- Use `inventory_snapshot` and `sales_transactions` with the dynamic 2 full prior years plus YTD filter to reduce scan volume while preserving the current active modeling window.
- Keep the current store derivation explicit: retail and ecomm should be retained; non-core location types should be excluded or surfaced separately.
- Do not use `sku_details.COST_PRICE` or `SELLING_PRICE` as populated price inputs until pricing source expectations are clarified.
- Do not join `sku_details.STYLE_CODE` directly to `product_attribute_s.STYLE_ID`; this direct join currently has zero coverage.
- Investigate the 169 inventory-only SKUs and 3 inventory-only locations before finalizing production readiness.
- Treat zero-unit/zero-revenue transactions deliberately. They are a material portion of raw sales and should not be silently dropped unless the business rule says so.

## Query Execution Notes

All checks used read-only BigQuery queries. No DDL, DML, table creation, or destructive operations were run.
