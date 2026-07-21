#!/usr/bin/env python3
"""
Drop Watcher — detect new client landings since last_seen and run Inbound Drop EDA.

Usage:
  python3 scripts/drop_watch.py --once --source local
  python3 scripts/drop_watch.py --interval 3600 --source gcs
  python3 scripts/drop_watch.py --once --source local --skip-bq   # detection-only smoke test
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.inbound_drop_lib import (  # noqa: E402
    DROP_FILENAME_RE,
    PROFILES_PATH,
    load_yaml,
    match_view_key_from_basename,
    run_profile,
)

CONFIG_EXAMPLE = ROOT / "findings/inbound_drop_agent/watcher_config.example.yaml"
CONFIG_PATH = ROOT / "findings/inbound_drop_agent/watcher_config.yaml"
DEFAULT_STATE_PATH = ROOT / "findings/inbound_drop_agent/drop_watcher_state.json"

EPOCH = datetime(1970, 1, 1, tzinfo=timezone.utc)


def expand_path(p: str) -> Path:
    path = Path(p).expanduser()
    if not path.is_absolute():
        path = ROOT / path
    return path.resolve()


def load_watcher_config(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(
            f"Watcher config not found: {path}\n"
            f"Copy {CONFIG_EXAMPLE.relative_to(ROOT)} → {CONFIG_PATH.relative_to(ROOT)}"
        )
    return load_yaml(path)


def load_watcher_state(path: Path) -> dict:
    if not path.exists():
        return {"sources": {}}
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def save_watcher_state(state: dict, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, default=str)


def parse_iso_dt(s: str | None) -> datetime:
    if not s:
        return EPOCH
    s = s.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(s)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except ValueError:
        return EPOCH


def source_state(state: dict, source_id: str) -> dict:
    sources = state.setdefault("sources", {})
    if source_id not in sources:
        sources[source_id] = {"last_seen": EPOCH.isoformat(), "processed": []}
    return sources[source_id]


def list_local_drops(drops_dir: Path, since: datetime, views: dict) -> list[dict]:
    found: list[dict] = []
    if not drops_dir.is_dir():
        return found
    for path in drops_dir.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() not in (".csv", ".parquet", ".json", ".jsonl", ".gz"):
            continue
        mtime = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
        if mtime <= since:
            continue
        view_key = match_view_key_from_basename(path.name, views)
        if not view_key:
            continue
        found.append(
            {
                "path": str(path),
                "view_key": view_key,
                "mtime": mtime,
            }
        )
    found.sort(key=lambda x: x["mtime"])
    return found


def list_gcs_drops(bucket: str, prefix: str, since: datetime, views: dict) -> list[dict]:
    uri = f"gs://{bucket}/{prefix}".rstrip("/")
    if prefix and not uri.endswith("/"):
        uri += "/**"
    else:
        uri = f"gs://{bucket}/**" if not prefix else uri + "**"

    cmd = ["gsutil", "ls", "-l", "-r", uri]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip() or "gsutil ls failed")

    found: list[dict] = []
    line_re = re.compile(r"^\s*(\d+)\s+(\d{4}-\d{2}-\d{2}T[\d:.]+Z?)\s+(gs://\S+)")
    for line in proc.stdout.splitlines():
        m = line_re.match(line)
        if not m:
            continue
        gcs_path = m.group(3)
        if gcs_path.endswith(":"):
            continue
        if not DROP_FILENAME_RE.match(Path(gcs_path).name):
            continue
        ts_str = m.group(2).replace("Z", "+00:00")
        try:
            mtime = datetime.fromisoformat(ts_str)
            if mtime.tzinfo is None:
                mtime = mtime.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
        if mtime <= since:
            continue
        view_key = match_view_key_from_basename(Path(gcs_path).name, views)
        if not view_key:
            continue
        found.append({"path": gcs_path, "view_key": view_key, "mtime": mtime})

    found.sort(key=lambda x: x["mtime"])
    return found


def pick_source(config: dict, source_arg: str | None) -> tuple[str, dict]:
    sources = config.get("sources") or {}
    if not sources:
        raise ValueError("No sources defined in watcher config")
    if source_arg:
        for sid, scfg in sources.items():
            stype = scfg.get("type", "")
            if sid == source_arg or stype == source_arg:
                return sid, scfg
        raise KeyError(f"Unknown source '{source_arg}'. Known: {', '.join(sources)}")
    if len(sources) == 1:
        sid = next(iter(sources))
        return sid, sources[sid]
    for sid, scfg in sources.items():
        if scfg.get("type") == "local":
            return sid, scfg
    sid = next(iter(sources))
    return sid, sources[sid]


def process_new_drops(
    drops: list[dict],
    src: dict,
    state: dict,
    source_id: str,
    skip_bq: bool,
    views_allowlist: set[str] | None,
) -> int:
    ss = source_state(state, source_id)
    processed: set[str] = set(ss.get("processed") or [])
    max_mtime = parse_iso_dt(ss.get("last_seen"))
    ran = 0

    for drop in drops:
        path = drop["path"]
        view_key = drop["view_key"]
        if views_allowlist and view_key not in views_allowlist:
            continue
        if path in processed:
            continue

        print(f"Processing drop: {path} → view={view_key}")
        try:
            result = run_profile(
                view_key=view_key,
                gcs_path=path,
                write_brief=True,
                trigger_mode="watcher",
                skip_bq=skip_bq,
            )
            print(f"  Verdict: {result.verdict} — {result.verdict_line}")
            if result.brief_path:
                print(f"  Brief: {result.brief_path}")
        except Exception as exc:
            print(f"  ERROR: {exc}", file=sys.stderr)
            continue

        processed.add(path)
        if drop["mtime"] > max_mtime:
            max_mtime = drop["mtime"]
        ran += 1

    ss["processed"] = sorted(processed)[-500:]
    ss["last_seen"] = max_mtime.isoformat()
    return ran


def run_once(
    config: dict,
    source_arg: str | None,
    state_path: Path,
    skip_bq: bool,
) -> int:
    source_id, src = pick_source(config, source_arg)
    state = load_watcher_state(state_path)
    ss = source_state(state, source_id)
    since = parse_iso_dt(ss.get("last_seen"))

    profiles = load_yaml(PROFILES_PATH)
    views = profiles.get("views") or {}
    allowlist_cfg = config.get("defaults", {}).get("view_allowlist")
    allowlist = set(allowlist_cfg) if allowlist_cfg else None

    stype = src.get("type")
    if stype == "local":
        drops_dir = expand_path(src["drops_dir"])
        drops = list_local_drops(drops_dir, since, views)
    elif stype == "gcs":
        drops = list_gcs_drops(src["bucket"], src.get("prefix", ""), since, views)
    else:
        raise ValueError(f"Unknown source type: {stype}")

    if not drops:
        print(f"No new drops for source '{source_id}' since {since.isoformat()}")
        save_watcher_state(state, state_path)
        return 0

    print(f"Found {len(drops)} new file(s) for source '{source_id}'")
    ran = process_new_drops(drops, src, state, source_id, skip_bq, allowlist)
    save_watcher_state(state, state_path)
    print(f"Processed {ran} drop(s); last_seen={source_state(state, source_id)['last_seen']}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Drop Watcher — new landing detection + EDA")
    parser.add_argument("--config", type=Path, default=CONFIG_PATH, help="Watcher YAML config")
    parser.add_argument("--state-path", type=Path, default=DEFAULT_STATE_PATH, help="State JSON path")
    parser.add_argument(
        "--source",
        default=None,
        help="Source id or type (local|gcs) from watcher_config.yaml",
    )
    parser.add_argument("--once", action="store_true", help="Run one scan and exit")
    parser.add_argument("--interval", type=int, default=None, help="Poll every N seconds (loop)")
    parser.add_argument(
        "--skip-bq",
        action="store_true",
        help="Detect drops and write brief shell without BQ queries (smoke test)",
    )
    parser.add_argument("--notify-webhook", default=None, help="Slack webhook URL (Phase 2 stub)")
    args = parser.parse_args()

    if args.notify_webhook:
        print("Note: --notify-webhook is reserved for Phase 2; not sent.", file=sys.stderr)

    config = load_watcher_config(args.config)

    if args.once or args.interval is None:
        return run_once(config, args.source, args.state_path, args.skip_bq)

    print(f"Watching every {args.interval}s (Ctrl+C to stop)")
    try:
        while True:
            run_once(config, args.source, args.state_path, args.skip_bq)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nStopped.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
