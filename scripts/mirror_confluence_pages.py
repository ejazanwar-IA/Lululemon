#!/usr/bin/env python3
"""Save Confluence pages to a local markdown mirror (offline reference).

Usage:
  # Save one page from stdin (getConfluencePage JSON)
  python3 scripts/mirror_confluence_pages.py save \\
    --mirror-dir reference_docs/IA_Platform/Sourcing_Tables \\
    --page-id 966393875 < page.json

  # Rebuild markdown + README from _raw/
  python3 scripts/mirror_confluence_pages.py build \\
    --mirror-dir reference_docs/IA_Platform/Sourcing_Tables \\
    --title "Sourcing Tables" \\
    --source-url "https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966393875/Sourcing+Tables"
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def slugify(title: str, page_id: str) -> str:
    base = re.sub(r"[^\w\s-]", "", title.lower())
    base = re.sub(r"[\s/]+", "_", base.strip())
    base = re.sub(r"_+", "_", base).strip("_")
    return f"{page_id}_{base}" if base else page_id


def slim(page: dict) -> dict:
    return {
        "id": page["id"],
        "title": page.get("title"),
        "webUrl": page.get("webUrl"),
        "createdAt": page.get("createdAt"),
        "body": page.get("body") or "",
    }


def page_to_markdown(page: dict, mirrored_date: str = "2026-05-21") -> str:
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
| Mirrored from | Impact Analytics Confluence (IA space) |
| Created (Confluence) | {created} |
| Last mirrored | {mirrored_date} |

---

{body}
"""


def build_index(pages: list[dict], title: str, source_url: str) -> str:
    lines = [
        f"# {title} — local mirror",
        "",
        f"Offline copy of [{title}]({source_url}) (IA Confluence space).",
        "",
        "**Why this exists:** MCP / Confluence access may not always be available.",
        "",
        "**Refresh:** re-fetch via Atlassian MCP (`getConfluencePage`), pipe to "
        "`python3 scripts/mirror_confluence_pages.py save --mirror-dir <dir> --page-id <id>`, "
        "then run `build`.",
        "",
        "---",
        "",
    ]
    for p in sorted(pages, key=lambda x: x.get("title", "")):
        slug = slugify(p.get("title", ""), p.get("id", ""))
        lines.append(f"- [{p.get('title')}](./{slug}.md)")
    lines.append("")
    return "\n".join(lines)


def cmd_save(args: argparse.Namespace) -> None:
    mirror_dir = ROOT / args.mirror_dir
    raw_dir = mirror_dir / "_raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    page = slim(json.loads(sys.stdin.read()))
    out = raw_dir / f"{page['id']}.json"
    out.write_text(json.dumps(page, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {out.relative_to(ROOT)}")


def cmd_build(args: argparse.Namespace) -> None:
    mirror_dir = ROOT / args.mirror_dir
    raw_dir = mirror_dir / "_raw"
    manifest_path = mirror_dir / "_pages.json"

    pages: list[dict] = []
    if args.page_ids:
        by_id = {}
        for path in raw_dir.glob("*.json"):
            obj = json.loads(path.read_text(encoding="utf-8"))
            by_id[obj["id"]] = obj
        pages = [by_id[pid] for pid in args.page_ids if pid in by_id]
    else:
        pages = sorted(
            [json.loads(p.read_text(encoding="utf-8")) for p in raw_dir.glob("*.json")],
            key=lambda x: x.get("title", ""),
        )

    mirror_dir.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(pages, ensure_ascii=False, indent=2), encoding="utf-8")

    for page in pages:
        slug = slugify(page.get("title", ""), page.get("id", ""))
        md_path = mirror_dir / f"{slug}.md"
        md_path.write_text(page_to_markdown(page), encoding="utf-8")

    if args.title and args.source_url:
        readme = mirror_dir / "README.md"
        readme.write_text(build_index(pages, args.title, args.source_url), encoding="utf-8")

    print(f"Built {len(pages)} pages -> {mirror_dir.relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)

    save_p = sub.add_parser("save")
    save_p.add_argument("--mirror-dir", required=True)
    save_p.add_argument("--page-id", required=True)

    build_p = sub.add_parser("build")
    build_p.add_argument("--mirror-dir", required=True)
    build_p.add_argument("--title", default="")
    build_p.add_argument("--source-url", default="")
    build_p.add_argument(
        "--page-ids",
        nargs="*",
        default=[],
        help="Optional ordered page ID list for manifest",
    )

    args = parser.parse_args()
    if args.cmd == "save":
        cmd_save(args)
    else:
        cmd_build(args)


if __name__ == "__main__":
    main()
