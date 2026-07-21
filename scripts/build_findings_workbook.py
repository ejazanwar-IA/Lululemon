#!/usr/bin/env python3
"""
Build a multi-sheet Excel workbook consolidating all EDA findings.

Output: findings/Lululemon_EDA_Findings.xlsx
Sheets:
  1. README            - Navigation
  2. Dashboard         - Exec-level status per table
  3. Action Items      - Full tracker (filterable) — now includes Root Cause
  4. Build Logic Stubs - Columns hardcoded NULL/0 in master build scripts
  5. Canonical Tables  - 26 tables reference card
  6. Data Quirks       - Known sentinels, typos, unusual patterns
  7. Self-Resolved     - Derivations applied internally

v2 (2026-04-21): Root Cause categorization added after learning master-table
build logic (see findings/master_table_build_logic.md).
"""

from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.table import Table, TableStyleInfo
from pathlib import Path

# -----------------------------------------------------------------------------
# Styling helpers
# -----------------------------------------------------------------------------

HEADER_FILL = PatternFill("solid", fgColor="1F4E78")
HEADER_FONT = Font(bold=True, color="FFFFFF", size=11)
TITLE_FONT = Font(bold=True, size=16, color="1F4E78")
SUBTITLE_FONT = Font(italic=True, size=10, color="7F7F7F")

FILL_P0 = PatternFill("solid", fgColor="F4CCCC")  # light red
FILL_P1 = PatternFill("solid", fgColor="FFF2CC")  # light yellow
FILL_P2 = PatternFill("solid", fgColor="D9EAD3")  # light green
FILL_RESOLVED = PatternFill("solid", fgColor="CFE2F3")  # light blue
FILL_DEFERRED = PatternFill("solid", fgColor="EAD1DC")  # light purple

THIN = Side(border_style="thin", color="CCCCCC")
CELL_BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)


def style_header_row(ws, row_idx, num_cols):
    for col in range(1, num_cols + 1):
        cell = ws.cell(row=row_idx, column=col)
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
        cell.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)
        cell.border = CELL_BORDER
    ws.row_dimensions[row_idx].height = 28


def set_col_widths(ws, widths):
    for i, w in enumerate(widths, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w


def write_title(ws, title, subtitle=None):
    ws.cell(row=1, column=1, value=title).font = TITLE_FONT
    if subtitle:
        ws.cell(row=2, column=1, value=subtitle).font = SUBTITLE_FONT
    return 4 if subtitle else 3  # next row to use


def apply_severity_fill(ws, row_idx, severity, num_cols):
    fills = {
        "P0": FILL_P0,
        "P1": FILL_P1,
        "P2": FILL_P2,
        "Resolved": FILL_RESOLVED,
        "Deferred": FILL_DEFERRED,
    }
    fill = fills.get(severity)
    if fill:
        for col in range(1, num_cols + 1):
            ws.cell(row=row_idx, column=col).fill = fill


def add_filter(ws, start_row, num_cols, end_row):
    ws.auto_filter.ref = f"A{start_row}:{get_column_letter(num_cols)}{end_row}"


# -----------------------------------------------------------------------------
# Root Cause mapping (v2 — post build-logic review)
# -----------------------------------------------------------------------------
# A = Source data gap (client escalation)
# B = Build-script stub (ask Ritik/DE — column hardcoded NULL/0 in DDL)
# C = Build-script logic bug/question (internal code review)
# D = Real business anomaly (outliers, negative OH, etc.)
# E = Cosmetic / naming / redundancy
# R = Self-resolved / workaround

ROOT_CAUSE = {
    "P0-1": ("A — Source data", "sku_details.COST_PRICE / SELLING_PRICE are 0 in raw"),
    "P0-2": ("B — Build stub", "Discount cols hardcoded 0 in master DDL; likely sourced from price_book"),
    "P0-3": ("D — Real anomaly", "Negative OH — investigate legitimacy"),
    "P0-4": ("A — Source data", "inventory_snapshot doesn't have pre-2023 history"),
    "P0-5": ("A — Source data", "product_master is single-season snapshot from PGH"),
    "P0-0": ("B — Build stub", "launch_date = NULL hardcoded in master DDL (deferred)"),
    "T4":   ("D — Real anomaly", "Extreme outliers — wholesale or data errors"),
    "T5":   ("D — Real anomaly", "Negative price + cost > price — likely data errors"),
    "T6":   ("B — Build stub", "All 12 cols hardcoded NULL in transaction_master DDL"),
    "T9":   ("B — Build stub", "clearance, flagged_rows hardcoded 0 in DDL"),
    "T10":  ("D — Real anomaly", "qty>0 but price=0 — likely free/promo items"),
    "I1":   ("B — Build stub", "oo, wip, initial_oh_quantity hardcoded 0 in DDL"),
    "I4":   ("D — Real anomaly", "Extreme max OH — DC aggregate likely"),
    "PM-4": ("D — Real anomaly", "Placeholder SKUs (short article codes)"),
    "PM-7": ("A — Source data", "fit_classification NULL in source product_attribute_s"),
    "PM-9": ("E — Semantics", "flex_status='Drop' meaning needs clarification"),
    "PM-11":("A — Source data", "size_scale lookup not provided"),
    "S1":   ("E — Cosmetic", "CMNTY vs COMMUNITY spelling inconsistency"),
    "S3":   ("A — Source data", "store_format_code NULL in 21% of raw"),
    "S4":   ("C — Build logic", "active = LOC_CLOSED_IND — polarity may be inverted"),
    "S5":   ("E — Semantics", "non-transactional channel codes (expected)"),
    "C1":   ("A — Source data", "calendar needs 3 more years appended"),
    "W1":   ("R — Workaround", "Combine flex_status with transaction recency"),
    "W2":   ("R — Workaround", "Filter qty>0 AND revenue>0"),
    "PM-T1":("E — Cosmetic", "l8_name has multiple values per l8_id"),
    "PM-T10":("E — Cosmetic", "designed_for_activity ≈ global_merch_team"),
    "PM-IVIVVA":("D — Real anomaly", "Deprecated brand still in master"),
    "PM-LAB":("D — Real anomaly", "Lab line 97.8% unsold"),
    "TM-CHAN":("E — Cosmetic", "channel/ws_channel duplicates"),
    "TM-TYPO":("E — Cosmetic", "fullfilment spelling typo"),
    "S2":   ("B — Build stub", "special_classification = NULL hardcoded"),
    "S6":   ("E — Cosmetic", "lat/long STRING not FLOAT"),
    "S7":   ("D — Real anomaly", "Virtual store address mismatches"),
    "S8":   ("E — Cosmetic", "s3_id name inconsistency"),
    "S9":   ("D — Real anomaly", "Placeholder open_dates (1999-12-31)"),
    "C2":   ("E — Semantics", "201401 sentinel for no-LY-comp"),
    "I2":   ("B — Build stub", "total_units = oh (same UNITS_ON_HAND source)"),
    "I6":   ("D — Real anomaly", "SKUs never stocked (new launches/placeholders)"),
    "I7":   ("D — Real anomaly", "Stores never stocked (inactive/closed)"),
    "I8":   ("D — Real anomaly", "ivivva 4.5M units across 1,312 stores — stranded?"),
    "R-GENDER": ("R — Self-resolved", "Parse l5_name prefix — 99.96% coverage"),
    "R-ACTIVE": ("R — Self-resolved", "Use flex_status IN ('Active','Drop')"),
    "R-COLOR":  ("R — Self-resolved", "Parse color_description (100% populated)"),
    "R-ORPHAN-TXN": ("R — Self-resolved", "Zero orphans — perfect referential integrity"),
    "R-ORPHAN-INV": ("R — Self-resolved", "Zero orphans"),
    # New items (v2) — cost/msrp real source issue and logic bugs
    "A-cost-msrp": ("A — Source data",
                    "sku_details.COST_PRICE / SELLING_PRICE are 0; master CTE AVG carries the 0 through"),
    "C-active-polarity": ("C — Build logic",
                          "store_master.active = LOC_CLOSED_IND — verify polarity"),
    "C-cost-cte": ("C — Build logic",
                   "transaction_master CTE uses AVG(COST_PRICE) per SKU — is avg the right semantics?"),
}


# -----------------------------------------------------------------------------
# Data: Action Items
# -----------------------------------------------------------------------------

ACTION_ITEMS = [
    # (ID, Table, Severity, Issue, Scope, Ask/Action, Owner, Status, Date Opened, Notes)
    # P0 — Blockers
    ("P0-1", "transaction_master", "P0",
     "cost and msrp are 100% zero",
     "389M rows",
     "Populate in next feed; OR confirm these are intentionally stripped from cleaned version",
     "Client (check DE first)", "Open", "2026-04-20",
     "Smells like filtered view, not missing data"),
    ("P0-2", "transaction_master", "P0",
     "Discount columns (unit_discount_amount, total_discount_amount, clearance_price) 100% zero",
     "389M rows",
     "Populate, OR confirm derivation from price_book is the intended source",
     "Client", "Open", "2026-04-20",
     "Likely derive: REGULAR_PRICE - transaction.price"),
    ("P0-3", "inventory_master", "P0",
     "64M rows (0.89%) have oh < 0; min = -3,704,869",
     "64,279,970 rows",
     "Explain: legitimate (oversold/shrinkage) or data bug?",
     "Client", "Open", "2026-04-20",
     "Needs call, not email"),
    ("P0-4", "inventory_master", "P0",
     "Inventory history starts 2023-01; transactions go back to 2021-11",
     "14+ months missing",
     "Provide pre-2023 inventory snapshots for forecast backtesting",
     "Client", "Open", "2026-04-20",
     "Biggest blocker for multi-year modeling"),
    ("P0-5", "product_master", "P0",
     "Only current season 25-4WI; no historical product records",
     "1.97M rows",
     "Provide per-season product snapshots OR append-only product log",
     "Client", "Open", "2026-04-20",
     "Needed for joins to 2023-2024 transactions"),
    # Deferred
    ("P0-0", "product_master", "Deferred",
     "launch_date 100% NULL",
     "1.97M rows",
     "Deferred per user. Forces first-transaction-date as launch proxy.",
     "Client", "Deferred", "2026-04-20",
     "Revisit when new-product forecasting becomes blocking"),
    # Transaction Master P1
    ("T4", "transaction_master", "P1",
     "Extreme outliers: max qty=31,047, max revenue=$20M, max price=$1M",
     "<50 rows",
     "Explain — wholesale/B2B? Data error?",
     "Client", "Open", "2026-04-20", ""),
    ("T5", "transaction_master", "P1",
     "42 rows with negative price AND cost > price",
     "42 rows",
     "Explain",
     "Client", "Open", "2026-04-20", ""),
    ("T6", "transaction_master", "P1",
     "12 columns 100% NULL (line_id, launch_price, transaction_type, etc.)",
     "All rows",
     "Populate in next feed or remove from schema",
     "Client", "Open", "2026-04-20", ""),
    ("T9", "transaction_master", "P1",
     "clearance and flagged_rows always 0",
     "All rows",
     "Populate or drop",
     "Client", "Open", "2026-04-20", ""),
    ("T10", "transaction_master", "P1",
     "9,290 rows with qty > 0 but price/revenue = 0 (free items?)",
     "9,290 rows",
     "Confirm treatment — keep or drop?",
     "Client", "Open", "2026-04-20", ""),
    # Inventory Master P1
    ("I1", "inventory_master", "P1",
     "oo, wip, initial_oh_quantity 100% zero across 7.2B rows",
     "All rows",
     "Populate or confirm deprecation",
     "Client", "Open", "2026-04-20", "Schema has 10 cols but only 3 useful"),
    ("I4", "inventory_master", "P1",
     "Max oh = 700,024 at single SKU-store-date",
     "1 row",
     "Explain — wholesale? DC aggregate?",
     "Client", "Open", "2026-04-20", ""),
    # Product Master P1
    ("PM-4", "product_master", "P1",
     "Placeholder SKUs (1,248 short-code articles like HX, MV, NK)",
     "55K rows",
     "Explain — brand refs? test data? Include/exclude in modeling?",
     "Client (15-min call)", "Open", "2026-04-20", ""),
    ("PM-7", "product_master", "P1",
     "fit_classification 24.7% NULL",
     "489K rows",
     "Improve coverage (Size Smart driver)",
     "Client", "Open", "2026-04-20", ""),
    ("PM-9", "product_master", "P1",
     "flex_status='Drop' semantics — sell-down? discontinuing?",
     "572K rows",
     "Confirm interpretation",
     "Client", "Open", "2026-04-20", ""),
    ("PM-11", "product_master", "P1",
     "size_scale coded letters (B, E, I, WA, J2, L1...) no lookup",
     "1.9M rows",
     "Provide lookup mapping to size ranges",
     "Client", "Open", "2026-04-20", ""),
    # Store Master P1
    ("S1", "store_master", "P1",
     "CMNTY (26) vs COMMUNITY (13) — same channel, two spellings",
     "39 stores",
     "Standardize in next refresh",
     "Client", "Open", "2026-04-20", "Easy fix"),
    ("S3", "store_master", "P1",
     "store_format_code 21% NULL",
     "392 stores",
     "Populate for all stores",
     "Client", "Open", "2026-04-20", ""),
    ("S4", "store_master", "P1",
     "active flag 11% NULL",
     "199 stores",
     "Every store should have active flag",
     "Client", "Open", "2026-04-20", ""),
    ("S5", "store_master", "P1",
     "21 channel_codes exist but have zero transactions",
     "~200 stores",
     "Expected (non-txn channels) or feed gap?",
     "Client", "Open", "2026-04-20", "FO/CMNTY/STRAT"),
    # Fiscal Calendar P1
    ("C1", "calendar_hierarchy", "P1",
     "Calendar ends FY27. Spec requires 5 years future",
     "—",
     "Extend to FY2030 (or FY2031 for safety)",
     "Client", "Open", "2026-04-20", "Otherwise pristine"),
    # Internal workarounds planned
    ("W1", "transaction_master", "P1",
     "106M zero-qty rows (27%) — non-sale events",
     "106M rows",
     "INTERNAL WORKAROUND: Apply WHERE qty > 0 AND revenue > 0. Confirm hypothesis with Ritik/Sri in 15-min call.",
     "Internal", "Workaround Planned", "2026-04-20",
     "Gift cards + ECOMM events + virtual stores"),
    ("W2", "product_master", "P1",
     "flex_status='Active' is weak filter (716K Active products never sold)",
     "716K SKUs",
     "INTERNAL WORKAROUND: Combine flex_status with transaction recency (last 90d)",
     "Internal", "Workaround Planned", "2026-04-20", ""),
    # P2 items
    ("PM-T1", "product_master", "P2",
     "l8 naming inconsistency (260K l8_ids have multiple names)",
     "260K IDs",
     "Use l8_id for joins; cosmetic name issue",
     "Internal (noted)", "Workaround Planned", "2026-04-20", ""),
    ("PM-T10", "product_master", "P2",
     "designed_for_activity ≈ global_merch_team (near-duplicates)",
     "All rows",
     "Pick designed_for_activity as canonical",
     "Internal", "Workaround Planned", "2026-04-20", ""),
    ("PM-IVIVVA", "product_master", "P2",
     "ivivva brand 100% unsold in 4 years",
     "~63K SKUs",
     "Drop ivivva from modeling; request deprecation at source",
     "Client", "Open", "2026-04-20", ""),
    ("PM-LAB", "product_master", "P2",
     "Lab line 97.8% unsold",
     "22K SKUs",
     "Confirm Lab is still active; consider excluding",
     "Client", "Open", "2026-04-20", ""),
    ("TM-CHAN", "transaction_master", "P2",
     "channel vs ws_channel redundant",
     "All rows",
     "Use channel_code; drop channel and ws_channel",
     "Internal", "Workaround Planned", "2026-04-20", ""),
    ("TM-TYPO", "transaction_master", "P2",
     "Column typo: fullfilment_location_customer",
     "—",
     "Flag for fix in next schema version; use typo'd name for now",
     "Client", "Open", "2026-04-20", ""),
    ("S2", "store_master", "P2",
     "special_classification 100% NULL",
     "All rows",
     "Populate or drop",
     "Client", "Open", "2026-04-20", ""),
    ("S6", "store_master", "P2",
     "lat/long stored as STRING not FLOAT",
     "1,853 rows",
     "Type inconsistency",
     "Client", "Open", "2026-04-20", ""),
    ("S7", "store_master", "P2",
     "Geographic mismatches in virtual stores (KR ECOMM city=Hong Kong)",
     "Handful of stores",
     "Historical HQ addresses; not functional",
     "Client (info)", "Open", "2026-04-20", ""),
    ("S8", "store_master", "P2",
     "s3_id has 2 IDs with multiple s3_names",
     "2 IDs",
     "Minor naming inconsistency",
     "Client", "Open", "2026-04-20", ""),
    ("S9", "store_master", "P2",
     "Placeholder open_dates (WeChat store shows 1999-12-31)",
     "Some virtual stores",
     "Verify open dates",
     "Client", "Open", "2026-04-20", ""),
    ("C2", "calendar_hierarchy", "P2",
     "ADJUSTED_LY_WEEK_ID=201401 sentinel for 371 rows (7.8%)",
     "371 rows",
     "Confirm sentinel interpretation (no valid LY comp)",
     "Client (info)", "Open", "2026-04-20", ""),
    ("I2", "inventory_master", "P2",
     "total_units 100% identical to oh — redundant",
     "All rows",
     "Drop from schema",
     "Client", "Open", "2026-04-20", ""),
    ("I6", "inventory_master", "P2",
     "23,782 SKUs in product_master never had inventory",
     "23.8K SKUs",
     "Likely new launches / placeholders",
     "Client (info)", "Open", "2026-04-20", ""),
    ("I7", "inventory_master", "P2",
     "467 stores in store_master never had inventory",
     "467 stores",
     "Likely inactive/closed/out-of-scope",
     "Client (info)", "Open", "2026-04-20", ""),
    ("I8", "inventory_master", "P2",
     "8M ivivva inventory rows for deprecated brand",
     "8M rows",
     "Legacy stock or current?",
     "Client", "Open", "2026-04-20", ""),
    # Self-resolved items
    ("R-GENDER", "product_master", "Resolved",
     "gender 73.4% NULL — SELF-RESOLVED via l5_name derivation",
     "1.45M rows rescued",
     "Derivation applied. 99.96% coverage achieved.",
     "Internal", "Resolved", "2026-04-20",
     "No client wait needed"),
    ("R-ACTIVE", "product_master", "Resolved",
     "active_flag/article_status uniformly ACTIVE — SELF-RESOLVED",
     "1.97M rows",
     "Use flex_status IN ('Active','Drop') instead.",
     "Internal", "Resolved", "2026-04-20", ""),
    ("R-COLOR", "product_master", "Resolved",
     "color_family 100% NULL — SELF-RESOLVED",
     "1.97M rows",
     "Parse color_description (100% populated, perfect 1:1 with color_code)",
     "Internal", "Resolved", "2026-04-20", ""),
    ("R-ORPHAN-TXN", "transaction_master", "Resolved",
     "Orphan SKUs check — CLEAN",
     "—",
     "Zero orphans. Perfect referential integrity with product_master.",
     "Internal", "Resolved", "2026-04-20", ""),
    ("R-ORPHAN-INV", "inventory_master", "Resolved",
     "Orphan SKUs/stores check — CLEAN",
     "—",
     "Zero orphans vs product_master and store_master.",
     "Internal", "Resolved", "2026-04-20", ""),
    # v2 items discovered during build-logic review
    ("C-active-polarity", "store_master", "P0",
     "active column is mapped from LOC_CLOSED_IND — polarity may be inverted",
     "1,853 stores",
     "Verify LOC_CLOSED_IND meaning (1=closed or 1=open?) — if inverted, every active-store filter is wrong",
     "Internal DE", "Open", "2026-04-21",
     "Discovered via master_table_build_logic.md review"),
    ("C-cost-cte", "transaction_master", "P1",
     "CTE averages COST_PRICE / SELLING_PRICE per SKU, losing time dimension",
     "389M rows",
     "Confirm whether SKU-level AVG is acceptable, or if we need time-aware price snapshots",
     "Internal DE", "Open", "2026-04-21",
     "Also: even if semantics OK, upstream sku_details has 0s (see P0-1)"),
    ("B-bundle", "multiple", "P1",
     "~22 columns hardcoded NULL/0 in master build DDLs",
     "Various",
     "Internal DE review: which of these can be populated cheaply from raw tables?",
     "Internal DE (Ritik)", "Open", "2026-04-21",
     "See Build Logic Stubs sheet for full list"),
]


# -----------------------------------------------------------------------------
# Data: Canonical Tables
# -----------------------------------------------------------------------------

CANONICAL_TABLES = [
    # (Table, Rows, Size GB, Type, Partition, Cluster, PK, EDA Status, Notes)
    ("inventory_master", 7214258665, 650.48, "BASE", "date", "store_code",
     "(date, store_code, product_code)", "✅ Phase 1",
     "7 of 10 cols useful. oh, it, brand, date, store, product. Others are 0 or redundant."),
    ("eligibility_cleaned_20251119", 2302517438, 254.79, "BASE", "", "",
     "—", "Not yet", "10× bigger than eligibility_20251119 — need to understand"),
    ("returns_transactions_20251119", 733682768, 78.76, "BASE", "", "",
     "—", "Not yet", "Sample shows all zero units/prices — hypothesis: similar to zero-qty txn pattern"),
    ("transfer_orders_cleaned_20251119", 710271174, 68.92, "BASE", "", "",
     "TRANSFER_ORDER_ID+SKU_ID", "Not yet", "DATE_SHIPPED is STRING (not DATE)"),
    ("price_book", 440496318, 32.42, "CLONE", "", "",
     "STYLE_OPTION_ID+LOC_ID+DATE", "Not yet", "ALL 8 cols are STRING incl prices — cast when using"),
    ("transaction_master", 389872378, 73.53, "CLONE", "date", "channel",
     "transaction_code", "✅ Phase 1-3", "12 cols 100% NULL. Discount/cost/msrp all 0. 27% rows are non-sale events."),
    ("eligibility_20251119", 241782410, 14.14, "BASE", "", "",
     "—", "Not yet", "Sibling of _cleaned; 10× smaller"),
    ("transfer_orders_new_cleaned", 75893552, 8.12, "BASE", "", "sku_id",
     "transfer_order_id", "Not yet", "Missing col position 12"),
    ("anaplan_transit_calender_cleaned", 51276624, 3.93, "BASE", "Datestring", "",
     "—", "Not yet", "Table name misspelled (calender)"),
    ("assortment_plan_cleaned", 42594160, 7.70, "BASE", "", "SKU_ID",
     "—", "Not yet", "FLEX_SIZE_VALUE is comma-separated list in one string"),
    ("anaplan_allocation_calendar_cleaned", 39230138, 7.22, "BASE", "", "SKU_ID",
     "—", "Not yet", "Raw version (anaplan_allocation_calender) is EMPTY"),
    ("anaplan_fdod_replen_cleaned", 30918903, 1.41, "BASE", "", "",
     "—", "Not yet", "Column names have spaces (Planning Style Option, Final FDOD)"),
    ("purchase_orders_cleaned_20251119", 20803006, 2.92, "BASE", "", "",
     "PURCHASE_ORDER_ID+SKU_ID", "Not yet", ""),
    ("anaplan_fdod_alloc_cleaned", 16032486, 1.44, "BASE", "", "SKU_ID",
     "—", "Not yet", ""),
    ("product_group_hierarchy", 11460436, 0.61, "BASE", "", "",
     "—", "Not yet", "Long-format version of product_master hierarchy"),
    ("anaplan_min_pres_cleaned", 8839533, 1.36, "BASE", "", "",
     "—", "Not yet", "Min presentation qty per size"),
    ("product_master", 1977528, 1.05, "CLONE", "", "",
     "product_code", "✅ Phase 1-3",
     "20 meaningful cols. 4 cols 100% NULL (launch_date, color_family, ordering, special_class)"),
    ("sku_details_cleaned", 1977528, 0.61, "CLONE", "", "",
     "ID or sku_id_code", "Not yet", "Parallel to product_master — same row count! Different columns"),
    ("dc_store_mapping_cleaned_20251119", 1110005, 0.07, "BASE", "", "",
     "—", "Not yet", "Raw dc_store_mapping is EMPTY"),
    ("style_option_20251119", 469512, 0.05, "BASE", "", "",
     "STYLE_OPTION_ID", "Not yet", ""),
    ("promotional_events_cleaned_20251119", 448134, 0.03, "BASE", "", "",
     "LOC_ID+NAME+START_DATE", "Not yet", "Holidays & store closures"),
    ("spatial_ai_cleaned", 22798, 0.01, "BASE", "", "",
     "QUARTER_ID+LOCATION_ID", "Not yet",
     "48 consumer-demography scores (Sweet Treats, Yoga Advocates, etc). EF03/EF04 are STRING."),
    ("anaplan_store_priority_cleaned", 8828, 0, "BASE", "", "",
     "store_code+division_code", "Not yet", ""),
    ("calendar_hierarchy", 4746, 0, "BASE", "", "",
     "DAY_ID", "✅ Complete", "PRISTINE. 13 FY years (2015-2027). 53-week years: FY18, FY24."),
    ("store_master", 1853, 0, "CLONE", "", "",
     "store_code", "✅ Phase 1", "10 virtual ECOMM stores identified. Tmall/WeChat/JD = 45186/45187/45189"),
    ("min_pres_eol", 99, 0, "BASE", "", "",
     "—", "Not yet", "Tiny reference table"),
]


# -----------------------------------------------------------------------------
# Data: Data Quirks & Sentinels
# -----------------------------------------------------------------------------

DATA_QUIRKS = [
    # (Table, Column(s), Quirk Type, Description, Mitigation)
    ("product_master", "gender", "NULL sentinel",
     r"\N literal 2-char string used for 73.4% of rows (IS NULL doesn't catch)",
     r"Use (gender IS NULL OR gender = '' OR gender = '\\N') in null checks"),
    ("assortment_plan_cleaned", "PLANNING_STYLE_OPTION", "NULL sentinel",
     r"\N literal string for null",
     r"Same as above"),
    ("price_book", "EFFECTIVE_TO_DAY_ID", "Date sentinel",
     "9999-12-31 = 'no end date' (open-ended price)",
     "Filter: != '9999-12-31' when filtering closed prices"),
    ("price_book", "All 8 columns", "Wrong type",
     "All columns are STRING — including ORIGINAL_PRICE, REGULAR_PRICE, CLEARANCE_PRICE",
     "CAST to FLOAT64 when using; handle \\N for clearance"),
    ("store_master", "open_date, close_date", "Wrong type",
     "STRING format, not DATE. Values are ISO-8601 'YYYY-MM-DD'.",
     "SAFE.PARSE_DATE('%Y-%m-%d', open_date) to cast"),
    ("store_master", "latitude, longitude", "Wrong type",
     "STRING not FLOAT64",
     "CAST if used for geo math"),
    ("store_master", "open_date (WeChat store)", "Placeholder date",
     "Some virtual stores have open_date='1999-12-31' — platform didn't exist then",
     "Verify with client; don't trust pre-2010 virtual store open dates"),
    ("transfer_orders_cleaned_20251119", "DATE_SHIPPED", "Wrong type",
     "STRING, while sibling DATE_RECEIVED and DATE_CREATED are DATE",
     "CAST to DATE when using"),
    ("dc_store_mapping_cleaned_20251119", "SECONDARY_DC_*", "Wrong type",
     "Secondary DC fields are STRING (INT64 sibling primary fields)",
     "CAST as needed"),
    ("spatial_ai_cleaned", "EF03_AWESTRUCK, EF04_HAPPY_PLACE", "Wrong type",
     "STRING while other 47 behavioral score columns are FLOAT64",
     "CAST to FLOAT64 before numerical use"),
    ("transaction_master", "fullfilment_location_customer", "Column name typo",
     "Should be 'fulfillment'. 100% NULL anyway.",
     "Use typo as-is in queries; don't 'fix' name"),
    ("anaplan_transit_calender_cleaned", "Table name", "Table name typo",
     "'calender' instead of 'calendar'. Dataset-wide.",
     "Use typo as-is"),
    ("dataset name", "souricng", "Dataset name typo",
     "Actual dataset is lululemon_souricng_outbound (not 'sourcing')",
     "Use as-is"),
    ("anaplan_fdod_replen_cleaned", "Planning Style Option, Final FDOD", "Column names with spaces",
     "Column names contain spaces",
     "Quote with backticks: `Planning Style Option`, `Final FDOD`"),
    ("min_pres_eol", "Min Pres, Size", "Column names with spaces",
     "Column names contain spaces",
     "Quote with backticks"),
    ("transaction_master", "channel vs ws_channel", "Redundant columns",
     "Same values, different spelling (ECOMM vs ECOM)",
     "Use channel_code (12 values, most granular) instead"),
    ("inventory_master", "total_units = oh (100%)", "Redundant column",
     "total_units is identical to oh in every row",
     "Drop total_units from downstream use"),
    ("inventory_master", "oo, wip, initial_oh_quantity", "100% zero",
     "All three columns are 0 across all 7.2B rows",
     "Drop from downstream use"),
    ("transaction_master", "12 INT64 columns", "100% NULL",
     "line_id, launch_price, transaction_type, revenue_before_tax, freight_cost, etc.",
     "Ignore"),
    ("transaction_master", "qty/revenue/price", "Zero-event overlap",
     "27% of rows have qty=0 AND price=0 AND revenue=0 (non-sale events)",
     "Filter WHERE qty > 0 AND revenue > 0 for modeling (drops 106M rows)"),
    ("calendar_hierarchy", "ADJUSTED_LY_WEEK_ID", "Sentinel value",
     "201401 is used for 371 rows where no valid LY comp exists",
     "WHERE ADJUSTED_LY_WEEK_ID != 201401 when doing YoY"),
    ("store_master", "CMNTY vs COMMUNITY", "Inconsistent spelling",
     "Same channel with 2 spellings (26 + 13 stores)",
     "Standardize in query: UPPER(TRIM(channel))"),
    ("product_master", "l8_name", "Naming inconsistency",
     "260K l8_ids have multiple names (87%)",
     "Always use l8_id for joins; l8_name is display-only"),
    ("product_master", "gender for Unisex", "Priority in derivation",
     "Unisex products often have l5_name='Womens X' — naive derivation overwrites to Womens",
     "Priority: populated gender > l5 prefix > Unisex fallback"),
    ("inventory_master", "oh < 0", "Negative values allowed",
     "64M rows (0.89%) have negative on-hand; min = -3,704,869",
     "Use GREATEST(oh, 0) for 'available' qty, or filter oh >= 0"),
]


# -----------------------------------------------------------------------------
# Data: Build Logic Stubs (columns hardcoded in master table DDL)
# -----------------------------------------------------------------------------

BUILD_LOGIC_STUBS = [
    # (Master Table, Column, Hardcoded Value, Populatable From (hypothesis), Notes)
    # product_master
    ("product_master", "article_status", "'ACTIVE'",
     "Could use flex_status; or derive from product_attribute_s",
     "Use flex_status IN ('Active','Drop') instead"),
    ("product_master", "active_flag", "1",
     "Same — derive from flex_status",
     "Useless as filter"),
    ("product_master", "color_family", "NULL",
     "Parse from color_description (self-resolved)",
     "R-COLOR already implements this"),
    ("product_master", "ordering", "NULL",
     "Unknown — ask DE",
     ""),
    ("product_master", "launch_date", "NULL",
     "product_group_hierarchy.FIRST_SELLING_DATE (hypothesis) or derive from sku_details",
     "P0-0 / deferred per user"),
    # transaction_master — NULL stubs (12)
    ("transaction_master", "line_id", "NULL",
     "sales_transactions.ORDER_LINE_ID (hypothesis)", ""),
    ("transaction_master", "launch_price", "NULL",
     "price_book", ""),
    ("transaction_master", "transaction_type", "NULL",
     "sales_transactions.TRANSACTION_TYPE", ""),
    ("transaction_master", "fullfilment_location_customer", "NULL",
     "sales_transactions (delivery fulfillment) — typo preserved", ""),
    ("transaction_master", "revenue_before_tax", "NULL",
     "sales_transactions.NET_SALES_AMOUNT (hypothesis)", ""),
    ("transaction_master", "ship_to_country", "NULL",
     "sales_transactions customer data", ""),
    ("transaction_master", "freight_cost", "NULL",
     "sales_transactions.SHIPPING_COST (hypothesis)", ""),
    ("transaction_master", "store_contribution", "NULL",
     "Derived KPI — may come later", ""),
    ("transaction_master", "workstream", "NULL",
     "Unknown — ask DE", ""),
    ("transaction_master", "currency_exchange_rate", "NULL",
     "Currency table needed", ""),
    ("transaction_master", "order_type", "NULL",
     "sales_transactions.ORDER_TYPE (hypothesis)", ""),
    ("transaction_master", "transaction_category", "NULL",
     "sales_transactions.TXN_CATEGORY (hypothesis)", ""),
    # transaction_master — 0 stubs
    ("transaction_master", "clearance", "0",
     "price_book.CLEARANCE_PRICE > 0 flag", ""),
    ("transaction_master", "unit_discount_amount", "0",
     "Derive: price_book.REGULAR_PRICE - transaction.price", "P0-2"),
    ("transaction_master", "total_discount_amount", "0",
     "Derive from unit_discount_amount * qty", "P0-2"),
    ("transaction_master", "clearance_price", "0",
     "price_book.CLEARANCE_PRICE", "P0-2"),
    ("transaction_master", "flagged_rows", "0",
     "Unknown — likely QC flag", ""),
    # inventory_master
    ("inventory_master", "oo", "0",
     "purchase_orders? open_orders table?", ""),
    ("inventory_master", "wip", "0",
     "Work-in-progress — unknown source", ""),
    ("inventory_master", "initial_oh_quantity", "0",
     "Derive from earliest snapshot date", ""),
    ("inventory_master", "total_units", "= oh",
     "Redundant — drop or redefine (e.g., oh + it + oo)",
     "Currently: A.UNITS_ON_HAND (same as oh)"),
    # store_master
    ("store_master", "location_attrib_squareft", "0",
     "location_details? client property data?", ""),
    ("store_master", "special_classification", "NULL",
     "Unknown — ask DE", ""),
    ("store_master", "company_name", "= s0_name",
     "Redundant", "Same as a.BRAND_NAME"),
    ("store_master", "district_name", "= s3_name",
     "Redundant", "Same as a.AREA_NAME"),
    ("store_master", "region", "= s4_name",
     "Redundant", "Same as a.REGION_NAME"),
    ("store_master", "channel", "= s1_name",
     "Redundant — same SPLIT expression", ""),
    ("store_master", "like_store_id", "= store_code",
     "Self-reference — should be actual like-store lookup?",
     "Currently: a.loc_id (same as store_code)"),
]


# -----------------------------------------------------------------------------
# Data: Self-Resolved items (summary)
# -----------------------------------------------------------------------------

SELF_RESOLVED = [
    # (Item, Table, Impact, Derivation / Resolution)
    ("Gender coverage",
     "product_master",
     "73% null → 99.96% coverage. No client wait.",
     "CASE populated-gender > l5_name prefix > Lab variants > Unisex fallback. See lululemon-bq-context.mdc."),
    ("Active-product filter",
     "product_master",
     "active_flag uniformly 'ACTIVE' was useless → flex_status gives clear sell-cycle",
     "WHERE flex_status IN ('Active','Drop'). 'Active' = 66.6%, 'Drop' = 28.9% (sell-down)."),
    ("Color family grouping",
     "product_master",
     "color_family 100% NULL → derive from color_description",
     "color_description is 100% populated with perfect 1:1 to color_code (26,480 codes)."),
    ("Zero-qty row hypothesis",
     "transaction_master",
     "27% (106M) of rows are non-sale events — confirmed via evidence",
     "WHERE qty > 0 AND revenue > 0. Drops 106M cart/browse/gift-card events. Retains 284M real sales."),
    ("Virtual store classification",
     "store_master",
     "10 ECOMM virtual stores formally flagged",
     "store_format_code='E-COMMERCE' (30 stores). Also discovered 3 China platforms: Tmall/WeChat/JD."),
    ("Referential integrity (all tables)",
     "inventory × product × store × transaction",
     "CLEAN. Zero orphans in any direction.",
     "No fix needed."),
    ("PK/Grain confirmation",
     "all 5 master tables",
     "All PKs confirmed, no hidden duplicates",
     "product_code, transaction_code, (date,store,product), store_code, DAY_ID"),
]


# -----------------------------------------------------------------------------
# Build workbook
# -----------------------------------------------------------------------------

wb = Workbook()


# ========== Sheet 1: README ==========
ws = wb.active
ws.title = "README"
set_col_widths(ws, [5, 40, 80])

ws.cell(row=1, column=1, value="Lululemon - EDA Findings Workbook (v2)").font = Font(bold=True, size=18, color="1F4E78")
ws.cell(row=2, column=1, value="Compiled 2026-04-21 | Owner: Ejaz Anwar | Phase 1 EDA complete on 5 master tables (~7.6B rows / 725 GB)").font = SUBTITLE_FONT

readme_content = [
    ("", "Sheet", "What it contains"),
    ("1", "README", "This page — navigation + quick status"),
    ("2", "Dashboard", "Exec-level status per table; item counts by severity"),
    ("3", "Action Items", "Full tracker. Now includes Root Cause categorization."),
    ("4", "Build Logic Stubs", "Columns hardcoded NULL/0 in master build DDLs — ~30 entries."),
    ("5", "Canonical Tables", "26 tables we should work with. Size, partition/cluster, PK, EDA status."),
    ("6", "Data Quirks", "Known sentinels, typos, type inconsistencies, and mitigation patterns."),
    ("7", "Self-Resolved", "Items we fixed ourselves with derivations (no client wait)."),
    ("", "", ""),
    ("", "v2 Change", "Root Cause categorization added after reviewing master_table_build_queries_20251119.csv."),
    ("", "Root Cause buckets", "A=Source data (client) | B=Build stub (DE) | C=Logic bug | D=Real anomaly | E=Cosmetic | R=Resolved/workaround"),
    ("", "Key status", "Phase 1 EDA complete. 3 genuine client blockers (A). ~22 build stubs to triage with DE (B). 2 logic questions (C)."),
    ("", "Confluence", "Each EDA page lives under /spaces/~7120208879.../pages/557057 (Data Cleaning & EDA parent)"),
    ("", "Local folder", "/Users/ejazanwarmd/Desktop/Lululemon/"),
    ("", "Key docs", "findings/master_table_build_logic.md | findings/consolidated_p0_p1_issues.md"),
]

for i, row in enumerate(readme_content, start=4):
    for col, val in enumerate(row, start=1):
        cell = ws.cell(row=i, column=col, value=val)
        if i == 4:  # header
            cell.fill = HEADER_FILL
            cell.font = HEADER_FONT
        else:
            cell.alignment = Alignment(vertical="top", wrap_text=True)


# ========== Sheet 2: Dashboard ==========
ws = wb.create_sheet("Dashboard")
set_col_widths(ws, [28, 15, 15, 15, 15, 15, 50])

next_row = write_title(ws, "Dashboard — EDA Status per Table",
                       "5 master tables complete. ✅ = Phase 1+ done. 🔴 = P0 open. 🟡 = P1 open. 🟢 = Clean.")

# Header
headers = ["Table", "Rows", "Size (GB)", "Status", "P0 Open", "P1 Open", "Notes"]
for col, h in enumerate(headers, start=1):
    ws.cell(row=next_row, column=col, value=h)
style_header_row(ws, next_row, len(headers))
next_row += 1

dashboard_rows = [
    ("product_master", 1977528, 1.05, "✅ Complete", 1, 4, "Historical snapshots is the only P0 blocker. 3 items self-resolved."),
    ("transaction_master", 389872378, 73.53, "✅ Complete", 2, 5, "Cost/msrp/discount 100% zero = P0s. 27% zero-qty hypothesis-confirmed."),
    ("inventory_master", 7214258665, 650.48, "✅ Phase 1", 2, 2, "4 of 10 cols useless. P0: 2022 history + negative oh."),
    ("store_master", 1853, 0, "✅ Complete", 0, 4, "🟢 Cleanest table. 10 virtual ECOMM stores classified."),
    ("calendar_hierarchy", 4746, 0, "✅ Complete", 0, 1, "🟢 PRISTINE. Extend to FY2030 = only ask."),
    ("-- Not yet EDA'd --", "", "", "", "", "", ""),
    ("returns_transactions_20251119", 733682768, 78.76, "⏳ Not started", "?", "?", "Sample suggests all-zero values pattern"),
    ("price_book", 440496318, 32.42, "⏳ Not started", "?", "?", "440M rows. All cols STRING. Source for discount derivation."),
    ("eligibility_cleaned_20251119", 2302517438, 254.79, "⏳ Not started", "?", "?", "10× bigger than sibling. Understand the 10×."),
]
for row_data in dashboard_rows:
    for col, val in enumerate(row_data, start=1):
        ws.cell(row=next_row, column=col, value=val)
    if row_data[0].startswith("--"):
        for col in range(1, len(headers) + 1):
            ws.cell(row=next_row, column=col).fill = PatternFill("solid", fgColor="E7E6E6")
            ws.cell(row=next_row, column=col).font = Font(italic=True, color="7F7F7F")
    next_row += 1

# Skip a row
next_row += 1

# Severity summary box
ws.cell(row=next_row, column=1, value="Severity Summary").font = Font(bold=True, size=13, color="1F4E78")
next_row += 1
summary_headers = ["Severity", "Count"]
for col, h in enumerate(summary_headers, start=1):
    ws.cell(row=next_row, column=col, value=h)
style_header_row(ws, next_row, len(summary_headers))
next_row += 1

p0_count = sum(1 for a in ACTION_ITEMS if a[2] == "P0")
p1_count = sum(1 for a in ACTION_ITEMS if a[2] == "P1")
p2_count = sum(1 for a in ACTION_ITEMS if a[2] == "P2")
resolved_count = sum(1 for a in ACTION_ITEMS if a[2] == "Resolved")
deferred_count = sum(1 for a in ACTION_ITEMS if a[2] == "Deferred")

summary_rows = [
    ("🔴 P0 — Blockers", p0_count),
    ("🟡 P1 — Quality issues", p1_count),
    ("🟢 P2 — Cosmetic / low priority", p2_count),
    ("✅ Resolved (self)", resolved_count),
    ("⏸️ Deferred", deferred_count),
]
for sev, cnt in summary_rows:
    ws.cell(row=next_row, column=1, value=sev)
    ws.cell(row=next_row, column=2, value=cnt)
    if sev.startswith("🔴"):
        ws.cell(row=next_row, column=1).fill = FILL_P0
        ws.cell(row=next_row, column=2).fill = FILL_P0
    elif sev.startswith("🟡"):
        ws.cell(row=next_row, column=1).fill = FILL_P1
        ws.cell(row=next_row, column=2).fill = FILL_P1
    elif sev.startswith("🟢"):
        ws.cell(row=next_row, column=1).fill = FILL_P2
        ws.cell(row=next_row, column=2).fill = FILL_P2
    elif sev.startswith("✅"):
        ws.cell(row=next_row, column=1).fill = FILL_RESOLVED
        ws.cell(row=next_row, column=2).fill = FILL_RESOLVED
    elif sev.startswith("⏸️"):
        ws.cell(row=next_row, column=1).fill = FILL_DEFERRED
        ws.cell(row=next_row, column=2).fill = FILL_DEFERRED
    next_row += 1


# ========== Sheet 3: Action Items ==========
ws = wb.create_sheet("Action Items")
set_col_widths(ws, [10, 22, 12, 20, 50, 60, 25, 60, 22, 20, 14, 40])

next_row = write_title(ws, "Action Items — All P0/P1/P2 tracker (v2)",
                       "Root Cause categorization added. Filter by Severity / Root Cause / Owner / Status.")

headers = ["ID", "Table", "Severity", "Root Cause", "Root Cause Detail",
           "Issue", "Scope", "Ask / Action",
           "Owner", "Status", "Date Opened", "Notes"]
for col, h in enumerate(headers, start=1):
    ws.cell(row=next_row, column=col, value=h)
style_header_row(ws, next_row, len(headers))
header_row = next_row
next_row += 1

for item in ACTION_ITEMS:
    item_id = item[0]
    rc = ROOT_CAUSE.get(item_id, ("Unclassified", ""))
    # Build row: ID, Table, Severity, Root Cause, Root Cause Detail, then original cols 4..10
    row = (item[0], item[1], item[2], rc[0], rc[1]) + item[3:]
    for col, val in enumerate(row, start=1):
        cell = ws.cell(row=next_row, column=col, value=val)
        cell.alignment = Alignment(vertical="top", wrap_text=True)
    apply_severity_fill(ws, next_row, item[2], len(headers))
    next_row += 1

# Freeze header + add filter
ws.freeze_panes = f"A{header_row + 1}"
add_filter(ws, header_row, len(headers), next_row - 1)


# ========== Sheet 3b: Build Logic Stubs ==========
ws = wb.create_sheet("Build Logic Stubs")
set_col_widths(ws, [22, 34, 18, 60, 50])

next_row = write_title(ws, "Build Logic Stubs — Hardcoded NULL/0 in Master DDLs",
                       "Columns NOT genuinely missing from source — they are hardcoded in the master build. Ask DE whether each can be populated.")

headers = ["Master Table", "Column", "Hardcoded Value",
           "Populatable From (hypothesis)", "Notes"]
for col, h in enumerate(headers, start=1):
    ws.cell(row=next_row, column=col, value=h)
style_header_row(ws, next_row, len(headers))
header_row = next_row
next_row += 1

for stub in BUILD_LOGIC_STUBS:
    for col, val in enumerate(stub, start=1):
        cell = ws.cell(row=next_row, column=col, value=val)
        cell.alignment = Alignment(vertical="top", wrap_text=True)
        cell.fill = PatternFill("solid", fgColor="FFF9E6")  # very light yellow
    next_row += 1

ws.freeze_panes = f"A{header_row + 1}"
add_filter(ws, header_row, len(headers), next_row - 1)


# ========== Sheet 4: Canonical Tables ==========
ws = wb.create_sheet("Canonical Tables")
set_col_widths(ws, [40, 16, 12, 10, 18, 20, 36, 18, 80])

next_row = write_title(ws, "Canonical Raw Tables — 26 tables to work with",
                       "Sorted by size. Pay attention to Partition/Cluster for cost-aware queries.")

headers = ["Table", "Rows", "Size (GB)", "Type", "Partition", "Cluster",
           "PK / Grain", "EDA Status", "Notes"]
for col, h in enumerate(headers, start=1):
    ws.cell(row=next_row, column=col, value=h)
style_header_row(ws, next_row, len(headers))
header_row = next_row
next_row += 1

for tbl in CANONICAL_TABLES:
    for col, val in enumerate(tbl, start=1):
        cell = ws.cell(row=next_row, column=col, value=val)
        cell.alignment = Alignment(vertical="top", wrap_text=True)
    # Highlight by EDA status
    status = tbl[7]
    if status.startswith("✅"):
        ws.cell(row=next_row, column=8).fill = FILL_P2  # green
    elif status.startswith("⏳") or "Not" in status:
        ws.cell(row=next_row, column=8).fill = FILL_P1  # yellow
    next_row += 1

ws.freeze_panes = f"A{header_row + 1}"
add_filter(ws, header_row, len(headers), next_row - 1)


# ========== Sheet 5: Data Quirks ==========
ws = wb.create_sheet("Data Quirks")
set_col_widths(ws, [35, 40, 22, 70, 60])

next_row = write_title(ws, "Data Quirks & Sentinels",
                       "Known pitfalls when writing queries. Read before modeling.")

headers = ["Table", "Column(s)", "Quirk Type", "Description", "Mitigation"]
for col, h in enumerate(headers, start=1):
    ws.cell(row=next_row, column=col, value=h)
style_header_row(ws, next_row, len(headers))
header_row = next_row
next_row += 1

for q in DATA_QUIRKS:
    for col, val in enumerate(q, start=1):
        cell = ws.cell(row=next_row, column=col, value=val)
        cell.alignment = Alignment(vertical="top", wrap_text=True)
    next_row += 1

ws.freeze_panes = f"A{header_row + 1}"
add_filter(ws, header_row, len(headers), next_row - 1)


# ========== Sheet 6: Self-Resolved ==========
ws = wb.create_sheet("Self-Resolved")
set_col_widths(ws, [35, 35, 50, 80])

next_row = write_title(ws, "Self-Resolved Items — No Client Wait",
                       "Things we fixed ourselves with derivations / derived flags.")

headers = ["Item", "Table", "Impact", "Derivation / Resolution"]
for col, h in enumerate(headers, start=1):
    ws.cell(row=next_row, column=col, value=h)
style_header_row(ws, next_row, len(headers))
header_row = next_row
next_row += 1

for r in SELF_RESOLVED:
    for col, val in enumerate(r, start=1):
        cell = ws.cell(row=next_row, column=col, value=val)
        cell.alignment = Alignment(vertical="top", wrap_text=True)
        cell.fill = FILL_RESOLVED
    next_row += 1


# ========== Save ==========
output_path = Path("/Users/ejazanwarmd/Desktop/Lululemon/findings/Lululemon_EDA_Findings.xlsx")
wb.save(output_path)
print(f"✅ Saved: {output_path}")
print(f"   Size: {output_path.stat().st_size} bytes")
print(f"   Sheets: {len(wb.sheetnames)}")
for s in wb.sheetnames:
    ws_iter = wb[s]
    print(f"   - {s}: {ws_iter.max_row} rows × {ws_iter.max_column} cols")
