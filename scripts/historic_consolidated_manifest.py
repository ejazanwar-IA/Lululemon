#!/usr/bin/env python3
"""Build consolidated/ copy manifest from feed rules + batch inventory detail."""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

DEFAULT_PREFIX = "gs://client_data_lululemon/Historic/s3_to_gcs"
DEFAULT_CONSOLIDATED = f"{DEFAULT_PREFIX}/consolidated"
DEFAULT_PROJECT = "lululemon-01042025"


def load_csv(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def inventory_key(batch: str, source_feed: str) -> tuple[str, str]:
    return batch, source_feed


def source_prefix_from_row(row: dict, batch: str, source_feed: str, prefix: str) -> str:
    sample = row["sample_uri"]
    pattern = row["path_pattern"]
    if pattern == "flat":
        return f"{prefix}/{batch}/"
    if "anaplan" in sample:
        parts = sample.split("/outbound/anaplan/", 1)[1]
        subfeed = parts.split("/", 1)[0]
        base = f"{prefix}/{batch}/outbound/anaplan/{subfeed}/"
        if source_feed == "TE2.0_EA_Demand_Forecast_pod":
            return base  # copy new/ only; copy script filters temp
        return base
    # standard outbound feed folder (new or processed)
    parts = sample.split(f"/{batch}/outbound/", 1)[1]
    feed_path = parts.split("/", 1)[0]  # e.g. sales_transactions
    status_dirs = row["path_pattern"].split("|")
    if len(status_dirs) == 1 and "processed" in status_dirs[0]:
        return f"{prefix}/{batch}/outbound/{feed_path}/processed/"
    if "processed" in row["path_pattern"] and "new" not in row["path_pattern"].split("|")[0]:
        pass
    # prefer new/; transfer_orders Aug had both - canonical Nov uses new only
    return f"{prefix}/{batch}/outbound/{feed_path}/new/"


def dest_prefix(consolidated: str, dest_folder: str, layout: str) -> str:
    if layout == "anaplan":
        return f"{consolidated}/{dest_folder}/"
    return f"{consolidated}/{dest_folder}/"


def copy_glob(source_prefix: str, layout: str, source_feed: str) -> tuple[str, str]:
    """Return (source_arg, dest_arg) preserving anaplan pod_id paths."""
    if layout == "anaplan":
        # Copy the whole new/ subtree so pod_id=N/ survives
        src = f"{source_prefix}new"
        return src, "tree"
    if source_feed.startswith("eligibility") or "product_attribute" in source_feed or "promotional" in source_feed or "inseason" in source_feed:
        return f"{source_prefix}{source_feed}_*", "flat"
    if source_feed in ("delivery_week_logic", "min_pres_eol"):
        return f"{source_prefix}*", "flat"
    return f"{source_prefix}*", "flat"


def build_manifest(
    rules: list[dict],
    inventory: list[dict],
    prefix: str,
    consolidated: str,
) -> list[dict]:
    inv_map = {(r["batch"], r["feed"]): r for r in inventory}
    out: list[dict] = []
    for rule in rules:
        feed = rule["feed"]
        batch = rule["source_batch"]
        source_feed = rule["source_feed"]
        key = inventory_key(batch, source_feed)
        row = inv_map.get(key)
        if not row:
            print(f"WARN: no inventory for {key}", file=sys.stderr)
            continue
        file_count = int(row["files"])
        size_gb = float(row["size_GB"])
        if source_feed == "TE2.0_EA_Demand_Forecast_pod":
            pov = inv_map.get((batch, "TE2.0_EA_Demand_Forecast_pov"))
            if pov:
                file_count += int(pov["files"])
                size_gb += float(pov["size_GB"])
        src = source_prefix_from_row(row, batch, source_feed, prefix)
        dst = dest_prefix(consolidated, rule["dest_folder"], rule["layout"])
        src_arg, _mode = copy_glob(src, rule["layout"], source_feed)
        out.append(
            {
                "feed": feed,
                "dest_folder": rule["dest_folder"],
                "source_batch": batch,
                "source_feed": source_feed,
                "layout": rule["layout"],
                "source_glob": src_arg,
                "dest_prefix": dst,
                "file_count": file_count,
                "size_GB": round(size_gb, 3),
                "snapshot_dates": row.get("snapshot_dates", ""),
                "notes": rule.get("notes", ""),
                "copy_command": (
                    f'gcloud storage cp -r "{src_arg}" "{dst}" --project={DEFAULT_PROJECT}'
                ),
            }
        )
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--rules",
        type=Path,
        default=Path("findings/gcs_eda_2026/consolidated_feed_rules.csv"),
    )
    parser.add_argument(
        "--inventory",
        type=Path,
        default=Path("findings/gcs_eda_2026/batch_inventory_detail.csv"),
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("findings/gcs_eda_2026/consolidated_manifest.csv"),
    )
    parser.add_argument("--prefix", default=DEFAULT_PREFIX)
    parser.add_argument("--consolidated", default=DEFAULT_CONSOLIDATED)
    args = parser.parse_args()

    rules = load_csv(args.rules)
    inventory = load_csv(args.inventory)
    manifest = build_manifest(rules, inventory, args.prefix, args.consolidated)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    if not manifest:
        print("ERROR: empty manifest", file=sys.stderr)
        return 1
    fn = list(manifest[0].keys())
    with args.out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fn)
        w.writeheader()
        w.writerows(manifest)
    total_gb = sum(float(r["size_GB"]) for r in manifest)
    total_files = sum(int(r["file_count"]) for r in manifest)
    print(f"Wrote {args.out}: {len(manifest)} feeds, {total_files} files, {total_gb:.2f} GB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
