# Training Sources

Internal L&D session recordings, notes, and reference PDFs. Archived as reference; cite when relevant to ingestion / QC / project-lifecycle questions.

## Files

| File | Date | Series | Topic |
|---|---|---|---|
| [`DI_Course_3_Ingestion_Basics_for_Analytics_Teams.md`](DI_Course_3_Ingestion_Basics_for_Analytics_Teams.md) | Unknown | Ingestion Basics for Analytics Teams — Course 3 | End-to-end ingestion foundations: pipeline concepts, infrastructure setup, sourcing/extraction/intermediate process, GSM/Generic Master Mapping, QC module, product integration, debugging, and common implementation issues |
| [`L&D_Data_Ingestion_Essentials_Session_3_2026-04-29.md`](L&D_Data_Ingestion_Essentials_Session_3_2026-04-29.md) | 2026-04-29 | Data Ingestion Essentials for Analytics — **Session 3 of 3** | Triggers (file-based `.TRG` vs view-based query rules; mandatory vs non-mandatory; warning + cutoff times); QC module (GSM `is_null_allowed` / `unique_by`, KPI Master, Rule Master, Custom QC); action types (Delete / Report / Pause / Replace); anomaly tables (`_anomaly`, `_anomaly_summary`, `_anomaly_all`); cross-validation QC; Airflow debug flow; QC Summary email |
| [`L&D_Strategic_Account_Planning_2026-04-22.md`](L&D_Strategic_Account_Planning_2026-04-22.md) | 2026-04-22 | Strategic Account Planning (standalone) | DSL responsibilities; project lifecycle (RFP → pre-sales → design → config → SIT → UAT → go-live → hypercare); CR process via Mojo form; pre-discovery; golden data sets; as-is/to-be design gaps |
| [`Quality_Control_QC_Module.pdf`](Quality_Control_QC_Module.pdf) | Unknown | QC module reference | Concise 7-page QC primer: validated-table checkpoint before final master table; GSM null and `unique_by` checks; KPI Rule Master action types (`Report`, `Pause`, `Delete`, `Replace`); Custom QC (`Report`, `Pause`); example pricing, quantity, date, lifecycle, value-validation, categorization, and cross-table checks; anomaly outputs |
| [`Retail_301_Understanding_the_Industry_Behind_the_Data.pdf`](Retail_301_Understanding_the_Industry_Behind_the_Data.pdf) | 2026-05-18 | Retail Knowledge 301 — deck | 11-page workshop deck on the **retail planning lifecycle**: Demand Forecasting → MFP → Assortment → Buying/OTB → Allocation → Replenishment → Pricing/Markdowns. Frames the cascade, defines every KPI (WAPE, OTB, GMROI, GM%, sell-through, WOS, ROS), and contrasts allocation vs. replenishment. Key thesis: "Sales ≠ Demand"; markdowns are a lagging indicator of upstream planning failures; analysts must shift from data fluency to **business fluency** ("buyers making ordering decisions without forward cover in 12% of cases" — not "forward cover field is NULL in 12% records"). |
| [`L&D_Retail_Knowledge_301_2026-05-18.md`](L&D_Retail_Knowledge_301_2026-05-18.md) | 2026-05-18 | Retail Knowledge 301 — meeting notes | Gemini transcript of the live session (Aditya Tyagi presenting). Same 7-step lifecycle as the deck, plus Q&A on **MFP–Demand Forecasting integration** (forecasts feed MFP via "seed with" function; MFP constrains Assortment / Buying / pricing) and **how markdowns/discounts are tracked in MFP** (promos, loyalty, employee discounts monitored at class-week level). Highlights phantom inventory, stale forecasts, lead-time issues, KVI pricing strategy. ~316 KB (embedded base64 screenshots). |

Markdown transcript files preserve original Gemini formatting including embedded base64 screenshots (Session 3 file is ~1.7 MB; Retail 301 file is ~316 KB for the same reason).

## Why the Retail 301 pair matters for the Lululemon project

The Retail 301 deck + meeting notes are the **business-context lens** for every master table we've EDA'd. Map them onto the Lululemon work:

| Retail 301 concept | Where it shows up in our Lululemon EDA |
|---|---|
| Demand Forecasting → "Sales ≠ Demand" | `transaction_master` 27% zero-qty rows + 351 negative-qty rows (unflagged returns?) — see [transaction_master Notion page](https://www.notion.so/364389502e7981c8befcc48c7f9c823c) |
| MFP / OTB cube (product × location × time) | `store_level_buy_qty_master_20260518` is a buy-qty plan at exactly this grain |
| Assortment Planning — breadth vs depth, store grades | `store_master` regions + `size_range_library_master_20260518` (size grids = depth) |
| Allocation vs Replenishment | Currently no master tracks either; gap to flag |
| Pricing / KVIs / Markdowns | **Blocked** — `sku_details.COST_PRICE` and `SELLING_PRICE` are 100% zero; cascades into `transaction_master.cost` / `msrp` = 0. No KVI / markdown / margin analysis possible until source pricing lands |
| "Business fluency, not data fluency" | The framing rule for the consolidated **Client QQ's** section on each Notion page — every QQ is phrased as a business decision being blocked, not a NULL count |

## Missing — Data Ingestion Series

Sessions 1 and 2 of the Data Ingestion series are referenced in Session 3 ("in previous two sessions we discussed pipeline configurations, sourcing queries, and GSM") but **not yet attached**. Expected scope based on the Session 3 lead-in:

- **Session 1** — pipeline configuration basics
- **Session 2** — sourcing queries + GSM (Generic Service Modules)

Add them to this folder when available, with the same naming pattern (`L&D_Data_Ingestion_Essentials_Session_N_YYYY-MM-DD.md`).

## Tool referenced throughout

The Session 3 transcript references the **IA Smart Platform Internal** (also called SelfPI / SelfServe portal) — 4-step config flow:

1. Data Extraction (Data Sources, Instance Details, Mapping Table, Sourcing Configuration, Triggers, Sample Selection)
2. Data Sourcing
3. Data Validation And Transformation
4. Product Integration

Tool screenshots not yet captured. Add to this folder if useful for future reference.
