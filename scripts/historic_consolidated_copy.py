#!/usr/bin/env python3
"""Copy feeds into Historic/s3_to_gcs/consolidated/ per manifest (cp only, no mv/rm)."""
from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from pathlib import Path

DEFAULT_PROJECT = "lululemon-01042025"
DATE_BATCHES = [
    "2025-08-28",
    "2025-09-18",
    "2025-10-06",
    "2025-10-08",
    "2025-11-18",
    "2025-12-03",
    "2025-12-05",
    "2026-05-08",
]


def load_manifest(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def batch_totals(prefix: str, project: str) -> dict[str, tuple[int, int]]:
    """Return batch -> (file_count, total_bytes) for date folders only."""
    import re

    totals: dict[str, tuple[int, int]] = {}
    for batch in DATE_BATCHES:
        cmd = [
            "gcloud",
            "storage",
            "ls",
            "-l",
            f"{prefix}/{batch}/**",
            f"--project={project}",
        ]
        try:
            out = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError:
            totals[batch] = (0, 0)
            continue
        n, b = 0, 0
        for line in out.splitlines():
            line = line.strip()
            if not line or line.endswith(":"):
                continue
            parts = line.split()
            if len(parts) >= 3 and parts[0].isdigit():
                n += 1
                b += int(parts[0])
        totals[batch] = (n, b)
    return totals


def run_copy(row: dict, project: str, dry_run: bool) -> int:
    glob = row["source_glob"]
    dest = row["dest_prefix"]
    cmd = ["gcloud", "storage", "cp", "-r", glob, dest, f"--project={project}"]
    print(f"\n=== {row['feed']} ({row['size_GB']} GB, {row['file_count']} files) ===")
    print(" ".join(cmd))
    if dry_run:
        return 0
    proc = subprocess.run(cmd, text=True)
    return proc.returncode


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("findings/gcs_eda_2026/consolidated_manifest.csv"),
    )
    parser.add_argument("--feed", action="append", help="Copy only these feed(s)")
    parser.add_argument("--skip-feed", action="append", default=[])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    parser.add_argument(
        "--prefix",
        default="gs://client_data_lululemon/Historic/s3_to_gcs",
    )
    parser.add_argument(
        "--verify-batches",
        action="store_true",
        help="Compare date-batch totals before vs after (post must match pre)",
    )
    parser.add_argument(
        "--pre-totals",
        type=Path,
        help="JSON-ish csv pre snapshot for --verify-batches",
    )
    args = parser.parse_args()

    rows = load_manifest(args.manifest)
    if args.feed:
        allow = set(args.feed)
        rows = [r for r in rows if r["feed"] in allow]
    if args.skip_feed:
        skip = set(args.skip_feed)
        rows = [r for r in rows if r["feed"] not in skip]

    # smallest first
    rows.sort(key=lambda r: float(r["size_GB"]))

    pre = None
    if args.verify_batches and not args.dry_run:
        pre = batch_totals(args.prefix, args.project)
        if args.pre_totals:
            args.pre_totals.parent.mkdir(parents=True, exist_ok=True)
            with args.pre_totals.open("w", newline="") as f:
                w = csv.writer(f)
                w.writerow(["batch", "files", "bytes"])
                for b, (n, by) in sorted(pre.items()):
                    w.writerow([b, n, by])

    failed = []
    for row in rows:
        rc = run_copy(row, args.project, args.dry_run)
        if rc != 0:
            failed.append(row["feed"])

    if pre is not None:
        post = batch_totals(args.prefix, args.project)
        ok = True
        for b in DATE_BATCHES:
            if pre[b] != post[b]:
                ok = False
                print(
                    f"BATCH INTEGRITY FAIL {b}: pre={pre[b]} post={post[b]}",
                    file=sys.stderr,
                )
        if ok:
            print("\nDate batch integrity OK (unchanged file counts/bytes).")
        else:
            return 2

    if failed:
        print(f"FAILED feeds: {failed}", file=sys.stderr)
        return 1
    print(f"\nDone: {len(rows)} feed(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
