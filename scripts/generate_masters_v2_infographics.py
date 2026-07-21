#!/usr/bin/env python3
"""
Generate Masters Reference Guide v2 infographic panels (static curated data).

Outputs (findings/assets/):
  - lululemon_store_hierarchy_summary_designed.png
  - lululemon_four_masters_summary.png
  - lululemon_raw_to_master_lineage.png
  - lululemon_sourcing_pipeline_flow.png

Regenerate stacked guide: python3 scripts/combine_lululemon_reference_pdf.py
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib.gridspec import GridSpec

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "findings" / "assets"
AS_OF = "2026-05-20"
PROJECT = "lululemon-01042025"

NAVY = "#1B2A4A"
ACCENT = "#C41E3A"
LIGHT_BG = "#F7F8FA"
GRID_COLOR = "#D0D5DD"
RAW_FILL = "#E8F4FD"
MASTER_FILL = "#FFF4E6"
SOURCING_FILL = "#E8F5E9"
PG_FILL = "#F3E8FD"


def _header(ax, title: str, subtitle: str) -> None:
    ax.set_axis_off()
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.add_patch(
        FancyBboxPatch(
            (0, 0.9), 1, 0.1, boxstyle="square,pad=0",
            facecolor=NAVY, edgecolor="none", transform=ax.transAxes,
        )
    )
    ax.text(0.5, 0.95, title, ha="center", va="center", fontsize=18,
            fontweight="bold", color="white", transform=ax.transAxes)
    ax.text(0.5, 0.91, subtitle, ha="center", va="center", fontsize=9,
            color="#B8C5D9", transform=ax.transAxes)


def build_store_hierarchy() -> plt.Figure:
    levels = [
        ("S0", "Brand", "s0_name", "1", "LULULEMON"),
        ("S1", "Channel", "s1_name", "6", "RETAIL, ECOMM, FO, STRAT, CMNTY, COMMUNITY"),
        ("S2", "Country", "s2_name", "~24", "US, China, Canada, …"),
        ("S3", "Region", "s3_name", "many", "7 rows with \\N sentinel → NULL"),
        ("S4", "Area", "s4_name", "many", "Geographic area under region"),
        ("S5", "Store", "store_code", "1,853", "Physical store / DC location"),
    ]
    distinct = [1, 6, 24, 50, 80, 1853]  # illustrative bar scale for s3/s4

    fig = plt.figure(figsize=(14, 10), facecolor="white")
    gs = GridSpec(2, 1, height_ratios=[0.55, 0.45], hspace=0.25)
    ax0 = fig.add_subplot(gs[0])
    _header(
        ax0,
        "Lululemon Store Hierarchy Summary",
        f"As of {AS_OF} · {PROJECT}.lulu_ingestion_dev.store_master · 1,853 rows · spine: location_group_hierarchy",
    )

    table_data = [
        ["Level", "Meaning", "Column", "Distinct", "Examples"],
        *[[lv[0], lv[1], lv[2], lv[3], lv[4]] for lv in levels],
    ]
    tbl = ax0.table(
        cellText=table_data[1:],
        colLabels=table_data[0],
        cellLoc="left",
        loc="upper center",
        bbox=[0.02, 0.05, 0.96, 0.82],
    )
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)
    tbl.scale(1, 1.45)
    for (row, col), cell in tbl.get_celld().items():
        cell.set_edgecolor(GRID_COLOR)
        if row == 0:
            cell.set_facecolor(NAVY)
            cell.set_text_props(color="white", fontweight="bold")
        else:
            cell.set_facecolor("white" if row % 2 else LIGHT_BG)

    ax1 = fig.add_subplot(gs[1])
    labels = [lv[0] for lv in levels]
    bars = ax1.barh(range(len(labels)), distinct, color=NAVY, height=0.6)
    ax1.set_yticks(range(len(labels)))
    ax1.set_yticklabels(labels)
    ax1.set_xscale("log")
    ax1.set_xlabel("Distinct count (log scale)")
    ax1.set_title("Granularity by Level", fontweight="bold")
    ax1.invert_yaxis()
    ax1.grid(axis="x", alpha=0.3)
    for bar, val in zip(bars, distinct):
        ax1.text(bar.get_width() * 1.05, bar.get_y() + bar.get_height() / 2,
                 f"{val:,}" if val > 1 else str(val), va="center", fontsize=9)

    fig.text(0.04, 0.02,
             "Store type: 93% Store (dc_flag=0, loc_type S) · 7% DC (dc_flag=1, loc_type W). "
             "Join inv/txn on store_code; channel in s1_name may differ from product_code suffix.",
             fontsize=8.5, color="#444", style="italic")
    return fig


def build_four_masters() -> plt.Figure:
    fig = plt.figure(figsize=(14, 9), facecolor="white")
    ax = fig.add_subplot(111)
    _header(
        ax,
        "Four Masters — Health Snapshot",
        f"As of {AS_OF} · {PROJECT}.lulu_ingestion_dev · billing: lululemon-data-scan",
    )

    rows = [
        ["product_master", "1,977,528", "0.82 GB", "product_code", "PASS", "0% null l0/l2/product_name"],
        ["store_master", "1,853", "<0.01 GB", "store_code", "PASS", "Full LGH + location_details match"],
        ["transaction_master", "354,138,091", "66.8 GB", "date × store × product", "PASS", "Filter qty>0 & revenue>0 for sales"],
        ["inventory_master", "5,539,053", "0.68 GB", "date × store × product", "PASS", "Single date POC: 2025-08-28"],
    ]
    cross = [
        ["X1 Txn → PM", "0 orphans", "PASS"],
        ["X2 Txn → SM", "0 orphans", "PASS"],
        ["X3 Inv → PM (strict suffix)", "364K rows INFO", "Channel suffix mismatch — bare SKU exists"],
        ["X4 Inv → SM", "0 orphans", "PASS"],
        ["X5 PM never sold", "63% SKUs", "INFO — assortment breadth"],
        ["X6 Channel alignment", "RETAIL/ECOMM", "PASS on sold SKUs"],
    ]

    t1 = ax.table(
        cellText=rows,
        colLabels=["Table", "Rows", "Size", "Grain", "Verdict", "Notes"],
        cellLoc="left", loc="upper center", bbox=[0.02, 0.52, 0.96, 0.36],
    )
    t1.auto_set_font_size(False)
    t1.set_fontsize(9)
    t1.scale(1, 1.5)
    for (row, col), cell in t1.get_celld().items():
        cell.set_edgecolor(GRID_COLOR)
        if row == 0:
            cell.set_facecolor(NAVY)
            cell.set_text_props(color="white", fontweight="bold")
        else:
            cell.set_facecolor("white" if row % 2 else LIGHT_BG)
            if col == 4 and "PASS" in cell.get_text().get_text():
                cell.set_facecolor("#E8F5E9")

    ax.text(0.04, 0.48, "Cross-master checks", fontsize=11, fontweight="bold", color=NAVY)
    t2 = ax.table(
        cellText=cross,
        colLabels=["Check", "Result", "Verdict"],
        cellLoc="left", loc="upper center", bbox=[0.02, 0.08, 0.7, 0.38],
    )
    t2.auto_set_font_size(False)
    t2.set_fontsize(9)
    t2.scale(1, 1.4)
    for (row, col), cell in t2.get_celld().items():
        cell.set_edgecolor(GRID_COLOR)
        if row == 0:
            cell.set_facecolor(NAVY)
            cell.set_text_props(color="white", fontweight="bold")
        else:
            cell.set_facecolor("white" if row % 2 else LIGHT_BG)

    ax.text(0.74, 0.22, "Datasets\n\n"
            "Raw: lululemon_souricng_outbound\n"
            "Sourcing: lulu_sourcing_dev\n"
            "Masters: lulu_ingestion_dev\n"
            "Postgres: lulu_dev.global.*",
            fontsize=9, va="top", color="#333",
            bbox=dict(boxstyle="round", facecolor=LIGHT_BG, edgecolor=GRID_COLOR))
    return fig


def _box(ax, xy, w, h, text, facecolor, fontsize=8):
    x, y = xy
    patch = FancyBboxPatch(
        (x, y), w, h, boxstyle="round,pad=0.01,rounding_size=0.02",
        facecolor=facecolor, edgecolor=NAVY, linewidth=1, transform=ax.transAxes,
    )
    ax.add_patch(patch)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fontsize,
            transform=ax.transAxes, wrap=True)


def _arrow(ax, start, end):
    ax.add_patch(FancyArrowPatch(
        start, end, transform=ax.transAxes,
        arrowstyle="->", color=NAVY, lw=1.5, mutation_scale=12,
    ))


def build_lineage() -> plt.Figure:
    fig, ax = plt.subplots(figsize=(14, 11), facecolor="white")
    _header(ax, "Raw → Master Lineage", f"Lululemon build paths · {AS_OF} · see findings/raw_to_master_lineage.md")

    # Raw column
    raws = [
        "product_group_hierarchy*\n+ sku_details\n+ product_attribute_s",
        "sales_transactions_4y",
        "inventory_snapshot_cleaned",
        "location_group_hierarchy\n+ location_details",
    ]
    masters = ["product_master\n1.98M", "transaction_master\n354M", "inventory_master\n5.5M (POC date)",
               "store_master\n1,853"]
    y_raw = [0.72, 0.54, 0.36, 0.18]
    y_m = y_raw
    for i, (raw, mas) in enumerate(zip(raws, masters)):
        _box(ax, (0.05, y_raw[i]), 0.38, 0.12, raw, RAW_FILL, 7.5)
        _box(ax, (0.55, y_m[i]), 0.38, 0.12, mas, MASTER_FILL, 7.5)
        _arrow(ax, (0.44, y_raw[i] + 0.06), (0.54, y_m[i] + 0.06))

    ax.text(0.05, 0.86, "RAW (lululemon_souricng_outbound → lulu_sourcing_dev cleaned)",
            fontsize=10, fontweight="bold", color=NAVY)
    ax.text(0.55, 0.86, "MASTERS (lulu_ingestion_dev)", fontsize=10, fontweight="bold", color="#7A2E02")

    notes = [
        "• product_master: pgh spine + LEFT sku_details + product_attribute_s",
        "• transaction_master: sales INNER pgh; store via location_id_sales",
        "• inventory_master: inv snapshot INNER pgh (sku_id_channel = sku_id_code)",
        "• store_master: LGH spine + LEFT location_details (ws_channel)",
        "• Ghost: sku_details_cleaned (no _20251119) — txn build refs suffixed table",
        "• Also: events_master ← promotional_events; fiscal_date_mapping ← calendar_hierarchy",
    ]
    for i, line in enumerate(notes):
        ax.text(0.05, 0.06 - i * 0.025, line, fontsize=8.5, color="#333")

    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    return fig


def build_sourcing_flow() -> plt.Figure:
    fig, ax = plt.subplots(figsize=(14, 10), facecolor="white")
    _header(ax, "Sourcing → Intermediate → Master", "IA Platform pipeline · Lululemon datasets")

    steps = [
        (0.08, "Client raw\nlululemon_souricng_outbound", RAW_FILL),
        (0.08, "Sourcing DAG\nlulu_sourcing_dev.*_cleaned", SOURCING_FILL),
        (0.08, "Intermediates\nproduct / store / txn / inv", SOURCING_FILL),
        (0.08, "BQ masters\nlulu_ingestion_dev.*_master", MASTER_FILL),
        (0.08, "Postgres ingestion\nlulu_dev global.*", PG_FILL),
    ]
    y = 0.72
    labels = [
        "mapping.view → extract",
        "create_*_intermediate_periodic.sql\nSYNCSTARTDATETIME / SNAPSHOT_TIME",
        "master_table_build_queries",
        "GSM → sync_*_master → PAF/SAF/PHF",
    ]
    for i, (x, text, color) in enumerate(steps):
        _box(ax, (x, y - i * 0.14), 0.84, 0.1, text, color, 10)
        if i < len(labels):
            ax.text(0.92, y - i * 0.14 + 0.04, "→", fontsize=14, fontweight="bold", color=NAVY)
        if i < len(steps) - 1:
            _arrow(ax, (0.5, y - i * 0.14 - 0.01), (0.5, y - (i + 1) * 0.14 + 0.11))

    intermediates = (
        "Intermediates (Confluence: Sourcing Tables):\n"
        "  product_intermediate · store_intermediate · transaction_intermediate\n"
        "  inventory_intermediate · fiscal_calendar_intermediate"
    )
    ax.text(0.08, 0.22, intermediates, fontsize=9, color="#333",
            bbox=dict(boxstyle="round", facecolor=LIGHT_BG, edgecolor=GRID_COLOR))

    ax.text(0.08, 0.08,
            "Periodic filter: lulu_sourcing_dev.mapping.filter_param · "
            "MERGE keys: (date, store_code, product_code) for txn/inv",
            fontsize=8.5, style="italic", color="#444")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    return fig


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    outputs = [
        ("store hierarchy", build_store_hierarchy, "lululemon_store_hierarchy_summary_designed.png"),
        ("four masters", build_four_masters, "lululemon_four_masters_summary.png"),
        ("lineage", build_lineage, "lululemon_raw_to_master_lineage.png"),
        ("sourcing flow", build_sourcing_flow, "lululemon_sourcing_pipeline_flow.png"),
    ]
    for label, builder, name in outputs:
        print(f"Building {label}...")
        fig = builder()
        path = ASSETS / name
        fig.savefig(path, dpi=150, bbox_inches="tight", facecolor="white")
        plt.close(fig)
        print(f"  Wrote {path}")


if __name__ == "__main__":
    main()
