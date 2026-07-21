# GCS feed availability tracker: non-master ForecastSmart requirements

`Scan date: 2026-06-29`

Project: `lululemon-01042025`

Scope: all 40 accessible GCS buckets in the project. The scan used object-name keyword discovery, one-shard header sampling, light row sampling, and read-only BigQuery metadata (`bq ls` / `bq show`). No GCS files were downloaded in full.

## Verdict Summary

| # | Requirement | Ideal grain | Verdict | Best available source | Main gap |
|---:|---|---|---|---|---|
| 7 | Holidays and Store Closure | Event ID x Store ID x Start Date x End Date | Partial | `promotional_events` | No event id column; no dedicated holiday calendar found |
| 8 | Purchase Order | SKU ID x PO ID x PO Line ID | Partial | `purchase_orders` | PO line id absent; feed is PO x SKU x receiving location |
| 9 | ASN | SKU ID x ASN ID x ASN Line ID | Confirmed N/A | None | ASN keyword scan returned zero hits |
| 10 | Receipts | SKU ID x Receipt ID x Receipt Date | Partial | `purchase_orders`, `transfer_orders` | Receive dates and units exist, but no receipt id grain |
| 11 | Future Promotions Pricing | Hierarchy x Week | Partial | `price_book`, `planned_sales`, `SLS_INV`, Anaplan demand | Multiple price/promo signals, no single promo calendar feed |
| 12 | Product attributes | SKU ID | Found, partial BQ | `product_attribute_s`, `product_attribute_so`, Foundation attributes | Style/style-option grain, not raw SKU-only for every attribute |
| 13 | Product Time dependent attributes | SKU ID x Start Date x End Date | Partial | seasonal product attribute feeds | Quarter-bounded, not explicit start/end dates |
| 14 | SKU-Store Allocation Eligibility | SKU ID x Store ID x Start Date x End Date | Partial | `eligibility`, Anaplan allocation tables | PSO/store/week source; SKU/date range available only after downstream mapping |
| 15 | StyleColor-Store Eligibility | Style Color ID x Store ID x Start Date x End Date | Partial | `eligibility` + `style_option` / Foundation product hierarchy | Derivable; no dedicated style-color x store feed found |

## Bucket Scan Result

Accessible buckets: 40.

Source-like CSV evidence was found mainly in 2 buckets (5.0% of accessible buckets):

| Bucket | What it contributed |
|---|---|
| `gs://client_data_lululemon/` | Historic consolidated feeds, `FOUNDATION_DATA` sales/inventory feed, June 25 copied files |
| `gs://lululemon-data-integration/` | Foundation product attributes, product hierarchy, SLS_INV, ecom exports |

Other buckets had relevant platform artifacts but not new raw source CSV feeds:

| Bucket | Relevant artifact type |
|---|---|
| `gs://lulu-ingestion-test/` | Derived SQL files such as `po_master.sql` and `sku_store_eligibility.sql` |
| `gs://lulu-ingestion-uat/` | Derived SQL files such as `po_master.sql` and `sku_store_eligibility.sql` |
| `gs://lulu-sourcing-dev/` | Airflow logs and intermediate SQL artifacts |
| `gs://lulu-size-optimization-data/` | Size/allocation model outputs such as `unit_allocation_df.csv` |
| `gs://lululemon_manual_allocation/` | Gurobi/manual allocation run artifacts, mostly pickles |

The targeted ASN scan returned 0 object-name hits across all 40 buckets (0.0% of accessible buckets). The targeted receipt-name scan also returned 0 object-name hits; receipt availability comes only through received fields inside PO / transfer feeds.

## Evidence by Requirement

### 7. Holidays and Store Closure

Verdict: Partial.

Best source: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/promotional_events/`

| Feed | Files | Size | Sample URI | Header result |
|---|---:|---:|---|---|
| `promotional_events` | 5 | 0.037 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/promotional_events/promotional_events20251118_153621_0_1_0.csv` | `LOC_ID`, `TYPE`, `NAME`, `START_DATE`, `END_DATE`, `DESCRIPTION`, `LOCATION_CLOSED_FLAG` |
| `calendar_hierarchy` | 1 | 0.002 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/calendar_hierarchy/calendar_hierarchy_20251118_152736_0_0_0.csv` | fiscal day/week/month/quarter calendar only |

Light sample results:

| Check | Result |
|---|---|
| `promotional_events` sample rows | 10,001 |
| Date range in sample | `2015-02-16` to `2027-10-01` |
| Store key | `LOC_ID` |
| Closure flag | `LOCATION_CLOSED_FLAG`, populated in sample |
| Event id | Not present |

Recommendation: Treat this as the event/closure candidate. It can satisfy store/date range closure signals, but it does not fully match Event ID x Store ID x Start Date x End Date unless we derive an event id from `TYPE` / `NAME` / dates.

### 8. Purchase Order

Verdict: Partial.

Best source: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/purchase_orders/`

| Feed | Files | Size | Sample URI | Header result |
|---|---:|---:|---|---|
| `purchase_orders` | 16 | 1.309 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/purchase_orders/purchase_orders_20251118_153631_0_0_0.csv` | `PURCHASE_ORDER_ID`, `SKU_ID`, `LOCATION_ID_RECEIVING`, units, dates, `PO_LINE_STATUS`, `TYPE_NAME` |

Light sample results:

| Check | Result |
|---|---|
| Sample rows | 10,001 |
| PO key | `PURCHASE_ORDER_ID` |
| SKU key | `SKU_ID` |
| PO line id | Not present |
| Date created range in sample | `2002-07-10` to `2025-11-18` |
| Expected delivery range in sample | `2018-06-25` to `2027-12-31` |
| Received date range in sample | `2018-06-25` to `2025-11-15` |

BQ metadata:

| Table | Rows | Size | Note |
|---|---:|---:|---|
| `lululemon_souricng_outbound.purchase_orders_cleaned` | 8,226,768 | 1.184 GB | Cleaned POC/outbound table exists |

Recommendation: Use this for PO availability. It is a strong candidate for PO x SKU x receiving location, but client alignment is needed on whether PO line can be inferred or whether PO x SKU is acceptable.

### 9. ASN

Verdict: Confirmed N/A.

Targeted keywords: `asn`, `advance_ship`, `shipment_notice`, `ASN_ID`.

| Check | Result |
|---|---|
| All-bucket object-name hits | 0 |
| Consolidated feed catalog | No ASN feed |
| BQ table metadata | No ASN-like table found in checked datasets |

Recommendation: Keep ASN as a client-confirmed gap. If ForecastSmart requires ASN, it needs a new client feed or an agreed proxy from PO / transfer paths.

### 10. Receipts

Verdict: Partial.

Best sources:

| Feed | Files | Size | Sample URI | Header result |
|---|---:|---:|---|---|
| `transfer_orders` | 64 | 26.373 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/transfer_orders/transfer_orders_20251118_153952_0_0_0.csv` | `TRANSFER_ORDER_ID`, `SKU_ID`, sending/receiving locations, `UNITS_RECEIVED`, `DATE_RECEIVED` |
| `purchase_orders` | 16 | 1.309 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/purchase_orders/purchase_orders_20251118_153631_0_0_0.csv` | `UNITS_RECEIVED`, `DATE_RECEIVED` present |

Light sample results:

| Feed | Sample rows | Received date range | Receipt id |
|---|---:|---|---|
| `transfer_orders` | 10,001 | `2018-09-17` to `2025-07-16` | Not present |
| `purchase_orders` | 10,001 | `2018-06-25` to `2025-11-15` | Not present |

Recommendation: Use PO/transfer received fields only as receipt proxies. There is no true `RECEIPT_ID` source in the scan.

### 11. Future Promotions Pricing

Verdict: Partial.

Candidate sources:

| Feed | Files | Size | Sample URI | What it gives |
|---|---:|---:|---|---|
| `price_book` | 64 | 33.933 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/price_book/price_book_20251118_153454_0_0_0.csv` | style-option x location x effective date prices |
| `planned_sales` | 32 | 11.146 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/planned_sales/planned_sales_20251118_153415_0_0_0.csv` | style-option x store x week planned units |
| `FOUNDATION_DATA/SLS_INV` | 40 | 9.116 GB | `gs://client_data_lululemon/FOUNDATION_DATA/exports/SLS_INV/sales_inventory.csv_0_1_0.csv` | PSO x location x week actual/planning price signals |
| `lululemon-data-integration/FOUNDATION_DATA/SLS_INV` | 256 | 58.345 GB | `gs://lululemon-data-integration/FOUNDATION_DATA/exports/SLS_INV/sales_inventory.csv_0_0_0.csv` | same structure, larger Foundation export |
| Anaplan demand forecast | 32 | 168.769 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/anaplan/demand_forecast/new/TE2.0_EA_Demand_Forecast_pod_01.csv` | regular and discount demand forecast columns |

Header evidence:

| Feed | Key / price columns |
|---|---|
| `price_book` | `STYLE_OPTION_ID`, `LOC_ID`, `EFFECTIVE_FROM_DAY_ID`, `EFFECTIVE_TO_DAY_ID`, `ORIGINAL_PRICE`, `REGULAR_PRICE`, `CLEARANCE_PRICE` |
| `planned_sales` | `PLAN_QUARTER_ID`, `WEEK_ID`, `STYLE_OPTION_ID`, `STORE_ID`, `WP_TOT_REG_SLS_U` |
| `SLS_INV` | `PLANNING_STYLE_OPTION_ID`, `LOC_ID`, `WEEK_ID`, `FIXED_FX_CURRENT_PRICE`, `FIXED_FX_REGULAR_PRICE`, `FIXED_FX_CLEARANCE_PRICE`, `FIXED_FX_AV_COST` |
| Anaplan demand | `Reg Demand Daily Forecast`, `Discount Demand Daily Forecast` |

BQ metadata:

| Table | Rows | Size | Note |
|---|---:|---:|---|
| `lulu_sourcing_dev.price_book` | 440,496,318 | 38.338 GB | Landed raw price book |
| `lululemon_souricng_outbound.anaplan_demand_forecast_cleaned` | 1,984,964,345 | 367.911 GB | Cleaned demand forecast exists |

Recommendation: There is no single clean "future promotions pricing hierarchy x week" file. The best practical approach is a derived feature set using `price_book` for reference prices, `planned_sales` / `SLS_INV` for week-level price signals, and Anaplan demand for regular vs discount forecast indicators.

### 12. Product Attributes

Verdict: Found in GCS, partial in BQ.

Candidate sources:

| Feed | Files | Size | Sample URI | Grain |
|---|---:|---:|---|---|
| `product_attribute_s` | 16 | 0.067 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_s/product_attribute_s20251118_153511_0_0_0.csv` | Style |
| `product_attribute_so` | 16 | 0.110 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_so/product_attribute_so20251118_153538_0_0_0.csv` | Style option |
| `style_option` | 5 | 0.051 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/style_option/style_option_20251118_153938_0_0_0.csv` | Style option mapping |
| Foundation `PRODUCT_ATTRIBUTE` | 32 | 0.073 GB | `gs://lululemon-data-integration/FOUNDATION_DATA/exports/PRODUCT_ATTRIBUTE/product_attributes_style.csv_0_0_0.csv` | Style / style option attributes |
| Foundation `PH` | 8 | 0.466 GB | `gs://lululemon-data-integration/FOUNDATION_DATA/exports/PH/product_hierarchy.csv_0_0_0.csv` | Product hierarchy and style-option mapping |

BQ metadata:

| Table | Rows | Size | Note |
|---|---:|---:|---|
| `lulu_sourcing_dev.product_attribute_s` | 86,135 | 0.059 GB | Only style-level attribute table is landed in sourcing dev |

Recommendation: Product attributes are available, but not all variants are landed in `lulu_sourcing_dev`. To reach SKU-level attributes, use product/style-option mapping through `sku_details`, `style_option`, and product hierarchy.

### 13. Product Time Dependent Attributes

Verdict: Partial.

Candidate sources:

| Feed | Files | Size | Sample URI | Header result |
|---|---:|---:|---|---|
| `product_attribute_s_seasonal` | 16 | 0.089 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_s_seasonal/product_attribute_s_seasonal20251118_153525_0_0_0.csv` | `STYLE_ID`, `QUARTER_ID`, `FLEX_SEASON_CODE`, `FLEX_STATUS`, seasonal fields |
| `product_attribute_so_seasonal` | 16 | 0.082 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_so_seasonal/product_attribute_so_seasonal20251118_153550_0_0_0.csv` | `STYLE_OPTION_ID`, `QUARTER_ID`, `FLEX_SEASON_CODE`, seasonal fields |
| Foundation style-option seasonal | part of 32-file product attribute export | 0.073 GB total for Foundation product attrs | `gs://lululemon-data-integration/FOUNDATION_DATA/exports/PRODUCT_ATTRIBUTE/product_attributes_style_option_seasonal.csv_0_0_0.csv` | `STYLE_OPTION_ID`, `QUARTER_ID`, `PRODUCT_SEASONAL_NEWNESS` |

Light sample results:

| Feed | Quarter range in sample | Season range in sample |
|---|---|---|
| `product_attribute_s_seasonal` | `20151` to `20273` | `15-1SP` to `27-3FA` |
| `product_attribute_so_seasonal` | `20151` to `20272` | `15-1SP` to `27-2SU` |
| Foundation style-option seasonal | `20151` to `20263` | Not explicit in the 3-column file |

Recommendation: Available as seasonal/quarter-bounded attributes. To satisfy Start Date / End Date, map `QUARTER_ID` to fiscal quarter start/end dates using `calendar_hierarchy`.

### 14. SKU-Store Allocation Eligibility

Verdict: Partial.

Candidate sources:

| Feed | Files | Size | Sample URI | Header result |
|---|---:|---:|---|---|
| `eligibility` | 64 | 14.551 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/eligibility/eligibility20251118_152846_0_0_0.csv` | `PLANNING_STYLE_OPTION_ID`, `STORE_ID`, `WEEK_ID`, `WP_FIRST_SELLING_WEEK_ID`, `WP_FIRST_SELLING_DAY_ID`, `WP_WEEKS_AT_REG_PRICE` |
| Anaplan allocation calendar | 33 | 0.661 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/anaplan/allocation_calender/new/pod_id=1/TE2.0_EA_Assortment_Parameters.csv` | Store x planning style option x allocation dates |
| Anaplan FDOD alloc | 33 | 0.082 GB | `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/anaplan/fdod_alloc/new/pod_id=1/TE2.0_EA_FDOD_Alloc.csv` | Planning style option x store x final FDOD |

Light sample results:

| Feed | Sample grain | Date / week range in sample |
|---|---|---|
| `eligibility` | PSO x store x week | `WEEK_ID` `202201` to `202618`; first selling day `2021-11-16` to `2026-04-28` |
| Anaplan allocation calendar | Store x planning style option x quarter | selling dates in sample `2025-04-29` to `2025-08-10` |
| Anaplan FDOD alloc | Planning style option x store | no date column in header |

BQ metadata:

| Table | Rows | Size | Note |
|---|---:|---:|---|
| `lululemon_souricng_outbound.eligibility_cleaned` | 376,110,858 | 44.389 GB | Includes `SKU_ID`, `product_code`, `article` added by downstream mapping |
| `lululemon_souricng_outbound.eligibility_cleaned_20251119` | 2,302,517,438 | 273.577 GB | Larger cleaned snapshot exists |
| `lululemon_souricng_outbound.anaplan_allocation_calendar_cleaned` | 39,230,138 | 7.756 GB | Includes `SKU_ID`, `sku_id_channel` |
| `lululemon_souricng_outbound.anaplan_fdod_alloc_cleaned` | 16,032,486 | 1.551 GB | Includes `SKU_ID`, `sku_id_channel` |
| `lulu_ingestion_uat.product_store_mapping` | 14,973,798 | 3.472 GB | Has SKU/store/start/end eligibility dates |

Derived SQL evidence:

| GCS artifact | What it shows |
|---|---|
| `gs://lulu-ingestion-test/derived_tables/sku_store_eligibility.sql` | Builds article/store/product eligibility from `eligibility_cleaned` and product/store masters |
| `gs://lulu-ingestion-uat/derived_tables/sku_store_eligibility.sql` | Uses `product_store_mapping` with `start_eligibility_date` / `end_eligibility_date` |

Recommendation: Treat allocation eligibility as available but not directly in the requested raw grain. Raw source is PSO/store/week; downstream cleaned/outbound tables map it to SKU/store and, in UAT, to start/end eligibility dates.

### 15. StyleColor-Store Eligibility

Verdict: Partial.

Best source pattern: derive from `eligibility` + `style_option` / Foundation product hierarchy.

| Source | Evidence |
|---|---|
| `eligibility` | PSO x store x week feed with `PLANNING_STYLE_OPTION_ID`, `STORE_ID`, `WEEK_ID` |
| `style_option` | maps `STYLE_OPTION_ID`, `STYLE_ID`, `COLOURWAY_ID`, `PLANNING_STYLE_OPTION_ID` |
| Foundation `PH` | maps `STYLE_ID`, `PLANNING_STYLE_OPTION_ID`, `STYLE_OPTION_ID`, colourway fields |

Sample header from `style_option`:

`STYLE_OPTION_ID`, `STYLE_ID`, `COLOURWAY_ID`, `PLANNING_STYLE_OPTION_ID`, `STYLE_OPTION_NAME`, `IS_PRIMARY_STYLE_OPTION`, `DELETE_IND`, `PLACEHOLDER_FLAG`, `ORIGINAL_STYLE_ID`

Recommendation: No dedicated StyleColor x Store x Start Date x End Date feed was found. It is derivable by joining eligibility to style-option mapping, then mapping week/quarter to fiscal dates.

## BQ Cross-Check Notes

The environment does not currently have `bigquery.jobs.create` on `lululemon-01042025`, so query-job based `INFORMATION_SCHEMA` scans could not run. Metadata-only commands (`bq ls`, `bq show`) worked and were used for table existence, schemas, row counts, and sizes where available.

Relevant landed/cleaned tables found:

| Dataset | Table | Rows | Size |
|---|---|---:|---:|
| `lulu_sourcing_dev` | `price_book` | 440,496,318 | 38.338 GB |
| `lulu_sourcing_dev` | `product_attribute_s` | 86,135 | 0.059 GB |
| `lululemon_souricng_outbound` | `purchase_orders_cleaned` | 8,226,768 | 1.184 GB |
| `lululemon_souricng_outbound` | `eligibility_cleaned` | 376,110,858 | 44.389 GB |
| `lululemon_souricng_outbound` | `eligibility_cleaned_20251119` | 2,302,517,438 | 273.577 GB |
| `lululemon_souricng_outbound` | `anaplan_allocation_calendar_cleaned` | 39,230,138 | 7.756 GB |
| `lululemon_souricng_outbound` | `anaplan_fdod_alloc_cleaned` | 16,032,486 | 1.551 GB |
| `lululemon_souricng_outbound` | `anaplan_demand_forecast_cleaned` | 1,984,964,345 | 367.911 GB |
| `lulu_ingestion_uat` | `product_store_mapping` | 14,973,798 | 3.472 GB |

## Prioritized Next Steps

| Priority | Action | Why |
|---|---|---|
| P0 | Add EDA / ingestion candidate for `purchase_orders` | Strong PO source and already has outbound cleaned table |
| P0 | Add EDA / ingestion candidate for `eligibility` | Unblocks SKU-store and stylecolor-store eligibility after mapping |
| P0 | Add EDA / ingestion candidate for `product_attribute_so`, `_s_seasonal`, `_so_seasonal` | Completes product and time-dependent product attributes beyond current `product_attribute_s` landing |
| P1 | Add EDA / ingestion candidate for `promotional_events` | Best holiday/store closure proxy |
| P1 | Decide receipt proxy | Use PO received fields, transfer received fields, or ask client for true receipts feed |
| P1 | Decide future promo pricing construction | Combine `price_book`, `planned_sales`, `SLS_INV`, and Anaplan demand rather than expecting one perfect file |
| Client question | Confirm ASN is N/A | Scan found zero ASN source files |

