#!/usr/bin/env python3
"""Write local markdown mirror from Confluence page JSON (Inventory Smart Handbook).

Usage:
  python3 scripts/mirror_inventorysmart_handbook.py \\
    reference_docs/Lululemon/InventorySmart_Handbook/_pages.json

Each entry: {"id","title","webUrl","createdAt","body"} (Confluence getConfluencePage shape).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "reference_docs" / "Lululemon" / "InventorySmart_Handbook"


def slugify(title: str, page_id: str) -> str:
    base = re.sub(r"[^\w\s-]", "", title.lower())
    base = re.sub(r"[\s/]+", "_", base.strip())
    base = re.sub(r"_+", "_", base).strip("_")
    return f"{page_id}_{base}" if base else page_id


def page_to_markdown(page: dict) -> str:
    title = page.get("title", "Untitled")
    page_id = page.get("id", "")
    web_url = page.get("webUrl", "")
    created = page.get("createdAt", "")
    body = page.get("body") or ""

    return f"""# {title}

| Field | Value |
|---|---|
| Confluence page ID | `{page_id}` |
| Source URL | {web_url} |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | {created} |
| Last mirrored | 2026-05-21 |

---

{body}
"""


def build_index(pages: list[dict]) -> str:
    handbooks = []
    user_stories = []
    other = []

    for p in sorted(pages, key=lambda x: x.get("title", "")):
        title = p.get("title", "")
        pid = p.get("id", "")
        fname = slugify(title, pid) + ".md"
        link = f"[{title}](./{fname})"
        parent_hint = p.get("_folder", "")
        if "User Story" in title or title.startswith("Configuration ->") or title.startswith("Grouping ->") or title.startswith("Constraints ->") or title.startswith("Create New") or title.startswith("Decision Dashboard -") or title.startswith("Report -") or title.startswith("Downstream") or title.startswith("Delta Feed") or title.startswith("Configurator") or title.startswith("[Old Version]") or title.startswith("View Past") or title.startswith("Order Batching -") or title.startswith("Product Profile -") or title == "User Story Index":
            user_stories.append(link)
        elif any(k in title for k in ("Handbook", "FAQs", "Validation", "Mapping")) or title == "Inventory Smart- Handbook":
            handbooks.append(link)
        else:
            other.append(link)

    def section(name: str, items: list[str]) -> str:
        if not items:
            return ""
        lines = "\n".join(f"- {x}" for x in items)
        return f"## {name}\n\n{lines}\n\n"

    return f"""# Inventory Smart Handbook — local mirror

Offline copy of the [Inventory Smart- Handbook](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609793) Confluence tree.

**Why this exists:** MCP / Confluence access may not always be available. Search this folder and `findings/lululemon_knowledge_bank.md` first.

**Refresh:** re-fetch pages via Atlassian MCP (`getConfluencePage`), append to `_pages.json`, re-run this script.

**External-only pages:** some Confluence pages link to Google Sheets only (see Module Level Table Mapping).

---

{section("Handbooks & reference", handbooks)}{section("User stories", user_stories)}{section("Other", other)}"""


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: mirror_inventorysmart_handbook.py <path-to-_pages.json>", file=sys.stderr)
        sys.exit(1)

    manifest = Path(sys.argv[1])
    pages: list[dict] = json.loads(manifest.read_text(encoding="utf-8"))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    user_stories_dir = OUT_DIR / "user_stories"
    user_stories_dir.mkdir(exist_ok=True)

    written = 0
    for page in pages:
        title = page.get("title", "Untitled")
        page_id = page.get("id", "")
        slug = slugify(title, page_id)
        is_user_story = (
            "User Story" in title
            or title.startswith("Configuration ->")
            or title.startswith("Grouping ->")
            or title.startswith("Constraints ->")
            or title.startswith("Create New")
            or title.startswith("Decision Dashboard -")
            or title == "User Story Index"
            or title.startswith("Downstream")
            or title.startswith("Delta Feed")
            or title.startswith("Configurator")
            or title.startswith("[Old Version]")
        )
        out_path = (user_stories_dir if is_user_story else OUT_DIR) / f"{slug}.md"
        out_path.write_text(page_to_markdown(page), encoding="utf-8")
        written += 1

    (OUT_DIR / "README.md").write_text(build_index(pages), encoding="utf-8")
    print(f"Wrote {written} pages to {OUT_DIR}")


if __name__ == "__main__":
    main()
