# Lululemon Final SOW - Demand Forecasting and Sizing

**Status:** Latest finalized client SOW for Demand Forecasting and Sizing table-delivery alignment.

**Source file:** [`lululemon_impact_analytics_sow_2026-06-25_final_demand_forecasting_and_sizing_sj.docx`](./lululemon_impact_analytics_sow_2026-06-25_final_demand_forecasting_and_sizing_sj.docx)

**Source received:** 2026-06-25 from user download `Demand Forecasting and Sizing lululemon - SJ.docx`.

**Use this for:** final scope, deliverables, table-delivery expectations, milestones, assumptions, and client-facing alignment. If this extract conflicts with the `.docx`, the `.docx` is authoritative.

## Extracted Text

Demand Forecasting and Sizing

The purpose of this Statement of Work (“SOW”) is to define the scope, deliverables, service levels, and commercial terms under which you will provide sizing, demand forecasting and related analytics services to lululemon athletica inc. (“lululemon”). This SOW establishes the framework for the Vendor’s provision of services in support of lululemon’s business objectives, including but not limited to sizing, demand forecasting, performance monitoring, and optional capabilities as expressly authorized by lululemon.

The scoping is for the use of the supplier’s logic and model, and not the applications or UI as that will not be procured to be used nor be part of the commercial model provided.

Timeline, Price, Implementation Time Frame, and Current Capabilities

Model Behaviour and Output Quality (Sizing)

Deliverables shall conform to the requirements set forth in Section 7 (Sizing Track), including, where applicable:

generation of size curves at the required granularity (Location × StyleOption × Quarter (Fiscal))

adherence to productlevel inference requirements, except where alternative behaviour is expressly permitted;

appropriate implementation of submarket channel fallback behaviour, where applicable; and

inclusion of influential style outputs meeting the minimum required criteria, where specified.

Deliverables

Daily Data refreshes

This will be completed regionally (APAC/China, NAM, EMEA once daily full refreshed and 3 x/region/day delta/incremental refresh at a minimum

Forecasting Track

Phase One: Forecasting MVP (Interim)

Vendor shall provide unit-level demand forecasts with statistical confidence intervals across all products and markets

15 Week SKU (or analogous) Store Sate Forecast

Forecast horizon shall include current week + 15 forward weeks at minimum

SKUs (or analogous) x Store/DC x Week (Flow 1.0)

DC level forecast is used for ECOM purposes

SKUs (or analogous) x Store/DC x Day (Flow 1.0)

DC level forecast is used for ECOM purposes

Disaggregation from week today is acceptable based on agreed upon methodology

Vendor shall demonstrate improvement across three (3) UAT iterations prior to go-live. They demonstrate measurable improvement against the existing baseline set during POV across those iterations, including reduced bias and improved forecast accuracy existing (replenishment) and new products (allocation) referenced within Appendix A.

Sizing Track

Design intent:

Merchants have expressed a clear preference for size profiles:

Near Real-Time Adjustment Capability (Daily in Phase 1, 3X per day in Phase 2)

Modification to size profiles (add/remove influential styles), or introduction of NEW styles that require profiling must be supported on the cadence.

The system must support rapid updates without requiring full model retraining

Statistical Update Requirement

Phase 1 - Size Curves MVP (Interim). Interim Solution will be delivered every quarter in line with lululemon Go-To-Market milestones.

Quarter/style option/store-level size curves for both new and existing upcoming or immediately passed buying season for evaluation

lululemon reserve the right to trigger a re-inference or create new curve ad-hoc, at most once per day.

The system must support rapid updates without requiring full model retraining

UAT iterations prior to go-live and commitment of fixes to all critical bugs/issues

Comparable influential style outputs by Style Option tailored to each Market (APAC, China, NAM, EMEA)

Comp style explainability based on product attribute logic (as demonstrated in POV)

Sizing Logic

Size curves generated at the Quarter / Style Option / store level for analysis

If data for any store is insufficient or incomplete, the output would default to submarket channel curve appropriate for that Style Option/store

Size curves generated aggregated from the store level size curves at the Quarter / Style Option/ Submarket level for system integration

Reporting Requirement

The vendor shall provide reporting outputs monthly sufficient to evaluate model performance, including

Accuracy Metrics based on backtesting

WAPE or equivalent agreed metric at defined grain

Size-level distribution accuracy

Drift Monitoring

Detection of material changes in curve behaviour over time

Identification of model degradation or instability

Explainability Diagnostics

Visibility into influential styles contributing to outputs

Supporting data to assess model behaviour

Data Quality Indicators

Flags for insufficient data

Fallback usage indicators

All reporting must be made available in a format accessible to lululemon for independent validation

Appendix A: Forecast model acceptance criteria

All the below forecast model acceptance criteria will apply for back-testing period mutually agreed upon by lululemon and IA teams.

Guiding Principles for accuracy measurement and acceptance criteria during the back-testing window

Accuracy requirements scale with business impact (volume contribution)

Metrics must reflect true demand signal, not artifacts of low-volume data

Distribution-based evaluation prevents masking of poor SKU-level performance

Metrics & thresholds must be defined such that the intent of business decisions are met while not enforcing too strict thresholds on model performance

WAPE requirements for back-testing of forecast models

Requirements for 52-week PSO-Country Sub-market-Week level forecast WAPE measurements during back-testing periods -

WAPE will be evaluated within each demand contribution segments created at PSO Country Month level and market/channel combination for a back-testing window

Forecast accuracy for back-testing will be evaluated using fixed, volume based strata:

High Contribution: 0-60% of cumulative demand

Mid Contribution: 60-90% of cumulative demand

Low Contribution: 90-100% of cumulative demand

Strata will be determined by ranking items in descending order of actual demand over the evaluation period and assigning them based on cumulative contribution

Strata assignments will be determined for each measurement period separately

Required WAPE by Channel X Regions -

| Demand Contribution Strata | NAM Retail | NAM ECOM | APAC Retail | APAC ECOM | China Retail | China ECOM | EMEA Retail | EMEA ECOM |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0-60% (High) | ≤40% | ≤40% | ≤45% | ≤45% | ≤45% | ≤45% | ≤45% | ≤45% |
| 60-90% (Mid) | ≤60% | ≤60% | ≤65% | ≤65% | ≤65% | ≤65% | ≤65% | ≤65% |
| 90-100% (Low) | ≤80% | ≤80% | ≤85% | ≤85% | ≤85% | ≤85% | ≤85% | ≤85% |

Acceptance rules -

Each stratum must meet its corresponding WAPE threshold

Lululemon and IA teams can mutually agree to relax the acceptance criteria for certain sub-market channel x strata combinations if data quality / sparsity renders modelling to be extremely difficult

Requirements for 17-week PSS-Store-Day level model during back-testing periods

Model performance will be measured separately based on Rate of Sales (ROS) of products:

High ROS - Products showcasing an average ROS of 20 units or higher at a PSS-Store-Week level for the back-testing period

Low ROS - Products showcasing an average ROS of 20 units or lower at a PSS-Store-week level for the back-testing period

Acceptance criteria for High ROS products:

WAPE measurement at a PSS X Store X Week level

WAPE acceptance levels-

| ROS Category | NAM Retail | NAM ECOM | APAC Retail | APAC ECOM | China Retail | China ECOM | EMEA Retail | EMEA ECOM |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| High ROS WAPE | ≤50% | ≤50% | ≤55% | ≤55% | ≤55% | ≤55% | ≤55% | ≤55% |

Acceptance criteria for Low ROS products:

Week of supply Deviation (WOSD) will be evaluated for each PSS-Store and calculated using the ration of the Unit Deviation of forecasts (Forecast Units - Actual Units) with the Average Rate of Sale of each PSS-Store during the Back-testing window. WOSD shows how the error in terms of weeks of inventory deviation

WOSD acceptance levels -

| ROS Category | NAM Retail | NAM ECOM | APAC Retail | APAC ECOM | China Retail | China ECOM | EMEA Retail | EMEA ECOM |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Low ROS WOSD | ±3WOSD/80% | ±3WOSD/ 80% | ±4WOSD/ 80% | ±4WOSD/ 80% | ±4WOSD/ 80% | ±4WOSD/ 80% | ±4WOSD/ 80% | ±4WOSD/ 80% |

± XX WOSD / YY% denotes that YY% or more PSS-Store combinations should fall within the ± XX WOSD error range

Acceptance rules -

WAPE thresholds are met for all High ROS category

WOSD thresholds are met for all Low ROS category

Failure in any of the above constitutes review of models and further improvement steps

Conditions & Exclusion of acceptance criteria

All the above acceptance criteria are valid only if there are no major shifts in the business goals and strategies such as -

Overhaul of assortments, changes to product life cycles or planning structures

Strategic focus shifts to new / emerging markets and geographies

Overhaul of pricing / promotional / marketing and go to customer strategies

Frequent changes in data and product hierarchies deeming it unfit for mapping and understanding historical behavior

Significant Alterations to Supply Chain or Distribution Network

All the above acceptance criteria are valid only if there are no major external forces disrupting the business performance such as -

Force Majeure Events including but not limited to acts of God (e.g., natural disasters such as floods, earthquakes, pandemics), acts of war, terrorism, civil unrest, labor strikes, and government-imposed lockdowns or trade restrictions

Sudden and Significant Shifts in Economic Conditions like huge inflation / deflation and economic depressions

Regulatory and Legislative Changes like imposition of new tariffs, taxes, import/export restrictions

Disruptions in Raw Material or Component Supply like a single-source supplier going out of business, a widespread crop failure etc.

Unforeseen Competitor Actions like the unexpected launch of a revolutionary new product, an aggressive and sustained price war, or the sudden exit of a major competitor from the market

Unforeseen media / PR driven change in customer perception leading to a volatile business scenarios
