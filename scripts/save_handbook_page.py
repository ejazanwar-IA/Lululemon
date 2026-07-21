#!/usr/bin/env python3
"""Append one Confluence page JSON (stdin) to handbook _raw/ and rebuild _pages.json."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "reference_docs" / "Lululemon" / "InventorySmart_Handbook" / "_raw"
MANIFEST = ROOT / "reference_docs" / "Lululemon" / "InventorySmart_Handbook" / "_pages.json"

PAGE_IDS = [
    "2696609793", "2696609807", "2696609825", "2696609990", "2696610014",
    "2696610398", "2696610422", "2696610488", "2696610522", "2696610534",
    "2696610554", "2696610609", "2696610627", "2696610653", "2696611795",
    "2696611810", "2696610685", "2696610753", "2696610771", "2696610787",
    "2696610803", "2696610831", "2696610859", "2696610885", "2696610899",
    "2696610922", "2696610948", "2696611025", "2696611046", "2696611080",
    "2696611113", "2696611146", "2696611179", "2696611213", "2696611244",
    "2696611283", "2696611375", "2696611410", "2696611422", "2696611453",
    "2696611595", "2696611649", "2696611670", "2696611682", "2696611703",
]


def slim(page: dict) -> dict:
    return {
        "id": page["id"],
        "title": page.get("title"),
        "webUrl": page.get("webUrl"),
        "createdAt": page.get("createdAt"),
        "body": page.get("body") or "",
    }


def rebuild_manifest() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    by_id: dict[str, dict] = {}
    for path in RAW.glob("*.json"):
        obj = json.loads(path.read_text(encoding="utf-8"))
        by_id[obj["id"]] = obj
    ordered = [by_id[pid] for pid in PAGE_IDS if pid in by_id]
    MANIFEST.write_text(json.dumps(ordered, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Manifest: {len(ordered)}/{len(PAGE_IDS)} pages")


def main() -> None:
    if len(sys.argv) == 2 and sys.argv[1] == "--rebuild-only":
        rebuild_manifest()
        return

    raw = sys.stdin.read()
    page = json.loads(raw)
    RAW.mkdir(parents=True, exist_ok=True)
    out = RAW / f"{page['id']}.json"
    out.write_text(json.dumps(slim(page), ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {out.name}")
    rebuild_manifest()


if __name__ == "__main__":
    main()
