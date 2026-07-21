# Lululemon x Impact Analytics — SOW (Jun 24 2026 Redlines, Demand Forecasting)

> **Source:** `lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.docx`  
> **Status:** Latest client SOW reference (Jun 30 2026). If this extract conflicts with the `.docx`, the `.docx` is authoritative.

---

EXHIBIT A

Statement of Work for Implementation of Demand Forecasting

The Parties agree to follow the format of the SOW template provided below, as such paragraphs are applicable to the specific engagement.

This Statement of Work (“SOW”), effective as of the date of last signature below, is made pursuant to, and incorporates by reference, the Master Agreement dated ________, 20__ by and between:

lululemon [athletica canada inc.] OR [usa inc.]  and, as applicable its Affiliates, (“lululemon”) having a registered office at  [1818 Cornwall Ave., Vancouver, B.C., V6J 1C7] OR [701 South Carson Street, Suite 200 Carson City, NV 89701] .

and

Impact Analytics, Inc. (“Vendor”) having a registered office at 780 Elkridge Landing Road, Suite 100 Linthicum, MD, 21090, USA

In the event of a conflict between this SOW and the Agreement, the Agreement shall govern and prevail unless this SOW explicitly states otherwise. All capitalized terms not defined herein shall have the meaning set forth in the Agreement. For clarity, for the purposes of the Agreement, this SOW is an “Order Document”.

The purpose of this Statement of Work (“SOW”) is to define the scope, deliverables, service levels, and commercial terms under which Impact Analytics (“IA) will provide, demand forecasting and related analytics services to lululemon athletica inc. (“lululemon”). This SOW establishes the framework for IA’s provision of services in support of Lululemon’s business objectives, including but not limited to, demand forecasting, performance monitoring, and optional capabilities as expressly authorized by lululemon.

Term of SOW:

Start Date:   Jul 6, 2026

Length of SOW

Six and a half months from date of signature

Ongoing Services: Analytics and data science service limited to the generation of demand forecastingand associated explainability outputs.

Termination: Review Termination of Convenience Section

Services:

Description of Services:

Impact Analytics (“IA”) shall provide demand forecasting, to support lululemon’s merchandise planning and allocation decisions by;

Providing a data science service limited to the generation of demand forecasting and associated explainability outputs.

Impact Analytics (“IA”) shall not provide a user interface, workflow tooling, or end-user decisioning system as part of this engagement.

Locations(s) where Vendor Services will be Performed (select all that apply):

✓Vendor Premises

☐lululemon Premises

Remote

☐Other:

Acceptance Criteria

General Acceptance Standard

Deliverables, detailed in section seven shall be accepted upon compliance with the functional, behavioural, structural, acceptance metric appendix, and operational requirements set forth in this SOW, including, as applicable, inference frequency, fallback constraints, and output granularity. Achievement of forecast accuracy metrics alone shall not be sufficient for acceptance.

In the event any Deliverable does not meet the applicable acceptance criteria, the Deliverable shall be subject to re-testing following remediation. If acceptance is not achieved after reasonable remediation efforts, lululemon has the right to terminate.

Deliverables will be considered accepted upon lululemon's written confirmation. If lululemon identifies deficiencies against the mutually agreed-upon requirements and acceptance criteria during the review period, IA will work with lululemon in good faith to create a remediation plan. If the cause of the deficiency is determined to be a result of IA's configuration or a failure to meet the requirements of this SOW, IA will perform the remediation at no additional cost. If the deficiency results from new or changed requirements, data issues, or other factors outside of IA's reasonable control, any remediation will be handled through the change request process.

IA shall complete User Acceptance (“UA”) iterations prior to go-live that are mutually agreed upon by both parties, during which continuous refinement and improvements are made and mutually accepted based on data, accuracy metric, business reviews, and criteria established by both parties.

Technical Conformance and Forecasting Behaviour

Acceptance of Technical Conformance and Forecasting Behaviour will be measured against and subject to the metrics outlined in Appendix.

Upon reasonable request, IA shall provide supporting documentation or evidence sufficient for lululemon to assess compliance with the acceptance criteria described herein.

lululemon may require further review or remediation where outputs exhibit characteristics that reasonably indicate non-conformance with the requirements of this SOW, including over-reliance on fallback behaviour or insufficient differentiation across products

Final acceptance shall be subject to lululemon’s written confirmation that the Deliverables meet the acceptance criteria and performance expectations set forth in this SOW.

Material non-conformance with the foregoing requirements may result in non-acceptance of the applicable Deliverables

IA will configure the solution and leverage the data provided by lululemon with the objective of achieving the accuracy metrics and performance standards set forth in Appendix A. Both parties acknowledge that data model accuracy can be influenced by numerous external factors. If the agreed-upon metrics are not met during acceptance testing, IA will collaborate with lululemon to diagnose the root cause. Should the variance be attributable to IA's modelling or configuration, IA will undertake reasonable efforts to remediate and re-test at no additional cost to lululemon.

In the event any Deliverable does not meet the applicable acceptance criteria, the Deliverable shall be subject to re-testing following remediation. If acceptance is not achieved after reasonable remediation efforts, lululemon shall have the right to terminate the Professional Services SOW; provided, however, that lululemon shall be responsible only for payment of fees that are due and payable as of the effective date of termination.

Geographic and Business Scope

The Services shall initially be provided for the regions, markets, channels, and store locations designated by lululemon in writing. lululemon may, at any time during the term, expand the scope of the Services to include additional newly opened store locations, which shall be deemed in-scope and included within the Fees set forth herein upon written notice to IA. Any expansions of the Services to additional regions or channels shall require a written change order and be mutually agreed to by both parties.

Global (North America, EMEA, APAC, China)

~800 stores

Channels: Retail and Ecommerce

All Categories

SKUs

Description of Service Requirements

The requirements set forth below are illustrative and not exhaustive; additional requirements may be identified during the engagement and shall be deemed within scope upon mutual written agreement of the parties.

Technical Conformance and Forecasting Behaviour

Vendor shall generate demand forecasting outputs in accordance with the requirements set forth in this SOW and applicable Schedules, including product level inference, permitted fallback behaviour, explainability standards, reinference cadence, and output granularity

Deliverables shall be produced using data‑driven methods that leverage available attributes, historical signals, and demand indicators at the applicable level of detail

Vendor shall support both incremental and batch re‑inference in accordance with agreed service levels, and outputs generated through different processing modes shall remain directionally consistent

Upon reasonable request, Vendor shall provide supporting documentation or evidence sufficient for lululemon to assess compliance with the acceptance criteria described herein.

lululemon may require further review or remediation where outputs exhibit characteristics that reasonably indicate non‑conformance with the requirements of this SOW, including over‑reliance on fallback behaviour or insufficient differentiation across products

IA shall provide access to key reporting metrics to lululemon to evaluate model performance. Key metrics are detailed in the Section 8: Reporting metrics.

IA shall perform all Services and produce all Deliverables in accordance with the accuracy metrics and performance standards set forth in Appendix A and shall implement and maintain appropriate processes, controls, and monitoring to ensure ongoing compliance with such metrics.

Implementation Methodology

Implementation Process is as outlined in the below steps:

Data transfer & data pipeline:

IA will prepare the ingestion pipeline design (detailing data sources, transforms and validations) for approval by lululemon. Post sign off from lululemon on the data design and formats, if lululemon needs to make changes, a Change Request may be necessary.

IA will develop the ingestion pipeline based on lululemon approved architecture (in accordance with the approved design) and will conduct testing, corrections and stabilization (one-time, catch-up and recurrent staggered)

User on-boarding

Walkthrough of all model logic and sample outputs from model re-training periods - IA to conduct training sessions to share the underlying model logic / configurations for educating users

Office hours during UAT and Pre-go Live time to explain output formats, interpretations, etc.

Reclassification: During Implementation

IA will provide two complimentary reclassifications, one during configuration and one close to go live (during or immediately after) within the scope of implementation. During the support phase, IA will continue to provide two reclassifications a year at no charge. Standard effort for a reclassification is two weeks.  The cost for that effort is $65,000.  Minor adjustments for adding new products do not constitute a re-class. IA reclass definitions:

SKU reclassifications may incur additional effort and fees to adjust the datasets, hierarchy, forecasting and optimization models. The additional effort and fees associated with the reclassification will be shared as part of the Change Request process.

lululemon considers the following not reclassification

Grouping for planning purpose lululemon may at will group products or skus together for the purposes of planning and replenishment, creating or adding to a sku-like construct, such that all history of all included products shall be used for forecasting future demand. Such grouping activities shall not be considered ‘Reclass’, and will not incur a change request, or additional fees

Description of Deliverables

Deliverables must be completed for a Q1 go live.

Daily Data refreshes

This will be completed regionally (APAC/China, NAM, EMEA 3 x/region/day delta/incremental refresh at a minimum, acknowledging that the expected volume is likely relatively small in comparison to the total dataset and is intended to address new data, new products, or changes in eligibility that may be reasonably expected to modify prior inference output materially. Lululemon reserves the right to request full re-inferencing to address broader systemic issues identified in any prior run. Or to address the availability of additional relevant data (eg: actualized sales)

IA will work with lululemon to determine when model training is required for larger data updates

Forecasting Track

Demand Forecast Weeks

52 Week Style-Option  x Submarket Channel x Week

17 Week SKU (or analogous) Store Day Forecast (PSS x Store/DC x Day)

Length

Product

Location

Time

Derivation

17 week

SKU (or analogous)

Store (Retail) /DC (Ecomm)

Day

Disaggregated to day from the first 17 weeks of the 52 week forecast by a method to be mutually agreed upon.

52 week

SKU (or analogous)

Store (Retail) /DC (Ecomm)

Week

Independently inferenced

52 week

Style-Option

Submarket Channel

Week

Independently inferenced

All forecast models must be capable of being backtested and independently validated by lululemon using historical data

Unit-level unconstrained demand forecasts with confidence intervals across all products and markets

Forecasting Architecture Requirements

All forecast outputs must adhere to the following principles:

Phase One: Forecasts may be independently inferenced at each defined level of granularity.

Phase Two: IA and lululemon will work together in developing and testing higher level and lower level without using aggregation and disaggregation of another forecast levels to determine if  the results provide a better overall state of the forecast architecture.

All outputs must represent unconstrained demand and be derived using statistical or machine learning methods

Forecasts shall be re‑generated in response to material business or demand events, including, at a minimum:

Assortment changes

Sales plan updates

Significant demand signal changes

Daily forecasts must be generated using statistically valid disaggregation methods incorporating intra-week demand signals

Forecasting and Demand Disaggregation Requirements and Prohibited Method and Limitations

The Vendor shall design, implement, and operate forecasting and demand disaggregation processes that are data‑driven, adaptive, and signal‑aware. Specifically, the Vendor shall:

Incorporate latest available daily sales, inventory, and event signals

Apply day-of-week normalization to isolate true demand variation

Dynamically update forecasts based on newly observed data

The Vendor shall not employ methodologies that are static, inflexible, or insufficiently responsive to demand signals. Without limitation, the Vendor shall not

Use static proportional splits

Use fixed day-of-week curves without signal adjustment

Explainability artifacts

Vendor shall complete User Acceptance (“UA”) iterations prior to golive that are mutually agreed upon by both parties, during which continuous refinement and improvements are made and mutually accepted based on data, business reviews, Appendix A, and criteria established by both parties.

Forecast Explainability Requirements

The Vendor must provide explainability artifacts sufficient to Provide visibility into

confidence intervals and forecast uncertainty

key drivers influencing forecast outputs

Acknowledges different modelling techniques provided different levels and methods of explainability

All explainability outputs must be delivered in a format accessible for independent validation by lululemon.

Transfer mechanism of the outputs will be as per what is agreed upon with the vendor during design phase

Forecast Change Tracking and Auditability

The Vendor must maintain a complete audit trail of forecast outputs, including:

Timestamp of each update

Inputs and signals used to generate the version of forecast output

The system must allow lululemon to reconstruct forecast values and changes at any point in time.

All forecast changes must be explainable from a methodology standpoint

Reporting Requirement

The Vendor shall provide reporting outputs monthly sufficient to evaluate model performance or the sufficient underlining data to produce reports internally, including

Accuracy Metrics

WAPE or equivalent agreed metric at defined grain

Size-level distribution accuracy

Drift Monitoring

Detection of material changes in curve behaviour over time

Identification of model degradation or instability

Explainability Diagnostics

Supporting data to assess model behaviour

All reporting must be made available in a format accessible to lululemon for independent validation

Implementation Team

IA will bring a comprehensive team of resources to ensure a successful deployment and integration of our solution. The key teams and roles include:

IA Engagement Team (On-site as needed):

Customer Success Manager (CSM): Ensures the project aligns with business goals, manages the implementation process and maintains lululemon satisfaction

Senior Technical Architect: Initially supports technical design and integration/data strategies.

Implementation Team (Remote. Can travel based on exceptions):

Program Management, Business Analysis & Data Science Team:

Project Lead: Oversees the project, manages the end to end implementation program, and owns the timelines

Data Integration Specialists: Handle data transfer and integration tasks, ensuring data consistency and accuracy

Analysts: Responsible for data understanding, data cleansing, exploratory data analysis, and provide analytical /consulting support

Data Scientists: Build forecasting models

Product and Engineering Team:

Technical Architect: Oversee the overall technical design and architecture of the solution to ensure seamless integration and functionality

Back-End Engineers: Implement system configurations and user interfaces, ensuring robust functionality and a seamless user experience

Quality Assurance Team:

Testers & Testing Leads: Collaborate on testing requirements, conduct thorough testing, and promptly fix any identified issues

A employs a structured cadence mechanism and effective communication (oral and written) to ensure appropriate stakeholder management. IA envisions the following roles and resource commitments from the lululemon side during implementation:

lululemon/SI Role

Roles & Responsibilities

Executive Sponsor

Resolve escalations as required

Project Sponsor

Responsibilities: Review progress, give direction, resolve escalations

Time Commitment: 1-2 hours every 2 weeks

Project Manager

Responsibilities: Review progress, document process, give direction, resolve escalations.

Time Commitment: 20 hours per week during data, design and UAT

Weekly meetings during initial phase for process/ data understanding

Weekly updates over emails from IA

Progress review meetings every 2 weeks

To include Data and Systems teams as and when needed

Product Management

Responsibilities:

Enable process/data understanding; review & approve feature sign offs

Provide feedback on managing change across the business

Become the process & system expert and champion – be the main point of contact for the end users

Time Commitment: 20 hours per week for first 8 weeks during data, design and 10-12 hours during UAT; ~4 hours weekly on final training, testing, etc. during the go live phase over 1-2 weeks for relevant roles by module

Weekly meetings during initial phase for process/ data understanding

Weekly updates over emails from IA

Progress review meetings every 2 weeks

IT Support Team

Responsibilities:

Help IA team with data understanding and integration

Time Commitment:  4-6 hours per week during data & design. 10-20 hours per week during SIT.

Business Change Leads

Responsibilities:

Assess effectiveness of change management efforts

Collect employee feedback and share with IA team

Monitor performance and adoption post Go Live

Lead the planning and execution of training and communication

Understand the process flows, and help evangelization

Regular meetings initially for planning the change management process

Once process is stabilized, weekly status update meetings

The parties acknowledge that IA’s ability to meet these timelines are dependent on lululemon:

(i) providing the necessary data to IA accurately, and in a timely manner; and

(ii) ensuring the ongoing availability of the specific stakeholders across each activity (as set out in sections # 8.2 and 8.3)

(iii) providing the necessary sign offs on time, as set forth in the timelines

Any delays in providing the necessary and accurate data, or due to the unavailability of lululemon’s stakeholders as needed, or delays in sign offs, will lead to a delay in the timelines.

Any additional customization requirements discovered during the design phase, that go beyond the feature list from the standard offering, provided in the section # 6 - Product Details, will require IA and the lululemon to meet in good faith to plan and account for the additional scope, cost and effort for those customisations, post the initial go live. Any additional deliverables requested by the lululemon for the consulting services, or any related change in scope, will lead to the timelines being extended, in good faith between IA and the lululemon.

The timelines above have been built in line with IA’s release calendar. Any delays in the lululemon dependent activities, will lead to a shift in the timelines, with due dates for UAT and go live changing strictly in accordance with the aforementioned release calendar. IA will not be able to accommodate requests for UAT and go live dates that are not in line with the same.

Availability

For the products listed in this SOW, data refreshes and system updates based on section 5.  .

Data Ingestion Timing

lululemon acknowledges that Impact Analytics requires a minimum of three (3) hours to ingest incoming data. lululemon shall be responsible for providing all required data in the prescribed format, complete and accurate, in accordance with the agreed-upon specifications and timelines. Should lululemon fail to provide data in the required form and completeness within the stipulated time frame, Impact Analytics shall not be held liable for any delay in updating the applications, and users may not be able to use the system with the updated data on time.

Project Governance

As part of the initial project phases (discovery, design), the lululemon and the Vendor will work together to design, document and establish the Project Governance framework. This includes, but is not limited to, defining key stakeholders, governance bodies, escalation paths and the overall decision-making structure for the project. Additionally, the Parties will collaboratively define roles and responsibilities for the project team through a RACI matrix, covering accountabilities, decision-making authority and collaboration expectations. All governance and responsibility structures will be jointly agreed upon to ensure clarity, alignment and effective project oversight.

Service Level Agreements

IA shall provide weekly written status reports during the implementation period detailing progress against the approved project plan, completed and upcoming activities, risks, issues, dependencies, and mitigation actions. Such reports shall be delivered no later than one (1) business day prior to the applicable weekly project meeting, if any.

IA shall acknowledge and respond to lululemon inquiries and requests as follows:

Critical implementation blocking issues: within four (4) business hours

All other implementation related requests: within one (1) business day

IA shall perform the Implementation Services in accordance with the timelines and milestones set forth in the approved project plan. IA shall promptly notify lululemon in writing of any actual or anticipated failure to meet a milestone and shall provide a written corrective action plan. Repeated or material failure to meet milestones shall constitute a performance issue.

IA shall identify, document, and escalate any risks, assumptions, constraints, or dependencies that may reasonably impact the implementation timeline, scope, or quality. Such escalation shall occur within two (2) business days of identification.

All Deliverables shall conform to the requirements and specifications set forth in this SOW and the approved design documentation. lululemon shall have fifteen (15) business days to review and either accept the Deliverable or provide written notice of deficiencies.

IA shall remediate any material defects or deficiencies identified by lululemon per the agreed upon terms within the MSA. IA shall implement the solution strictly in accordance with lululemon￼approved design documentation. No material deviation shall be implemented without lululemon’s prior written approval. Absent such approval, IA shall remain obligated to deliver in accordance with the approved design.

IA shall perform data validation activities during implementation to confirm data completeness and integrity. IA shall notify lululemon in writing of any material data quality or integration issues within two (2) business days of discovery.

Where errors, reprocessing, or re‑runs are required due to IA’s configuration, processing, or implementation activities, IA shall perform such reprocessing or corrections promptly and at no additional cost to lululemon.

IA shall assign qualified personnel with appropriate skills and experience to perform the Implementation Services. Any substitution of key personnel shall require prior written notice and replacement personnel shall possess qualifications and experience equal to or greater than those of the individual being replaced. If IA replaces personnel per their decision or at the request of lululemon the lost downtime or deliverables not completed as originally agreed upon and during that period will not be charged and/or a change order will not be requested to lululemon.

Prior to completion of the Implementation Services, IA shall deliver implementation documentation, configuration details, and operational assumptions sufficient to enable lululemon to support ongoing operations and use of the solution.

Failure by IA to meet the service levels set forth in this SOW on a material or recurring basis shall constitute a performance issue and breach of contract subject to escalation and all remedies available to lululemon under the Agreement.

Change Request Process

The parties acknowledge that successful implementation requires disciplined scope management while allowing flexibility to address evolving business needs. This Change Request (“CR”) process is intended to provide transparency, predictability, and structured prioritization of changes without disrupting system stability, agreed timelines, or overall program objectives.

Vendor shall not classify work as a Change Request where such work is required to meet the approved design, acceptance criteria

Definitions

For clarity, requests will be categorized as follows:

Defect

A failure of the Solution to materially perform in accordance with the approved functional or technical design documentation. Defects will be addressed in accordance with applicable warranty and support provisions and do not constitute a Change Request.

Configuration Adjustment

A modification within the boundaries of the approved design and existing system capabilities that does not materially alter scope, integrations, data structures, or workflows. Such adjustments may be handled through standard support or agreed services processes.

Change Request (CR)

Any request that:

Introduces new functionality, workflows, reports, integrations, or data structures not included in the approved scope;

Deviates from the formally approved design documentation; or

Impacts downstream integrations, performance architecture, upgrade path, or release sequencing.

Change Request Process

Submission

lululemon will submit a written CR request outlining:

Business objective

Functional description

Urgency and desired timeline

Impact Assessment

a commercially reasonable period, IA will provide:

Feasibility determination

Effort estimate

estimate

impact

Architectural and integration considerations

Risk assessment (if applicable)

Prioritization Options

Upon receipt of the impact assessment, the lululemon may elect one of the following scheduling options:

Standard Scheduling

Included in the next available release or agreed delivery window

Effort-based fees apply

No impact to committed milestones

Accelerated Scheduling

Reprioritized within the current or upcoming release cycle

Effort-based fees apply

A reasonable prioritization premium may apply to reflect resource reallocation

Deferred Scheduling

Included in a future agreed roadmap cycle

Where a requested CR requires significant displacement of committed work or introduces material production risk, the parties will mutually agree on a prioritization premium reflective of the operational impact.

Approval

No CR work will commence without written approval from the lululemon.

Plan Adjustment

Upon approval, the parties will update the project plan, delivery schedule, and commercial documentation as applicable.

Design Integrity

Following formal design sign-off, material deviations from approved documentation may impact timeline and cost. IA will provide transparent impact assessments prior to execution to ensure informed decision-making.

Good Faith Collaboration

The parties agree to review CRs in good faith, balancing business value, system stability, and long-term product integrity. Neither party shall unreasonably withhold approval of mutually agreed prioritization decisions.

Fees:

Vendor will invoice lululemon, and lululemon will pay Vendor, in accordance with the Agreement for the amount of a monthly fixed fee $145,000.00 USD for the implementation services (the “Implementation Services”), which fee covers the performance of the Services and the delivery of any specified Deliverables, including Goods, as described herein and outlined in Schedule 1A. The parties acknowledge that the anticipated implementation timeframe for the Implementation Services is approximately eight (8) to nine (9) months, based on an estimated effort of approximately forty (40) hours per week..

Any amount exceeding the Maximum Total Fees, including any out-of-pocket expenses, must be pre-approved by lululemon in writing before work commences.  Vendor acknowledges that a failure to deliver the Deliverables, Services, or Goods or meet designated milestones by the designated delivery date (unless due to no fault of Vendor) will result in damages to lululemon.  Vendor acknowledges that in addition to any other remedies that lululemon may have at law, lululemon will not be obligated to pay for Deliverables, Services, or Goods that were not delivered by the agreed upon delivery date and that cause a material delay in lululemon’s launching plans, provided that lululemon has not solely caused the delay

Invoicing and Payment Terms

Invoicing Detail: Invoices will be rendered monthly in arrears based on actual days delivered.

All undisputed invoices shall be paid net Sixty(60) days after receipt of invoice.

Exchange of Personal Data

In the event Vendor Processes lululemon Personal Data in connection with this SOW, the Parties agree that the terms of the Data Privacy Addendum, available shop.lululemon.com/help/legal/vendor-terms#data-privacy-addendum, shall apply and are incorporated by reference.

Annex 1 to this Statement of Work describes the details of Processing of lululemon Personal Data.  The list of relevant Subprocessors for this SOW will be provided by Vendor in the attached Annex 2.

Resources Deployed (Specific Allocation and Substitution)

Resource Substitution: IA shall have the right to substitute personnel assigned to the project at its reasonable discretion, subject to prior written notice to the lululemon. IA warrants that any replacement personnel will have qualifications and experience substantially similar to or greater than those of the individual being replaced. Lululemon may, at it’s discretion and upon written notice, request the substitution of any personnel due to performance issues, operational challenges, or other project-related concerns, and IA may promptly provide replacement personnel meeting the qualifications set forth herein.

On-Site vs. Remote Work: Roles designated as "Remote" but requested on-site by the lululemon will trigger a CR for travel costs and, potentially, an adjustment to the daily rate if a different rate applies for on-site work.

lululemon Responsibilities and Impact of Delays

Data Timeliness and Accuracy: . IA’s timelines are dependent on the receipt of data from Lululemon that is reasonably accurate, complete, and provided in accordance with agreed specifications. In the event of delays or issues caused by data that does not meet these standards, IA shall promptly notify Lululemon and the parties will collaborate in good faith to determine appropriate timeline adjustments. Any such adjustments must be mutually agreed in writing, and no additional fees shall apply unless expressly approved by Lululemon through a written change request

Stakeholder Availability: Each party will use commercially reasonable efforts to ensure the availability of required stakeholders as outlined in Sections 8.2 and 8.3. If the unavailability of identified stakeholders materially impacts the delivery schedule, the parties will collaboratively assess the impact and agree in writing on any necessary timeline adjustments.

Sign-off Delays: If either party experiences delays in providing required sign-offs on data, design, or UAT, the parties will work in good faith to mitigate the impact. Any resulting timeline adjustments or additional costs must be mutually agreed upon in writing through the change request (“CR”) process

Where delays are attributable to either party, the impacted party shall promptly notify the other, and the parties will work together in good faith to minimize inefficiencies and mitigate impacts. IA shall not bill Lululemon for waiting time, work-arounds, or rework unless such effort is directly attributable to Lululemon actions, unavoidable despite reasonable mitigation efforts by IA, and expressly approved in advance by Lululemon through a written change request (“CR”). No billing or timeline adjustment shall occur without Lululemon’s prior written authorization.  Any additional time or effort resulting from delays shall be jointly reviewed and, if applicable, documented through an approved CR. In the event IA is responsible for lost time or rework, IA shall provide an appropriate credit to Lululemon for the impacted time or fees, as mutually agreed.

Scope and Change Management

CR Process Tie-in: Any work requested beyond the approved scope in the feature list (Section 6), will require an approved CR and will be billed as additional T&M effort using the agreed-upon fixed monthly quote.  Any CR less that one month will be prorated accordingly.  rate card.

Travel and Expense Cost

IA shall not book or incur any travel‑related expenses in connection with the Services unless expressly pre‑approved in writing by Lululemon. Lululemon shall have no obligation to reimburse any travel expenses incurred without such approval.

Lululemon will reimburse IA for reasonable, verifiable, and previously approved travel and other expenses, which Vendor will invoice monthly. Any travel expenses incurred will be billed as per actuals and IA will adhere to lululemon’s Global Travel and Expense Policy. Such travel invoices will be updated with monthly invoices.

Collaboration and Evolving Technology

The parties shall collaborate in good faith throughout the term of this Statement of Work to support continuous improvement and the adoption of evolving technologies. The Vendor shall work with the Client to identify, evaluate, and, where mutually agreed, implement enhancements, innovations, or technology advancements that improve performance, efficiency, or outcomes. Such collaboration shall not materially alter scope, fees, or obligations unless expressly documented in a written amendment to this SOW.

Termination of Convenance

If the Vendor is unable to meet or maintain the agreed-upon acceptance criteria, deliverables, or accuracy levels as mutually established by the parties, lululemon may terminate the Services, in whole or in part, upon written notice, without penalty. The parties acknowledge that the Implementation Services are structured into discrete phases, including design, testing, and deployment, and following formal written acceptance and design sign-off by lululemon, or at the conclusion of any subsequent phase, lululemon shall have the right, upon written notice, to discontinue further Services under this SOW without penalty, subject only to payment for Services satisfactorily performed and accepted through the end of the applicable phase; any unused fees for future phases shall not be payable. lululemon’s termination and phase-break rights may be exercised regardless of Vendor breach or fault.

The Parties executed this SOW on the date(s) set out below after having the opportunity to discuss this Agreement with their legal advisors. Each Party represents and warrants that its respective signatory is duly authorized to execute this Agreement on its behalf.

VENDOR:

Impact Analytics Inc.

lululemon

SIGNATURE:

SIGNATURE:

NAME:

Luke Batman

NAME:

TITLE:

CFO

TITLE:

EMAIL:

Luke.Batman@impactanalytics.ai

EMAIL:

legalnotices@lululemon.com

DATE:

DATE:

Appendix A: Forecast model acceptance criteria

The acceptance criteria set out in this Appendix A — including the back-testing periods and windows, accuracy measures and thresholds, and applicable inclusions and exclusions — are provisional, and the parties shall review and finalise such acceptance criteria within thirty (30) days of the project start date.

All the below forecast model acceptance criteria will apply for a back-testing period mutually agreed upon by lululemon and IA teams.

Guiding Principles for accuracy measurement and acceptance criteria during the back-testing window

Accuracy requirements scale with business impact (volume contribution)

Metrics must reflect true demand signal, not artifacts of low-volume data

Distribution-based evaluation prevents masking of poor SKU-level performance

Metrics & thresholds must be defined such that the intent of business decisions are met while not enforcing too strict thresholds on model performance

WAPE requirements for back-testing of forecast models

Requirements for 52-week PSO-Country Sub-market-Week level forecast WAPE measurements during back-testing periods –

WAPE will be evaluated within each demand contribution segments created at PSO Country Month level and market/channel combination for a back-testing window

Forecast accuracy for back-testing will be evaluated using fixed, volume based strata as % of cumulative demand across:

High Contribution (Range TBD)

Mid Contribution

Low Contribution

Strata will be determined by ranking items in descending order of actual demand over the evaluation period and assigning them based on cumulative contribution

Strata assignments will be determined for each measurement period separately

Required WAPE by Channel × Regions –

Demand Contribution Strata

NAM Retail

NAM ECOM

APAC Retail

APAC ECOM

China Retail

China ECOM

EMEA Retail

EMEA ECOM

High Stata

To be discussed & defined based on mutual agreement

Mid Strata

Low Strata

Acceptance rules –

Each stratum must meet its corresponding WAPE threshold

Lululemon and IA teams can mutually agree to relax the acceptance criteria for certain sub-market channel × strata combinations if data quality / sparsity renders modelling to be extremely difficult

Requirements for 17-week PSS-Store-Day level model during back-testing periods

Model performance will be measured separately based on Rate of Sales (ROS) of products:

High ROS – Products showcasing an average ROS of X units or higher at a PSS-Store-Week level for the back-testing period

Low ROS – Products showcasing an average ROS of Y units or lower at a PSS-Store-week level for the back-testing period

Acceptance criteria for High ROS products:

WAPE measurement at a PSS × Store × Week level

WAPE acceptance levels –

ROS Category

NAM Retail

NAM ECOM

APAC Retail

APAC ECOM

China Retail

China ECOM

EMEA Retail

EMEA ECOM

High ROS WAPE

To be discussed & defined based on mutual agreement

Acceptance criteria for Low ROS products:

Week of supply Deviation (WOSD) will be evaluated for each PSS-Store and calculated using the ratio of the Unit Deviation of forecasts (Forecast Units – Actual Units) with the Average Rate of Sale of each PSS-Store during the Back-testing window. WOSD shows the error in terms of weeks of inventory deviation.

WOSD acceptance levels –

ROS Category

NAM Retail

NAM ECOM

APAC Retail

APAC ECOM

China Retail

China ECOM

EMEA Retail

EMEA ECOM

Low ROS WOSD

±XX WOSD / YY%

±XX WOSD / YY%

±XX WOSD / YY%

±XX WOSD / YY%

±XX WOSD / YY%

±XX WOSD / YY%

±XX WOSD / YY%

±XX WOSD / YY%

± XX WOSD / YY% denotes that YY% or more PSS-Store combinations should fall within the ± XX WOSD error range

Acceptance rules –

WAPE thresholds are met for all High ROS category

WOSD thresholds are met for all Low ROS category

Failure in any of the above constitutes review of models and further improvement steps

Conditions & Exclusion of acceptance criteria

All the above acceptance criteria are valid only if there are no major shifts in the business goals and strategies such as –

Overhaul of assortments, changes to product life cycles or planning structures

Strategic focus shifts to new / emerging markets and geographies

Overhaul of pricing / promotional / marketing and go to customer strategies

Frequent changes in data and product hierarchies deeming it unfit for mapping and understanding historical behavior

Significant Alterations to Supply Chain or Distribution Network

All the above acceptance criteria are valid only if there are no major external forces disrupting the business performance such as –

Force Majeure Events including but not limited to acts of God (e.g., natural disasters such as floods, earthquakes, pandemics), acts of war, terrorism, civil unrest, labor strikes, and government-imposed lockdowns or trade restrictions

Sudden and Significant Shifts in Economic Conditions like huge inflation / deflation and economic depressions

Regulatory and Legislative Changes like imposition of new tariffs, taxes, import/export restrictions

Disruptions in Raw Material or Component Supply like a single-source supplier going out of business, a widespread crop failure etc.

Unforeseen Competitor Actions like the unexpected launch of a revolutionary new product, an aggressive and sustained price war, or the sudden exit of a major competitor from the market

Unforeseen media / PR driven change in customer perception leading to volatile business scenarios

Appendix B: Change Request Form

Change Request Form

[This form is divided into three sections. Section 1 is intended for use by the individual submitting the change request. Section 2 is intended for use by Impact Analytics to document/communicate their initial impact analysis of the requested change. Section 3 is intended for use by the Project Manager / Business team to document their final decision regarding the requested change.]

1.) SUBMITTER - GENERAL INFORMATION

CR#

Type of CR

☐ Enhancement Request

☐ Change Request

Project/Program/Initiative

Submitter Name

Brief Description of Request

Date Submitted

Date Required

Priority

☐ Low

☐ Medium

☐ High

☐ Mandatory

Reason for Change

Other Artifacts Impacted

[List other artifacts affected by this change]

Assumptions and Notes

[Document assumptions or comments regarding the requested change]

Comments

Attachments or References

☐ Yes

☐ No

Link:

Date

2.) IMPACT ANALYTICS - INITIAL ANALYSIS

Task

Effort Estimate (In days)

Effort Estimate (In Man Hours)

Duration Impact

Schedule Impact

Cost Impact

Comments

Recommendations

3.) PROJECT MANAGER / BUSINESS DECISION

Decision

☐ Approved

☐ Approved with Conditions

☐ Rejected

☐ More Info

Decision Date

[mm/dd/yyyy]

Decision Explanation

[Document the decision]

Conditions

[Document any conditions imposed]

Approval

[Approver Full Name]

Date Signed

Change Order

This Change Order is entered into as of < > (the “Effective Date”), and when fully executed by both parties becomes incorporated by reference into the Master Agreement dated < > and the Statement of Work dated < > by and between Impact Analytics, Inc. and Customer(“ ”)

Nature of the proposed changes:

Reason for the Change:

Impact of the Change:

Project SOW:

Project pricing:

Other impact:

P.O. to which changes will apply if applicable:

All other terms and conditions of the Master Agreement and Statement of Work, except to the extent expressly modified herein, remain in full force and effect.

Signatures:

This Change Order shall be considered fully executed and binding when authorized representatives of both parties have signed and dated below.

Customer

Service Provider: Impact Analytics

By:

By:

Name:

Name:

Title:

Title:

Date:

Date: