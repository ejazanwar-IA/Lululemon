"""
Inbound Drop Agent — shared EDA, diff, brief rendering, and history.
"""

from __future__ import annotations

import json
import re
import subprocess
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
PROFILES_PATH = ROOT / "findings/inbound_drop_agent/view_profiles.yaml"
TEMPLATE_PATH = ROOT / "findings/inbound_drop_agent/data_drop_brief_template.md"
BRIEFS_DIR = ROOT / "findings/inbound_drop_agent/briefs"
HISTORY_PATH = ROOT / "findings/inbound_drop_agent/metrics_history.json"

DROP_FILENAME_RE = re.compile(r"^(.+)_(\d{14})(?:\.\w+)?$", re.IGNORECASE)


@dataclass
class ProfileResult:
    view_key: str
    profile: dict
    meta: dict
    schema: list[dict]
    grain: dict
    dates: dict
    sentinels: list[dict]
    joins: list[dict]
    diff: dict
    verdict: str
    verdict_line: str
    gcs_path: str | None = None
    brief_path: Path | None = None


def load_yaml(path: Path) -> dict:
    import yaml  # type: ignore

    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def bq_query(sql: str, billing_project: str) -> list[dict]:
    cmd = [
        "bq",
        "query",
        f"--project_id={billing_project}",
        "--use_legacy_sql=false",
        "--format=json",
        "--max_rows=10000",
        sql,
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip() or "bq query failed")
    raw = proc.stdout.strip()
    if not raw:
        return []
    return json.loads(raw)


def fq_table(project: str, dataset: str, table: str) -> str:
    return f"`{project}.{dataset}.{table}`"


def backtick_ident(name: str) -> str:
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", name):
        return name
    return f"`{name}`"


def parse_syncstart_from_gcs(gcs_path: str | None, folder_date: str | None) -> str:
    if not gcs_path:
        return folder_date or "—"
    base = gcs_path.rstrip("/").split("/")[-1]
    m = re.search(r"_(\d{14})(?:\.\w+)?$", base)
    if m:
        s = m.group(1)
        return f"{s[0:4]}-{s[4:6]}-{s[6:8]} {s[8:10]}:{s[10:12]}:{s[12:14]}"
    m = re.search(r"_(\d{8})(?:\.\w+)?$", base)
    if m:
        s = m.group(1)
        return f"{s[0:4]}-{s[4:6]}-{s[6:8]} 00:00:00"
    if folder_date:
        return f"{folder_date} 00:00:00 (from folder)"
    return "—"


def infer_folder_date(path: str | None) -> str | None:
    if not path:
        return None
    for part in path.replace("\\", "/").split("/"):
        if re.match(r"^\d{4}-\d{2}-\d{2}$", part):
            return part
    return None


def parse_drop_timestamp(path: str) -> datetime | None:
    base = path.rstrip("/").split("/")[-1]
    m = DROP_FILENAME_RE.match(base)
    if not m:
        return None
    s = m.group(2)
    try:
        return datetime.strptime(s, "%Y%m%d%H%M%S").replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def match_view_key_from_basename(basename: str, views: dict) -> str | None:
    m = DROP_FILENAME_RE.match(basename)
    if not m:
        return None
    gcs_view = m.group(1)
    for key, prof in views.items():
        if prof.get("gcs_view") == gcs_view or key == gcs_view:
            return key
    return None


def load_profile(config: dict, view_key: str) -> dict:
    defaults = config.get("defaults") or {}
    views = config.get("views") or {}
    if view_key not in views:
        raise KeyError(f"Unknown view '{view_key}'. Known: {', '.join(sorted(views))}")
    profile = {**defaults, **views[view_key]}
    profile["view_key"] = view_key
    return profile


def resolve_sample_date(profile: dict, sample_date: str | None) -> str | None:
    if sample_date:
        return sample_date
    joins_cfg = profile.get("join_checks") or []
    if joins_cfg and joins_cfg[0].get("sample_date"):
        return joins_cfg[0]["sample_date"]
    return None


def _dataset_candidates(profile: dict) -> list[str]:
    primary = profile["bq_dataset"]
    out = [primary]
    alt = profile.get("bq_dataset_raw")
    if alt and alt not in out:
        out.append(alt)
    return out


def resolved_dataset(profile: dict) -> str:
    return profile.get("bq_dataset_resolved") or profile["bq_dataset"]


def tier0_metadata(profile: dict) -> dict:
    project = profile["gcp_project"]
    table = profile["bq_table"]
    billing = profile["billing_project"]
    for dataset in _dataset_candidates(profile):
        sql = f"""
SELECT
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 3) AS size_gb,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified_at
FROM `{project}.{dataset}.__TABLES__`
WHERE table_id = '{table}'
"""
        rows = bq_query(sql, billing)
        if rows:
            r = rows[0]
            profile["bq_dataset_resolved"] = dataset
            return {
                "exists": True,
                "dataset": dataset,
                "row_count": int(r.get("row_count") or 0),
                "size_gb": r.get("size_gb"),
                "last_modified_at": r.get("last_modified_at"),
            }
    return {"exists": False}


def tier0_schema(profile: dict) -> list[dict]:
    project = profile["gcp_project"]
    dataset = resolved_dataset(profile)
    table = profile["bq_table"]
    billing = profile["billing_project"]
    sql = f"""
SELECT column_name, data_type, is_nullable
FROM `{project}.{dataset}.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = '{table}'
ORDER BY ordinal_position
"""
    return bq_query(sql, billing)


def tier1_grain(profile: dict, sample_date: str | None) -> dict:
    project = profile["gcp_project"]
    dataset = resolved_dataset(profile)
    table = profile["bq_table"]
    billing = profile["billing_project"]
    grain_cols = profile.get("grain_columns") or []
    if not grain_cols:
        return {}
    concat = " || '|' || ".join(
        f"COALESCE(CAST({backtick_ident(c)} AS STRING), '')" for c in grain_cols
    )
    tbl = fq_table(project, dataset, table)
    where = ""
    date_col = profile.get("date_column")
    if date_col and sample_date:
        where = f"WHERE {backtick_ident(date_col)} = DATE '{sample_date}'"
    sql = f"""
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT {concat}) AS distinct_grain
FROM {tbl}
{where}
"""
    rows = bq_query(sql, billing)
    if not rows:
        return {}
    total = int(rows[0].get("total_rows") or 0)
    distinct = int(rows[0].get("distinct_grain") or 0)
    dup = total - distinct
    pct = round(100.0 * dup / total, 4) if total else 0.0
    return {
        "total_rows": total,
        "distinct_grain": distinct,
        "duplicate_rows": dup,
        "duplicate_pct": pct,
        "grain_label": ", ".join(grain_cols),
    }


def tier2_dates(profile: dict, sample_date: str | None) -> dict:
    date_col = profile.get("date_column")
    if not date_col:
        return {"skipped": True, "reason": "No date_column in profile"}
    project = profile["gcp_project"]
    dataset = resolved_dataset(profile)
    table = profile["bq_table"]
    billing = profile["billing_project"]
    tbl = fq_table(project, dataset, table)
    dc = backtick_ident(date_col)
    if sample_date:
        sql = f"""
SELECT
  {dc} AS business_date,
  COUNT(*) AS row_count
FROM {tbl}
WHERE {dc} = DATE '{sample_date}'
GROUP BY 1
"""
        sample_rows = bq_query(sql, billing)
    else:
        sample_rows = []
    sql2 = f"""
SELECT MIN({dc}) AS min_date, MAX({dc}) AS max_date, COUNT(DISTINCT {dc}) AS distinct_dates
FROM {tbl}
WHERE {dc} >= DATE '2024-01-01'
"""
    range_rows = bq_query(sql2, billing)
    return {
        "sample_date": sample_date,
        "sample_rows": sample_rows,
        "range": range_rows[0] if range_rows else {},
    }


def tier3_sentinels(profile: dict, sample_date: str | None) -> list[dict]:
    cols = profile.get("string_sentinel_columns") or []
    date_col = profile.get("date_column")
    if not cols:
        return []
    project = profile["gcp_project"]
    dataset = resolved_dataset(profile)
    table = profile["bq_table"]
    billing = profile["billing_project"]
    tbl = fq_table(project, dataset, table)
    predicates = []
    for c in cols:
        ic = backtick_ident(c)
        predicates.append(
            f"COUNTIF({ic} IS NULL OR CAST({ic} AS STRING) IN ('', '\\\\N')) AS {c}_null_sentinel"
        )
    where = ""
    if date_col and sample_date:
        where = f"WHERE {backtick_ident(date_col)} = DATE '{sample_date}'"
    sql = f"SELECT COUNT(*) AS row_count, {', '.join(predicates)} FROM {tbl} {where}"
    return bq_query(sql, billing)


def tier4_joins(profile: dict, sample_date: str | None) -> list[dict]:
    checks = profile.get("join_checks") or []
    if not checks:
        return []
    project = profile["gcp_project"]
    dataset = resolved_dataset(profile)
    table = profile["bq_table"]
    billing = profile["billing_project"]
    tbl = fq_table(project, dataset, table)
    date_col = profile.get("date_column")
    results = []
    for chk in checks:
        left = backtick_ident(chk["left_key"])
        right_tbl = chk["right_table"]
        right_key = backtick_ident(chk["right_key"])
        sd = chk.get("sample_date") or sample_date
        filter_clause = ""
        if date_col and sd:
            filter_clause = f"WHERE {backtick_ident(date_col)} = DATE '{sd}'"
        sql = f"""
WITH feed AS (
  SELECT DISTINCT {left} AS join_key FROM {tbl} {filter_clause}
),
ref AS (
  SELECT DISTINCT {right_key} AS join_key FROM `{project}.{right_tbl}`
)
SELECT
  '{chk.get("label", "join")}' AS check_name,
  COUNT(*) AS feed_keys,
  COUNTIF(r.join_key IS NOT NULL) AS matched,
  COUNTIF(r.join_key IS NULL) AS orphans,
  ROUND(100.0 * COUNTIF(r.join_key IS NULL) / NULLIF(COUNT(*), 0), 2) AS orphan_pct
FROM feed f
LEFT JOIN ref r ON f.join_key = r.join_key
"""
        rows = bq_query(sql, billing)
        if rows:
            rows[0]["note"] = chk.get("note", "")
            results.append(rows[0])
    return results


def extract_sentinel_counts(sentinels: list[dict]) -> dict[str, int]:
    if not sentinels:
        return {}
    r = sentinels[0]
    out: dict[str, int] = {}
    for k, v in r.items():
        if k.endswith("_null_sentinel") and v is not None:
            try:
                out[k] = int(v)
            except (TypeError, ValueError):
                pass
    return out


def extract_join_orphans(joins: list[dict]) -> dict[str, float]:
    return {str(j.get("check_name", "join")): float(j.get("orphan_pct") or 0) for j in joins}


def schema_map(schema: list[dict]) -> dict[str, str]:
    return {c["column_name"]: c["data_type"] for c in schema if c.get("column_name")}


def tier5_diff(
    prior: dict | None,
    meta: dict,
    schema: list[dict],
    grain: dict,
    sentinels: list[dict],
    joins: list[dict],
) -> dict:
    """Compare current run vs prior metrics_history snapshot."""
    findings: list[dict[str, str]] = []
    red_flags: list[str] = []
    amber_flags: list[str] = []

    if not prior:
        return {
            "has_prior": False,
            "findings": [{"level": "INFO", "message": "First run — no prior drop to diff."}],
            "red_flags": [],
            "amber_flags": [],
            "row_delta_pct": None,
            "new_columns": [],
            "dropped_columns": [],
            "type_changes": [],
        }

    current_cols = schema_map(schema)
    prior_cols_list = prior.get("column_names") or []
    prior_types = prior.get("column_types") or {}
    if not prior_types and prior_cols_list:
        prior_types = {n: "UNKNOWN" for n in prior_cols_list}

    prior_names = set(prior_types.keys()) if prior_types else set(prior_cols_list)
    current_names = set(current_cols.keys())
    new_cols = sorted(current_names - prior_names)
    dropped_cols = sorted(prior_names - current_names)
    type_changes = []
    for name in sorted(current_names & prior_names):
        pt = prior_types.get(name)
        ct = current_cols.get(name)
        if pt and ct and pt != ct and pt != "UNKNOWN":
            type_changes.append({"column": name, "prior": pt, "current": ct})

    if new_cols:
        amber_flags.append(f"New columns: {', '.join(new_cols)}")
        findings.append({"level": "AMBER", "message": f"New columns ({len(new_cols)}): {', '.join(new_cols[:10])}"})
    if dropped_cols:
        amber_flags.append(f"Dropped columns: {', '.join(dropped_cols)}")
        findings.append(
            {"level": "AMBER", "message": f"Dropped columns ({len(dropped_cols)}): {', '.join(dropped_cols[:10])}"}
        )
    for tc in type_changes:
        red_flags.append(f"Type change on `{tc['column']}`: {tc['prior']} → {tc['current']}")
        findings.append(
            {
                "level": "RED",
                "message": f"Type change `{tc['column']}`: {tc['prior']} → {tc['current']}",
            }
        )

    row_count = meta.get("row_count")
    prior_rows = prior.get("row_count")
    row_delta_pct = None
    if prior_rows and isinstance(row_count, int) and prior_rows > 0:
        row_delta_pct = round(100.0 * (row_count - prior_rows) / prior_rows, 2)
        if abs(row_delta_pct) > 30:
            red_flags.append(f"Row count delta {row_delta_pct}% vs prior (>{30}% threshold)")
            findings.append(
                {"level": "RED", "message": f"Row count {row_count:,} vs prior {prior_rows:,} ({row_delta_pct:+.2f}%)"}
            )
        elif abs(row_delta_pct) > 10:
            amber_flags.append(f"Row count delta {row_delta_pct}% vs prior")
            findings.append(
                {"level": "AMBER", "message": f"Row count shifted {row_delta_pct:+.2f}% vs prior drop"}
            )

    prior_lm = str(prior.get("last_modified_at", ""))
    cur_lm = str(meta.get("last_modified_at", ""))
    if prior_lm and cur_lm and prior_lm != cur_lm and row_count == prior_rows:
        amber_flags.append("BQ last_modified changed but row_count unchanged")
        findings.append({"level": "AMBER", "message": "Table touched in BQ but row count unchanged — verify load."})

    prior_orphans = prior.get("join_orphans") or {}
    for j in joins:
        name = str(j.get("check_name", "join"))
        orphan = float(j.get("orphan_pct") or 0)
        prior_orphan = float(prior_orphans.get(name, 0))
        delta = orphan - prior_orphan
        if orphan > 50:
            red_flags.append(f"Join '{name}' orphan {orphan}% (>50%)")
        elif delta > 5:
            amber_flags.append(f"Join '{name}' orphan drift +{delta:.1f} pp")
            findings.append(
                {"level": "AMBER", "message": f"Join '{name}' orphan {orphan}% (was {prior_orphan}%, +{delta:.1f} pp)"}
            )

    prior_sent = prior.get("sentinel_counts") or {}
    cur_sent = extract_sentinel_counts(sentinels)
    sample_rows = (sentinels[0].get("row_count") if sentinels else None) or 0
    for key, cur_val in cur_sent.items():
        prior_val = prior_sent.get(key)
        if prior_val is None:
            continue
        if sample_rows and prior_val > 0:
            pct_increase = 100.0 * (cur_val - prior_val) / prior_val
            if pct_increase > 10:
                col = key.replace("_null_sentinel", "")
                amber_flags.append(f"Sentinel spike on `{col}` (+{pct_increase:.0f}%)")
                findings.append(
                    {
                        "level": "AMBER",
                        "message": f"`{col}` null/\\N/blank: {cur_val:,} vs prior {prior_val:,}",
                    }
                )

    prior_dup = prior.get("duplicate_pct")
    cur_dup = grain.get("duplicate_pct")
    if prior_dup is not None and cur_dup is not None and cur_dup > prior_dup + 0.05:
        amber_flags.append(f"Duplicate % increased ({prior_dup}% → {cur_dup}%)")
        findings.append({"level": "AMBER", "message": f"Grain duplicate % rose from {prior_dup}% to {cur_dup}%"})

    if not findings:
        findings.append({"level": "GREEN", "message": "No material drift vs prior drop."})

    return {
        "has_prior": True,
        "findings": findings,
        "red_flags": red_flags,
        "amber_flags": amber_flags,
        "row_delta_pct": row_delta_pct,
        "new_columns": new_cols,
        "dropped_columns": dropped_cols,
        "type_changes": type_changes,
    }


def compute_verdict(
    meta: dict,
    grain: dict,
    joins: list[dict],
    diff: dict | None = None,
) -> tuple[str, str]:
    lines: list[str] = []
    severity = 0  # 0 green, 1 amber, 2 red

    if not meta.get("exists"):
        return "RED", "BQ table not found — extraction may not have landed."

    if diff:
        if diff.get("type_changes") or diff.get("red_flags"):
            severity = max(severity, 2)
            lines.extend(diff.get("red_flags") or [])
        if diff.get("amber_flags"):
            severity = max(severity, 1)
            if not lines:
                lines.extend(diff["amber_flags"][:2])

    dup_pct = grain.get("duplicate_pct") or 0.0
    if dup_pct > 0.1:
        severity = max(severity, 2)
        lines.append(f"Grain duplicates {dup_pct}% — investigate before ingest.")
    for j in joins:
        orphan = float(j.get("orphan_pct") or 0)
        if orphan > 50:
            severity = max(severity, 2)
            lines.append(f"Join '{j.get('check_name')}' orphan {orphan}% — blocking.")
        elif orphan > 10:
            severity = max(severity, 1)
            lines.append(f"Join '{j.get('check_name')}' orphan {orphan}% — review join policy.")
    if dup_pct > 0 and severity < 2:
        severity = max(severity, 1)
        if not any("duplicate" in x.lower() for x in lines):
            lines.append("Non-zero grain duplicates — confirm expected.")

    if severity == 2:
        return "RED", lines[0] if lines else "Blocking issues detected."
    if severity == 1:
        return "AMBER", lines[0] if lines else "Review recommended before ingest."
    return "GREEN", "Metadata, grain, joins, and drift within expected bounds."


def build_history_entry(
    view_key: str,
    meta: dict,
    schema: list[dict],
    grain: dict,
    sentinels: list[dict],
    joins: list[dict],
    verdict: str,
    gcs_path: str | None,
    brief_path: str | None,
) -> dict:
    cols = schema_map(schema)
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "gcs_path": gcs_path,
        "row_count": meta.get("row_count"),
        "size_gb": meta.get("size_gb"),
        "last_modified_at": meta.get("last_modified_at"),
        "column_names": list(cols.keys()),
        "column_types": cols,
        "duplicate_pct": grain.get("duplicate_pct"),
        "join_orphans": extract_join_orphans(joins),
        "sentinel_counts": extract_sentinel_counts(sentinels),
        "verdict": verdict,
        "brief_path": brief_path,
    }


def load_history(path: Path | None = None) -> dict:
    p = path or HISTORY_PATH
    if not p.exists():
        return {}
    with p.open(encoding="utf-8") as f:
        return json.load(f)


def save_history(history: dict, path: Path | None = None) -> None:
    p = path or HISTORY_PATH
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("w", encoding="utf-8") as f:
        json.dump(history, f, indent=2, default=str)


def format_schema_table(columns: list[dict]) -> str:
    if not columns:
        return "_No schema returned._"
    lines = ["| Column | Type | Nullable |", "|--------|------|----------|"]
    for c in columns[:40]:
        lines.append(
            f"| {c.get('column_name', '')} | {c.get('data_type', '')} | {c.get('is_nullable', '')} |"
        )
    if len(columns) > 40:
        lines.append(f"| _…_ | _{len(columns) - 40} more columns_ | |")
    return "\n".join(lines)


def format_date_section(date_info: dict) -> str:
    if date_info.get("skipped"):
        return f"_Date profiling skipped: {date_info.get('reason', '')}_"
    parts = []
    rng = date_info.get("range") or {}
    if rng:
        parts.append(
            f"- Business date range (since 2024-01-01): **{rng.get('min_date')}** → **{rng.get('max_date')}** "
            f"({rng.get('distinct_dates')} distinct dates)"
        )
    for sr in date_info.get("sample_rows") or []:
        rc = sr.get("row_count")
        if rc is not None:
            rc_fmt = f"{int(rc):,}" if str(rc).isdigit() else str(rc)
            parts.append(f"- Sample {sr.get('business_date')}: **{rc_fmt}** rows")
        else:
            parts.append(f"- Sample: {sr}")
    return "\n".join(parts) if parts else "_No date metrics._"


def format_sentinel_section(rows: list[dict]) -> str:
    if not rows:
        return "_No sentinel columns configured._"
    r = rows[0]
    lines = []
    if isinstance(r.get("row_count"), int):
        lines.append(f"- Rows in sample: **{r.get('row_count', '—'):,}**")
    for k, v in r.items():
        if k.endswith("_null_sentinel"):
            col = k.replace("_null_sentinel", "")
            vfmt = f"{int(v):,}" if v is not None and str(v).isdigit() else str(v)
            lines.append(f"- `{col}` null/\\N/blank: **{vfmt}**")
    return "\n".join(lines) if lines else "_No sentinel metrics._"


def format_join_section(joins: list[dict]) -> str:
    if not joins:
        return "_No join checks configured._"
    lines = [
        "| Check | Feed keys | Matched | Orphans | Orphan % |",
        "|-------|----------:|--------:|--------:|---------:|",
    ]
    for j in joins:
        lines.append(
            f"| {j.get('check_name', '')} | {j.get('feed_keys', '')} | {j.get('matched', '')} | "
            f"{j.get('orphans', '')} | {j.get('orphan_pct', '')} |"
        )
        if j.get("note"):
            lines.append(f"\n_{j['note']}_")
    return "\n".join(lines)


def format_diff_section(diff: dict) -> str:
    if not diff.get("has_prior"):
        return "_First automated run for this view — diff populates on the next drop._"
    lines = ["| Level | Finding |", "|-------|---------|"]
    for f in diff.get("findings") or []:
        lines.append(f"| {f.get('level', '')} | {f.get('message', '')} |")
    nc = diff.get("new_columns") or []
    dc = diff.get("dropped_columns") or []
    if nc:
        lines.append(f"\n**New columns:** `{', '.join(nc)}`")
    if dc:
        lines.append(f"\n**Dropped columns:** `{', '.join(dc)}`")
    return "\n".join(lines)


def format_anomaly_section(diff: dict, grain: dict, joins: list[dict]) -> str:
    parts = []
    dup = grain.get("duplicate_pct")
    if dup is not None and dup > 0:
        parts.append(f"- Grain duplicate rate **{dup}%** on sample scope")
    for j in joins:
        orphan = float(j.get("orphan_pct") or 0)
        if orphan > 10:
            parts.append(f"- High join orphan rate on **{j.get('check_name')}**: **{orphan}%**")
    if diff.get("red_flags"):
        for flag in diff["red_flags"]:
            parts.append(f"- **Red:** {flag}")
    if diff.get("amber_flags"):
        for flag in diff["amber_flags"][:5]:
            parts.append(f"- **Amber:** {flag}")
    if not parts:
        parts.append("- No threshold anomalies flagged on this run.")
    parts.append("\n_Numeric z-score checks require 3+ prior runs (post-MVP)._")
    return "\n".join(parts)


def brief_output_path(view_key: str, drop_path: str | None) -> Path:
    ts = parse_drop_timestamp(drop_path or "") or datetime.now(timezone.utc)
    stamp = ts.strftime("%Y%m%d_%H%M")
    return BRIEFS_DIR / f"{view_key}_{stamp}.md"


def render_brief(
    profile: dict,
    meta: dict,
    schema: list[dict],
    grain: dict,
    dates: dict,
    sentinels: list[dict],
    joins: list[dict],
    diff: dict,
    verdict: str,
    verdict_line: str,
    gcs_path: str | None,
    trigger_mode: str = "manual",
) -> str:
    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    project = profile["gcp_project"]
    dataset = resolved_dataset(profile)
    table = profile["bq_table"]
    fqn = f"{project}.{dataset}.{table}"
    now = datetime.now(timezone.utc)
    view_key = profile["view_key"]
    gcs_view = profile.get("gcs_view", view_key)
    folder = infer_folder_date(gcs_path)
    sync = parse_syncstart_from_gcs(gcs_path, folder)
    sample_date = profile.get("_sample_date")

    history = load_history()
    prior = history.get(view_key, {})
    prior_rows = prior.get("row_count")
    row_count = meta.get("row_count") or grain.get("total_rows") or "—"
    delta_pct = diff.get("row_delta_pct")
    row_delta_str = f"{delta_pct:+.2f}%" if delta_pct is not None else "—"
    if delta_pct is None and prior_rows and isinstance(row_count, int) and prior_rows > 0:
        row_delta_str = f"{round(100.0 * (row_count - prior_rows) / prior_rows, 2):+.2f}%"

    red, amber, green = [], [], []
    for f in diff.get("findings") or []:
        lvl = f.get("level")
        msg = f.get("message", "")
        if lvl == "RED":
            red.append(msg)
        elif lvl == "AMBER":
            amber.append(msg)
        elif lvl == "GREEN":
            green.append(msg)
    if verdict == "RED":
        if verdict_line not in red:
            red.insert(0, verdict_line)
    elif verdict == "AMBER":
        if verdict_line not in amber:
            amber.insert(0, verdict_line)
    else:
        if verdict_line not in green:
            green.insert(0, verdict_line)

    agent_line = "drop-watch" if trigger_mode == "watcher" else "inbound-drop-eda (manual)"

    replacements = {
        "{{VIEW_NAME}}": gcs_view,
        "{{VIEW_KEY}}": view_key,
        "{{GCS_VIEW}}": gcs_view,
        "{{GCS_PATH}}": gcs_path or "— (not supplied)",
        "{{SYNCSTARTDATETIME}}": sync,
        "{{BQ_TABLE_FQN}}": fqn,
        "{{VERDICT}}": verdict,
        "{{VERDICT_ONE_LINER}}": verdict_line,
        "{{TABLE_EXISTS}}": "Yes" if meta.get("exists") else "No",
        "{{ROW_COUNT}}": f"{row_count:,}" if isinstance(row_count, int) else str(row_count),
        "{{SIZE_GB}}": str(meta.get("size_gb", "—")),
        "{{LAST_MODIFIED}}": str(meta.get("last_modified_at", "—")),
        "{{COLUMN_COUNT}}": str(len(schema)),
        "{{PARTITION_HINT}}": profile.get("partition_hint", ""),
        "{{SCHEMA_TABLE}}": format_schema_table(schema),
        "{{GRAIN_LABEL}}": grain.get("grain_label", "—"),
        "{{GRAIN_TOTAL_ROWS}}": f"{grain.get('total_rows', '—'):,}"
        if isinstance(grain.get("total_rows"), int)
        else "—",
        "{{DISTINCT_GRAIN}}": f"{grain.get('distinct_grain', '—'):,}"
        if isinstance(grain.get("distinct_grain"), int)
        else "—",
        "{{DUPLICATE_ROWS}}": f"{grain.get('duplicate_rows', '—'):,}"
        if isinstance(grain.get("duplicate_rows"), int)
        else "—",
        "{{DUPLICATE_PCT}}": str(grain.get("duplicate_pct", "—")),
        "{{GRAIN_SCOPE_NOTE}}": (
            f"_Grain metrics on sample date {sample_date} only._"
            if sample_date and profile.get("date_column")
            else "_Grain metrics on full table — confirm size in Tier 0 before running._"
        ),
        "{{GRAIN_DESCRIPTION}}": grain.get("grain_label", "Configure grain_columns in view_profiles.yaml"),
        "{{DATE_COVERAGE_SECTION}}": format_date_section(dates),
        "{{SENTINEL_SECTION}}": format_sentinel_section(sentinels),
        "{{JOIN_SECTION}}": format_join_section(joins),
        "{{CHANGES_VS_PRIOR_SECTION}}": format_diff_section(diff),
        "{{ANOMALY_SECTION}}": format_anomaly_section(diff, grain, joins),
        "{{PRIOR_ROW_COUNT}}": f"{prior_rows:,}" if prior_rows else "—",
        "{{ROW_DELTA_PCT}}": row_delta_str,
        "{{PRIOR_DROP_REF}}": prior.get("brief_path", "first run"),
        "{{RED_ITEMS}}": "\n".join(f"- {x}" for x in red) or "- _None_",
        "{{AMBER_ITEMS}}": "\n".join(f"- {x}" for x in amber) or "- _None_",
        "{{GREEN_ITEMS}}": "\n".join(f"- {x}" for x in green) or "- _None_",
        "{{ACTION_1}}": "Share brief with DI + PL for drop sign-off",
        "{{ACTION_2}}": "If Green: advance `view_mapping_table.filter_param` per periodic sourcing runbook",
        "{{ACTION_3}}": "If Red/Amber: run deep EDA SQL in `queries/` before enabling DAG",
        "{{GENERATED_AT}}": now.strftime("%Y-%m-%d %H:%M UTC"),
        "{{GENERATED_DATE}}": now.strftime("%Y-%m-%d"),
        "{{REVIEWER}}": "_pending_",
        "{{AGENT_RUN_LINE}}": agent_line,
    }
    out = template
    for k, v in replacements.items():
        out = out.replace(k, v)
    return out


def run_profile(
    view_key: str,
    gcs_path: str | None = None,
    sample_date: str | None = None,
    write_brief: bool = False,
    dry_run: bool = False,
    trigger_mode: str = "manual",
    skip_bq: bool = False,
) -> ProfileResult:
    """Run full EDA pack for a view; optionally write brief and update history."""
    config = load_yaml(PROFILES_PATH)
    profile = load_profile(config, view_key)
    sd = resolve_sample_date(profile, sample_date)
    profile["_sample_date"] = sd

    if dry_run:
        return ProfileResult(
            view_key=view_key,
            profile=profile,
            meta={},
            schema=[],
            grain={},
            dates={},
            sentinels=[],
            joins=[],
            diff={},
            verdict="GREEN",
            verdict_line="dry-run",
            gcs_path=gcs_path,
        )

    if skip_bq:
        meta: dict = {"exists": False, "skipped": True}
        schema: list[dict] = []
        grain: dict = {}
        dates: dict = {}
        sentinels: list[dict] = []
        joins: list[dict] = []
    else:
        meta = tier0_metadata(profile)
        if not meta.get("exists"):
            schema = []
            grain = {}
            dates = {}
            sentinels = []
            joins = []
        else:
            schema = tier0_schema(profile)
            grain = tier1_grain(profile, sd)
            dates = tier2_dates(profile, sd)
            sentinels = tier3_sentinels(profile, sd)
            joins = tier4_joins(profile, sd)

    history = load_history()
    prior = history.get(view_key)
    diff = tier5_diff(prior, meta, schema, grain, sentinels, joins)
    verdict, verdict_line = compute_verdict(meta, grain, joins, diff)

    brief_path = None
    if write_brief:
        brief = render_brief(
            profile, meta, schema, grain, dates, sentinels, joins, diff, verdict, verdict_line, gcs_path, trigger_mode
        )
        BRIEFS_DIR.mkdir(parents=True, exist_ok=True)
        brief_path = brief_output_path(view_key, gcs_path)
        brief_path.write_text(brief, encoding="utf-8")
        entry = build_history_entry(
            view_key, meta, schema, grain, sentinels, joins, verdict, gcs_path, str(brief_path.relative_to(ROOT))
        )
        history[view_key] = entry
        save_history(history)

    return ProfileResult(
        view_key=view_key,
        profile=profile,
        meta=meta,
        schema=schema,
        grain=grain,
        dates=dates,
        sentinels=sentinels,
        joins=joins,
        diff=diff,
        verdict=verdict,
        verdict_line=verdict_line,
        gcs_path=gcs_path,
        brief_path=brief_path,
    )
