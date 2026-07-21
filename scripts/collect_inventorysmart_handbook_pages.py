#!/usr/bin/env python3
"""Collect Confluence page JSON from agent-tools dumps into _pages.json."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HANDBOOK = ROOT / "reference_docs" / "Lululemon" / "InventorySmart_Handbook"
OUT = HANDBOOK / "_pages.json"
RAW = HANDBOOK / "_raw"
AGENT_TOOLS = Path.home() / ".cursor/projects/Users-ejazanwarmd-Desktop-Lululemon/agent-tools"

PAGE_IDS = [
    "2696609793",
    "2696609807",
    "2696609825",
    "2696609990",
    "2696610014",
    "2696610398",
    "2696610422",
    "2696610488",
    "2696610522",
    "2696610534",
    "2696610554",
    "2696610609",
    "2696610627",
    "2696610653",
    "2696611795",
    "2696611810",
    "2696610685",
    "2696610753",
    "2696610771",
    "2696610787",
    "2696610803",
    "2696610831",
    "2696610859",
    "2696610885",
    "2696610899",
    "2696610922",
    "2696610948",
    "2696611025",
    "2696611046",
    "2696611080",
    "2696611113",
    "2696611146",
    "2696611179",
    "2696611213",
    "2696611244",
    "2696611283",
    "2696611375",
    "2696611410",
    "2696611422",
    "2696611453",
    "2696611595",
    "2696611649",
    "2696611670",
    "2696611682",
    "2696611703",
]


def extract_pages_from_text(text: str) -> dict[str, dict]:
    found: dict[str, dict] = {}
    # Each MCP dump is a single JSON object
    for match in re.finditer(r'\{\s*"id"\s*:\s*"(26966\d+)"', text):
        start = match.start()
        depth = 0
        for i in range(start, len(text)):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
                if depth == 0:
                    chunk = text[start : i + 1]
                    try:
                        obj = json.loads(chunk)
                    except json.JSONDecodeError:
                        break
                    pid = obj.get("id")
                    if pid and obj.get("body") is not None:
                        found[pid] = {
                            "id": pid,
                            "title": obj.get("title"),
                            "webUrl": obj.get("webUrl"),
                            "createdAt": obj.get("createdAt"),
                            "body": obj.get("body"),
                        }
                    break
    return found


def main() -> None:
    pages: dict[str, dict] = {}
    if RAW.is_dir():
        for path in RAW.glob("*.json"):
            try:
                obj = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue
            pid = obj.get("id")
            if pid:
                pages[pid] = obj
    if AGENT_TOOLS.is_dir():
        for path in AGENT_TOOLS.glob("*.txt"):
            try:
                text = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            pages.update(extract_pages_from_text(text))

    ordered = [pages[pid] for pid in PAGE_IDS if pid in pages]
    missing = [pid for pid in PAGE_IDS if pid not in pages]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(ordered, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Collected {len(ordered)} / {len(PAGE_IDS)} pages -> {OUT}")
    if missing:
        print("Missing page IDs (re-fetch via MCP):", ", ".join(missing))


if __name__ == "__main__":
    main()
