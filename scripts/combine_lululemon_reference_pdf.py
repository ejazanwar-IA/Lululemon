#!/usr/bin/env python3
"""
Combine Lululemon reference PNGs into a single multi-page PDF and stacked PNG.

Masters Reference Guide v2 (7 panels):
  1. Product hierarchy L0–L8
  2. Store hierarchy S0–S5
  3. Channel codes on product_code suffix
  4. Four masters health snapshot
  5. Raw → master lineage
  6. Sourcing → intermediate → master → Postgres
  7. InventorySmart Decision Dashboard

Generate v2 panels: python3 scripts/generate_masters_v2_infographics.py

Output:
  - findings/assets/lululemon_masters_reference_guide.pdf
  - findings/assets/lululemon_masters_reference_guide_stacked.png
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "findings" / "assets"

HIERARCHY_PNG = ASSETS / "lululemon_product_hierarchy_summary_designed.png"
HIERARCHY_PNG_FALLBACK = ASSETS / "lululemon_product_hierarchy_summary.png"
STORE_HIERARCHY_PNG = ASSETS / "lululemon_store_hierarchy_summary_designed.png"
CHANNEL_PNG = ASSETS / "lululemon_channel_suffix_reference.png"
FOUR_MASTERS_PNG = ASSETS / "lululemon_four_masters_summary.png"
LINEAGE_PNG = ASSETS / "lululemon_raw_to_master_lineage.png"
SOURCING_PNG = ASSETS / "lululemon_sourcing_pipeline_flow.png"
DECISION_DASHBOARD_PNG = ASSETS / "lululemon_decision_dashboard_reference.png"
PDF_OUT = ASSETS / "lululemon_masters_reference_guide.pdf"
STACKED_PNG_OUT = ASSETS / "lululemon_masters_reference_guide_stacked.png"


def load_rgb(path: Path) -> Image.Image:
    img = Image.open(path)
    if img.mode in ("RGBA", "LA"):
        background = Image.new("RGB", img.size, (255, 255, 255))
        background.paste(img, mask=img.split()[-1])
        return background
    return img.convert("RGB")


def build_pdf(pages: list[Image.Image], out_path: Path) -> None:
    if not pages:
        raise ValueError("No pages to write")
    first, *rest = pages
    first.save(
        out_path,
        "PDF",
        resolution=150.0,
        save_all=True,
        append_images=rest,
    )


def build_stacked(pages: list[Image.Image], out_path: Path, gap: int = 24) -> None:
    """Single tall PNG: all panels top-to-bottom (same width)."""
    target_w = max(p.width for p in pages)
    resized: list[Image.Image] = []
    for p in pages:
        if p.width != target_w:
            h = int(p.height * target_w / p.width)
            resized.append(p.resize((target_w, h), Image.Resampling.LANCZOS))
        else:
            resized.append(p)
    total_h = sum(p.height for p in resized) + gap * (len(resized) - 1)
    canvas = Image.new("RGB", (target_w, total_h), (255, 255, 255))
    y = 0
    for i, p in enumerate(resized):
        canvas.paste(p, (0, y))
        y += p.height + (gap if i < len(resized) - 1 else 0)
    canvas.save(out_path, "PNG", optimize=True)


def resolve_hierarchy_png() -> Path:
    if HIERARCHY_PNG.is_file():
        return HIERARCHY_PNG
    if HIERARCHY_PNG_FALLBACK.is_file():
        print(f"Note: using fallback {HIERARCHY_PNG_FALLBACK.name}")
        return HIERARCHY_PNG_FALLBACK
    raise FileNotFoundError(f"Missing hierarchy PNG: {HIERARCHY_PNG} or {HIERARCHY_PNG_FALLBACK}")


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    hierarchy_path = resolve_hierarchy_png()
    page_order: list[tuple[str, Path]] = [
        ("Product hierarchy (L0–L8)", hierarchy_path),
        ("Store hierarchy (S0–S5)", STORE_HIERARCHY_PNG),
        ("Channel codes on product_code suffix", CHANNEL_PNG),
        ("Four masters health snapshot", FOUR_MASTERS_PNG),
        ("Raw → master lineage", LINEAGE_PNG),
        ("Sourcing → intermediate → master", SOURCING_PNG),
        ("InventorySmart Decision Dashboard", DECISION_DASHBOARD_PNG),
    ]
    missing = [p for _, p in page_order if not p.is_file()]
    if missing:
        hint = "Run: python3 scripts/generate_masters_v2_infographics.py"
        raise FileNotFoundError(
            f"Missing inputs ({len(missing)}): "
            + ", ".join(p.name for p in missing)
            + f"\n{hint}"
        )

    pages = [load_rgb(path) for _, path in page_order]
    build_pdf(pages, PDF_OUT)
    build_stacked(pages, STACKED_PNG_OUT)
    print(f"Wrote {PDF_OUT} ({len(pages)} pages)")
    for title, _ in page_order:
        print(f"  - {title}")
    print(f"Wrote {STACKED_PNG_OUT}")


if __name__ == "__main__":
    main()
