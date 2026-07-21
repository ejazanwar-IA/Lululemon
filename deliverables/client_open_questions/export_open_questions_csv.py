#!/usr/bin/env python3
"""Export per-master client open-question tables to CSV and OneNote paste formats."""

import csv
import html
import re
from pathlib import Path

OUT = Path(__file__).resolve().parent
EM_DASH = "\u2014"

HEADER = [
    "S.no",
    "Open Q",
    "Source Data",
    "Priority",
    "Action Item",
    "Response (Client)",
    "Notes",
]

ASK_FIRST = [
    ("A-1", "sku details **cost/sell price zero in some GCS batch drops** (Sep/Nov 2025+); Aug 2025 drop had prices. Which drop is canonical?", "Product Master (source)", "P0"),
    ("A-2", "Inventory history starts **Jan 2023**; sales start **Nov 2021**", "Inventory Master", "P0"),
    ("A-3", "Product master pinned to **one season (25-4WI)** on current load; Aug/Sep 2025 GCS drops were **25-3FA**", "Product Master", "P0"),
    ("F-1", "Confirm **PSS** (planning style size) is the Phase 1 forecast product grain and which field defines it", "Product Master", "P0"),
    ("F-4", "**Returns policy:** gross transaction master vs returns feed?", "Transaction Master", "P0"),
    ("F-2", "**Store/DC universe** for forecast", "Store Master", "P0"),
]

SECTION_ORDER = [
    ("product_master_open_questions.csv", "1. Product Master"),
    ("transaction_master_open_questions.csv", "2. Transaction Master"),
    ("inventory_master_open_questions.csv", "3. Inventory Master"),
    ("store_master_open_questions.csv", "4. Store Master"),
    ("calendar_hierarchy_open_questions.csv", "5. Fiscal Calendar"),
    ("cross_cutting_open_questions.csv", "6. Cross-cutting (feeds and delivery)"),
]

TABLES = {
    "product_master_open_questions.csv": [
        (1, "sku details **cost/sell price zero in Sep 2025+ GCS drops**; Aug 2025 drop ~99.9% priced; price currency dummy on all drops; confirm canonical pricing source", "GCS sku_details, lulu_sourcing_dev.sku_details", "P0", "Confirm which batch/drop should drive masters; rehydrate from priced drop or alternate feed (e.g. price_book)", "", "GCS scan: 20250807 priced, 20250905+ zero; May extraction loaded 20251118 batch. Breaks txn cost/msrp. See sku_details_gcs_batch_pricing_scan.md"),
        (2, "Product master **season_code is single-season (25-4WI)** on current load; GCS Aug/Sep 2025 sku_details drops were **25-3FA**; no append-only season history in build", "GCS sku_details, lulu_sourcing_dev.sku_details", "P0", "Confirm canonical season per drop; provide per-season snapshots or append if forecasting needs lifecycle", "", "May extraction loaded 20251118 (25-4WI). Season from sku_details SEASON_CODE. GCS: 20250807/20250905=25-3FA. See sku_details_gcs_batch_pricing_scan.md"),
        (3, "Confirm **PSS** grain for Phase 1 forecast (SOW: PSS × store × week); sales land at **SKU** level today", "product_master, product_group_hierarchy", "P0", "Sign off PSS identifier and rule to roll up SKU sales to PSS × store × week", "", "IA read: PGH PLANNING_STYLE_SIZE maps to l8_name/product_name (169K names). Txns at product_code (1.97M SKU×channel). l8_id/article = planning style option + channel, not PSS code; PLANNING_STYLE_SIZE_CODE not on product_master. Sizing SOW uses PSO×submarket×week (separate grain). Median 2 SKUs per planning-style-size×channel. Internal: master_table_build_logic.md. F-1"),
        (4, "**~29% of catalog** shows flex status **Drop**; confirm sell-down vs discontinued and whether to include in **forecast universe**", "product_attribute_s, product_intermediate", "P1", "Confirm planner rule for Drop styles (include, exclude, or separate forecast treatment)", "", "GCS verified (20250813 + 20251118 shards): FLEX_STATUS Drop ~48%, Active ~43% at style level; matches BQ sourcing dev (not batch/cleaning artifact). ~29% Drop at SKU×channel on product_intermediate (572K rows). Not on GSM product_master; article_status hardcoded ACTIVE (PM #8). IA interim: exclude Drop from forward forecast. raw_product_attribute_s_eda.md"),
        (5, "**~3% of catalog** uses very short article codes (e.g. HX, MV, NK); likely placeholders or internal codes", "product_master, product_group_hierarchy", "P1", "Confirm what short codes represent and whether to exclude from forecast universe", "", "Rule: LENGTH(article_original)<=3. 54,598 rows (2.8%), 1,248 distinct codes. Source: PGH PLANNING_STYLE_OPTION (55,991 rows in sourcing PGH). ~57% of placeholder SKUs have txn sales; do not auto-exclude. GCS PGH shard confirms short codes in raw. Distinct from PM #15 (AGG, HAADL, MU). SQL: queries/lululemon_client_open_questions.sql PM-5"),
        (6, "Catalog is **wider than the sold set** (~26% of SKUs never in raw sales); confirm **forecast universe** rule for zero-history SKUs", "product_master, sales_transactions, transaction_master", "P1", "Sign off forecast filter (e.g. sales history, Active, exclude Drop); not a data-quality defect", "", "IA view: zero-history SKUs expected for wide assortment (unreleased, Drop, channel-only, pre-2021 styles). Metrics: raw 252K/989K PGH SKUs absent from sales_transactions (~26%); GSM SKU 580K/989K (~59%); SKU×channel 1.25M/1.98M (~63%). 388K never-sold still Active on some channel. Overlaps PM #4 Drop, PM #5 placeholder (~10K). SQL: queries/lululemon_client_open_questions.sql PM-6"),
        (7, "[Internal DE] **product_attribute_s 3× load** in sourcing dev; client outbound is 1 row per style", "product_attribute_s", "P2", "DE: dedup on STYLE_ID at periodic ingest (not a client ask)", "", "Not client-facing. Outbound product_attribute_s_20251119: 86,135 rows = 1 per STYLE_ID. GCS: 1 row per STYLE_ID per shard. Triplicate only in lulu_sourcing_dev (3 byte-identical copies). SQL: queries/lululemon_client_open_questions.sql PM-7"),
        (8, "Confirm **`FLEX_STATUS`** is canonical lifecycle field; build stubs **`article_status = ACTIVE`** on all rows", "product_attribute_s, product_intermediate", "P1", "Sign off FLEX_STATUS meanings (Active/Drop/Inactive/Hold) and mapping to platform article_status", "", "Client feed has FLEX_STATUS (GCS + outbound product_attribute_s: style level Drop ~47%, Active ~43%). product_intermediate has flex_status at SKU×channel (~29% Drop). GSM product_master: article_status=ACTIVE on 100% (1.98M rows); flex_status not on GSM table. Hardcoded in create_product_intermediate_periodic.sql. IA can wire build after semantic sign-off. Overlaps PM #4. SQL: queries/lululemon_client_open_questions.sql PM-8"),
        (9, "Which **product_attribute_s** fields feed Phase 1 **forecast features and explainability** (beyond PGH hierarchy on product master)?", "product_attribute_s, product_intermediate", "P1", "Sign off prioritized attribute list for modeling; confirm sparse columns (fabric, inseam) vs hierarchy-only MVP", "", "Source: 100 cols in product_attribute_s; 14 wired to product_intermediate; GSM product_master has hierarchy + season/size/color only (no gender/silhouette/flex on GSM). SOW Phase 1 needs explainability drivers. IA read on outbound (86K styles): Tier A >90% pop: gender, product_line, flex_status, size_scale; Tier B 60-85%: design_line, designed_for_activity, global_merch_team; Tier C 40-55%: silhouette, planning_product_grouping; sparse: fabric_family 39%, inseam 28%, franchise 15%. ACTIVITY col 99.7% empty, use DESIGNED_FOR_ACTIVITY. Overlaps PM #4/#8. SQL: queries/lululemon_client_open_questions.sql PM-9"),
        (10, "Confirm style join key: **`PGH STYLE.VALUE_CODE` = `product_attribute_s.STYLE_ID`**; **42K styles in PA** not in current PGH", "product_attribute_s, product_group_hierarchy", "P1", "Confirm canonical style identifier; clarify PA-only styles (historical / out of current assortment?)", "", "IA verified: PGH 43,642 STYLE codes; 100% match PA STYLE_ID; 988,764 PGH SKUs 100% attribute join via l7_id. GSM l7_id=43,642. PA superset 86,135 styles; 42,493 PA-only (~75% Drop) absent from PGH STYLE level. PGH style code 1:1 with name. Build: STYLE_CODE=STYLE_ID. GCS PGH STYLE VALUE_CODE format matches (e.g. LW1ETUS). SQL: queries/lululemon_client_open_questions.sql PM-10"),
        (11, "PGH ~2× EAV row duplication; dedup on load?", "product_group_hierarchy_cleaned", "P1", "Confirm if source is append-only", "", ""),
        (12, "~13K SKUs lack planning style size in PGH", "product_group_hierarchy_cleaned", "P2", "Placeholders or unreleased SKUs?", "", ""),
        (13, "Only ~33% of PGH SKUs appear in product master; intentional filter?", "PGH → PM build", "P1", "Confirm ingest filter vs join loss", "", ""),
        (14, "Third brand expected beyond lululemon / ivivva?", "product_group_hierarchy", "P2", "", "", ""),
        (15, "Short legacy article codes (AGG, HAADL, MU); exclude placeholders?", "product_master", "P1", "Confirm SAP legacy vs active", "", ""),
        (16, "9-digit L6 IDs (912xxx, 932xxx); merge or keep separate?", "product_master", "P2", "", "", ""),
        (17, "sku details vs product master; relationship and join rules", "sku_details_cleaned, product_master", "P1", "Confirm 1:1 grain and channel suffix rules", "", ""),
        (18, "fit classification 25% null; expected?", "product_attribute_s", "P2", "", "", "Deferred; low forecast impact"),
    ],
    "transaction_master_open_questions.csv": [
        (1, "**Cost and msrp zero** in current txn build; traces to **Nov 2025 sku_details drop** (Aug 2025 GCS drop had prices)", "lulu_sourcing_dev.sku_details (via build join)", "P0", "Same as product master #1; load priced batch or alternate pricing feed", "", "Symptom of A-1; not hardcoded null cost. GCS 20251118 batch loaded May 2026"),
        (2, "**Returns policy:** transaction master is gross-only; 734M-row returns feed exists", "sales_transactions, returns_transactions", "P0", "Net sales vs gross? Use returns feed? Reconciliation rule?", "", "F-4"),
        (3, "Single transaction type value; where are returns / voids?", "sales_transactions", "P0", "Point to returns source or confirm gross-only model", "", ""),
        (4, "**Zero-qty transactions** (~27% of rows); keep, filter, or impute?", "sales_transactions", "P1", "Confirm modeling filter (qty > 0 and revenue > 0?)", "", "F-8; IA workaround: filter for real sales"),
        (5, "**Extreme outliers**; max qty 31K, max revenue $20M", "sales_transactions", "P1", "Wholesale/B2B or data errors? Remove from forecast?", "", "D-2"),
        (6, "351 rows with **negative qty**", "sales_transactions", "P1", "Returns in this feed or errors?", "", ""),
        (7, "42 rows **negative price** with cost > price", "sales_transactions", "P2", "Drop or real returns?", "", "D-3"),
        (8, "9,290 rows qty > 0 but price/revenue = 0 (free items?)", "transaction_master", "P1", "Include in demand forecast?", "", ""),
        (9, "Synthetic sales order / item ids; no real order numbers", "sales_transactions", "P2", "Expected? Basket analysis not possible", "", ""),
        (10, "**Sales history start:** transactions from **Nov 2021**", "sales_transactions", "P0", "Confirm complete history for forecast backtest window", "", "Pairs with inventory master #1 gap"),
        (11, "Join price book for discount / launch price / clearance?", "price_book", "P1", "Confirm if pricing features needed; feed join keys", "", "Discount cols stubbed in build; DE + client"),
    ],
    "inventory_master_open_questions.csv": [
        (1, "**History gap:** inventory from **Jan 2023**; sales from Nov 2021 (~14 months missing)", "inventory_snapshot_cleaned", "P0", "Provide pre-2023 inventory snapshots", "", "Source gap A-2"),
        (2, "Sparse snapshot dates (33 dates / 33 months; **2024 gap**)", "inventory_snapshot_cleaned", "P0", "Confirm expected cadence and backfill", "", ""),
        (3, "**64M rows negative on-hand** (min -3.7M); legitimate or bug?", "inventory_snapshot", "P1", "Oversold/shrinkage vs data error? Filter rule?", "", "D-1, F-8"),
        (4, "**8M ivivva inventory rows** (deprecated brand)", "inventory_master", "P1", "Exclude from forecast / modeling?", "", "D-5"),
        (5, "Max on-hand = 700K at one SKU/store/date", "inventory_snapshot", "P2", "DC aggregate or wholesale?", "", "D-4"),
        (6, "-1 in unit fields; sentinel semantics?", "inventory_snapshot", "P1", "Define sentinel vs real negative", "", ""),
        (7, "Negative units inbound", "inventory_snapshot", "P2", "Returns / reversals?", "", ""),
        (8, "Nov 2025 spike loads (50M+ rows); expected backfill?", "inventory_snapshot", "P2", "", "", ""),
        (9, "**Sales ≤ inventory** per SKU-store-date (I11 check)", "transaction_master + inventory_master", "P1", "Confirm if violations are data bug or business event", "", "Cross-master QC"),
    ],
    "store_master_open_questions.csv": [
        (1, "**Store/DC universe** for PSS × store/DC × week/day: which locations in scope?", "store_master, location_details", "P0", "List DCs, retail, ecomm virtual stores in forecast", "", "F-2"),
        (2, "**Submarket channel** definition; map to store master (s1–s4, channel)", "store_master", "P0", "Provide mapping table for PSO-level outputs", "", "F-3"),
        (3, "**China ecomm:** Tmall (45189), WeChat (45187), JD (45186); separate channels?", "store_master", "P0", "Confirm vs single China ecomm", "", "Partial; IA identified IDs"),
        (4, "**95 digital / virtual stores**; only ~10 transact; classify non-transacting?", "store_master", "P1", "Drop-ship, placeholders, or new launches?", "", "F-6"),
        (5, "**636 stores** never appear in transactions", "store_master, sales_transactions", "P1", "Expected (DC, virtual, out-of-scope)? Exclude?", "", ""),
        (6, "Cmnty vs Community spelling (39 stores)", "location_details", "P1", "Standardize at source", "", ""),
        (7, "21 channel codes with zero transactions", "store_master", "P2", "Expected in universe?", "", ""),
        (8, "Closed indicator / active null for 199 stores (mostly new)", "location_details", "P1", "Populate closed/active flags", "", "C-1 polarity; verify with DE"),
        (9, "Store format code null for 392 stores", "location_details", "P1", "Populate format codes", "", ""),
        (10, "**ivivva** stores / inventory; exclude from store grain?", "store_master", "P1", "Align with inventory master #4", "", "Links D-5"),
    ],
    "calendar_hierarchy_open_questions.csv": [
        (1, "Calendar ends **FY27**; spec wants **5 years forward (FY2030)**", "calendar_hierarchy", "P1", "Extend fiscal calendar feed", "", "F-7"),
        (2, "Confirm fiscal week is canonical grain for **PSS × store/DC × week**", "calendar_hierarchy, fiscal_date_mapping", "P0", "Sign off week definition vs retail calendar", "", "Ties to IA transfer"),
    ],
    "cross_cutting_open_questions.csv": [
        (1, "**1 vs 3 regional instances** (NAM / EMEA / APAC) for data packaging", "SOW / delivery design", "P1", "Reconcile SOW template vs section 13", "", "F-5"),
        (2, "**Incremental daily refresh**; cadence, regions, delta vs full reload", "S3/GCS feeds", "P1", "Written schedule before go-live", "", "F-9"),
        (3, "Standardize on cleaned / dated raw table variants", "Various raw tables", "P1", "Confirm canonical table per feed", "", ""),
        (4, "Rebuild from cleaned masters; **not** POC master modeling outputs", "BQ master POC tables", "P1", "Confirm IA will not use PC modeling tables", "", ""),
        (5, "calender vs calendar spelling in dataset names", "BQ datasets", "P2", "Canonical naming", "", ""),
        (6, "returns transactions (734M rows); role vs sales transactions", "returns_transactions", "P0", "See transaction master #2", "", "Duplicate pointer for feed owners"),
    ],
}


def _assert_no_em_dash() -> None:
    """Fail export if any table cell contains an em dash (see ~/.cursor/rules/no-em-dash.mdc)."""
    def check(val: str, where: str) -> None:
        if EM_DASH in val:
            raise ValueError(f"Em dash forbidden in {where}: {val!r}")

    for row in ASK_FIRST:
        for i, cell in enumerate(row):
            check(cell, f"ASK_FIRST {row[0]} col{i}")
    for fname, rows in TABLES.items():
        for row in rows:
            for i, cell in enumerate(row):
                if isinstance(cell, str):
                    check(cell, f"{fname} row{row[0]} col{i}")


def _cell_plain(text: object) -> str:
    if not text:
        return ""
    return str(text).replace("**", "")


def _cell_html(text: object) -> str:
    if not text:
        return "&nbsp;"
    parts: list[str] = []
    for chunk in re.split(r"(\*\*.*?\*\*)", str(text)):
        if chunk.startswith("**") and chunk.endswith("**"):
            parts.append(f"<b>{html.escape(chunk[2:-2], quote=True)}</b>")
        elif chunk:
            parts.append(html.escape(chunk, quote=True))
    return "".join(parts)


_CELL = "color:#000;font-family:Segoe UI,Arial,sans-serif;font-size:11pt;"
_TABLE = (
    "border-collapse:collapse;font-family:Segoe UI,Arial,sans-serif;font-size:11pt;color:#000;"
)
_TH = f"border:1px solid #000;padding:6px;{_CELL}font-weight:bold;text-align:left;"
_TH_CENTER = f"border:1px solid #000;padding:6px;{_CELL}font-weight:bold;text-align:center;"
_TD = f"border:1px solid #000;padding:6px;{_CELL}vertical-align:top;text-align:left;"
_TD_CENTER = f"border:1px solid #000;padding:6px;{_CELL}vertical-align:top;text-align:center;"


def _table_html(rows: list[tuple]) -> str:
    parts = [
        f"<table cellpadding='0' cellspacing='0' style='{_TABLE}'>",
        "<thead><tr>",
    ]
    for i, h in enumerate(HEADER):
        style = _TH_CENTER if i == 0 else _TH
        parts.append(f"<th style='{style}'>{_esc(h)}</th>")
    parts.append("</tr></thead><tbody>")
    for row in rows:
        parts.append("<tr>")
        for i, cell in enumerate(row):
            style = _TD_CENTER if i == 0 else _TD
            parts.append(f"<td style='{style}'>{_cell_html(cell)}</td>")
        parts.append("</tr>")
    parts.append("</tbody></table>")
    return "".join(parts)


def _esc(cell: object) -> str:
    return html.escape(str(cell), quote=True)


def _table_tsv(rows: list[tuple]) -> str:
    lines = ["\t".join(HEADER)]
    for row in rows:
        lines.append("\t".join(_cell_plain(c).replace("\t", " ") for c in row))
    return "\n".join(lines)


def write_onenote_html() -> None:
    path = OUT / "open_questions_onenote.html"
    chunks = [
        "<!DOCTYPE html><html><head><meta charset='utf-8'>",
        "<title>Lululemon Client Open Questions</title>",
        f"<style>body,h1,h2,p,table,th,td{{color:#000;}}</style>",
        "</head><body>",
        f"<h1 style='{_CELL}'>Lululemon: Client Open Questions</h1>",
        f"<p style='{_CELL}'>",
        "Forecasting + data transfer. Updated 2026-06-16. ",
        "Copy each table below into OneNote (select table → Cmd+C → paste).</p>",
        f"<h2 style='{_CELL}'>Ask first (kick-off)</h2>",
        f"<table cellpadding='0' cellspacing='0' style='{_TABLE}'>",
        "<thead><tr>",
        f"<th style='{_TH_CENTER}'>ID</th>",
        f"<th style='{_TH}'>Open Q</th>",
        f"<th style='{_TH}'>Master</th>",
        f"<th style='{_TH}'>Priority</th>",
        "</tr></thead><tbody>",
    ]
    for id_, q, master, pri in ASK_FIRST:
        chunks.append(
            "<tr>"
            f"<td style='{_TD_CENTER}'>{_esc(id_)}</td>"
            f"<td style='{_TD}'>{_cell_html(q)}</td>"
            f"<td style='{_TD}'>{_esc(master)}</td>"
            f"<td style='{_TD}'>{_esc(pri)}</td>"
            "</tr>"
        )
    chunks.append("</tbody></table><br/>")

    for filename, title in SECTION_ORDER:
        rows = TABLES[filename]
        chunks.append(f"<h2 style='{_CELL}'>{_esc(title)}</h2>")
        chunks.append(_table_html(rows))
        chunks.append("<br/><br/>")

    chunks.append("</body></html>")
    path.write_text("".join(chunks), encoding="utf-8")
    print(f"Wrote {path}")


def write_onenote_paste_txt() -> None:
    path = OUT / "open_questions_onenote_paste.txt"
    lines = [
        "Lululemon client open questions (OneNote paste) paste",
        "=" * 60,
        "",
        "How to paste into OneNote",
        "1. Recommended: open open_questions_onenote.html in a browser, select one table, copy, paste.",
        "   Bold key terms are preserved when pasting from HTML.",
        "2. Alternative: copy a TSV block below (header row through last data row), paste into OneNote.",
        "3. Paste one section at a time so each master stays a separate OneNote table.",
        "",
        "=" * 60,
        "Ask first (kick-off)",
        "=" * 60,
        "ID\tOpen Q\tMaster\tPriority",
    ]
    for row in ASK_FIRST:
        lines.append("\t".join(_cell_plain(c) for c in row))
    lines.append("")

    for filename, title in SECTION_ORDER:
        lines.extend(["=" * 60, title, "=" * 60, _table_tsv(TABLES[filename]), ""])

    path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {path}")


def _md_cell(text: object) -> str:
    if text is None or text == "":
        return ""
    return str(text).replace("|", "\\|").replace("\n", " ")


def _md_table(rows: list[tuple], center_first: bool = True) -> list[str]:
    cols = len(HEADER)
    if center_first:
        sep = "|:---:|" + "|".join(["---"] * (cols - 1)) + "|"
    else:
        sep = "|" + "|".join(["---"] * cols) + "|"
    lines = [
        "| " + " | ".join(HEADER) + " |",
        sep,
    ]
    for row in rows:
        lines.append("| " + " | ".join(_md_cell(c) for c in row) + " |")
    return lines


def _md_table_simple(headers: list[str], rows: list[list[str]], center_cols: set[int] | None = None) -> list[str]:
    center_cols = center_cols or set()
    sep_parts = [":---:" if i in center_cols else "---" for i in range(len(headers))]
    lines = [
        "| " + " | ".join(headers) + " |",
        "|" + "|".join(sep_parts) + "|",
    ]
    for row in rows:
        lines.append("| " + " | ".join(_md_cell(c) for c in row) + " |")
    return lines


def write_markdown() -> None:
    path = OUT.parent.parent / "findings" / "lululemon_client_open_questions.md"
    lines = [
        "# Open Questions for Lululemon Client",
        "",
        "Last updated: 2026-06-16.",
        "",
        "Scope: Forecasting + data transfer sign-off. SizeSmart archived → "
        "[archive/sizesmart/](../archive/sizesmart/).",
        "",
        "Format: One table per master (workbook style). Exports → "
        "[deliverables/client_open_questions/](../deliverables/client_open_questions/) "
        "(CSV + OneNote HTML/TSV). Regenerate: "
        "`python3 deliverables/client_open_questions/export_open_questions_csv.py`",
        "",
        "Related: [consolidated_p0_p1_issues.md](consolidated_p0_p1_issues.md) · "
        "[master_table_build_logic.md](master_table_build_logic.md)",
        "",
        "---",
        "",
        "## Ask first (top 6 for kick-off)",
        "",
        "| ID | Open Q | Master | Priority |",
        "|:--:|--------|--------|----------|",
    ]
    for id_, q, master, pri in ASK_FIRST:
        lines.append(f"| {id_} | {_md_cell(q)} | {master} | {pri} |")
    lines.extend(
        [
            "",
            "Root cause (in Notes): Source gap = client rehydrate feed · "
            "Hardcoded stub = ask DE first · Business/policy = kick-off decision.",
            "",
            "Not client P0: ~22 PC-era hardcoded stub columns → "
            "[Appendix: IA internal (DE)](#appendix-ia-internal-de-not-for-client-workbook).",
            "",
            "---",
            "",
        ]
    )

    section_headings = {
        "product_master_open_questions.csv": "## 1. Product Master",
        "transaction_master_open_questions.csv": "## 2. Transaction Master",
        "inventory_master_open_questions.csv": "## 3. Inventory Master",
        "store_master_open_questions.csv": "## 4. Store Master",
        "calendar_hierarchy_open_questions.csv": "## 5. Fiscal Calendar",
        "cross_cutting_open_questions.csv": "## 6. Cross-cutting (feeds and delivery)",
    }
    for filename, title in SECTION_ORDER:
        lines.append(section_headings[filename])
        lines.append("")
        lines.extend(_md_table(TABLES[filename]))
        lines.extend(["", "---", ""])

    lines.extend(
        [
            "## Appendix: IA internal (DE), not for client workbook",
            "",
            "Hardcoded in PC build scripts; ask Ritik / DE, not lululemon:",
            "",
            "| Master | Stubbed columns (examples) |",
            "|--------|----------------------------|",
            "| Product Master | launch_date, color_family, ordering, article_status active stub, active_flag 1 |",
            "| Transaction Master | clearance, discounts, transaction_type, order_type, launch_price, … |",
            "| Inventory Master | oo, wip, initial_oh_quantity (= 0) |",
            "| Store Master | location_attrib_squareft, special_classification |",
            "",
            "Logic review: store_master.active = LOC_CLOSED_IND polarity; "
            "AVG(cost_price) semantics in txn build.",
            "",
            "Self-resolved (no ask): gender from l5_name; color_family from color_description; "
            "zero-qty filter; product_attribute_s ingest dedup (PM #7, DE only).",
            "",
            "---",
            "",
            "## Changelog",
            "",
            "| Date | Change |",
            "|------|--------|",
            "| 2026-06-16 | S.no column center-aligned in MD and OneNote tables |",
            "| 2026-06-16 | Removed em dashes from open Q text |",
            "| 2026-06-16 | Dropped Master Table column (redundant with section headers) |",
            "| 2026-06-16 | Sentence-case open Q text; bold key terms only; plain black style (MD + OneNote) |",
            "| 2026-06-16 | Rebuilt as per-master workbook tables (Option A) + CSV exports (Option B) |",
            "| 2026-06-16 | Root cause column; forecasting filter; SizeSmart archived |",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {path}")


def main() -> None:
    _assert_no_em_dash()
    for filename, rows in TABLES.items():
        path = OUT / filename
        with path.open("w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(HEADER)
            for row in rows:
                writer.writerow(tuple(_cell_plain(c) for c in row))
        print(f"Wrote {path} ({len(rows)} rows)")
    write_onenote_html()
    write_onenote_paste_txt()
    write_markdown()


if __name__ == "__main__":
    main()
