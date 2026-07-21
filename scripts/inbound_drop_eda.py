#!/usr/bin/env python3
"""
Inbound Drop Agent — Phase 1 runner.
Profiles a BQ table from view_profiles.yaml and writes a Data Drop Brief.

Usage:
  python3 scripts/inbound_drop_eda.py --view inventory_snapshot --write-brief
  python3 scripts/inbound_drop_eda.py --view inventory_snapshot \\
    --gcs-path 'gs://bucket/2026-05-28/inventory_snapshot_20260528143000.csv' --write-brief
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.inbound_drop_lib import PROFILES_PATH, load_yaml, run_profile  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description="Inbound Drop Agent — Phase 1")
    parser.add_argument("--view", required=True, help="Key in view_profiles.yaml")
    parser.add_argument("--gcs-path", default=None, help="Full gs:// or local path to landed file")
    parser.add_argument(
        "--sample-date",
        default=None,
        help="DATE filter for sample checks (default: profile join_checks sample_date)",
    )
    parser.add_argument("--write-brief", action="store_true", help="Write brief markdown")
    parser.add_argument("--dry-run", action="store_true", help="Print profile JSON only, no bq")
    args = parser.parse_args()

    if args.dry_run:
        config = load_yaml(PROFILES_PATH)
        from lib.inbound_drop_lib import load_profile

        profile = load_profile(config, args.view)
        print(json.dumps(profile, indent=2))
        return 0

    profile = args.view
    p = run_profile(
        view_key=args.view,
        gcs_path=args.gcs_path,
        sample_date=args.sample_date,
        write_brief=args.write_brief,
        dry_run=False,
        trigger_mode="manual",
    )

    ds = p.profile.get("bq_dataset_resolved") or p.profile["bq_dataset"]
    print(f"Profiling {p.profile['gcp_project']}.{ds}.{p.profile['bq_table']} ...")
    if not p.meta.get("exists"):
        print("WARNING: table not found in __TABLES__", file=sys.stderr)

    print(f"Verdict: {p.verdict} — {p.verdict_line}")
    if p.brief_path:
        print(f"Wrote {p.brief_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
