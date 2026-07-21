# Lululemon POC Chat Findings

Source: copied Google Chat history from the prior Lululemon POC working group, primarily Oct 2025 to Jan 2026.

This note captures reusable project intelligence from the chat. It is not a full transcript summary. It focuses on decisions, data issues, table references, assumptions, and risks that should inform current Lululemon forecasting, sizing, and allocation work.

## Executive Takeaways

- Treat prior POC chat findings as an evidence register, not as final source truth. Several conclusions changed after feed refreshes, table rebuilds, or client clarifications.
- The highest-risk areas were not modeling choices alone. Feed freshness, table versioning, inventory duplication, transaction refresh deltas, price book anomalies, and product hierarchy mismatches materially affected outputs.
- The most reusable operational pattern is: validate raw feed coverage first, then cleaned/intermediate tables, then forecast or sizing outputs. Many POC issues came from trusting downstream tables before rechecking feed coverage and grain.
- PSS / planning style size became the practical sizing grain because Lululemon did not provide the SO-to-SKU mapping and confirmed multiple SKUs under the same planning style option and size can represent identical vendor variants.
- Current work should preserve a small set of canonical filters and known-good table names, especially for transaction filtering, LSI, future discounts, eligibility, and inventory comparisons.

## Decision And Assumption Register

| Area | Decision or assumption | Evidence from chat | Current implication |
|---|---|---|---|
| Product grain | Use PSS / planning style size where SKU mapping is missing or vendor SKUs are equivalent. | Lululemon would not share SO-to-SKU mapping; business team said size curve calculation happens at planning style size level and PSS-level SKU IDs are unique. | Sizing and curve logic should not assume a clean one-to-one SKU relationship unless revalidated. |
| Product master construction | Product master was built from `sku_details` and `product_group_hierarchy`, not `planned_sales`. | Team noted planned sales was not supposed to be used for product master and missing PSOs should be raised as a discrepancy. | Planned-sales coverage gaps should be reported separately, not force-joined into product master. |
| Multiple SKUs | Multiple SKUs under the same article-size can happen and may be vendor-equivalent. | Client said different SKU IDs under same planning style option and size are identical from different vendors. | Quantify duplicates, then aggregate only at a grain that makes business sense. |
| Transaction filter | Use positive demand and valid discount filters for sales truth. | Repeated filters included `qty > 0`, `total_discount_amount >= 0`, selected geographies, `RETAIL` / `ECOMM`, and `dc_flag != 1`. | Keep these filters explicit in EDA, validation, and accuracy queries. |
| Eligible geographies/channels | Core working geographies were United States, China, Canada, plus later APAC and EMEA country sets for global work. | Transaction filters initially used United States, China, Canada; later discount logic included APAC and EMEA countries. | Be explicit about whether a query is North America-focused or global. |
| Eligibility feed | `eligibility_cleaned` was manipulated; raw eligibility is preferred when client-shared structure matters. | Ritik confirmed `eligibility_cleaned` had product-code and channel concatenations and should not be used as raw client shape. | Use `eligibility_cleaned_20251119` only when its transformations are intended and documented. |
| LSI table | Use `master_input_imputed` for latest LSI numbers, not `master_input_imputed_table`. | On Jan 6, Veda confirmed `master_input_imputed` should be used for LSI. | Current LSI calculations should use `master_input_imputed` unless a newer table is confirmed. |
| Future discount table | `future_discount_selection_v2` was the usable discount input after fixes. | Earlier discount tables had grain, week, and extreme-value issues; `future_discount_selection_v2` was later confirmed as the table to use. | Do not use `future_discount_selection` without checking whether it predates fixes. |
| Discount source filter | `workstream IS NOT NULL` is required in discount calculation. | Workstream null rows corresponded to ivivva brand products and could skew higher-level promo averages. | Promo and discount rollups should include this filter unless the scope intentionally includes those products. |
| New stores | New stores can have zero discount if forecasts are also zero for fully new stores. | Team discussed fallback logic and accepted zero discount for new stores where forecast is zero. | If forecasts are nonzero for new stores, revisit this assumption. |
| Forecast output grain | Week-level forecasts were primary; day-level forecasts were created later for allocation simulation needs. | Team agreed to share both week-level and day-level tables; forward weeks only for day split from Oct 20. | Keep week-level forecast as source of truth and document any day split assumptions. |
| Forecast horizon | 16-week future forecasts were requested, but team created 20 weeks plus holdout append. | Chat references 16-week forecast from Oct 20, 20 weeks created, and previous 10 holdout weeks appended. | State exact week coverage when comparing outputs. |
| Forecast comparison | IA forecast should be compared to Lululemon Anaplan forecast using common product-store-week-size keys. | Veda shared a query joining `anaplan_demand_forecast_cleaned`, `lululemon_sims_out`, `future_discount_selection_v2`, and `master_input_imputed`. | Use common filters and aligned grain before making IA vs Lululemon claims. |
| MFP / planned sales | `planned_sales` was considered a possible MFP-like source but lacked SKU-level detail and required joins through hierarchy. | Team debated whether `planned_sales` could be MFP; no formal MFP feed was confirmed by client. | Do not call `planned_sales` MFP without caveat. |
| Size curve availability | 2024 size curves were not available; 2025 holdout and simulation curves were available. | Anshul confirmed no 2024 size curve data; 2025 holdout and simulation tables were shared. | YOY size-curve comparisons may need recalculation for 2024. |

## Known Issues Register

| Issue | What happened | Magnitude or example | Status in chat | Current validation needed |
|---|---|---:|---|---|
| Inventory duplication | Duplicate inventory entries were aggregated during ingestion, inflating inventory. | Chat mentions around 2x to 4x increases in checks before fixes. | Fixed iteratively, but residual deltas were still discussed. | Compare `inventory_master` vs `inventory_master_old` by fiscal week, geography, and channel. |
| Inventory partial feed | Later inventory feed was mistakenly shared from Nov 12 instead of the intended t-120 day range. | Expected around Aug/Sep start, received Nov start. | Re-shared later; Dec 5 message says inventory available Jan 2023 to previous day. | Reconfirm min/max dates and weekly coverage before any holdout or simulation use. |
| Transaction refresh delta | Refreshed transaction feed materially reduced US retail numbers. | Around 30% lower vs old table for US retail; raw-level check mentioned around 35% average sales down. | Raised to client as a mishap from their side. | Rebuild trend checks by feed version and date range. |
| Product master row drop | New product feed dropped many SKU IDs vs prior feed. | Around 285,000 (21.92% of 1.3 million SKU IDs) dropped; user noted 500,000 after ECOMM + RETAIL doubling. | Accepted as client feed behavior. | Quantify dropped active SKUs and whether they appear in transactions, eligibility, planned sales, or forecasts. |
| Planned sales mismatch | Planned sales had style options missing from product master. | Around 1,000 (2.70% of 37,000 style options) for one quarter; around 10,000 across full planned sales table, denominator unclear. | Team proceeded while flagging discrepancy. | Report missing PSOs with percentage of planned-sales style options. |
| Anaplan underforecast | Some Anaplan examples underforecast actuals materially. | Example `LM7BCVS-063781-XL`: about 8 forecast units vs 65 actual units. | Confirmed raw Anaplan matched cleaned table, so underforecast was in client feed. | Use this as a pattern, but select current representative examples with WAPE impact. |
| Discount table wrong grain | Early `future_discount_selection` was product-channel-week, not product-store-week. | User flagged all channels for one product and missing store dimension. | Later rebuilt at product-store-week. | Validate uniqueness at product-store-week and final week range. |
| Discount extremes | Early discount table had extreme final discount values. | Max reported as 327,272,770.0. | Fixed by revised logic and filters. | Check min/max discount and count of values outside 0 to 100. |
| MSRP anomalies | MSRP values in price book or derived product format fluctuated heavily. | Example MSRP ranging from 60,000 to 59 in LY simulation period. | Identified as likely driver of day-level forecast spikes. | Run price outlier and effective-date overlap checks. |
| Day-level forecast spikes | Same product-store-percent_off had highly different daily forecasts across dates. | Product `152975195%`, store `0000050070`, dates Dec 26, 2025 vs Jan 8, 2026. | Root cause suspected as MSRP / pricing fluctuation. | Compare day split, price, discount, and weekly forecast inputs for spike cases. |
| Forecast table ambiguity | `inseason_demand_forecast_20251119` was not the same as expected Anaplan weekly feed. | It had future weeks but IT was unclear on purpose. | Expected to receive Anaplan forecast separately. | Document which forecast table is client forecast source for each analysis. |
| Eligibility versioning | Different eligibility tables existed, including raw and cleaned/suffixed versions. | `eligibility_cleaned_20251119` was later called correct updated SSE table. | Correct table named in chat. | Confirm whether current workflow expects raw eligibility or cleaned SSE table. |

## Reusable Filters And Snippets

Transaction filters repeatedly used in the POC:

```sql
WHERE qty > 0
  AND total_discount_amount >= 0
  AND store_code IN (
    SELECT store_code
    FROM `lululemon-01042025.lululemon_souricng_outbound.store_master`
    WHERE s2_name IN ('United States', 'China', 'Canada')
      AND UPPER(channel) IN ('RETAIL', 'ECOMM')
      AND dc_flag != 1
  )
```

Discount source filter that became important:

```sql
WHERE qty_without_returns > 0
  AND msrp > 0
  AND percent_off < 1
  AND workstream IS NOT NULL
```

## High-Value Questions To Revalidate

- Which table is the authoritative client forecast for the current phase: Anaplan forecast, in-season demand forecast, or a newer feed?
- Are current product, planned sales, eligibility, and price book feeds all aligned to the same refresh date?
- Are missing PSOs from planned sales expected business behavior, or are they feed gaps?
- Should new stores always receive zero forecast and zero discount, or are there cases where channel or market fallback is required?
- Which events are expected to be modeled explicitly: LSI, marathons, tournaments, Olympics, Yoga Day, MLB Cup, tariff periods, or regional campaign events?
- Are ivivva or null-workstream products always out of scope for current forecasting and sizing outputs?

## Immediate Reuse For Current Work

1. Use this file as the working memory of prior POC pitfalls.
2. Pair it with the table reference and validation checklist before trusting any refreshed tables.
3. When drafting client-facing notes, avoid saying a data issue is resolved unless the related validation check has been rerun on the current table version.
