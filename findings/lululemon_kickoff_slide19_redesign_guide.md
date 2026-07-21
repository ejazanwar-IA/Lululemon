# Lululemon Kickoff: Slide 19 Engagement Plan Redesign Guide

`Last updated: 2026-06-30`

**Live Google deck:** [Cursor Copy of Lululemon May 2026 - Project Kickoff v2](https://docs.google.com/presentation/d/15aYGFZb2OZc3jCdSer9jg_8EKzpHuKWK0HemyZuQ-PE/edit?usp=sharing)

**IA-branded replacement:** `~/Documents/Lululemon_Engagement_Plan_Slide19_20260630.pptx` (regenerate with `node scripts/build_lululemon_engagement_slide.js`)

**Date source:** [`reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.xlsx`](../reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.xlsx) Milestone Tracker

---

## Before vs after

### Before (slide 19 today)

```
+------------------------------------------------------------------+
|  [ambiguous dates: July'13  Aug'07  Sep'25  Sept 26  Aug'26]     |
|  Historical Data Transfer & Data Query Resolution                |
|  Design sessions (Forecasting)                                   |
|  Testing & Training - Other Geos                                   |
|  Go-Live - Other Geos & Hypercare                                |
|  IT focused | Business focused | IT & Business  (floating)       |
|  + parallel 5-row US/CA vs Other Geos track                      |
|  Engagement Plan  (title at bottom)                              |
+------------------------------------------------------------------+
```

Problems: two timelines on one slide, ambiguous dates, geo order conflicts with SOW, stakeholder bands not tied to gates.

### After (recommended)

```
+------------------------------------------------------------------+
|  Engagement Plan: Phase 1 Forecasting          [IA logo]           |
|  ----------------------------------------------------------------|
|  Gantt (May-Aug)          |  IT-led                             |
|  6 rows + 3 diamonds      |  Business-led                       |
|                           |  Joint sign-off                      |
|  [delta footnote vs slide 17]                                    |
|  [IA blue footer bar]                                            |
+------------------------------------------------------------------+
```

Optional **slide 19b:** 6-box rollout grid (Intl → US/CA readout sequence per SOW).

---

## Gantt data (Timelines v3)

| Row | Phase | Owner | Milestones | Key dates |
|-----|-------|-------|------------|-----------|
| 1 | Data transfer & queries | LL / IA | M1–4 | May 16 – Jun 13 |
| 2 | Discovery & design | LL + IA | M6 | Jun 6 (sign-off gate) |
| 3 | Ingestion & daily feeds | LL + IA | M5 | through Jul 25 |
| 4 | US/CA build & readout | IA | M7–8 | Jul 4 – Jul 11 |
| 5 | Intl build & readout | IA | M11–12 | Aug 8 – Aug 22 |
| 6 | SIT, handover, hypercare | LL + IA | M9, 13 | Jul 11 – Aug 29 |

**Sign-off diamonds (amber):**

| Gate | Date | Gantt row |
|------|------|-----------|
| Data sign-off | Jun 6 | Row 1 |
| US/CA readout | Jul 11 | Row 4 |
| Final handover | Aug 29 | Row 6 |

---

## Delta vs kickoff slide 17

Kickoff deck slide 17 ("Lululemon Product Critical Milestones") shows **Jul–Nov 2026** dates. Timelines v3 Milestone Tracker shows **May 16 – Aug 29** for forecasting Phase 1.

| Milestone | Kickoff slide 17 | Timelines v3 (authoritative) |
|-----------|------------------|------------------------------|
| Historical data transfer | 12 Jul | **16 May** |
| Data checks & queries | 31 Jul | **30 May** |
| Historical data sign-off | 7 Aug | **6 Jun** |
| Transfer mechanism sign-off | 14 Jun* | **13 Jun** |
| Data ingestion & feeds | 25 Sept | **25 Jul** |
| US/CA model retraining | 18 Sept | **4 Jul** |
| Final handover | 27 Nov | **29 Aug** |

\*Slide 17 row 4 shows "14 Jun" while other rows are Jul–Nov; likely a typo.

**Recommendation:** Update slide 17 to match Timelines v3 in a separate pass. Slide 19 uses Timelines v3 only.

---

## Option A: Fastest: import IA PPTX as image (recommended)

1. Open `~/Documents/Lululemon_Engagement_Plan_Slide19_20260630.pptx` in PowerPoint or Keynote.
2. Export slide 1 as PNG (high resolution).
3. In Google Slides, go to **slide 19**.
4. Delete all existing shapes on slide 19 (dual tracks, floating IT/Business bands, bottom title).
5. **Insert → Image → Upload** the PNG; stretch to fill content area below section title.
6. Add section title at top if not in PNG: **Engagement Plan: Phase 1 Forecasting**.
7. Optional: insert slide 19b PNG as a new slide after slide 19 (rollout sequence).

Regenerate PPTX anytime:

```bash
node /Users/ejazanwarmd/Desktop/Lululemon/scripts/build_lululemon_engagement_slide.js
```

---

## Option B: Rebuild natively in Google Slides

### Step 1: Clear slide 19

Remove:

- Top date row (`July'13`, `Aug'07`, etc.)
- Both swimlane groups (4-row + 5-row tracks)
- Floating "IT focused / Business focused / IT & Business" band
- Bottom "Engagement Plan" title (move to top)

### Step 2: Add section title

- Text: **Engagement Plan: Phase 1 Forecasting**
- Place at top of slide (same style as other section slides)

### Step 3: Build Gantt table (left ~65%)

Create a table or grouped shapes:

**Column headers:** May | Jun | Jul | Aug

**Rows:**

1. Data transfer & queries: bar May–Jun: label `LL / IA`
2. Discovery & design: bar Jun–Jul: label `LL + IA`
3. Ingestion & daily feeds: bar Jun–Jul: label `LL + IA`
4. US/CA build & readout: bar Jul: label `IA`
5. Intl build & readout: bar Aug: label `IA`
6. SIT, handover, hypercare: bar Jul–Aug: label `LL + IA`

**Bar colors:**

| Meaning | Color |
|---------|-------|
| IA-led phase | Blue `#264CD7` |
| Complete (if showing progress) | Green `#3DD499` |
| Sign-off gate | Amber diamond `#E3F576` |

**Diamond markers at:** Jun 6 (Data sign-off), Jul 11 (US/CA readout), Aug 29 (Final handover)

### Step 4: Add stakeholder cards (right ~35%)

Three stacked cards:

| Header | Body |
|--------|------|
| IT-led | Data transfer, ingestion, feeds, SIT integration |
| Business-led | Design sessions, acceptance criteria, readout review |
| Joint sign-off | Historical data, transfer mechanism, handover gates |

### Step 5: Footer note

Add italic footnote above footer bar:

> Note: Kickoff deck slide 17 shows Jul–Nov dates; Timelines v3 (May 16–Aug 29) is authoritative.

### Step 6: Optional slide 19b

Insert new slide after 19. Title: **Rollout sequence: Intl then US/CA**

Six boxes in 2×3 grid (SOW readout order):

1. Intl Style-Color 52w
2. US/CA Style-Color 52w
3. Intl SKU-Store 52w
4. US/CA SKU-Store 52w
5. US SKU-Store 17w day
6. CAN SKU-Store 17w day

---

## Legend (add to speaker notes or small text on slide)

| Symbol | Meaning |
|--------|---------|
| Blue bar | Phase in progress or planned |
| Amber diamond | LL + IA sign-off gate |
| M1–13 | Milestone Tracker row in Timelines v3 |

---

## QA checklist (IA design system)

After update, verify:

- [ ] Section title at top (not bottom)
- [ ] One primary message: who leads what, May–Aug 2026
- [ ] Max 6 Gantt rows (no second geo swimlane on same slide)
- [ ] Dates match Timelines v3, not ambiguous `July'13` format
- [ ] Stakeholder cards tied to activity types (not floating bands)
- [ ] Delta footnote present if slide 17 not yet updated
- [ ] Slide 20 Planned Activities updated from [`lululemon_kickoff_slide20_planned_activities_draft.md`](lululemon_kickoff_slide20_planned_activities_draft.md)

---

## Related files

| File | Role |
|------|------|
| [`lululemon_kickoff_slide20_planned_activities_draft.md`](lululemon_kickoff_slide20_planned_activities_draft.md) | Slide 20 design sessions: Planned Activities column (paste draft) |
| [`scripts/build_lululemon_engagement_slide.js`](../scripts/build_lululemon_engagement_slide.js) | Regenerate IA PPTX |
| [`reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.md`](../reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.md) | Searchable timeline extract |
| [`.cursor/rules/lululemon-forecasting-timelines.mdc`](../.cursor/rules/lululemon-forecasting-timelines.mdc) | Authoritative timeline rule |
