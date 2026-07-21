# Lululemon Forecasting Timelines v3

> **Source:** `lululemon_forecasting_timelines_v3.xlsx`
> **Status:** Latest project timeline reference (Jun 30 2026). If this extract conflicts with the `.xlsx`, the `.xlsx` is authoritative.

---

## Milestone Tracker

| No. | Phase | Milestone | Task owner | Final due date |
|---|---|---|---|---|
|  | No. | Phase | Milestone | Task owner |
|  | 1.0 | Data | Complete data transfer of historical data for all solutions | LL |
|  | 2.0 | Data | Complete data checks & queries | IA |
|  | 3.0 | Data | All party signoff on historical data & data query resolution | LL + IA |
|  | 4.0 | Data | Sign off on transfer mechanism and frequency of periodic transfer | LL + IA |
|  | 5.0 | Data | Complete data ingestion and daily feed set-up | LL + IA |
|  | 6.0 | Data | Completion of discovery & design sessions | LL + IA |
|  | 7.0 | Forecasting | Complete model retraining for US & CA | IA |
|  | 8.0 | Forecasting | Forecasting service readout for US & CA | IA |
|  | 9.0 | Forecasting | Complete SIT - Integration with Lululemon | LL + IA |
|  | 10.0 | Forecasting | Complete fine tuning of models | IA |
|  | 11.0 | Forecasting | Complete model creation for other geographies | IA |
|  | 12.0 | Forecasting | Readout - Other geographies | IA |
|  | 13.0 | Forecasting | Final forecast output handover - All Regions | IA |
|  | 14.0 | Sizing | Complete sizing outputs preparation for US and CA | IA |
|  | 15.0 | Sizing | Sizing outputs handover for US and CA | IA |
|  | 16.0 | Sizing | Complete product configuration of all geographies & internal testing | IA |
|  | 17.0 | Sizing | Complete SIT | IA |
|  | 18.0 | Sizing | Complete UAT | IA |
|  | 19.0 | Sizing | Complete training for all users | IA |
|  | 20.0 | Sizing | Deployment & Go live - All Regions | IA |

## Key deliverables (Forecast track)

| Section 6 — Key Deliverables (Forecast Track & Outbound) |
| --- |
| # |
| 1.0 |
| 2.0 |
| 3.0 |
| 4.0 |
| 5.0 |
| 6.0 |
| 7.0 |

## Deliverable detail (SOW Section 6 summary)

| Area | Requirement | Detail / Notes |
|---|---|---|
| Area | Requirement | Detail / Notes |
| Go-live | Q1 go-live | All deliverables must be completed for a Q1 go-live. |
| Daily data refreshes (Outbound) | Regional incremental refresh | Completed regionally (APAC/China, NAM, EMEA) at a minimum 3× per region per day (delta/incremental). Intended to address new data, new products, or eligibility changes that may materially modify prior inference output. |
|  | Full re-inferencing on request | lululemon may request full re-inferencing to address broader systemic issues in any prior run, or to address the availability of additional relevant data (e.g., actualized sales). |
|  | Model training cadence | IA will work with lululemon to determine when model training is required for larger data updates. |
| Forecasting track | 17-week SKU-Store-Day | 17 week × SKU (or analogous) × Store(Retail)/DC(Ecomm) × Day. Disaggregated to day from the first 17 weeks of the 52-week forecast (method to be mutually agreed). Rollout: International first, then US/CA. |
|  | 52-week SKU-Store | 52 week × SKU (or analogous) × Store(Retail)/DC(Ecomm) × Week. Independently inferenced. Rollout: International first, then US/CA. |
|  | 52-week Style-Color Sub-Market | 52 week × Style-Color (Style-Option) × Submarket Channel × Week. Independently inferenced. Rollout: International first, then US/CA. |
|  | Backtesting & validation | All forecast models must be capable of being backtested and independently validated by lululemon using historical data. |
|  | Unconstrained demand + CI | Unit-level unconstrained demand forecasts with confidence intervals across all products and markets. |
| Forecasting architecture | Phase One | Forecasts may be independently inferenced at each defined level of granularity. |
|  | Phase Two | IA and lululemon work together to develop and test higher and lower levels without using aggregation/disaggregation of another forecast level, to determine whether results provide a better overall forecast architecture. |
|  | Unconstrained, statistical/ML | All outputs must represent unconstrained demand and be derived using statistical or machine learning methods. |
|  | Re-generation triggers | Forecasts re-generated in response to material business or demand events, at a minimum: assortment changes; sales plan updates; significant demand signal changes. |
|  | Daily disaggregation | Daily forecasts generated using statistically valid disaggregation methods incorporating intra-week demand signals. |
| Disaggregation — required | Signal-aware methods | Processes must be data-driven, adaptive and signal-aware: incorporate latest daily sales, inventory and event signals; apply day-of-week normalization to isolate true demand variation; dynamically update forecasts on newly observed data. |
| Disaggregation — prohibited | Static methods not allowed | Must not use static proportional splits; must not use fixed day-of-week curves without signal adjustment. |
| Explainability | UA iterations | Vendor completes User Acceptance (UA) iterations prior to go-live, mutually agreed, with continuous refinement based on data, business reviews, Appendix A and agreed criteria. |
|  | Explainability artifacts | Provide visibility into confidence intervals and forecast uncertainty, and key drivers influencing outputs. Different modelling techniques provide different levels/methods of explainability. Outputs delivered in a format accessible for independent validation. Transfer mechanism agreed during design phase. |
| Change tracking & audit | Audit trail | Maintain a complete audit trail of forecast outputs: timestamp of each update; inputs and signals used to generate each version. |
|  | Reconstruction | System must allow lululemon to reconstruct forecast values and changes at any point in time. |
|  | Methodology explainability | All forecast changes must be explainable from a methodology standpoint. |

## Assumptions

- **#** Assumptions
- **1.0** Current timeline reflects PSS/Store/Week forecast for NA.  EMEA and APAC to follow
- **2.0** The UI will come in phase two for both ForecastSmart & SizeSmart
- **3.0** Size profiles will be shared once a quarter (4 each year) for all regions globally are included in this timeline.
- **4.0** In order to adhere to the timeline, Milestones MUST be met.
- **5.0** Critical milestone is data delivery and sign-off of missing data from October to present and any net new data required for delivery.
- **6.0** Project kick-off 4/20
- **7.0** Line 15 represents 1 week of Discvoery for alignment in case any CR's are required.  The remaining three weeks are for Design.

## Workplan activities (`Workplan_Updated` sheet)

Primary workplan sheet in v3. Week-level scheduling lives in the xlsx.

