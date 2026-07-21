#!/usr/bin/env python3
"""Flatten multiline DESCRIPTION fields in promotional_events CSV shards for BQ load."""

from __future__ import annotations

import argparse
import csv
import io
import re
import subprocess
import sys
from pathlib import Path

EXPECTED_HEADER = [
    "LOC_ID",
    "TYPE",
    "NAME",
    "START_DATE",
    "END_DATE",
    "DESCRIPTION",
    "LOCATION_CLOSED_FLAG",
]
DESC_IDX = 5
MULTILINE_RE = re.compile(r"[\r\n]+")


def download_gcs(uri: str, project: str) -> str:
    proc = subprocess.run(
        ["gcloud", "storage", "cat", uri, f"--project={project}"],
        capture_output=True,
        text=True,
        errors="replace",
        check=True,
    )
    return proc.stdout


def upload_gcs(local_path: Path, uri: str, project: str) -> None:
    subprocess.run(
        ["gcloud", "storage", "cp", str(local_path), uri, f"--project={project}"],
        check=True,
    )


def flatten_shard(text: str, replacement: str = " ") -> tuple[str, list[dict[str, str]]]:
    reader = csv.reader(io.StringIO(text))
    header = next(reader)
    if header != EXPECTED_HEADER:
        raise ValueError(f"Unexpected header: {header}")

    flattened_rows: list[dict[str, str]] = []
    out = io.StringIO()
    writer = csv.writer(out, lineterminator="\n")
    writer.writerow(header)

    logical_rows = 0
    for row in reader:
        if not row:
            continue
        if len(row) != len(EXPECTED_HEADER):
            raise ValueError(f"Bad column count {len(row)} at logical row {logical_rows + 1}")
        logical_rows += 1
        desc = row[DESC_IDX]
        if MULTILINE_RE.search(desc):
            new_desc = MULTILINE_RE.sub(replacement, desc).strip()
            flattened_rows.append(
                {
                    "loc_id": row[0],
                    "type": row[1],
                    "name": row[2],
                    "start_date": row[3],
                    "end_date": row[4],
                    "old_description": desc,
                    "new_description": new_desc,
                }
            )
            row[DESC_IDX] = new_desc
        writer.writerow(row)

    body = out.getvalue()
    physical_lines = len(body.splitlines()) - 1
    if physical_lines != logical_rows:
        raise ValueError(
            f"Sanitized file still has multiline rows: physical={physical_lines}, logical={logical_rows}"
        )
    return body, flattened_rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default="lululemon-01042025")
    parser.add_argument(
        "--gcs-folder",
        default="gs://client_data_lululemon/2026-06-25",
        help="Dated GCS folder containing promotional_events shards",
    )
    parser.add_argument(
        "--shards",
        nargs="+",
        default=[
            "promotional_events20251118_153621_0_1_0.csv",
            "promotional_events20251118_153621_1_1_0.csv",
        ],
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("findings/promotional_events_clean_20260630"),
    )
    parser.add_argument("--upload", action="store_true", help="Upload cleaned shards back to GCS")
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    audit_path = args.out_dir / "flatten_audit.md"
    audit_lines = [
        "# promotional_events DESCRIPTION flatten audit",
        "",
        f"GCS folder: `{args.gcs_folder}`",
        "",
    ]
    total_flattened = 0

    for shard in args.shards:
        uri = f"{args.gcs_folder.rstrip('/')}/{shard}"
        print(f"Processing {uri} ...", file=sys.stderr)
        raw = download_gcs(uri, args.project)
        cleaned, flattened = flatten_shard(raw)
        out_path = args.out_dir / shard
        out_path.write_text(cleaned, encoding="utf-8", newline="\n")

        logical_rows = sum(1 for _ in csv.reader(io.StringIO(cleaned))) - 1
        audit_lines.append(f"## {shard}")
        audit_lines.append("")
        audit_lines.append(f"- URI: `{uri}`")
        audit_lines.append(f"- Logical rows: {logical_rows:,}")
        audit_lines.append(f"- Flattened rows: {len(flattened)}")
        audit_lines.append("")
        for i, item in enumerate(flattened, start=1):
            audit_lines.append(
                f"{i}. LOC_ID={item['loc_id']} TYPE={item['type']} "
                f"{item['start_date']}..{item['end_date']}"
            )
            audit_lines.append(f"   - before: {repr(item['old_description'][:160])}")
            audit_lines.append(f"   - after:  {item['new_description'][:200]}")
            audit_lines.append("")
        total_flattened += len(flattened)

        if args.upload:
            print(f"Uploading {out_path} -> {uri}", file=sys.stderr)
            upload_gcs(out_path, uri, args.project)

    audit_lines.insert(4, f"Total flattened rows: **{total_flattened}**")
    audit_lines.insert(5, "")
    audit_path.write_text("\n".join(audit_lines), encoding="utf-8")
    print(f"Wrote {audit_path}")
    print(f"Flattened {total_flattened} row(s) across {len(args.shards)} shard(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
