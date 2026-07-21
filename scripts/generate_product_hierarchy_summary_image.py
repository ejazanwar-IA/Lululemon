#!/usr/bin/env python3
"""
Generate Lululemon Product Hierarchy Summary infographic from live BQ product_master.

Output: findings/assets/lululemon_product_hierarchy_summary.png
Data:   lululemon-01042025.lulu_ingestion_dev.product_master
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.gridspec import GridSpec

PROJECT = "lululemon-01042025"
DATASET = "lulu_ingestion_dev"
TABLE = f"`{PROJECT}.{DATASET}.product_master`"
BILLING = "lululemon-data-scan"
AS_OF = "2026-05-20"

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "findings" / "assets"
OUT_PATH = OUT_DIR / "lululemon_product_hierarchy_summary.png"

LEVELS = [
    ("L0", "Brand", "l0_name"),
    ("L1", "Channel", "l1_name"),
    ("L2", "Division", "l2_name"),
    ("L3", "Department", "l3_name"),
    ("L4", "Class", "l4_name"),
    ("L5", "Subclass", "l5_name"),
    ("L6", "Product Family / Style Group", "l6_name"),
    ("L7", "Style / Article Name", "l7_name"),
    ("L8", "Size-Level Product Name", "l8_name"),
]

NAVY = "#1B2A4A"
ACCENT = "#C41E3A"
LIGHT_BG = "#F7F8FA"
GRID_COLOR = "#D0D5DD"


def bq_json(sql: str) -> list[dict]:
    proc = subprocess.run(
        [
            "bq",
            "query",
            "--use_legacy_sql=false",
            f"--project_id={BILLING}",
            "--format=prettyjson",
            "--max_rows=10000",
            sql,
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(proc.stdout)


def fetch_counts() -> dict[str, int]:
    parts = ",\n".join(
        f"COUNT(DISTINCT {col}) AS {col}" for _, _, col in LEVELS
    )
    row = bq_json(f"SELECT {parts} FROM {TABLE}")[0]
    return {col: int(row[col]) for _, _, col in LEVELS}


def fetch_examples() -> dict[str, str]:
    examples: dict[str, str] = {}
    for _, _, col in LEVELS:
        rows = bq_json(
            f"""
            SELECT {col} AS val, COUNT(*) AS n
            FROM {TABLE}
            WHERE {col} IS NOT NULL AND {col} NOT IN ('', '\\\\N')
            GROUP BY {col}
            ORDER BY n DESC
            LIMIT 3
            """
        )
        vals = [r["val"] for r in rows if r.get("val")]
        if col == "l0_name":
            examples[col] = ", ".join(vals)
        elif col == "l1_name":
            examples[col] = ", ".join(vals)
        else:
            short = [v if len(v) <= 28 else v[:25] + "..." for v in vals]
            examples[col] = ", ".join(short) if short else "—"
    return examples


def build_figure(counts: dict[str, int], examples: dict[str, str]) -> plt.Figure:
    labels = [lv[0] for lv in LEVELS]
    meanings = [lv[1] for lv in LEVELS]
    cols = [lv[2] for lv in LEVELS]
    distinct = [counts[c] for c in cols]
    ex = [examples[c] for c in cols]

    fig = plt.figure(figsize=(14, 11), facecolor="white")
    gs = GridSpec(3, 1, height_ratios=[0.42, 0.36, 0.22], hspace=0.28)

    # --- Header + table ---
    ax0 = fig.add_subplot(gs[0])
    ax0.set_axis_off()
    ax0.set_xlim(0, 1)
    ax0.set_ylim(0, 1)

    ax0.add_patch(mpatches.FancyBboxPatch(
        (0, 0.88), 1, 0.12, boxstyle="square,pad=0",
        facecolor=NAVY, edgecolor="none", transform=ax0.transAxes,
    ))
    ax0.text(
        0.5, 0.94, "Lululemon Product Hierarchy Summary",
        ha="center", va="center", fontsize=20, fontweight="bold", color="white",
        transform=ax0.transAxes,
    )
    ax0.text(
        0.5, 0.89,
        f"As of {AS_OF} · {PROJECT}.{DATASET}.product_master · 1,977,528 rows",
        ha="center", va="center", fontsize=10, color="#B8C5D9",
        transform=ax0.transAxes,
    )

    table_data = [
        ["Level", "Meaning", "Example", "Distinct Count"],
        *[
            [labels[i], meanings[i], ex[i], f"{distinct[i]:,}"]
            for i in range(len(LEVELS))
        ],
    ]
    tbl = ax0.table(
        cellText=table_data[1:],
        colLabels=table_data[0],
        cellLoc="left",
        loc="upper center",
        bbox=[0.02, 0.02, 0.96, 0.82],
    )
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)
    tbl.scale(1, 1.55)

    for (row, col), cell in tbl.get_celld().items():
        cell.set_edgecolor(GRID_COLOR)
        if row == 0:
            cell.set_facecolor(NAVY)
            cell.set_text_props(color="white", fontweight="bold")
        else:
            cell.set_facecolor("white" if row % 2 else LIGHT_BG)

    ax0.text(
        0.02, 0.0,
        "How to read: L2–L5 = stable category segmentation. L6–L8 = style/article/size detail. "
        "Distinct counts rise sharply after L5.",
        ha="left", va="bottom", fontsize=9, color="#444", style="italic",
        transform=ax0.transAxes,
    )

    # --- Bar chart ---
    ax1 = fig.add_subplot(gs[1])
    y_pos = range(len(labels))
    bars = ax1.barh(y_pos, distinct, color=NAVY, height=0.65)
    ax1.set_yticks(y_pos)
    ax1.set_yticklabels(labels, fontsize=11)
    ax1.set_xscale("log")
    ax1.set_xlabel("Distinct count (log scale)", fontsize=10)
    ax1.set_title("Granularity by Level", fontsize=13, fontweight="bold", pad=10)
    ax1.grid(axis="x", alpha=0.3)
    ax1.invert_yaxis()
    for bar, val in zip(bars, distinct):
        ax1.text(
            bar.get_width() * 1.05,
            bar.get_y() + bar.get_height() / 2,
            f"{val:,}",
            va="center",
            ha="left",
            fontsize=9,
        )

    # --- Footer: caution + identifiers ---
    ax2 = fig.add_subplot(gs[2])
    ax2.set_axis_off()
    ax2.set_xlim(0, 1)
    ax2.set_ylim(0, 1)

    ax2.add_patch(mpatches.FancyBboxPatch(
        (0.02, 0.52), 0.96, 0.42, boxstyle="round,pad=0.02,rounding_size=0.02",
        facecolor="#FDECEC", edgecolor=ACCENT, linewidth=1.5, transform=ax2.transAxes,
    ))
    ax2.text(
        0.04, 0.82, "Key grain caution", fontsize=11, fontweight="bold",
        color=ACCENT, transform=ax2.transAxes,
    )
    ax2.text(
        0.04, 0.62,
        "At product_code_original grain, channel-dependent fields can double-count. "
        "Use product_code for channel-specific distributions.",
        fontsize=10, color="#333", wrap=True, transform=ax2.transAxes,
    )

    ax2.text(
        0.04, 0.38, "Identifier key", fontsize=11, fontweight="bold",
        color=NAVY, transform=ax2.transAxes,
    )
    id_lines = [
        "product_code_original = bare SKU",
        "product_code = channel-specific SKU (_RETAIL / _ECOMM)",
        "article_original = style-color without channel",
        "article = style-color with channel",
    ]
    for i, line in enumerate(id_lines):
        ax2.text(0.04, 0.28 - i * 0.08, f"• {line}", fontsize=9.5, color="#333",
                 transform=ax2.transAxes)

    return fig


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print("Fetching distinct counts from BigQuery...")
    counts = fetch_counts()
    print("Fetching top examples per level...")
    examples = fetch_examples()
    print("Building figure...")
    fig = build_figure(counts, examples)
    fig.savefig(OUT_PATH, dpi=150, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"Wrote {OUT_PATH}")
    print("Counts:", {lv[0]: counts[lv[2]] for lv in LEVELS})


if __name__ == "__main__":
    main()
