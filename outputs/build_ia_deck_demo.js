"use strict";
const path = require("path");
const PptxGenJS = require(path.join(process.env.HOME, ".cursor/skills/ia-deck-cs/node_modules/pptxgenjs"));
const {
  addTitleSlide,
  addAgendaSlide,
  addContentSlide,
  addTakeawaysSlide,
  addCardWithIcon,
  addSixBoxGrid,
  addStatCard,
  addChartSlide,
} = require(path.join(process.env.HOME, ".cursor/skills/ia-deck-cs/scripts/helpers"));

const FOOTER = "Lululemon · Impact Analytics · Confidential";
const OUT = path.join(process.env.HOME, "Documents", "lululemon_data_readiness_demo.pptx");

const pres = new PptxGenJS();
pres.layout = "LAYOUT_16x9";

addTitleSlide(
  pres,
  "Demand Forecasting Data Readiness",
  "Executive summary · June 2026",
  null,
  "Lululemon"
);

addAgendaSlide(pres, [
  "Engagement scope",
  "Master data status",
  "Inbound feed health",
  "Forecasting grain alignment",
  "Next 90 days",
]);

// 3-column capabilities
const s1 = addContentSlide(pres, "Engagement scope", FOOTER);
addCardWithIcon(
  pres, s1, 0.35, 0.93, 2.90, 4.12,
  "Demand forecasting",
  "PSS × store/DC × week/day grains for allocation and inventory planning.",
  "analytics"
);
addCardWithIcon(
  pres, s1, 3.55, 0.93, 2.90, 4.12,
  "Sizing alignment",
  "Product size definitions and hierarchy mapped to platform master tables.",
  "layers"
);
addCardWithIcon(
  pres, s1, 6.75, 0.93, 2.90, 4.12,
  "Outcome delivery",
  "Table delivery, refresh cadence, and acceptance criteria per Jun 2026 SOW.",
  "target"
);

// 3-stat KPI row
const s2 = addContentSlide(pres, "Master data status", FOOTER);
addStatCard(pres, s2, 0.35, 0.95, 2.90, 4.10, "Product master", "12.4M", "SKUs in scope", "package");
addStatCard(pres, s2, 3.55, 0.95, 2.90, 4.10, "Store master", "680", "Active locations", "globe");
addStatCard(pres, s2, 6.75, 0.95, 2.90, 4.10, "Hierarchy depth", "L5", "Product attributes", "grid");

// 6-box feed health
const s3 = addContentSlide(pres, "Inbound feed health", FOOTER);
addSixBoxGrid(pres, s3, [
  { icon: "database", title: "Inventory snapshot", body: "Daily OH by SKU-store; latest sync validated." },
  { icon: "barChart", title: "Sales transactions", body: "POS gross and returns; partition filters applied." },
  { icon: "document", title: "Product master", body: "Hierarchy, size scale, and season attributes populated." },
  { icon: "check", title: "Store master", body: "Channel, region, and DC mapping complete." },
  { icon: "trendUp", title: "SKU details", body: "Pricing batch gate: Aug priced, Sep zeroed — flagged." },
  { icon: "shield", title: "Data quality", body: "EDA sign-off pack with Green/Amber/Red per drop." },
]);

// Chart slide
const trendData = [
  { name: "Rows ingested (M)", labels: ["Apr", "May", "Jun"], values: [42, 48, 51] },
  { name: "Target (M)", labels: ["Apr", "May", "Jun"], values: [40, 45, 50] },
];
addChartSlide(pres, "Ingestion volume vs plan", "line", trendData, FOOTER);

addTakeawaysSlide(pres, "Key takeaways", [
  "Master tables are loaded; hierarchy and store coverage meet forecasting grain requirements.",
  "Inbound GCS drops need batch-level pricing checks before downstream sourcing builds.",
  "Next 90 days: finalize intermediate table specs, EDA sign-off, and SOW table delivery milestones.",
], FOOTER);

pres.writeFile({ fileName: OUT }).then(() => {
  console.log("Wrote:", OUT);
});
