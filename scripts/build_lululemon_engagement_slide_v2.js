"use strict";
/**
 * Lululemon Engagement Plan — IA-branded v2 (custom executive layout)
 *
 * Same IA tokens (Inter Tight, #264CD7, cards, icons, footer) but NOT the
 * stock addTimelineSlide + side-card template. Uses a 4-phase journey,
 * date-accurate stat row, owner swimlanes, and sign-off gate rail.
 */
const os = require("os");
const path = require("path");
const PptxGenJS = require(path.join(os.homedir(), ".cursor/skills/ia-deck-cs/node_modules/pptxgenjs"));
const {
  IA,
  makeShadow,
  getIconData,
  addContentSlide,
  addStatCard,
  addFooter,
  addLogo,
} = require(path.join(os.homedir(), ".cursor/skills/ia-deck-cs/scripts/helpers"));

const FOOTER =
  "Lululemon · Phase 1 Forecasting · Timelines v3 · LL + IA sign-off at each gate";
const DATE_STAMP = new Date().toISOString().slice(0, 10).replace(/-/g, "");
const OUT = path.join(
  os.homedir(),
  "Documents",
  `Lululemon_Engagement_Plan_v2_Executive_${DATE_STAMP}.pptx`
);

const FONT = "Inter Tight";

const GATES = [
  { label: "Data sign-off", date: "Jun 6", icon: "database" },
  { label: "US/CA readout", date: "Jul 11", icon: "target" },
  { label: "Final handover", date: "Aug 29", icon: "rocket" },
];

const PHASES = [
  {
    num: "01",
    title: "Foundation",
    range: "May 16 – Jun 13",
    owner: "LL + IA",
    ownerColor: IA.blue,
    icon: "database",
    bullets: [
      "Historical data transfer (LL)",
      "Data checks and query resolution (IA)",
      "Transfer mechanism sign-off",
    ],
  },
  {
    num: "02",
    title: "Design & feeds",
    range: "Jun 6 – Jul 25",
    owner: "LL + IA",
    ownerColor: IA.blue,
    icon: "settings",
    bullets: [
      "Discovery and design sessions",
      "Data ingestion pipeline build",
      "Daily feed setup and stabilization",
    ],
  },
  {
    num: "03",
    title: "Model build",
    range: "Jul 4 – Aug 22",
    owner: "IA",
    ownerColor: IA.teal,
    icon: "analytics",
    bullets: [
      "US/CA retrain and readout (Jul 11)",
      "Intl geographies build (Aug 22)",
      "Benchmarking and fine-tuning",
    ],
  },
  {
    num: "04",
    title: "Integrate & launch",
    range: "Jul 11 – Aug 29",
    owner: "LL + IA",
    ownerColor: IA.blue,
    icon: "check",
    bullets: [
      "SIT with Lululemon systems",
      "UA iterations and readouts",
      "Final forecast handover all regions",
    ],
  },
];

const STAKEHOLDERS = [
  { icon: "database", title: "IT-led", body: "Data, ingestion, feeds, SIT" },
  { icon: "team", title: "Business-led", body: "Design, acceptance, readouts" },
  { icon: "shield", title: "Joint gates", body: "Sign-off at each phase exit" },
];

function addOwnerPill(slide, x, y, text, color) {
  const w = 0.72;
  const h = 0.22;
  slide.addShape("roundRect", {
    x,
    y,
    w,
    h,
    fill: { color },
    line: { color },
    rectRadius: 0.08,
  });
  slide.addText(text, {
    x,
    y,
    w,
    h,
    fontSize: 7.5,
    bold: true,
    color: IA.white,
    fontFace: FONT,
    align: "center",
    valign: "middle",
  });
}

function addPhaseCard(pres, slide, x, y, w, h, phase) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x,
    y,
    w,
    h,
    fill: { color: IA.bgCard },
    line: { color: IA.border, width: 1 },
    shadow: makeShadow(),
  });

  slide.addShape(pres.shapes.RECTANGLE, {
    x,
    y,
    w,
    h: 0.06,
    fill: { color: phase.ownerColor },
    line: { color: phase.ownerColor },
  });

  slide.addText(phase.num, {
    x: x + 0.12,
    y: y + 0.14,
    w: 0.45,
    h: 0.38,
    fontSize: 22,
    bold: true,
    color: IA.blueLight,
    fontFace: FONT,
  });

  slide.addShape(pres.shapes.OVAL, {
    x: x + w - 0.58,
    y: y + 0.08,
    w: 0.40,
    h: 0.40,
    fill: { color: phase.ownerColor },
    line: { color: phase.ownerColor },
  });
  slide.addImage({
    data: getIconData(phase.icon, "FFFFFF"),
    x: x + w - 0.52,
    y: y + 0.14,
    w: 0.28,
    h: 0.28,
  });

  slide.addText(phase.title, {
    x: x + 0.12,
    y: y + 0.48,
    w: w - 0.24,
    h: 0.32,
    fontSize: 11.5,
    bold: true,
    color: IA.text,
    fontFace: FONT,
  });

  slide.addText(phase.range, {
    x: x + 0.12,
    y: y + 0.78,
    w: w - 0.24,
    h: 0.22,
    fontSize: 8.5,
    color: IA.textMuted,
    fontFace: FONT,
  });

  addOwnerPill(slide, x + 0.12, y + 1.02, phase.owner, phase.ownerColor);

  slide.addShape(pres.shapes.LINE, {
    x: x + 0.14,
    y: y + 1.32,
    w: w - 0.28,
    h: 0,
    line: { color: IA.border, width: 0.75 },
  });

  const bulletText = phase.bullets.map((b) => `• ${b}`).join("\n");
  slide.addText(bulletText, {
    x: x + 0.12,
    y: y + 1.38,
    w: w - 0.22,
    h: h - 1.48,
    fontSize: 8.5,
    color: IA.text,
    fontFace: FONT,
    valign: "top",
    lineSpacing: 14,
  });
}

function addChevron(pres, slide, x, y) {
  slide.addShape(pres.shapes.ISOSCELES_TRIANGLE, {
    x,
    y,
    w: 0.18,
    h: 0.28,
    fill: { color: IA.blueLight },
    line: { color: IA.blueLight },
    rotate: 90,
  });
}

function addSignOffRail(pres, slide, y) {
  const x0 = 0.55;
  const x1 = 9.45;
  const midY = y + 0.18;

  slide.addText("Sign-off gates", {
    x: 0.35,
    y: y - 0.02,
    w: 1.2,
    h: 0.22,
    fontSize: 8.5,
    bold: true,
    color: IA.blue,
    fontFace: FONT,
  });

  slide.addShape(pres.shapes.LINE, {
    x: x0,
    y: midY,
    w: x1 - x0,
    h: 0,
    line: { color: IA.border, width: 1.5 },
  });

  const positions = [0.18, 0.50, 0.82];
  GATES.forEach((gate, i) => {
    const gx = x0 + (x1 - x0) * positions[i] - 0.09;
    slide.addShape(pres.shapes.RECTANGLE, {
      x: gx,
      y: midY - 0.09,
      w: 0.18,
      h: 0.18,
      fill: { color: IA.amber },
      line: { color: IA.amber },
      rotate: 45,
    });
    slide.addText(gate.date, {
      x: gx - 0.22,
      y: midY - 0.38,
      w: 0.62,
      h: 0.22,
      fontSize: 9,
      bold: true,
      color: IA.blue,
      fontFace: FONT,
      align: "center",
    });
    slide.addText(gate.label, {
      x: gx - 0.35,
      y: midY + 0.14,
      w: 0.88,
      h: 0.28,
      fontSize: 7.5,
      color: IA.textMuted,
      fontFace: FONT,
      align: "center",
    });
  });
}

function addStakeholderStrip(pres, slide, y) {
  const w = 2.90;
  const gap = 0.30;
  STAKEHOLDERS.forEach((s, i) => {
    const x = 0.35 + i * (w + gap);
    slide.addShape(pres.shapes.RECTANGLE, {
      x,
      y,
      w,
      h: 0.72,
      fill: { color: IA.bgCard },
      line: { color: IA.border, width: 1 },
      shadow: makeShadow(),
    });
    slide.addShape(pres.shapes.RECTANGLE, {
      x,
      y,
      w: 0.055,
      h: 0.72,
      fill: { color: IA.blue },
      line: { color: IA.blue },
    });
    slide.addShape(pres.shapes.OVAL, {
      x: x + 0.14,
      y: y + 0.14,
      w: 0.38,
      h: 0.38,
      fill: { color: IA.blue },
      line: { color: IA.blue },
    });
    slide.addImage({
      data: getIconData(s.icon, "FFFFFF"),
      x: x + 0.20,
      y: y + 0.20,
      w: 0.26,
      h: 0.26,
    });
    slide.addText(s.title, {
      x: x + 0.58,
      y: y + 0.12,
      w: w - 0.66,
      h: 0.24,
      fontSize: 10,
      bold: true,
      color: IA.text,
      fontFace: FONT,
    });
    slide.addText(s.body, {
      x: x + 0.58,
      y: y + 0.36,
      w: w - 0.66,
      h: 0.30,
      fontSize: 8.5,
      color: IA.textMuted,
      fontFace: FONT,
    });
  });
}

const pres = new PptxGenJS();
pres.layout = "LAYOUT_16x9";

const slide = addContentSlide(pres, "Engagement Plan: Phase 1 Forecasting", FOOTER);

slide.addText("May – Aug 2026  ·  Forecasting track  ·  Source: Timelines v3", {
  x: 0.35,
  y: 0.82,
  w: 8.5,
  h: 0.22,
  fontSize: 9,
  color: IA.textMuted,
  fontFace: FONT,
  italic: true,
});

GATES.forEach((gate, i) => {
  addStatCard(
    pres,
    slide,
    0.35 + i * 3.20,
    1.05,
    2.90,
    1.05,
    gate.label,
    gate.date,
    "2026 milestone",
    gate.icon
  );
});

const cardY = 2.22;
const cardH = 2.05;
const cardW = 2.05;
const gap = 0.22;
const startX = 0.35;

PHASES.forEach((phase, i) => {
  const x = startX + i * (cardW + gap + 0.18);
  addPhaseCard(pres, slide, x, cardY, cardW, cardH, phase);
  if (i < PHASES.length - 1) {
    addChevron(pres, slide, x + cardW + 0.02, cardY + cardH / 2 - 0.14);
  }
});

addSignOffRail(pres, slide, 4.38);
addStakeholderStrip(pres, slide, 4.78);

pres.writeFile({ fileName: OUT }).then(() => {
  console.log("Wrote:", OUT);
});
