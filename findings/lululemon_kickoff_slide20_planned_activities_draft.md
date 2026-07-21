# Kickoff Slide 20: Design Sessions Planned Activities (paste draft)

`Last updated: 2026-06-30`

**Live deck:** [Cursor Copy of Lululemon May 2026 - Project Kickoff v2](https://docs.google.com/presentation/d/15aYGFZb2OZc3jCdSer9jg_8EKzpHuKWK0HemyZuQ-PE/edit?usp=sharing), slide 20

**How to use:** Copy each **Planned Activities** block below into column 3 of the design sessions table. Use **one merged cell per IA deliverable row group** (same row span as the Topics column).

**Sources:** Team inputs (as-is forecasting discovery; to-be deliverable/acceptance alignment) + [Jun 24 SOW](../reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.md) (Section 6, Appendix A, Phase 2 outbound refresh).

---

## Column 3: Planned Activities (paste-ready)

### 1. As-is process mapping*

Led Q+A and working sessions to document Lululemon's current-state forecasting landscape:

• Process & ownership: End-to-end as-is forecasting workflow: who builds, reviews, and consumes forecasts; cadence and timelines; regional/channel differences (NA, APAC, EMEA, China; Retail vs ECOM).

• Methods & benchmarks: Current forecasting approach, tools/systems, hierarchy/grain used today, and any internal accuracy benchmarks or KPIs already tracked.

• Key drivers & parameters: Inputs, assumptions, and business rules that drive forecasts (e.g. seasonality, events, eligibility, hierarchy, fallback behaviour); parameters that would carry into IA deliverables.

• People & governance: Team structure, key stakeholders, approval flow, and communication paths for forecast changes and sign-off.

• Data & constraints: Data sources, known data quality gaps, and operational constraints that affect forecast reliability or refresh (including dependencies on allocation/replen/PO/transfers only where they impact forecast inputs or downstream use).

• Playback: Summarize findings for LL alignment before moving to to-be design.

Output: As-is playback deck / notes agreed by business and IT.

---

### 2. As-Is Clarifications

Follow-up sessions (as needed) to close open items from as-is discovery:

• Resolve unanswered questions on current forecasting process, benchmarks, roles, and data gaps.
• Confirm regional/channel variations and any exceptions to the standard workflow.
• Validate that as-is documentation reflects GA/OOTB IA forecasting service scope (no UI/workflow tooling in Phase 1).

Output: Updated as-is summary with no material open clarifications before to-be sessions.

---

### 3. Final To-be documentation for client alignment

Draft to-be documentation for LL review ahead of formal showcase/sign-off:

• Target operating model for offline demand forecasting service: inputs, outputs, refresh cadence, and handoff to Lululemon systems.
• Deliverable catalogue aligned to SOW Section 6 (52w Style-Color × Submarket Channel × Week; 52w SKU × Store/DC × Week; 17w SKU × Store/DC × Day; readout sequence Intl then US/CA).
• Preliminary acceptance framework referencing Appendix A (back-testing window, WAPE strata by channel × region, High/Low ROS rules, unit deviation / WOSD where applicable).
• Phase 2 readiness note: regional 3× daily delta refresh capability (APAC/China, NAM, EMEA).

Output: To-be document circulated for soft alignment before Product Showcase sessions.

---

### 4. Product Showcase

Walkthrough of to-be IA forecasting service design and initial alignment on deliverables:

• To-be process: High-level overview of how IA generates, validates, and delivers unconstrained demand forecasts (no end-user UI in this SOW).
• Deliverables & time horizons: Confirm grains, horizons (52w week-level; 17w day-level disaggregation), rollout sequence (Intl → US/CA), and output formats for readouts/handover.
• Acceptance criteria: Align on back-testing period/window, WAPE thresholds by demand-contribution strata and channel × region (Appendix A); High vs Low ROS measurement approach; unit deviation / WOSD rules where applicable.
• Operational design: Inference/regeneration triggers, explainability expectations, audit trail, and LL validation approach during UA.
• Phase 2: Confirm 3× per region/day incremental refresh scope and when full re-inference may be requested.

Output: Soft Sign-off #1 on to-be design, deliverables, and draft acceptance criteria (open items logged).

---

### 5. Product Showcase 2

Second showcase to resolve refinements from Soft Sign-off #1 and lock design decisions:

• Incorporate LL feedback on deliverable definitions, readout sequence, and acceptance metric thresholds.
• Finalize back-testing methodology: evaluation periods, strata assignment, inclusions/exclusions, and pass/fail rules per Appendix A.
• Confirm Phase 1 vs Phase 2 boundary (Phase 1 forecasting MVP vs Phase 2 daily 3× refresh and model improvements).
• Review any CR candidates explicitly out of scope vs in-scope remediation.

Output: Soft Sign-off #2; consolidated design decision log ready for formal sign-off package.

---

### 6. Final design documentation for sign-off

Prepare formal sign-off package incorporating Soft Sign-off #1 and #2 outcomes:

• Final to-be process, input/output specifications, and deliverable matrix (grain × horizon × geography × channel).
• Finalized acceptance criteria: back-testing window, WAPE (and WOSD/unit deviation where applicable) by channel × region × strata; UA iteration approach.
• Phase 2 outbound refresh design summary (3× per region/day minimum).
• Open issues / assumptions / dependencies list with owners and dates.

Output: Final design document set for formal LL + IA sign-off session.

---

### 7. Sign-off

Formal sign-off session with Lululemon project management, super users, end users (as applicable), and IT:

• Review and approve final to-be designs: process, inputs, outputs, and acceptance criteria.
• Written confirmation that deliverables, time horizons, and Appendix A metrics are agreed (or explicit exceptions documented).
• Confirm Phase 2 refresh expectations (3× daily regional delta refresh) and change-request path for post-sign-off scope changes.

Output: Signed design / scope alignment record; baseline for build, UA, and readout milestones (Timelines v3).

---

## Column 2: Topics (optional tidy, forecasting-first)

If updating the Topics column at the same time, use these replacements:

| Current topic (approx.) | Replace with |
|-------------------------|--------------|
| As-is forecasting and store alloc/ replen | As-is forecasting |
| Key parameters for alloc/ replen | Key parameters for forecasting |
| High-level as-is process understanding across forecasting, Store allocation & replenishment, PO process, transfers**, etc. | High-level as-is forecasting process and downstream consumption touchpoints |

**Keep unchanged (still valid):**

- As is process across teams
- Team structure, key stakeholders and process/communication alignment
- Confirm current Store allocation/replen process and forecasting (if any) process → consider: **Confirm current forecasting process and downstream consumption touchpoints**
- Understand allocators per channel… → consider: **Understand forecast consumers per channel, workflow differences, approval flow, and regional variations**
- Understand pack configurations, constraints such as WOS… → consider: **Understand forecast-relevant constraints (eligibility, hierarchy, DC/store mapping, lead times) where they affect demand signal**

---

## Footnotes (keep on slide)

- `*` As-is design will be reconciled with GA/OOTB features & capabilities.
- `**` If transfers (or other cross-functional topics) require additional discussion, schedule separate sessions; not in core forecasting design path unless they affect forecast inputs.

---

## Quick reference: row mapping

| IA deliverable (col 1) | Merge Planned Activities block |
|------------------------|--------------------------------|
| As-is process mapping* | Block 1 |
| As-Is Clarifications | Block 2 |
| Final To-be documentation for client alignment | Block 3 |
| Product Showcase | Block 4 |
| Product Showcase 2 | Block 5 |
| Final design documentation for sign-off | Block 6 |
| Sign-off | Block 7 |
