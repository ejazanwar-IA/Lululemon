#!/usr/bin/env python3
"""Inventory Historic/s3_to_gcs date batches via gcloud storage ls -l (metadata only).

Parses feed names, embedded snapshot dates from filenames, path patterns, and
aggregates per (batch, feed). No full file downloads.

Examples:
  python3 scripts/historic_batch_inventory.py --all-batches
  python3 scripts/historic_batch_inventory.py --batch 2026-05-08
  python3 scripts/historic_batch_inventory.py --all-batches \\
    --out-csv findings/gcs_eda_2026/batch_inventory_detail.csv
"""
from __future__ import annotations

import argparse
import csv
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_PREFIX = "gs://client_data_lululemon/Historic/s3_to_gcs"
DEFAULT_PROJECT = "lululemon-01042025"
ALL_BATCHES = [
    "2025-08-28",
    "2025-09-18",
    "2025-10-06",
    "2025-10-08",
    "2025-11-18",
    "2025-12-03",
    "2025-12-05",
    "2026-05-08",
]

# feed_YYYYMMDD_HHMMSS_a_b_c.csv or TE2.0_EA_*.csv variants
SNAPSHOT_RE = re.compile(r"_(\d{8})_\d{6}_")
SNAPSHOT_RE_ALT = re.compile(r"_(\d{8})_\d+_\d+_\d+\.csv")
TE20_RE = re.compile(r"^(TE2\.0_EA_|TE20_EA_|Inventory_Parameters_)")
DATE_SUFFIX_FEED_RE = re.compile(
    r"^(eligibility|product_attribute_s|product_attribute_so|"
    r"product_attribute_s_seasonal|product_attribute_so_seasonal|"
    r"promotional_events|inseason_demand_forecast)(\d{8})$"
)


@dataclass
class FeedAgg:
    files: int = 0
    bytes: int = 0
    snapshot_dates: set[str] = field(default_factory=set)
    path_patterns: set[str] = field(default_factory=set)
    first_ts: str = ""
    last_ts: str = ""
    sample_uri: str = ""

    def add(self, uri: str, size: int, ts: str, snapshot: str | None, pattern: str) -> None:
        self.files += 1
        self.bytes += size
        if snapshot:
            self.snapshot_dates.add(snapshot)
        self.path_patterns.add(pattern)
        if not self.sample_uri:
            self.sample_uri = uri
        if not self.first_ts or ts < self.first_ts:
            self.first_ts = ts
        if not self.last_ts or ts > self.last_ts:
            self.last_ts = ts


def parse_ls_line(line: str) -> tuple[int, str, str] | None:
    line = line.strip()
    if not line or line.endswith(":"):
        return None
    parts = line.split()
    if len(parts) < 3:
        return None
    if not parts[0].isdigit():
        return None
    size = int(parts[0])
    ts = parts[1]
    uri = parts[-1]
    if uri.endswith("/"):
        return None
    return size, ts, uri


def extract_batch(uri: str, prefix: str) -> str | None:
    rest = uri.replace(prefix.rstrip("/") + "/", "")
    batch = rest.split("/")[0]
    if re.match(r"^\d{4}-\d{2}-\d{2}$", batch):
        return batch
    return None


def snapshot_from_filename(name: str) -> str | None:
    m = SNAPSHOT_RE.search(name)
    if m:
        return m.group(1)
    m = SNAPSHOT_RE_ALT.search(name)
    if m:
        return m.group(1)
    m = DATE_SUFFIX_FEED_RE.match(name.split("_")[0] if "_" not in name else "")
    return None


def logical_feed_from_path(uri: str, batch: str) -> tuple[str, str | None, str]:
    """Return (logical_feed, snapshot_date, path_pattern)."""
    parts = uri.split("/")
    try:
        idx = parts.index(batch)
        rel = parts[idx + 1 :]
    except ValueError:
        rel = parts

    name = parts[-1]
    snapshot = snapshot_from_filename(name)

    # Flat layout: batch/feed_*.csv
    if len(rel) == 1 and name.endswith(".csv"):
        m = re.match(
            r"^(eligibility|product_attribute_s|product_attribute_so|"
            r"product_attribute_s_seasonal|product_attribute_so_seasonal|"
            r"promotional_events|inseason_demand_forecast)(\d{8})_",
            name,
        )
        if m:
            return m.group(1) + m.group(2), m.group(2), "flat"
        if TE20_RE.match(name):
            base = name.rsplit(".", 1)[0]
            if "_pod_" in name:
                feed = base.split("_pod_")[0] + "_pod"
            elif "_pov_" in name:
                feed = base.split("_pov_")[0] + "_pov"
            else:
                feed = base
            return feed, snapshot, "flat"
        m = re.match(r"^([a-z_]+?)_\d{8}_", name)
        feed = m.group(1) if m else name.split(".")[0]
        return feed, snapshot, "flat"

    # Standard outbound layout
    if "outbound" in rel:
        ob_idx = rel.index("outbound")
        after = rel[ob_idx + 1 :]
        if not after:
            return "unknown", snapshot, "outbound"
        if after[0] == "anaplan":
            subfeed = after[1] if len(after) > 1 else "anaplan"
            fname = name.rsplit(".", 1)[0]
            if TE20_RE.match(name):
                if "_pod_" in name:
                    feed = fname.split("_pod_")[0] + "_pod"
                elif "_pov_" in name:
                    feed = fname.split("_pov_")[0] + "_pov"
                else:
                    feed = fname
            else:
                feed = fname
            pattern = f"outbound/anaplan/{subfeed}"
            if "pod_id=" in uri:
                pattern += "/pod_id=N"
            return feed, snapshot, pattern
        feed_folder = after[0]
        status = after[1] if len(after) > 1 else ""
        pattern = f"outbound/{feed_folder}/{status}".rstrip("/")
        # Date-suffixed folder names: eligibility20250818
        m = DATE_SUFFIX_FEED_RE.match(feed_folder)
        if m:
            return feed_folder, m.group(2), pattern
        if feed_folder in (
            "min_pres_eol",
            "delivery_week_logic",
        ) or name in ("min_pres_eol.csv", "delivery_week_logic.csv"):
            return feed_folder, None, pattern
        return feed_folder, snapshot, pattern

    return name, snapshot, "other"


def normalize_feed_key(feed: str, name: str) -> str:
    """Normalize date-suffixed feeds from filename when folder is generic."""
    m = re.match(
        r"^(eligibility|product_attribute_s|product_attribute_so|"
        r"product_attribute_s_seasonal|product_attribute_so_seasonal|"
        r"promotional_events|inseason_demand_forecast)(\d{8})",
        name,
    )
    if m:
        return m.group(1) + m.group(2)
    if name == "nohup.out":
        return "nohup.out"
    if TE20_RE.match(name):
        base = name.rsplit(".", 1)[0]
        if "_pod_" in name:
            return base.split("_pod_")[0] + "_pod"
        if "_pov_" in name:
            return base.split("_pov_")[0] + "_pov"
        return base
    return feed


def list_batch(prefix: str, batch: str, project: str) -> list[tuple[int, str, str]]:
    uri_prefix = f"{prefix.rstrip('/')}/{batch}/"
    cmd = ["gcloud", "storage", "ls", "-l", f"{uri_prefix}**", f"--project={project}"]
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        print(f"WARN: listing failed for {batch}: {e.output[:500]}", file=sys.stderr)
        return []
    rows = []
    for line in out.splitlines():
        parsed = parse_ls_line(line)
        if parsed:
            rows.append(parsed)
    return rows


def aggregate_batch(
    prefix: str, batch: str, project: str
) -> dict[str, FeedAgg]:
    objects = list_batch(prefix, batch, project)
    feeds: dict[str, FeedAgg] = defaultdict(FeedAgg)
    for size, ts, uri in objects:
        name = uri.split("/")[-1]
        feed_raw, snapshot, pattern = logical_feed_from_path(uri, batch)
        feed = normalize_feed_key(feed_raw, name)
        feeds[feed].add(uri, size, ts, snapshot, pattern)
    return dict(feeds)


def rows_to_csv_rows(
    prefix: str, batches: list[str], project: str
) -> list[dict]:
    out: list[dict] = []
    for batch in batches:
        feeds = aggregate_batch(prefix, batch, project)
        for feed, agg in sorted(feeds.items()):
            snaps = sorted(agg.snapshot_dates)
            snap_str = "|".join(snaps) if snaps else ""
            patterns = "|".join(sorted(agg.path_patterns))
            out.append(
                {
                    "batch": batch,
                    "feed": feed,
                    "files": agg.files,
                    "size_GB": round(agg.bytes / 1e9, 3),
                    "snapshot_dates": snap_str,
                    "path_pattern": patterns,
                    "first_ts": agg.first_ts[:10] if agg.first_ts else "",
                    "last_ts": agg.last_ts[:10] if agg.last_ts else "",
                    "sample_uri": agg.sample_uri,
                }
            )
    return out


def catalog_rows(detail_rows: list[dict]) -> list[dict]:
    """Same shape as catalog_historic.csv."""
    return [
        {
            "batch": r["batch"],
            "feed": r["feed"],
            "files": r["files"],
            "size_GB": r["size_GB"],
            "first_ts": r["first_ts"],
            "last_ts": r["last_ts"],
            "sample_uri": r["sample_uri"],
        }
        for r in detail_rows
    ]


def print_summary(detail_rows: list[dict]) -> None:
    by_batch: dict[str, list[dict]] = defaultdict(list)
    for r in detail_rows:
        by_batch[r["batch"]].append(r)
    for batch in sorted(by_batch):
        rows = by_batch[batch]
        total_files = sum(r["files"] for r in rows)
        total_gb = sum(r["size_GB"] for r in rows)
        feeds = len(rows)
        print(f"\n{batch}: {feeds} feeds, {total_files} files, {total_gb:.2f} GB")
        for r in sorted(rows, key=lambda x: -x["size_GB"])[:8]:
            print(
                f"  {r['feed']}: {r['files']} files, {r['size_GB']:.2f} GB"
                f" snapshots={r['snapshot_dates'] or 'n/a'}"
            )
        if len(rows) > 8:
            print(f"  ... +{len(rows) - 8} more feeds")


def build_feed_matrix(detail_rows: list[dict], batches: list[str]) -> list[dict]:
    feeds = sorted({r["feed"] for r in detail_rows})
    by_bf: dict[tuple[str, str], dict] = {
        (r["batch"], r["feed"]): r for r in detail_rows
    }
    matrix: list[dict] = []
    for feed in feeds:
        row: dict = {"feed": feed}
        for batch in batches:
            r = by_bf.get((batch, feed))
            if r:
                snap = r["snapshot_dates"] or "n/a"
                row[batch] = f"{r['files']}f/{r['size_GB']:.1f}GB snap={snap}"
            else:
                row[batch] = ""
        matrix.append(row)
    return matrix


def write_csv(path: Path, rows: list[dict], fieldnames: list[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        return
    fn = fieldnames or list(rows[0].keys())
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fn, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description="Historic s3_to_gcs batch inventory")
    parser.add_argument("--prefix", default=DEFAULT_PREFIX)
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    parser.add_argument("--batch", action="append", help="Single batch (repeatable)")
    parser.add_argument("--all-batches", action="store_true")
    parser.add_argument(
        "--out-csv",
        type=Path,
        default=Path("findings/gcs_eda_2026/batch_inventory_detail.csv"),
    )
    parser.add_argument(
        "--catalog-csv",
        type=Path,
        default=Path("findings/gcs_eda_2026/catalog_historic.csv"),
    )
    parser.add_argument(
        "--matrix-csv",
        type=Path,
        default=Path("findings/gcs_eda_2026/batch_feed_matrix.csv"),
    )
    parser.add_argument("--no-matrix", action="store_true")
    args = parser.parse_args()

    if args.all_batches:
        batches = ALL_BATCHES
    elif args.batch:
        batches = args.batch
    else:
        batches = ALL_BATCHES

    detail = rows_to_csv_rows(args.prefix, batches, args.project)
    write_csv(args.out_csv, detail)
    write_csv(args.catalog_csv, catalog_rows(detail))

    if not args.no_matrix:
        matrix = build_feed_matrix(detail, ALL_BATCHES if args.all_batches else batches)
        if matrix:
            fn = ["feed"] + (ALL_BATCHES if args.all_batches else batches)
            write_csv(args.matrix_csv, matrix, fieldnames=fn)

    print_summary(detail)
    print(f"\nWrote {args.out_csv} ({len(detail)} rows)")
    print(f"Wrote {args.catalog_csv}")
    if not args.no_matrix:
        print(f"Wrote {args.matrix_csv}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
