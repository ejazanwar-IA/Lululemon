# Lululemon POC Chat Table Reference

Source: copied POC Google Chat. Use this as a starting reference, then verify current schemas and row coverage before querying large tables.

Important: the live outbound dataset name in the POC chat is misspelled as `lululemon_souricng_outbound`. Do not silently correct it in SQL unless the dataset has been renamed.

## Canonical Working Tables

| Table (lululemon_souricng_outbound) | Purpose from chat | Grain or join key | Status / caveat |
|---|---|---|---|
| `product_master` | Product master used for joins to transaction, inventory, forecast, and sizing outputs. | `product_code`; article fields such as `article_original`, `l8_id`, `size`. | Built from `sku_details` and `product_group_hierarchy`, not `planned_sales`. Verify active rows and channel suffix logic before use. |
| `product_master_v2` | Team-created product master variant referenced in planned-sales mismatch checks. | `product_code`, `l8_id`, `size`. | Treat as modeling/team table, not necessarily client source truth. |
| `product_group_hierarchy_cleaned` | Product hierarchy source used to build product master and resolve PSO/PSS fields. | `PLANNING_STYLE_OPTION_CODE`, `planning_style_size_code`, `sku_id_channel`. | Called latest in Dec 16 chat; validate against current project state. |
| `sku_details_cleaned` | SKU detail source used in product master construction. | SKU / article fields. | Cost and sell price from this table were removed from product master in one POC iteration. |
| `transaction_master` | Sales transactions used for actuals, trend checks, forecast accuracy, and discount history. | `product_code`, `store_code`, `date`. | Apply sales filters explicitly. Later refresh materially changed US retail totals. |
| `inventory_master` | Inventory history used for holdout and simulation inventory context. | `product_code`, `store_code`, `date`. | Had duplicate aggregation and partial-feed issues. Always check date coverage and compare to backup when available. |
| `inventory_master_old` | Backup of prior inventory table. | Same as `inventory_master`. | Use only for deltas and regression checks, not current modeling unless explicitly approved. |
| `store_master` | Store, country, channel, active, and DC filtering. | `store_code`. | Used in nearly every filter. Be careful with `dc_flag` type in current BQ context. |
| `fiscal_date_mapping` | Date to fiscal week mapping. | `date`, `fiscal_year_week`. | Core join for week-level analyses. The chat used both `date` and `calendar_date` in snippets, so verify schema before running. |
| `price_book` | MSRP / regular / clearance price source. | `STYLE_OPTION_ID`, `LOC_ID`, effective dates. | MSRP anomalies were linked to forecast spikes. Run outlier and effective-date overlap checks before trusting. |
| `eligibility_cleaned` | Earlier cleaned SSE/eligibility table. | Product/store/channel variant. | Confirmed as manipulated, with product-code and channel concatenations. Avoid as raw client feed. |
| `eligibility_cleaned_20251119` | Updated SSE / eligibility table referenced later. | Product/store eligibility grain. | Called correct updated SSE table on Dec 11. Still validate transformations before client-facing use. |
| `anaplan_demand_forecast_cleaned` | Client forecast feed for Anaplan demand forecast. | `size_code`, `l5_code` as store, `parsed_date`. | Confirmed latest demand forecast on Dec 8 and used for IA vs Lululemon comparison. |
| `inseason_demand_forecast_20251119` | New forecast-like feed shared in Nov. | Product-store-week according to chat, exact grain to verify. | IT was unclear on purpose. Not treated as the weekly Anaplan feed. |
| `master_input_imputed` | LSI / lost-sales imputed table. | `product_code`, `store_code`, `date`, fiscal week fields. | Confirmed Jan 6 as the table for LSI numbers. Prefer over `master_input_imputed_table`. |
| `master_input_imputed_table` | Earlier referenced lost sales table. | Similar to LSI output. | Superseded by `master_input_imputed` in later chat. |
| `master_table` | Modeling master table used for discount selection and product/store attributes. | `product_code`, `store_code`, `date`. | Discount logic relied on `qty_without_returns`, `percent_off`, `msrp`, and `workstream`. |
| `master_validated_table_v3` | Older validated master used in inventory delta comparisons. | `date`, `fiscal_year_week`, `s2_name`, `channel_s`. | Use only for historical comparison if still available. |
| `lululemon_sims_out` | IA simulation / forecast output at week level. | `product_code`, `store_code`, `fiscal_year_week`, `percent_off`. | Jan 7 note says it contained simulation weeks `202538` to `202605` and holdout weeks `202528` to `202537`. |
| `lululemon_sims_out_day_level_w_date` | Day-level forecast/simulation output. | `product_code`, `store_code`, `date`, `percent_off`. | Day-level spikes were investigated; verify day split and pricing before using examples. |
| `future_discount_selection` | Early future discount table. | Initially product-channel-week, later product-store-week. | Had extreme values and wrong grain in early versions. Prefer `future_discount_selection_v2` if available. |
| `future_discount_selection_v2` | Final future discount table referenced after fixes. | `product_code`, `store_code`, `fiscal_year_week`, `percent_off` after transform. | Rebuilt with product-store-week grain, `workstream IS NOT NULL`, and hierarchy fallbacks. |
| `planned_sales` | Possible MFP-like table and size range source. | Size/store or style option fields. | Not formally confirmed as MFP. No SKU-level detail per chat. |
| `planned_sales_20251119` | Updated planned sales / size range library. | `STYLE_OPTION_ID`, `WEEK_ID`, `PLAN_QUARTER_ID`, `planned_size_range`. | Used for size range and planned-sales mismatch checks. |
| `purchase_orders_20251119` | Purchase order feed. | PO/store/product fields; submarket info was found here. | No buy quantity info was confirmed in chat. |
| `location_group_hierarchy_20251119` | Market, submarket, and channel mapping. | `MARKET_ID`, `market_name`, `SUB_MARKET_CHANNEL_ID`, `SUB_MARKET_CHANNEL_NAME`. | Used to derive market, submarket, and channel codes such as `RTL`. |
| `product_attribute_so_cleaned` | Product attributes at style option / SKU-like grain. | `SKU_ID`, product attributes. | Some requested size-curve attributes were expected here. |
| `product_attribute_so_seasonal_cleaned` | Seasonal style option attributes. | `SKU_ID`, quarter/seasonal fields. | Had future data to 20272 per chat. Some requested columns still missing. |
| `product_attribute_s_cleaned` | Style-level product attributes. | Style-level key. | Suggested fallback for missing SO attributes, but still did not contain all requested columns per chat. |
| `cc_target` | Newly added feed mentioned Oct 29. | Unknown from chat. | Needs schema validation before use. |
| `class_location_attribute_seasonal` | Newly added feed mentioned Oct 29. | Class-location-seasonal. | Needs schema validation before use. |

## Modeling And External Project Tables

| Table (project.dataset) | Purpose from chat | Grain or join key | Status / caveat |
|---|---|---|---|
| `ai-ps6060.vsl_bnm.lululemon_usa_ecomm_202433_202445_NA_itr1_validation_size_split_table` | Final forecast table at product-store-week with 20 discount points. | Product-store-week-discount. | Later copied to Lululemon project. Scope appears USA ECOMM validation. |
| `lululemon_souricng_outbound.lululemon_usa_ecomm_202433_202445_NA_itr1_validation_size_split_table` | Copy of the above in Lululemon project. | Product-store-week-discount. | Created Nov 28 per chat. |
| `ai-ps6060.vsl_bnm.lulu_womens_size_store_curve_lulu_approach_us_retail_holdout` | 2025 holdout size curves. | Size-store curve, likely department/product/store scope. | Shared Jan 14. Despite name, chat later said simulation table has all departments. |
| `ai-ps6060.vsl_bnm.lulu_womens_size_store_curve_lulu_approach_us_retail_2025q1` | 2025 Q1 size curves. | Size-store curve. | Shared Jan 14. |
| `ai-ps6060.vsl_bnm.lulu_womens_size_store_curve_lulu_approach_us_retail_simulations` | 2025 simulation size curves. | Size-store curve. | Chat later says this table should have all departments. |

## Join Map From Chat

| Left table | Right table | Join key | Notes |
|---|---|---|---|
| `transaction_master` | `product_master` | `product_code` | Used to map transactions to article and size. |
| `inventory_master` | `store_master` | `store_code` | Used for geography/channel inventory checks. |
| `inventory_master` | `fiscal_date_mapping` | `date` | Used for weekly inventory rollups. |
| `transaction_master` | `store_master` | `store_code` | Used for geography, channel, and DC filters. |
| `transaction_master` | `fiscal_date_mapping` | `date` | Used for weekly sales trends and forecast actuals. |
| `price_book` | `store_master` | `LOC_ID` to `store_code` after cast or padding | Chat used `lpad(LOC_ID, 10, '0')` in one snippet and `CAST` in another. Verify current types. |
| `price_book` | `product_master` | `STYLE_OPTION_ID` to `article_original` / `l8_id` depending query | Verify intended style option field before using. |
| `product_attribute_so_cleaned` | `product_master` | `SKU_ID` to `product_code_original` | Shared Nov 7 as join path for attributes. |
| `product_attribute_so_seasonal_cleaned` | `product_master` | `SKU_ID` to `product_code_original` | Same as above, but seasonal/quarter grain may duplicate rows. |
| `planned_sales_20251119` | `product_master` | `STYLE_OPTION_ID` to stripped `l8_id` | Known mismatch exists. Do not assume full coverage. |
| `location_group_hierarchy_20251119` | store/location outputs | Market and submarket fields | Use for `market`, `sub_market`, `channel` metadata. |
| `anaplan_demand_forecast_cleaned` | `fiscal_date_mapping` | `parsed_date` to `date` | Used for client forecast week rollup. |
| `anaplan_demand_forecast_cleaned` | `store_master` | `l5_code` to `store_code` | Used in comparison query. Confirm `l5_code` semantics. |
| `lululemon_sims_out` | `future_discount_selection_v2` | `product_code`, `store_code`, `fiscal_year_week`, `percent_off` | Used to align IA forecast with selected future discount. |
| `lululemon_sims_out` | `master_input_imputed` | `product_code`, `store_code`, shifted `fiscal_year_week` | Used for LSI actuals and holdout comparison. |

## Product Attribute Fields Requested For Size Curves

The client requested attributes including:

- `COLOUR_BUCKET`
- `COLOUR_EXECUTION`
- `COLOUR_FAMILY`
- `COLOUR_PRINT_TYPE`
- `COLOUR_SEASONALITY`
- `COLOUR_SHADE`
- `GLOBAL_LINE_SEGMENT`
- `GLOBAL_LINE_SEGMENT_STYLE_OPTION`
- `GLOBAL_OFFERING_LIFECYCLE`
- `MATERIAL`
- `SEGMENTATION`
- `QUARTER_ID`
- `GLOBAL_PRODUCT_SEASONAL_NEWNESS_STYLE_OPTION`
- `PRODUCT_LIFE_STAGE_STYLE_OPTION`
- `SEASONAL_COLOURWAY_TYPE`
- `GLOBAL_PRODUCT_SEASONAL_NEWNESS_STYLE`
- `GUEST_FACING_NEWNESS_INDEX`
- `HIGH_ATTENTION_STYLE`
- `PRODUCT_LIFE_STAGE_STYLE`
- `PRODUCT_SEASONAL_NEWNESS_STYLE_CATEGORY`
- `SEASONAL_STYLE_TYPE`

Initial table guidance was `product_attribute_so_cleaned` and `product_attribute_so_seasonal_cleaned`, joined via `SKU_ID` to `product_code_original`. Later, some fields still could not be found in `product_attribute_s_cleaned`. Treat this as an unresolved schema-mapping item.

## Table Version Pitfalls

- `_20251119` suffix does not always mean latest or correct. Some suffixed tables were staging refreshes, while some unsuffixed master tables were overwritten in place.
- Backup names such as `_old` were used for comparison, not necessarily for production use.
- Some tables were created, dropped, or rebuilt during urgent workflows, especially `future_discount_selection_v2`.
- Chat statements like "latest" are time-bound. Always pair any table reference with current row counts, min/max dates, and last modified timestamp.

## Minimum Checks Before Using A Table

1. Confirm the table exists in the expected dataset.
2. Capture row count, min/max date or week, and last modified time.
3. Confirm key grain uniqueness for the intended use.
4. Compare against backup or prior table where a feed refresh could materially change results.
5. Document any known caveat from this reference in the analysis note or deck appendix.
