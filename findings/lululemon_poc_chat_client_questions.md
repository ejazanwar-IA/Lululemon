# Lululemon POC-Derived Client Questions

This list converts unresolved or repeated POC chat issues into concise client-facing questions. Use it selectively. Not every question should be sent at once.

## Priority Questions

| Topic | Client-facing question | Why we need it | Evidence from POC chat |
|---|---|---|---|
| Product grain | For sizing and size curves, should Impact Analytics continue using planning style size as the primary grain when multiple SKU IDs map to the same planning style option and size? | Confirms the accepted workaround for missing SO-to-SKU mapping. | Lululemon did not share SO-to-SKU mapping and said size curve calculation happens at planning style size level. |
| Vendor-equivalent SKUs | When different SKU IDs sit under the same planning style option and size, should they always be treated as equivalent vendor variants? | Prevents double-counting or separate size contributions for equivalent products. | Business team said different SKU IDs under same PSO and size are identical from different vendors. |
| Planned sales vs product master | We see style options in planned sales that are not present in product master. Are these expected future/planning-only styles, or should they also appear in product hierarchy / SKU details? | Determines whether to exclude, backfill, or escalate planned-sales coverage gaps. | Chat found around 1,000 missing in one quarter and around 10,000 across the full planned sales table, denominator unclear. |
| Product feed drops | The refreshed product feed appears to remove a large set of SKU IDs versus the prior feed. Are these intentionally out of scope, inactive, or removed by a feed filter? | Product drops can affect forecast, sizing, and allocation coverage. | POC chat mentioned around 285,000 (21.92% of 1.3 million SKU IDs) dropped, with ECOMM + RETAIL doubling explaining a larger apparent gap. |
| Inventory feed coverage | For the latest inventory feed, what date range should be present, and was it generated as a full historical feed or a rolling t-N-day feed? | POC had multiple inventory-feed mistakes, including partial feeds. | One feed was sent from Nov 12 instead of expected t-120; later feed was said to cover Jan 2023 to current. |
| Inventory deltas | If inventory totals shift materially for historical weeks after refresh, should we treat the refreshed feed as corrected source truth even when prior weeks change? | Determines whether to rerun historical outputs or preserve prior baseline. | POC saw 2x to 4x inventory inflation from duplicate aggregation and later residual deltas. |
| Transaction refresh delta | When refreshed transaction data changes historical sales materially, should prior outputs be restated using the refreshed feed? | Avoids comparing outputs built on different data vintages. | POC saw US retail transaction numbers around 30% lower than a prior table after refresh. |
| Forecast source | Which client forecast feed is authoritative for weekly forecast comparison: Anaplan demand forecast or in-season demand forecast? | Prevents mixing client forecast sources. | `inseason_demand_forecast_20251119` existed, but the team still expected Anaplan forecast for weekly comparison. |
| Forecast horizon | For current validation and simulation, should the comparison horizon be 16 weeks from Oct 20, 20 weeks, or 10 holdout weeks plus future weeks? | Ensures deck metrics and table outputs use the same horizon. | Chat references 16-week request, 20-week creation, and 10 prior holdout weeks appended. |
| Discount / promo input | Should future promo assumptions be at product-store-week grain, or is product-country-channel-week acceptable for the current allocation use case? | Promo granularity can materially change forecast rollups. | Early table was product-channel-week; later rebuilt at product-store-week after concern that promo affects forecast significantly. |
| Null workstream products | Are null-workstream / ivivva products out of scope for current forecasting, sizing, and allocation outputs? | Determines whether `workstream IS NOT NULL` should remain a standard filter. | POC identified null workstream rows as ivivva and a source of skewed promo averages. |
| Price book anomalies | If price book contains extreme MSRP changes for a product/location, should IA cap, exclude, or accept those prices as source truth? | MSRP anomalies caused forecast spikes and can break discount calculations. | POC found MSRP ranging from 60,000 to 59 for one case. |
| Local events | Which localized events should be included as forecast features, and can Lululemon provide historical and future event dates by market/store impact? | Events were mentioned as model inputs but the feed coverage was incomplete. | POC discussed marathons, tournaments, Olympics, Yoga Day, MLB Cup, and localized sporting events. |
| MFP / buy plan | Is `planned_sales` intended to serve as an MFP or buy-plan input, or should IA wait for a separate buy quantity / MFP feed? | Sizing outputs need size range and buy-plan context. | Team debated `planned_sales`; client IT reportedly said no MFP feed had been shared. |
| Size range | Is `planned_size_range` in `planned_sales_20251119` the authoritative size range for sizing outputs? | Prevents using an inferred size range when the client has a planning-library source. | POC used planned sales as size range library. |
| Output structure | Is the sizing output structure shared in Teams the latest required format, and should it supersede earlier output expectations? | Avoids late rework on final sizing files. | A sizing output structure PDF was shared late and caused confusion. |

## Internal Caveats To Preserve

These are not necessarily client questions, but should be stated as caveats in analysis notes when relevant.

- If we use `eligibility_cleaned_20251119`, specify whether it is raw client structure or a transformed table.
- If `future_discount_selection_v2` is used, state the week range, grain, and fallback hierarchy used to fill missing product-store history.
- If we compare IA forecast to Lululemon forecast, state whether actuals include LSI or true sales only.
- If day-level forecast is shown, state whether it came from IA day split or an allocation-side split.
- If planned-sales style options are excluded because they are missing in product master, report the excluded count and percentage of planned-sales style options.
- If inventory is refreshed mid-analysis, rerun inventory trend checks before updating any downstream deck numbers.

## Suggested Question Bundles

### Data Refresh Bundle

Use when a new feed lands or historical values shift.

1. Can you confirm the expected date range and scope for each refreshed feed: product, transaction, inventory, price book, eligibility, and planned sales?
2. For feeds that replace prior history, should Impact Analytics restate previous outputs using the refreshed data?
3. Are historical changes in inventory and transaction data expected source-truth corrections, or should they be treated as feed defects?

### Forecast And Promo Bundle

Use before producing forecast comparison or allocation simulation outputs.

1. Which forecast feed is authoritative for weekly comparison against IA forecasts?
2. Should promo assumptions be modeled at product-store-week grain for the current output?
3. How should IA handle extreme MSRP or price book values that create unrealistic discount percentages?

### Sizing Bundle

Use before final sizing outputs.

1. Should IA use planning style size as the sizing grain where SKU-level vendor variants exist?
2. Is `planned_size_range` the authoritative size range source?
3. Should style options present in planned sales but missing in product master be excluded from sizing outputs, or should Lululemon provide additional product hierarchy rows?

## Suggested Slack / Teams Message

```text
Hi team, we are doing a final data-readiness pass before refreshing the forecast, sizing, and allocation outputs. A few items from the prior POC need confirmation so we do not mix table vintages or grains:

1. Which forecast feed should be treated as the authoritative Lululemon forecast for weekly comparison?
2. For sizing, should we continue using planning style size as the grain when multiple SKU IDs exist under the same planning style option and size?
3. For the latest inventory and transaction refreshes, should historical changes be treated as corrected source truth?
4. Is planned_sales_20251119 the authoritative source for planned size range, or should we wait for another buy-plan / MFP feed?

We can proceed with the current assumptions if these are aligned, but wanted to confirm before locking the next output refresh.
```
