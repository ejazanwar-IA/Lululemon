"use strict";
/**
 * IA-branded Slide 19 (Engagement Plan) + optional Slide 19b (Rollout sequence)
 * Source dates: reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.xlsx
 */
const os = require("os");
const path = require("path");
const PptxGenJS = require(path.join(os.homedir(), ".cursor/skills/ia-deck-cs/node_modules/pptxgenjs"));
const {
  addContentSlide,
  addTimelineViz,
  addCardWithIcon,
  addSixBoxGrid,
} = require(path.join(os.homedir(), ".cursor/skills/ia-deck-cs/scripts/helpers"));

const FOOTER =
  "Lululemon business and IT sign-off required at each gate | Source: Timelines v3";
const DELTA_FOOTNOTE =
  "Note: Kickoff deck slide 17 shows Jul–Nov dates; Timelines v3 (May 16–Aug 29) is authoritative.";
const DATE_STAMP = new Date().toISOString().slice(0, 10).replace(/-/g, "");
const OUT = path.join(
  os.homedir(),
  "Documents",
  `Lululemon_Engagement_Plan_Slide19_${DATE_STAMP}.pptx`
);

// Timelines v3 Milestone Tracker → 6 Gantt rows (May–Aug 2026)
const PERIODS = ["May", "Jun", "Jul", "Aug"];

const PHASES = [
  {
    label: "Data transfer & queries",
    startPeriod: 0,
    durationPeriods: 2,
    status: "active",
    barLabel: "LL / IA · M1–4",
  },
  {
    label: "Discovery & design",
    startPeriod: 1,
    durationPeriods: 2,
    status: "upcoming",
    barLabel: "LL + IA · M6",
  },
  {
    label: "Ingestion & daily feeds",
    startPeriod: 1,
    durationPeriods: 2,
    status: "upcoming",
    barLabel: "LL + IA · M5",
  },
  {
    label: "US/CA build & readout",
    startPeriod: 2,
    durationPeriods: 1,
    status: "upcoming",
    barLabel: "IA · M7–8",
  },
  {
    label: "Intl build & readout",
    startPeriod: 3,
    durationPeriods: 1,
    status: "upcoming",
    barLabel: "IA · M11–12",
  },
  {
    label: "SIT, handover, hypercare",
    startPeriod: 2,
    durationPeriods: 2,
    status: "upcoming",
    barLabel: "LL + IA · M9,13",
  },
];

const MILESTONES = [
  { label: "Data sign-off", period: 1, row: 0 },
  { label: "US/CA readout", period: 2, row: 3 },
  { label: "Final handover", period: 3, row: 5 },
];

const STAKEHOLDER_CARDS = [
  {
    icon: "database",
    header: "IT-led",
    body: "Data transfer, ingestion, feeds, SIT integration",
  },
  {
    icon: "team",
    header: "Business-led",
    body: "Design sessions, acceptance criteria, readout review",
  },
  {
    icon: "check",
    header: "Joint sign-off",
    body: "Historical data, transfer mechanism, handover gates",
  },
];

const ROLLOUT_ITEMS = [
  {
    icon: "globe",
    title: "Intl Style-Color 52w",
    body: "Phase 1 readout #1 · Submarket Channel × Week",
  },
  {
    icon: "target",
    title: "US/CA Style-Color 52w",
    body: "Phase 1 readout #2 · Submarket Channel × Week",
  },
  {
    icon: "globe",
    title: "Intl SKU-Store 52w",
    body: "Phase 1 readout #3 · Store/DC × Week",
  },
  {
    icon: "target",
    title: "US/CA SKU-Store 52w",
    body: "Phase 1 readout #4 · Store/DC × Week",
  },
  {
    icon: "clock",
    title: "US SKU-Store 17w day",
    body: "Phase 1 readout #5 · Day-level disaggregation",
  },
  {
    icon: "clock",
    title: "CAN SKU-Store 17w day",
    body: "Phase 1 readout #6 · Day-level disaggregation",
  },
];

const pres = new PptxGenJS();
pres.layout = "LAYOUT_16x9";

// Slide 19 — Gantt (left) + stakeholder cards (right)
const s19 = addContentSlide(pres, "Engagement Plan: Phase 1 Forecasting", FOOTER);
addTimelineViz(pres, s19, PHASES, PERIODS, MILESTONES, {
  x: 0.35,
  y: 0.93,
  w: 5.65,
  h: 3.85,
});

const cardX = 6.25;
const cardW = 3.40;
const cardGap = 0.10;
const cardH = (3.85 - cardGap * 2) / 3;
STAKEHOLDER_CARDS.forEach((card, i) => {
  addCardWithIcon(
    pres,
    s19,
    cardX,
    0.93 + i * (cardH + cardGap),
    cardW,
    cardH,
    card.header,
    card.body,
    card.icon
  );
});

s19.addText(DELTA_FOOTNOTE, {
  x: 0.35,
  y: 4.88,
  w: 9.30,
  h: 0.28,
  fontSize: 8,
  color: "888888",
  fontFace: "Inter Tight",
  italic: true,
});

// Slide 19b — SOW readout sequence
const s19b = addContentSlide(pres, "Rollout sequence: Intl then US/CA", FOOTER);
addSixBoxGrid(pres, s19b, ROLLOUT_ITEMS);

pres.writeFile({ fileName: OUT }).then(() => {
  console.log("Wrote:", OUT);
  console.log("Slides: 2 (Engagement Plan + Rollout sequence)");
});
