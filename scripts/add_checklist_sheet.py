"""Add / refresh the 'Master Table Checklist' sheet in Lululemon_EDA_Findings.xlsx.

Reads the checklist structure directly — source of truth is
`findings/master_table_checklist.md`. This script keeps the Excel tab in sync
with the hand-maintained status in that md.
"""
from __future__ import annotations

from pathlib import Path

from openpyxl import load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parent.parent
WB_PATH = ROOT / "findings" / "Lululemon_EDA_Findings.xlsx"
SHEET = "Master Table Checklist"

HEADER_FILL = PatternFill("solid", fgColor="1F2937")
HEADER_FONT = Font(bold=True, color="FFFFFF")
SECTION_FILL = PatternFill("solid", fgColor="374151")
SECTION_FONT = Font(bold=True, color="FFFFFF")
STATUS_FILL = {
    "Done":  PatternFill("solid", fgColor="D1FAE5"),
    "WIP":   PatternFill("solid", fgColor="FEF3C7"),
    "Open":  PatternFill("solid", fgColor="FEE2E2"),
    "N/A":   PatternFill("solid", fgColor="E5E7EB"),
}

HEADERS = ["Stage", "ID", "Check", "product", "txn", "inv", "store", "fiscal", "Evidence / Comment"]


def row(stage, cid, check, p="-", t="-", i="-", s="-", f="-", ev=""):
    return [stage, cid, check, p, t, i, s, f, ev]


# Populated from master_table_checklist.md. Kept compact.
DATA: list[list[str]] = [
    # --- Stage 0 ---
    row("0 — Pre-build", "S0.1", "Grain documented up-front", "Done","Done","Done","Done","Done","master_table_build_logic.md"),
    row("0 — Pre-build", "S0.2", "Source tables listed with alias convention", "Done","Done","Done","Done","Done","master_table_build_logic.md"),
    row("0 — Pre-build", "S0.3", "Column inventory with origin intent", "Done","Done","Done","Done","Done","column-origin tables per master"),
    row("0 — Pre-build", "S0.4", "Join keys + cardinality expectation", "Done","Done","Done","Done","Done","consolidated_p0_p1_issues.md"),
    # --- Stage 1 ---
    row("1 — Build-script review", "S1.1", "Hardcoded NULL/0/constants enumerated & justified", "Done","Done","Done","Done","Done","master_table_build_logic.md Section  1–6"),
    row("1 — Build-script review", "S1.2", "CASE/IF polarity vs source field verified", "Done","N/A","N/A","WIP","N/A","store_master.active = LOC_CLOSED_IND — open with DE"),
    row("1 — Build-script review", "S1.3", "String manipulation NULL-safety", "Done","Done","N/A","Done","N/A","SPLIT/CONCAT sites reviewed"),
    row("1 — Build-script review", "S1.4", "CTE aggregation semantics reviewed", "N/A","WIP","N/A","N/A","N/A","all_skus AS AVG(cost_price) — DE review"),
    row("1 — Build-script review", "S1.5", "DISTINCT / GROUP BY usage justified", "Done","WIP","Done","Done","Done","txn uses SELECT DISTINCT — 660K gap"),
    row("1 — Build-script review", "S1.6", "Source-snapshot consistency across joins", "Done","Done","WIP","Done","Done","inv joins non-suffixed pgh"),
    row("1 — Build-script review", "S1.7", "Partition & cluster keys aligned with queries", "N/A","N/A","Done","N/A","N/A","inv PARTITION BY date, CLUSTER BY store_code"),
    # --- Stage 2 ---
    row("2 — Global G1–G6", "G1", "Total row count", "Done","Done","Done","Done","Done","consolidated_p0_p1_issues.md"),
    row("2 — Global G1–G6", "G2", "Column-level data dictionary", "Done","Done","Done","Done","Done","schema_inventory.md + EDA files"),
    row("2 — Global G1–G6", "G3", "Null % per column + decision", "Done","Done","Done","Done","Done","merged with S1.1"),
    row("2 — Global G1–G6", "G4", "Outliers + categorical standardization", "Done","Done","Done","Done","Done","per-master EDA SQL"),
    row("2 — Global G1–G6", "G5", "Grain confirmed by COUNT DISTINCT = COUNT(*)", "Done","Done","Done","Done","Done","EDA Q1/Q2"),
    row("2 — Global G1–G6", "G6", "Row-level duplicate check", "Done","Done","Done","Done","Done","txn has 660K near-dupes"),
    # --- Stage 3A — Transaction (single-master focus) ---
    row("3A — Transaction", "T1",  "Classify txns by type (qty / fulfilment / shipping / channel)", "-","Open","-","-","-","transaction_type / order_type hardcoded NULL"),
    row("3A — Transaction", "T2",  "Qty > 0 when Retail/Cost Price = 0/null", "-","Done","-","-","-","cost=0 for ~54% of rows"),
    row("3A — Transaction", "T3",  "Qty > 0 when Net Selling Price = 0/null", "-","Done","-","-","-","flagged"),
    row("3A — Transaction", "T4",  "Discount > 0 with Qty > 0", "-","Open","-","-","-","discount cols hardcoded 0"),
    row("3A — Transaction", "T5",  "Qty < 0 but revenue > 0", "-","Done","-","-","-","returns flow"),
    row("3A — Transaction", "T6",  "Net Selling Price < 0 for Qty > 0", "-","Done","-","-","-","D-series"),
    row("3A — Transaction", "T7",  "Discount amt not in sync with Retail/Net Sales", "-","Open","-","-","-","disc hardcoded"),
    row("3A — Transaction", "T8",  "Discount Amt > Retail Unit Price", "-","Open","-","-","-","disc hardcoded"),
    row("3A — Transaction", "T9",  "Net Selling Price < Cost Price (neg margin)", "-","Done","-","-","-","distorted by cost=0"),
    row("3A — Transaction", "T10", "Retail Price < Cost Price with qty > 0", "-","Done","-","-","-","subset of T9"),
    row("3A — Transaction", "T11", "NSP > RUP with disc<0 & qty>0", "-","Open","-","-","-","disc hardcoded"),
    row("3A — Transaction", "T12", "NSP < RUP & disc>0 with qty>0", "-","Open","-","-","-","disc hardcoded"),
    row("3A — Transaction", "T13", "Multiple RUP for a SKU", "-","WIP","-","-","-","price variation — partial"),
    row("3A — Transaction", "T14", "Multiple RUP for SKU-Date", "-","Open","-","-","-","not yet run"),
    row("3A — Transaction", "T15", "Multiple RUP for SKU-Store-Date", "-","Open","-","-","-","not yet run"),
    row("3A — Transaction", "T16", "Range (min/max/stddev) of RUP for SKUs", "-","Done","-","-","-","D-series"),
    row("3A — Transaction", "T17", "Range (min/max/stddev) of Disc % for SKUs", "-","Open","-","-","-","disc hardcoded"),
    row("3A — Transaction", "T18", "Min & max txn date", "-","Done","-","-","-","4 years confirmed"),
    row("3A — Transaction", "T19", "Distribution of qty_sold", "-","Done","-","-","-","D-series histogram"),
    row("3A — Transaction", "T20", "Missing dates in txn master", "-","Done","-","-","-","no gaps"),
    row("3A — Transaction", "T21", "CLEARANCE_IND spread", "-","Open","-","-","-","clearance hardcoded 0"),
    row("3A — Transaction", "T22", "Multi-currency", "-","Open","-","-","-","currency_exchange_rate NULL"),
    row("3A — Transaction", "T23", "SKUs in txn missing from product master", "-","Done","-","-","-","cross-master integrity"),
    row("3A — Transaction", "T24", "Multiple store_code at TransID-LineID", "-","Open","-","-","-","not yet run"),
    row("3A — Transaction", "T25", "Multiple SKU at TransID-LineID", "-","Open","-","-","-","not yet run"),
    # --- Stage 3B — Product ---
    row("3B — Product", "P1", "Active-flag source / fallback via recent txn", "WIP","-","-","-","-","active_flag hardcoded; use flex_status"),
    row("3B — Product", "P2", "Dept/Class/Subclass → one description each", "Done","-","-","-","-","hierarchy integrity"),
    row("3B — Product", "P3", "Sub-SKUs in txn (retail) present in PM", "Done","-","-","-","-","coverage"),
    row("3B — Product", "P4", "Sub-SKUs in txn (outlet) present in PM", "Done","-","-","-","-","coverage"),
    row("3B — Product", "P5", "Sub-SKUs in txn (ECom) present in PM", "Done","-","-","-","-","coverage"),
    row("3B — Product", "P6", "Duplicates at attribute level for Sub-SKU", "Open","-","-","-","-","not yet run"),
    row("3B — Product", "P7", "Sub-SKU in inv present in PM", "Done","-","-","-","-","23,782 PM SKUs not in inv"),
    row("3B — Product", "P8", "Multi-currency", "N/A","-","-","-","-","out-of-scope for PM"),
    row("3B — Product", "P9", "1:1 hierarchy integrity", "Done","-","-","-","-","hierarchy check done"),
    # --- Stage 3C — Inventory ---
    row("3C — Inventory", "I1",  "SKU in inv but not in txn (dead stock)", "-","-","Done","-","-","cross-master"),
    row("3C — Inventory", "I2",  "SKU in txn but not in inv", "-","-","Done","-","-","cross-master"),
    row("3C — Inventory", "I3",  "SKUs in inv not in PM", "-","-","Done","-","-","cross-master"),
    row("3C — Inventory", "I4",  "Store in inv present in SM", "-","-","Done","-","-","cross-master"),
    row("3C — Inventory", "I5",  "Inventory allocated to closed stores", "-","-","Open","-","-","depends on S1.2 polarity"),
    row("3C — Inventory", "I6",  "On-hand < 0", "-","-","Done","-","-","P0 flag"),
    row("3C — Inventory", "I7",  "On-hand = 0", "-","-","Done","-","-","zero-OH by channel"),
    row("3C — Inventory", "I8",  "Total DC count", "-","-","Done","-","-","store audit"),
    row("3C — Inventory", "I9",  "DC min/max dates + DC OH", "-","-","WIP","-","-","needs DC-specific slice"),
    row("3C — Inventory", "I10", "Inv/txn overlap (flow check)", "-","-","Open","-","-","SKU-store-date join not yet run"),
    row("3C — Inventory", "I11", "Sales ≤ inventory per SKU-store-date", "-","-","Open","-","-","CRITICAL for Sizesmart"),
    # --- Stage 3D — Store ---
    row("3D — Store", "S1", "Store code format consistent", "-","-","-","Done","-","location_audit.md"),
    row("3D — Store", "S2", "Store IDs in txn present in SM", "-","-","-","Done","-","location_audit.md"),
    row("3D — Store", "S3", "Store IDs in inv present in SM", "-","-","-","Done","-","location_audit.md"),
    row("3D — Store", "S4", "Store count by channel", "-","-","-","Done","-","location_audit.md"),
    row("3D — Store", "S5", "Closed-date spread", "-","-","-","Done","-","3 stores w/ close dates"),
    # --- Stage 3E — Fiscal ---
    row("3E — Fiscal", "F1", "Calendar continuity (no missing days)", "-","-","-","-","Done","fiscal EDA Q1"),
    row("3E — Fiscal", "F2", "Week/month/quarter/year hierarchy 1:1", "-","-","-","-","Done","fiscal EDA Q2"),
    row("3E — Fiscal", "F3", "Season coverage", "-","-","-","-","Done","fiscal EDA Q3"),
    row("3E — Fiscal", "F4", "Hardcoded NULL columns enumerated", "-","-","-","-","Done","13 cols — build logic Section  6"),
    row("3E — Fiscal", "F5", "Prior-period window functions sanity check", "-","-","-","-","Done","fiscal EDA Q4"),
    row("3E — Fiscal", "F6", "Holiday/trend columns — populate plan", "-","-","-","-","Open","business rules needed"),
    # --- Stage 4 ---
    row("4 — Lineage",   "L1", "Raw → master column-level lineage diagram", "Done","Done","Done","Done","Done","raw_to_master_lineage.md"),
    row("4 — Lineage",   "L2", "Column origin tagged (real/hardcoded/derived/dup/bug)", "Done","Done","Done","Done","Done","column-origin tables"),
    row("4 — Lineage",   "L3", "Open questions tagged to owner", "Done","Done","Done","Done","Done","Open Questions blocks per master"),
    # --- Stage 5A — Store EDA ---
    row("5A — Store EDA",  "SD1",  "SKU-Store-Date: qty_sold > on-hand inv", "-","-","Open","-","-","blocker for Sizesmart"),
    row("5A — Store EDA",  "SD2",  "Sales pattern across H1 / Year", "-","Open","-","-","-",""),
    row("5A — Store EDA",  "SD3",  "Sales pattern across Channel × Year", "-","Open","-","-","-",""),
    row("5A — Store EDA",  "SD4",  "SKU count across H1", "-","-","-","-","-","Open"),
    row("5A — Store EDA",  "SD5",  "Revenue-based SKU classification (ABC)", "Open","-","-","-","-",""),
    row("5A — Store EDA",  "SD6",  "Age-based SKU classification", "Open","-","-","-","-","needs inv + txn"),
    row("5A — Store EDA",  "SD7",  "Hierarchy x min/max date x sales x qty x new-SKU x contribution", "Open","-","-","-","-",""),
    row("5A — Store EDA",  "SD8",  "Promo behavior by dept", "-","Open","-","-","-","blocked by disc=0"),
    row("5A — Store EDA",  "SD9",  "Product life-cycle on sales flow × merch cat", "-","Open","-","-","-",""),
    row("5A — Store EDA",  "SD10", "Sales > inventory TY — top SKU / top dept", "-","-","Open","-","-",""),
    row("5A — Store EDA",  "SD11", "Discount flow EDA + future promo guidance", "-","Open","-","-","-","blocked by disc=0"),
    row("5A — Store EDA",  "SD12", "Retail price range across class/sub-class/dept", "-","Open","-","-","-",""),
    # --- Stage 5B — Ecom EDA ---
    row("5B — Ecom EDA",   "ED1",  "Distribution of SKUs across channels", "-","Open","-","-","-",""),
    row("5B — Ecom EDA",   "ED2",  "Ecom-only vs retail-only SKU overlap", "-","Open","-","-","-",""),
    row("5B — Ecom EDA",   "ED3",  "Price/discount variation Ecom vs BnM", "-","Open","-","-","-","disc blocked"),
    row("5B — Ecom EDA",   "ED4",  "Drop-ship / dotcom-exclusive SKU sales pattern", "-","Open","-","-","-","if feed has indicator"),
    row("5B — Ecom EDA",   "ED5",  "Channel × dept × season contribution", "-","Open","-","-","-",""),
]


def colour_cell(cell, value):
    v = str(value).strip()
    # Convert shorthand for md -> Excel (Done/WIP/Open/N/A are already here)
    if v in STATUS_FILL:
        cell.fill = STATUS_FILL[v]
        cell.alignment = Alignment(horizontal="center", vertical="center")


def main() -> None:
    wb = load_workbook(WB_PATH)
    if SHEET in wb.sheetnames:
        del wb[SHEET]
    # Place as second tab (right after the summary) if possible
    ws = wb.create_sheet(SHEET, index=min(1, len(wb.sheetnames)))

    # Header
    for col_idx, h in enumerate(HEADERS, start=1):
        c = ws.cell(row=1, column=col_idx, value=h)
        c.fill = HEADER_FILL
        c.font = HEADER_FONT
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    prev_stage = None
    for r_idx, row_data in enumerate(DATA, start=2):
        for col_idx, value in enumerate(row_data, start=1):
            cell = ws.cell(row=r_idx, column=col_idx, value=value)
            cell.alignment = Alignment(vertical="center", wrap_text=True)
            if col_idx in (4, 5, 6, 7, 8):
                colour_cell(cell, value)

        # Section tint on stage when it changes (subtle)
        if row_data[0] != prev_stage:
            prev_stage = row_data[0]

    # Column widths
    widths = [26, 8, 55, 10, 10, 10, 10, 10, 60]
    for i, w in enumerate(widths, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w

    # Freeze header + first 3 columns
    ws.freeze_panes = "D2"

    # Autofilter
    ws.auto_filter.ref = f"A1:{get_column_letter(len(HEADERS))}{ws.max_row}"

    wb.save(WB_PATH)
    print(f"Wrote {ws.max_row - 1} rows to '{SHEET}' in {WB_PATH}")


if __name__ == "__main__":
    main()
