#!/usr/bin/env python3
"""Stream-scan sku_details CSV(s) for COST_PRICE / SELLING_PRICE coverage.

Designed for huge files: reads row-by-row, never loads full file into memory.
Use one representative shard per batch timestamp before scanning all shards.

Examples:
  # Local file (your Downloads path)
  python3 scripts/sku_details_price_scan.py \\
    --local "/Users/you/Downloads/sku_details_20250807_125510_0_0_0.csv"

  # One GCS object (streams via gcloud storage cat)
  python3 scripts/sku_details_price_scan.py \\
    --gcs gs://client_data_lululemon/Historic/.../sku_details_20250807_125510_0_0_0.csv

  # Gate check: first shard per batch under a prefix (lists via gcloud)
  python3 scripts/sku_details_price_scan.py \\
    --gcs-prefix gs://client_data_lululemon/Historic/s3_to_gcs/2025-08-28/outbound/sku_details/new/ \\
    --one-per-batch
"""
from __future__ import annotations

import argparse
import csv
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable, TextIO

BATCH_RE = re.compile(r"sku_details_(\d{8})_\d+")


def open_csv_source(local: str | None, gcs: str | None) -> tuple[TextIO, str]:
    if local:
        p = Path(local)
        return p.open(newline="", encoding="utf-8", errors="replace"), str(p)
    if gcs:
        proc = subprocess.Popen(
            ["gcloud", "storage", "cat", gcs],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        assert proc.stdout is not None
        return proc.stdout, gcs
    raise ValueError("Need --local or --gcs")


def scan_stream(f: Iterable[dict], label: str) -> dict:
    n = cost_pos = sell_pos = 0
    seasons: Counter[str] = Counter()
    currencies: Counter[str] = Counter()
    for row in f:
        n += 1
        cp = (row.get("COST_PRICE") or "").strip()
        sp = (row.get("SELLING_PRICE") or "").strip()
        seasons[(row.get("SEASON_CODE") or "").strip()] += 1
        currencies[(row.get("PRICE_CURRENCY") or "").strip()] += 1
        try:
            if float(cp) > 0:
                cost_pos += 1
            if float(sp) > 0:
                sell_pos += 1
        except ValueError:
            pass
    pct = (100.0 * cost_pos / n) if n else 0.0
    return {
        "label": label,
        "rows": n,
        "cost_pos": cost_pos,
        "sell_pos": sell_pos,
        "pct_cost_pos": round(pct, 2),
        "top_season": seasons.most_common(1),
        "top_currency": currencies.most_common(1),
    }


def list_gcs_shards(prefix: str) -> list[str]:
    prefix = prefix.rstrip("/") + "/"
    out = subprocess.check_output(
        ["gcloud", "storage", "ls", f"{prefix}sku_details_*.csv"],
        text=True,
    )
    return [ln.strip() for ln in out.splitlines() if ln.strip()]


def one_per_batch(uris: list[str]) -> list[str]:
    seen: set[str] = set()
    picks: list[str] = []
    for uri in sorted(uris):
        m = BATCH_RE.search(uri)
        if not m:
            continue
        batch = m.group(1)
        if batch in seen:
            continue
        seen.add(batch)
        picks.append(uri)
    return picks


def main() -> int:
    parser = argparse.ArgumentParser(description="Stream-scan sku_details CSV pricing")
    parser.add_argument("--local", help="Local CSV path")
    parser.add_argument("--gcs", help="Single gs:// object URI")
    parser.add_argument(
        "--gcs-prefix",
        help="GCS folder prefix; use with --one-per-batch to gate by drop timestamp",
    )
    parser.add_argument(
        "--one-per-batch",
        action="store_true",
        help="Scan only the lexicographically first shard per sku_details_YYYYMMDD batch",
    )
    args = parser.parse_args()

    targets: list[tuple[str | None, str | None, str]] = []
    if args.local:
        targets.append((args.local, None, Path(args.local).name))
    elif args.gcs:
        targets.append((None, args.gcs, args.gcs.split("/")[-1]))
    elif args.gcs_prefix:
        uris = list_gcs_shards(args.gcs_prefix)
        if args.one_per_batch:
            uris = one_per_batch(uris)
        for uri in uris:
            targets.append((None, uri, uri.split("/")[-1]))
    else:
        parser.error("Provide --local, --gcs, or --gcs-prefix")

    print(f"{'file':<55} {'rows':>12} {'cost>0':>12} {'pct':>8}  season")
    print("-" * 95)
    for local, gcs, label in targets:
        fh, src = open_csv_source(local, gcs)
        try:
            reader = csv.DictReader(fh)
            stats = scan_stream(reader, label)
        finally:
            if hasattr(fh, "close"):
                fh.close()
        season = stats["top_season"][0][0] if stats["top_season"] else "?"
        print(
            f"{stats['label']:<55} {stats['rows']:>12,} {stats['cost_pos']:>12,} "
            f"{stats['pct_cost_pos']:>7.2f}%  {season}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
