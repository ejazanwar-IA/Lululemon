#!/usr/bin/env python3
"""Streaming EDA for selected Lululemon GCS CSV feeds.

Reads GCS CSV shards row-by-row through `gcloud storage cat`, keeping only
aggregate counters and approximate distinct sketches in memory.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import heapq
import json
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path
from typing import Iterable

PROJECT_ID = "lululemon-01042025"
HASH_SPACE = float(1 << 64)

FEEDS = {
    "purchase_orders": {
        "prefix": "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/purchase_orders/",
        "keys": [
            "PURCHASE_ORDER_ID",
            "SKU_ID",
            "LOCATION_ID_RECEIVING",
        ],
        "distinct": [
            ("purchase_orders", ["PURCHASE_ORDER_ID"]),
            ("skus", ["SKU_ID"]),
            ("po_sku", ["PURCHASE_ORDER_ID", "SKU_ID"]),
            ("po_sku_location", ["PURCHASE_ORDER_ID", "SKU_ID", "LOCATION_ID_RECEIVING"]),
        ],
        "dates": ["DATE_CREATED", "DATE_SCHEDULED", "DATE_SHIPPED", "DATE_EXPECTED_DELIVERY", "DATE_RECEIVED"],
        "categories": ["PO_LINE_STATUS", "TYPE_NAME"],
        "numeric": ["UNITS_ORDERED", "UNITS_SHIPPED", "UNITS_RECEIVED", "UNITS_ALLOCATED", "UNITS_AVAILABLE"],
        "future_dates": ["DATE_CREATED", "DATE_EXPECTED_DELIVERY"],
    },
    "product_attribute_s_seasonal": {
        "prefix": "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_s_seasonal/",
        "keys": ["STYLE_ID", "QUARTER_ID"],
        "distinct": [
            ("styles", ["STYLE_ID"]),
            ("quarters", ["QUARTER_ID"]),
            ("style_quarter", ["STYLE_ID", "QUARTER_ID"]),
        ],
        "dates": ["QUARTER_ID"],
        "categories": [
            "FLEX_SEASON_CODE",
            "FLEX_STATUS",
            "SEASONAL_STYLE_TYPE",
            "GLOBAL_PRODUCT_SEASONAL_NEWNESS_STYLE",
            "PRODUCT_SEASONAL_NEWNESS_STYLE_CATEGORY",
        ],
        "numeric": [],
    },
    "product_attribute_so_seasonal": {
        "prefix": "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_so_seasonal/",
        "keys": ["STYLE_OPTION_ID", "QUARTER_ID"],
        "distinct": [
            ("style_options", ["STYLE_OPTION_ID"]),
            ("quarters", ["QUARTER_ID"]),
            ("style_option_quarter", ["STYLE_OPTION_ID", "QUARTER_ID"]),
        ],
        "dates": ["QUARTER_ID"],
        "categories": [
            "FLEX_SEASON_CODE",
            "FLEX_STATUS",
            "GLOBAL_PRODUCT_SEASONAL_NEWNESS_STYLE_OPTION",
            "PRODUCT_SEASONAL_NEWNESS",
            "SEASONAL_COLOURWAY_TYPE",
        ],
        "numeric": [],
    },
    "eligibility": {
        "prefix": "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/eligibility/",
        "keys": ["PLANNING_STYLE_OPTION_ID", "STORE_ID", "WEEK_ID"],
        "distinct": [
            ("planning_style_options", ["PLANNING_STYLE_OPTION_ID"]),
            ("stores", ["STORE_ID"]),
            ("weeks", ["WEEK_ID"]),
            ("pso_store", ["PLANNING_STYLE_OPTION_ID", "STORE_ID"]),
            ("pso_store_week", ["PLANNING_STYLE_OPTION_ID", "STORE_ID", "WEEK_ID"]),
        ],
        "dates": ["WEEK_ID", "WP_FIRST_SELLING_WEEK_ID", "WP_FIRST_SELLING_DAY_ID"],
        "categories": ["QUARTER_NAME", "WP_WEEKS_AT_REG_PRICE"],
        "numeric": ["WP_WEEKS_AT_REG_PRICE"],
        "future_dates": ["WP_FIRST_SELLING_DAY_ID"],
    },
    "style_option": {
        "prefix": "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/style_option/",
        "keys": ["STYLE_OPTION_ID", "STYLE_ID", "COLOURWAY_ID", "PLANNING_STYLE_OPTION_ID"],
        "distinct": [
            ("style_options", ["STYLE_OPTION_ID"]),
            ("styles", ["STYLE_ID"]),
            ("colourways", ["COLOURWAY_ID"]),
            ("planning_style_options", ["PLANNING_STYLE_OPTION_ID"]),
            ("pso_style_option", ["PLANNING_STYLE_OPTION_ID", "STYLE_OPTION_ID"]),
        ],
        "dates": [],
        "categories": ["IS_PRIMARY_STYLE_OPTION", "DELETE_IND", "PLACEHOLDER_FLAG"],
        "numeric": [],
    },
}


class ApproxDistinct:
    """KMV approximate distinct counter using the k smallest 64-bit hashes."""

    def __init__(self, k: int = 4096) -> None:
        self.k = k
        self.heap: list[int] = []
        self.hashes: set[int] = set()

    @staticmethod
    def _hash(value: str) -> int:
        return int.from_bytes(hashlib.blake2b(value.encode("utf-8", "replace"), digest_size=8).digest(), "big")

    def add(self, value: str) -> None:
        if not value:
            return
        h = self._hash(value)
        if h in self.hashes:
            return
        if len(self.heap) < self.k:
            heapq.heappush(self.heap, -h)
            self.hashes.add(h)
            return
        current_largest = -self.heap[0]
        if h < current_largest:
            removed = -heapq.heapreplace(self.heap, -h)
            self.hashes.discard(removed)
            self.hashes.add(h)

    def estimate(self) -> int:
        if len(self.heap) < self.k:
            return len(self.heap)
        kth = -self.heap[0]
        if kth == 0:
            return len(self.heap)
        return round((self.k - 1) * HASH_SPACE / kth)


def run_gcloud(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def list_gcs_csvs(prefix: str) -> list[str]:
    proc = run_gcloud(["gcloud", "storage", "ls", prefix, "--project", PROJECT_ID])
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip())
    return sorted(line.strip() for line in proc.stdout.splitlines() if line.strip().endswith(".csv"))


def open_gcs_csv(uri: str) -> subprocess.Popen[str]:
    proc = subprocess.Popen(
        ["gcloud", "storage", "cat", uri, "--project", PROJECT_ID],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if proc.stdout is None:
        raise RuntimeError(f"No stdout while opening {uri}")
    return proc


def clean_value(value: object) -> str:
    if value is None:
        return ""
    value_s = str(value).strip()
    if value_s in {"", r"\N", "NULL", "null"}:
        return ""
    return value_s


def join_key(row: dict[str, str], cols: Iterable[str]) -> str:
    return "\x1f".join(clean_value(row.get(c)) for c in cols)


def pct(part: int | float, total: int | float) -> float:
    return round((100.0 * part / total), 4) if total else 0.0


def scan_feed(feed: str, limit_files: int | None = None) -> dict:
    cfg = FEEDS[feed]
    uris = list_gcs_csvs(cfg["prefix"])
    if limit_files:
        uris = uris[:limit_files]

    rows = 0
    columns: list[str] = []
    nulls: Counter[str] = Counter()
    nonnulls: Counter[str] = Counter()
    minmax: dict[str, list[str | None]] = {c: [None, None] for c in cfg["dates"]}
    category_counts: dict[str, Counter[str]] = {c: Counter() for c in cfg["categories"]}
    numeric = {c: {"positive": 0, "zero": 0, "negative": 0, "invalid": 0, "min": None, "max": None, "sum": 0.0} for c in cfg["numeric"]}
    distinct = {name: ApproxDistinct() for name, _ in cfg["distinct"]}
    future_counts: Counter[str] = Counter()
    samples: list[dict[str, str]] = []
    today = date.today().isoformat()

    for uri in uris:
        proc = open_gcs_csv(uri)
        reader = csv.DictReader(proc.stdout)
        if reader.fieldnames and not columns:
            columns = reader.fieldnames

        for row in reader:
            rows += 1
            if len(samples) < 3:
                sample_cols = cfg["keys"] + cfg["dates"] + cfg["categories"] + cfg["numeric"]
                samples.append({c: clean_value(row.get(c)) for c in sample_cols if c in row})

            for col in columns:
                if clean_value(row.get(col)):
                    nonnulls[col] += 1
                else:
                    nulls[col] += 1

            for col in cfg["dates"]:
                value = clean_value(row.get(col))
                if value:
                    if minmax[col][0] is None or value < minmax[col][0]:
                        minmax[col][0] = value
                    if minmax[col][1] is None or value > minmax[col][1]:
                        minmax[col][1] = value
                    if col in cfg.get("future_dates", []) and value > today:
                        future_counts[col] += 1

            for col in cfg["categories"]:
                value = clean_value(row.get(col)) or "<missing>"
                category_counts[col][value] += 1

            for col, stats in numeric.items():
                value = clean_value(row.get(col))
                if not value:
                    stats["invalid"] += 1
                    continue
                try:
                    value_f = float(value)
                except ValueError:
                    stats["invalid"] += 1
                    continue
                stats["sum"] += value_f
                stats["min"] = value_f if stats["min"] is None else min(stats["min"], value_f)
                stats["max"] = value_f if stats["max"] is None else max(stats["max"], value_f)
                if value_f > 0:
                    stats["positive"] += 1
                elif value_f < 0:
                    stats["negative"] += 1
                else:
                    stats["zero"] += 1

            for name, cols in cfg["distinct"]:
                distinct[name].add(join_key(row, cols))

        stderr = proc.stderr.read() if proc.stderr else ""
        code = proc.wait()
        if code != 0:
            raise RuntimeError(f"gcloud storage cat failed for {uri}: {stderr.strip()}")

    distinct_estimates = {name: counter.estimate() for name, counter in distinct.items()}
    grain_name = cfg["distinct"][-1][0] if cfg["distinct"] else None
    grain_distinct = distinct_estimates.get(grain_name, rows) if grain_name else rows

    return {
        "feed": feed,
        "prefix": cfg["prefix"],
        "files_scanned": len(uris),
        "rows": rows,
        "columns": columns,
        "column_count": len(columns),
        "missing_columns_expected": [c for c in cfg["keys"] if c not in columns],
        "column_population": {
            c: {
                "nonnull": nonnulls[c],
                "missing": nulls[c],
                "nonnull_pct": pct(nonnulls[c], rows),
                "missing_pct": pct(nulls[c], rows),
            }
            for c in columns
        },
        "date_ranges": {c: {"min": vals[0], "max": vals[1]} for c, vals in minmax.items()},
        "future_counts": {c: {"rows": future_counts[c], "pct": pct(future_counts[c], rows)} for c in cfg.get("future_dates", [])},
        "top_values": {c: [{"value": v, "rows": n, "pct": pct(n, rows)} for v, n in counts.most_common(10)] for c, counts in category_counts.items()},
        "numeric": {
            c: {
                **stats,
                "positive_pct": pct(stats["positive"], rows),
                "zero_pct": pct(stats["zero"], rows),
                "negative_pct": pct(stats["negative"], rows),
                "invalid_pct": pct(stats["invalid"], rows),
                "avg": round(stats["sum"] / rows, 4) if rows else None,
            }
            for c, stats in numeric.items()
        },
        "distinct_estimates": distinct_estimates,
        "grain_check": {
            "grain_name": grain_name,
            "row_count": rows,
            "distinct_estimate": grain_distinct,
            "duplicate_rows_estimate": max(rows - grain_distinct, 0),
            "duplicate_pct_estimate": pct(max(rows - grain_distinct, 0), rows),
        },
        "sample_rows": samples,
        "notes": {
            "approx_distinct": "Distinct counts use KMV approximate distinct sketches for memory safety.",
        },
    }


def scan_style_overlap(limit_files: int | None = None) -> dict:
    style_metrics = scan_feed("style_option")
    style_uris = list_gcs_csvs(FEEDS["style_option"]["prefix"])
    style_pso: set[str] = set()
    style_option_by_pso: Counter[str] = Counter()
    colourway_by_pso: dict[str, set[str]] = defaultdict(set)

    for uri in style_uris:
        proc = open_gcs_csv(uri)
        reader = csv.DictReader(proc.stdout)
        for row in reader:
            pso = clean_value(row.get("PLANNING_STYLE_OPTION_ID"))
            if not pso:
                continue
            style_pso.add(pso)
            style_option_by_pso[pso] += 1
            colourway = clean_value(row.get("COLOURWAY_ID"))
            if colourway:
                colourway_by_pso[pso].add(colourway)
        stderr = proc.stderr.read() if proc.stderr else ""
        code = proc.wait()
        if code != 0:
            raise RuntimeError(f"gcloud storage cat failed for {uri}: {stderr.strip()}")

    eligibility_uris = list_gcs_csvs(FEEDS["eligibility"]["prefix"])
    if limit_files:
        eligibility_uris = eligibility_uris[:limit_files]

    rows = matched_rows = 0
    all_pso = ApproxDistinct()
    matched_pso = ApproxDistinct()
    sample_unmatched: list[str] = []

    for uri in eligibility_uris:
        proc = open_gcs_csv(uri)
        reader = csv.DictReader(proc.stdout)
        for row in reader:
            rows += 1
            pso = clean_value(row.get("PLANNING_STYLE_OPTION_ID"))
            all_pso.add(pso)
            if pso in style_pso:
                matched_rows += 1
                matched_pso.add(pso)
            elif pso and len(sample_unmatched) < 10:
                sample_unmatched.append(pso)
        stderr = proc.stderr.read() if proc.stderr else ""
        code = proc.wait()
        if code != 0:
            raise RuntimeError(f"gcloud storage cat failed for {uri}: {stderr.strip()}")

    multi_style_pso = sum(1 for n in style_option_by_pso.values() if n > 1)
    multi_colourway_pso = sum(1 for colours in colourway_by_pso.values() if len(colours) > 1)

    return {
        "analysis": "stylecolor_store_overlap",
        "style_option_metrics": style_metrics,
        "eligibility_files_scanned": len(eligibility_uris),
        "eligibility_rows_scanned": rows,
        "style_option_planning_style_options": len(style_pso),
        "eligibility_planning_style_options_estimate": all_pso.estimate(),
        "matched_eligibility_rows": matched_rows,
        "matched_eligibility_rows_pct": pct(matched_rows, rows),
        "matched_eligibility_planning_style_options_estimate": matched_pso.estimate(),
        "matched_pso_pct_estimate": pct(matched_pso.estimate(), all_pso.estimate()),
        "pso_with_multiple_style_options": multi_style_pso,
        "pso_with_multiple_style_options_pct": pct(multi_style_pso, len(style_pso)),
        "pso_with_multiple_colourways": multi_colourway_pso,
        "pso_with_multiple_colourways_pct": pct(multi_colourway_pso, len(style_pso)),
        "sample_unmatched_pso": sample_unmatched,
        "notes": {
            "coverage": "Eligibility source uses PLANNING_STYLE_OPTION_ID; style colour can be derived when that key maps through style_option.",
        },
    }


def write_json(data: dict, output: str | None) -> None:
    payload = json.dumps(data, indent=2, sort_keys=True)
    if output:
        Path(output).write_text(payload + "\n", encoding="utf-8")
    else:
        print(payload)


def main() -> int:
    parser = argparse.ArgumentParser(description="Stream EDA for Lululemon GCS CSV feeds")
    parser.add_argument("--feed", choices=sorted(FEEDS), help="Feed to scan")
    parser.add_argument("--style-overlap", action="store_true", help="Run style_option to eligibility overlap analysis")
    parser.add_argument("--limit-files", type=int, default=None, help="Optional first-N file limit for testing")
    parser.add_argument("--output", help="Write JSON metrics to this path")
    args = parser.parse_args()

    if args.style_overlap:
        data = scan_style_overlap(limit_files=args.limit_files)
    elif args.feed:
        data = scan_feed(args.feed, limit_files=args.limit_files)
    else:
        parser.error("Provide --feed or --style-overlap")

    write_json(data, args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
