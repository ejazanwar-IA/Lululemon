#!/usr/bin/env python3
"""FORK of scripts/lulu_s3_to_gcs_sync.py, curated to add concurrent shard processing for
throughput - the parent script processes one shard at a time (download -> transform -> upload
-> next), even though a direct benchmark this session showed ~2x throughput from running shards
concurrently on this same network (bounded by the same corporate-network bandwidth ceiling, so
not dramatic, but real and free - no new infra/permissions needed).

Do NOT let this drift from the parent except for the concurrency change below - the parent is
actively running live in production right now and must not be touched.

The only functional difference: not-yet-uploaded shards are processed by a ThreadPoolExecutor
(--max-workers, default 6) instead of a plain for-loop. Each shard's work (download -> append
timestamp -> upload) already operates on its own independent temp file, so this is safe to
parallelize directly - no shared mutable state between shards. The idempotent "already in GCS"
check still happens once upfront, before any threads spawn. If any shard in a batch fails, the
rest of that batch still finishes (success or failure) before the first exception is raised -
since everything is idempotent, a partial-batch failure just means the next resume re-checks
that same batch, which is cheap and safe.

Everything else (append_sync_timestamp, null marker normalization, safe bq_load,
--allow_quoted_newlines, the billing-project split) is identical to the parent - copied as of
2026-08-05.

- Source: Lululemon S3 bucket, via the role chain in scripts/lulu_s3_client.py (separate, untouched).
- Destination: gs://client_data_lululemon/YYYY-MM-DD/<view>/<exact S3 source filename> - falls
  back to <view>_<timestamp>_<shard>.csv only for any older shard that already exists under that
  legacy generic name (never re-uploaded under a second, duplicate name).
- Every file gets a SYNCSTARTDATETIME column appended as the last column before upload,
  matching the platform's existing sourcing-table convention - same value for a whole run.
- --load-to-bq: safely loads every source column as STRING into a temporary table, validates
  inferred conversions, then creates the final typed BQ table. Pass --bq-append to append instead.
- Requires: gcloud/bq CLI authenticated; config from config/lulu_dev_s3.env.

Two modes - discover (no guessing) or manual (you already know the exact path):

Usage:
  # auto-discover every real feed under Impact_Analytics/outbound/ and sync all of them
  scripts/lulu_s3_to_gcs_sync_concurrent.py --discover [--discover-root PREFIX] [--dry-run] [--load-to-bq]

  # manual: target one feed you already know the exact S3 path for
  scripts/lulu_s3_to_gcs_sync_concurrent.py --view inventory_snapshot \\
      --s3-prefix "Impact_Analytics/outbound/inventory_snapshot/new" --load-to-bq --max-workers 6
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta, timezone
from pathlib import Path

import boto3
from botocore.exceptions import ClientError, SSLError
from tqdm import tqdm

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("LULU_S3_ENV_FILE", ROOT / "config/lulu_dev_s3.env"))
CA_BUNDLE_CACHE = ROOT / "config/.lulu_s3_ca_bundle.pem"
BQ_LOAD_MANIFEST = ROOT / "config/.lulu_bq_load_manifest.json"  # tracks which GCS URIs
# have already been bq-loaded into which table, so re-running never appends duplicate rows
GCS_BUCKET = "client_data_lululemon"
BQ_PROJECT = "lululemon-01042025"
BQ_DATASET = "lulu_sourcing_dev"
BQ_BILLING_PROJECT = "lululemon-data-scan"  # job submission/billing project - this account often lacks
# bigquery.jobs.create on BQ_PROJECT itself (see lululemon-bq-context skill, rule G16)
DEFAULT_DISCOVER_ROOT = "Impact_Analytics/outbound/"  # excludes inbound/ - that's OUR uploads to Lululemon, not client data
GCS_DATE_FOLDER = "2026-08-03"  # fixed landing folder for this batch - every feed lands here regardless of
# which calendar day it's actually run on; update this when starting a new batch of transfers
IST = timezone(timedelta(hours=5, minutes=30))  # SYNCSTARTDATETIME is recorded in IST, not UTC
SAFE_LOAD_MAX_QUERY_BYTES = 500 * 1024 ** 3
SAFE_CAST_TYPES = {
    "BOOL", "BOOLEAN", "DATE", "DATETIME", "FLOAT", "FLOAT64", "INT64", "INTEGER",
    "NUMERIC", "BIGNUMERIC", "TIME", "TIMESTAMP",
}


class SafeLoadApprovalRequired(RuntimeError):
    """Raised when the safe conversion query exceeds the project's auto-execution limit."""


def load_env(path: Path) -> dict:
    """Parses the KEY=VALUE secrets file into a dict.
    Exits with a clear message if the file is missing or required keys aren't set."""
    if not path.is_file():
        sys.exit(f"Missing env file: {path} (copy {path.with_suffix('')}.env.example)")
    env = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip()
    required = [
        "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "FIRST_ROLE_ARN",
        "SECOND_ROLE_ARN", "EXTERNAL_ID", "S3_BUCKET",
    ]
    missing = [k for k in required if not env.get(k)]
    if missing:
        sys.exit(f"{path} is missing values for: {', '.join(missing)}")
    env.setdefault("AWS_REGION", "us-east-1")
    return env


def build_zscaler_ca_bundle() -> str:
    """Merges the Zscaler root cert into certifi's bundle so boto3 can verify TLS on this network.
    Result is cached to disk after the first build."""
    if CA_BUNDLE_CACHE.is_file():
        return str(CA_BUNDLE_CACHE)
    import certifi

    zscaler_pem = subprocess.run(
        ["security", "find-certificate", "-a", "-c", "Zscaler", "-p",
         "/Library/Keychains/System.keychain"],
        capture_output=True, text=True, check=True,
    ).stdout
    combined = Path(certifi.where()).read_text() + zscaler_pem
    CA_BUNDLE_CACHE.write_text(combined)
    return str(CA_BUNDLE_CACHE)


def assume_role_chain(env: dict, verify) -> boto3.session.Session:
    """Runs the two-hop AssumeRole chain (IA account -> Lululemon account).
    Returns a session built from the final hop's temporary credentials."""
    base = boto3.session.Session(
        aws_access_key_id=env["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=env["AWS_SECRET_ACCESS_KEY"],
    )
    sts1 = base.client("sts", region_name=env["AWS_REGION"], verify=verify)
    creds1 = sts1.assume_role(
        RoleArn=env["FIRST_ROLE_ARN"], RoleSessionName="lulu-s3-gcs-hop1",
        ExternalId=env["EXTERNAL_ID"],
    )["Credentials"]

    hop1 = boto3.session.Session(
        aws_access_key_id=creds1["AccessKeyId"],
        aws_secret_access_key=creds1["SecretAccessKey"],
        aws_session_token=creds1["SessionToken"],
    )
    sts2 = hop1.client("sts", region_name=env["AWS_REGION"], verify=verify)
    creds2 = sts2.assume_role(
        RoleArn=env["SECOND_ROLE_ARN"], RoleSessionName="lulu-s3-gcs-hop2",
        ExternalId=env["EXTERNAL_ID"],
    )["Credentials"]

    return boto3.session.Session(
        aws_access_key_id=creds2["AccessKeyId"],
        aws_secret_access_key=creds2["SecretAccessKey"],
        aws_session_token=creds2["SessionToken"],
    )


def get_s3_client(env: dict):
    """Builds an S3 client via the role chain. Call this ONCE per run and reuse it -
    repeated calls multiply STS calls and risk tripping Zscaler's 3rd-consecutive-call block.
    Retries once with the Zscaler CA bundle if the first attempt hits an SSL error."""
    verify = None
    for attempt in (1, 2):
        try:
            session = assume_role_chain(env, verify)
            return session.client("s3", region_name=env["AWS_REGION"], verify=verify)
        except SSLError:
            if attempt == 2:
                raise
            verify = build_zscaler_ca_bundle()


def retry_call(fn, attempts=3, delay=1.5):
    """Retries a flaky call up to `attempts` times with a delay in between.
    Some AWS calls intermittently hit a corporate-proxy network block unrelated to permissions."""
    last_err = None
    for i in range(attempts):
        try:
            return fn()
        except Exception as e:  # noqa: BLE001 - deliberately broad, see docstring
            last_err = e
            if i < attempts - 1:
                time.sleep(delay)
    raise last_err


def list_source_files(s3, bucket: str, prefix: str) -> list[dict]:
    """Lists every real object under a prefix, skipping folder-marker keys (those ending in '/')."""
    paginator = s3.get_paginator("list_objects_v2")
    files = []
    for page in retry_call(lambda: list(paginator.paginate(Bucket=bucket, Prefix=prefix))):
        for obj in page.get("Contents", []):
            if not obj["Key"].endswith("/"):
                files.append(obj)
    return files


def read_source_header(s3, bucket: str, key: str) -> list[str]:
    """Reads only the first MiB of a source object to obtain its CSV header."""
    response = retry_call(lambda: s3.get_object(Bucket=bucket, Key=key, Range="bytes=0-1048575"))
    text = response["Body"].read().decode("utf-8-sig")
    try:
        header = next(csv.reader(io.StringIO(text)))
    except StopIteration:
        sys.exit(f"Source file has no CSV header: s3://{bucket}/{key}")
    if not header or any(not name for name in header):
        sys.exit(f"Source file has an invalid CSV header: s3://{bucket}/{key}")
    return header


def sanitize_view_name(segments: tuple) -> str:
    """Turns S3 path segments into a valid BigQuery table/view name.
    Non-alphanumeric characters become underscores; a leading digit gets prefixed with '_'."""
    parts = [re.sub(r"[^A-Za-z0-9_]", "_", seg).strip("_").lower() for seg in segments]
    name = "_".join(p for p in parts if p)
    return f"_{name}" if name and name[0].isdigit() else name


def assert_no_name_collisions(feeds: list[dict]):
    """Aborts if two different S3 paths sanitized down to the same view name.
    Sanitizing is many-to-one, so this can happen even though the raw path join is collision-safe."""
    seen: dict[str, list[str]] = {}
    for f in feeds:
        seen.setdefault(f["view"], []).append(f["s3_prefix"])
    dupes = {name: paths for name, paths in seen.items() if len(paths) > 1}
    if dupes:
        detail = "; ".join(f"{name!r} <- {paths}" for name, paths in dupes.items())
        sys.exit(f"[discover] derived name collision, aborting: {detail}")


def discover_feeds(s3, bucket: str, root_prefix: str) -> tuple:
    """Groups real objects under root_prefix by their nearest 'new/' ancestor folder (not just
    the immediate parent - some real feeds nest a partition folder, e.g. pod_id=1/, below 'new/').
    Returns (feeds, skipped) - skipped covers objects with no 'new' ancestor, never silently dropped."""
    root_prefix = root_prefix.rstrip("/") + "/"
    objects = list_source_files(s3, bucket, root_prefix)

    feeds_by_key: dict[tuple, dict] = {}
    skipped_by_key: dict[tuple, dict] = {}
    for obj in objects:
        rel = obj["Key"][len(root_prefix):]
        segments = [s for s in rel.split("/") if s]
        if len(segments) < 2:
            continue  # loose file directly under root - no folder to derive a name from
        path_segments = segments[:-1]  # drop the filename
        if "new" in path_segments:
            new_idx = path_segments.index("new")
            feed_segments = tuple(path_segments[:new_idx])
            if not feed_segments:
                continue  # 'new' sitting directly at root - nothing to name it with
            acc = feeds_by_key.setdefault(feed_segments, {
                "view": sanitize_view_name(feed_segments),
                "s3_prefix": root_prefix + "/".join(feed_segments) + "/new/",
                "count": 0, "total_bytes": 0,
            })
        else:
            acc = skipped_by_key.setdefault(tuple(path_segments), {
                "path": root_prefix + "/".join(path_segments) + "/",
                "count": 0, "total_bytes": 0,
            })
        acc["count"] += 1
        acc["total_bytes"] += obj.get("Size", 0)

    feeds = sorted(feeds_by_key.values(), key=lambda f: f["view"])
    skipped = sorted(skipped_by_key.values(), key=lambda s: s["path"])
    assert_no_name_collisions(feeds)
    return feeds, skipped


NULL_MARKERS = (r"\N", r"\\N")  # source feeds mix both the standard single-backslash MySQL/Postgres
# null convention and a doubled-backslash variant (confirmed via raw byte inspection on spatial_ai) -
# often in the same typed column alongside genuinely empty fields (confirmed on promotional_events),
# which BigQuery's own --null_marker can't reconcile (it only recognizes one marker string at a time
# and breaks empty-field handling for the other). Normalizing both down to true empty here means
# BigQuery's default null handling works uniformly with no custom --null_marker needed downstream.


def append_sync_timestamp(local_path: Path, sync_ts: str):
    """Appends a SYNCSTARTDATETIME column as the last column of every row - matches the
    platform's existing sourcing-table convention (see lulu_sourcing_dev.location_details).
    Every row in a run gets the same value: when this sync actually executed.

    Also normalizes the source's literal null markers (see NULL_MARKERS) down to true empty
    strings, so a later `bq load` doesn't need a custom --null_marker at all."""
    tmp_out = local_path.with_name(local_path.name + ".synctmp")
    with open(local_path, newline="", encoding="utf-8") as src, open(tmp_out, "w", newline="", encoding="utf-8") as dst:
        reader = csv.reader(src)
        writer = csv.writer(dst)
        header = next(reader)
        writer.writerow([*header, "SYNCSTARTDATETIME"])
        for row in reader:
            normalized = ["" if cell in NULL_MARKERS else cell for cell in row]
            writer.writerow([*normalized, sync_ts])
    tmp_out.replace(local_path)


def gcs_upload(local_path: Path, dest_uri: str, dry_run: bool):
    """Uploads one local file to GCS via `gcloud storage cp`.
    In dry-run mode, just prints the destination instead of uploading."""
    if dry_run:
        print(f"  [dry-run] would upload -> {dest_uri}")
        return
    subprocess.run(["gcloud", "storage", "cp", str(local_path), dest_uri], check=True)
    print(f"  -> {dest_uri}")


def list_existing_gcs_uris(prefix_uri: str) -> set:
    """Lists what's already sitting in GCS under this prefix, one call for the whole batch.
    Used to skip re-uploading files a previous run already placed there."""
    result = subprocess.run(["gcloud", "storage", "ls", prefix_uri], capture_output=True, text=True)
    if result.returncode != 0:
        return set()  # nothing uploaded under this prefix yet
    return {line.strip() for line in result.stdout.splitlines() if line.strip()}


def load_bq_manifest() -> dict:
    """Reads the local record of which GCS URIs are already loaded into which BQ table."""
    if BQ_LOAD_MANIFEST.is_file():
        return json.loads(BQ_LOAD_MANIFEST.read_text())
    return {}


def save_bq_manifest(manifest: dict):
    """Writes the manifest back after a successful load, so the next run knows what's done."""
    BQ_LOAD_MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True))


def bq_table_reference(project: str, dataset: str, table: str) -> str:
    return f"{project}:{dataset}.{table}"


def bq_sql_table_reference(project: str, dataset: str, table: str) -> str:
    return f"`{project}.{dataset}.{table}`"


def bq_query_json(query: str, billing_project: str, dry_run: bool = False) -> dict | list:
    """Runs one standard-SQL query and parses BigQuery's JSON response."""
    cmd = ["bq", "query", f"--project_id={billing_project}", "--use_legacy_sql=false", "--format=json"]
    if dry_run:
        cmd.append("--dry_run")
    cmd.append(query)
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def bq_query(query: str, billing_project: str):
    """Runs one standard-SQL DDL/DML query, preserving bq job progress in the terminal."""
    subprocess.run(
        ["bq", "query", f"--project_id={billing_project}", "--use_legacy_sql=false", query],
        check=True,
    )


def bq_remove_table(project: str, dataset: str, table: str, billing_project: str) -> bool:
    """Removes a unique temporary table created by this invocation only."""
    result = subprocess.run(
        ["bq", "rm", "-f", f"--project_id={billing_project}", bq_table_reference(project, dataset, table)],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"  WARNING: could not remove temporary table {bq_table_reference(project, dataset, table)}")
        return False
    return True


def safe_bq_identifier(name: str) -> str:
    """Quotes a client-provided CSV header for BigQuery without permitting a backtick escape."""
    if "`" in name:
        sys.exit(f"CSV header contains an unsupported backtick character: {name!r}")
    return f"`{name}`"


def string_schema(header: list[str]) -> list[dict]:
    return [{"name": name, "type": "STRING", "mode": "NULLABLE"} for name in header]


def write_temp_json(payload: dict | list) -> Path:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False, encoding="utf-8") as tmp:
        json.dump(payload, tmp)
    return Path(tmp.name)


def bq_load_all_strings(uris: list[str], project: str, dataset: str, raw_table: str, header: list[str],
                        billing_project: str):
    """Loads CSV data into a temporary table with an explicit all-STRING schema."""
    schema_path = write_temp_json(string_schema(header))
    try:
        subprocess.run(
            [
                "bq", "load", f"--project_id={billing_project}", "--replace", "--source_format=CSV",
                "--skip_leading_rows=1", "--allow_quoted_newlines", f"--schema={schema_path}",
                bq_table_reference(project, dataset, raw_table), ",".join(uris),
            ],
            check=True,
        )
    finally:
        schema_path.unlink(missing_ok=True)


def bq_autodetected_schema(uris: list[str], project: str, dataset: str, probe_table: str,
                           billing_project: str) -> list[dict]:
    """Gets BigQuery's candidate CSV types using a temporary external-table probe."""
    definition_path = write_temp_json({
        "autodetect": True,
        "csvOptions": {"encoding": "UTF-8", "quote": "\""},
        "sourceFormat": "CSV",
        "sourceUris": uris,
    })
    try:
        subprocess.run(
            [
                "bq", "mk", f"--project_id={billing_project}",
                f"--external_table_definition={definition_path}",
                bq_table_reference(project, dataset, probe_table),
            ],
            check=True,
        )
        probe = subprocess.run(
            [
                "bq", "show", f"--project_id={billing_project}", "--format=json",
                bq_table_reference(project, dataset, probe_table),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        return json.loads(probe.stdout)["schema"]["fields"]
    finally:
        definition_path.unlink(missing_ok=True)


def align_schema_to_header(fields: list[dict], header: list[str]) -> list[dict]:
    """Preserves CSV column order and falls back to STRING for unsupported inferred field types."""
    by_name = {field["name"]: field for field in fields}
    missing = [name for name in header if name not in by_name]
    unexpected = [name for name in by_name if name not in header]
    if missing or unexpected:
        sys.exit(
            "CSV header and inferred BigQuery schema differ. "
            f"Missing in schema: {missing or 'none'}; unexpected in schema: {unexpected or 'none'}."
        )
    aligned = []
    for name in header:
        field_type = by_name[name].get("type", "STRING").upper()
        field_type = {"FLOAT": "FLOAT64"}.get(field_type, field_type)
        aligned.append({
            "name": name,
            "type": field_type if field_type == "STRING" or field_type in SAFE_CAST_TYPES else "STRING",
            "mode": "NULLABLE",
        })
    return aligned


def safe_cast_expression(field: dict) -> str:
    column = safe_bq_identifier(field["name"])
    cleaned = f"NULLIF({column}, '')"
    return cleaned if field["type"] == "STRING" else f"SAFE_CAST({cleaned} AS {field['type']})"


def safe_load_validation_query(project: str, dataset: str, raw_table: str, fields: list[dict]) -> tuple[str, list[dict]]:
    typed_fields = [field for field in fields if field["type"] != "STRING"]
    expressions = ["COUNT(*) AS raw_row_count"]
    for index, field in enumerate(typed_fields):
        column = safe_bq_identifier(field["name"])
        cleaned = f"NULLIF({column}, '')"
        expressions.append(
            f"COUNTIF({cleaned} IS NOT NULL AND SAFE_CAST({cleaned} AS {field['type']}) IS NULL) "
            f"AS invalid_cast_{index}"
        )
    return (
        "SELECT\n  " + ",\n  ".join(expressions) + "\nFROM " + bq_sql_table_reference(project, dataset, raw_table),
        typed_fields,
    )


def query_bytes(dry_run_result: dict | list) -> int:
    if not isinstance(dry_run_result, dict):
        return 0
    return int(dry_run_result.get("statistics", {}).get("query", {}).get("totalBytesProcessed", 0))


def require_safe_query_approval(query: str, billing_project: str, allow_large_safe_cast: bool) -> int:
    estimated_bytes = query_bytes(bq_query_json(query, billing_project, dry_run=True))
    if estimated_bytes > SAFE_LOAD_MAX_QUERY_BYTES and not allow_large_safe_cast:
        raise SafeLoadApprovalRequired(
            "Safe conversion is paused before changing the final table. Its dry run estimates "
            f"{estimated_bytes / 1024 ** 3:.2f} GiB, above the 500 GiB automatic-execution limit. "
            "The all-STRING staging table is retained. Re-run the same command with "
            "--confirm-large-safe-cast after approving the scan."
        )
    return estimated_bytes


def bq_safe_load(uris: list[str], project: str, dataset: str, table: str, replace: bool, dry_run: bool,
                 header: list[str], billing_project: str = BQ_BILLING_PROJECT,
                 allow_large_safe_cast: bool = False) -> bool:
    """Safely loads CSVs through an all-STRING staging table before publishing the final table.

    BigQuery's CSV autodetect samples only part of a source. A late alphanumeric value can therefore
    fail an inferred INT64 load. This workflow retains every source value: it validates every inferred
    non-string conversion over the staging table, downgrades any failing field to STRING, and only then
    publishes the final table. Temporary tables are removed after success and retained on a failure.
    """
    destination = bq_table_reference(project, dataset, table)
    mode = "replace" if replace else "append"
    if dry_run:
        print(
            f"  [dry-run] would safe-load ({mode}) -> {destination} from {len(uris)} file(s): "
            "all-STRING staging, conversion validation, final table, cleanup"
        )
        return True

    run_id = uuid.uuid4().hex[:12]
    raw_table = f"{table}__safe_raw_{run_id}"
    probe_table = f"{table}__safe_schema_probe_{run_id}"
    raw_retained = True
    probe_created = False
    try:
        print(f"  safe-load staging -> {bq_table_reference(project, dataset, raw_table)}")
        bq_load_all_strings(uris, project, dataset, raw_table, header, billing_project)
        raw_info = bq_table_exists(project, dataset, raw_table, billing_project)
        if raw_info is None:
            raise RuntimeError(f"Safe-load staging table was not created: {raw_table}")

        final_info = bq_table_exists(project, dataset, table, billing_project)
        if final_info is not None and not replace:
            candidate_fields = final_info.get("schema", {}).get("fields", [])
        else:
            probe_created = True
            candidate_fields = bq_autodetected_schema(uris, project, dataset, probe_table, billing_project)

        fields = align_schema_to_header(candidate_fields, header)
        validation_sql, typed_fields = safe_load_validation_query(project, dataset, raw_table, fields)
        validation_bytes = require_safe_query_approval(validation_sql, billing_project, allow_large_safe_cast)
        validation_rows = bq_query_json(validation_sql, billing_project)
        validation = validation_rows[0] if validation_rows else {}

        downgraded = []
        for index, field in enumerate(typed_fields):
            invalid_count = int(validation.get(f"invalid_cast_{index}", 0))
            if invalid_count:
                field["type"] = "STRING"
                downgraded.append((field["name"], invalid_count))

        final_sql = (
            ("CREATE OR REPLACE TABLE " if replace or final_info is None else "INSERT INTO ")
            + bq_sql_table_reference(project, dataset, table)
            + "\nSELECT\n  "
            + ",\n  ".join(f"{safe_cast_expression(field)} AS {safe_bq_identifier(field['name'])}" for field in fields)
            + "\nFROM "
            + bq_sql_table_reference(project, dataset, raw_table)
        )
        final_bytes = require_safe_query_approval(final_sql, billing_project, allow_large_safe_cast)
        bq_query(final_sql, billing_project)

        final_info = bq_table_exists(project, dataset, table, billing_project)
        raw_rows = int(raw_info.get("numRows", 0))
        final_rows = int(final_info.get("numRows", 0)) if final_info else -1
        if replace and raw_rows != final_rows:
            raise RuntimeError(f"Safe-load row mismatch: staging={raw_rows:,}, final={final_rows:,}")

        if downgraded:
            summary = ", ".join(f"{name} ({count:,} incompatible value(s))" for name, count in downgraded)
            print(f"  safe-load preserved mixed data as STRING: {summary}")
        print(
            f"  safe-load validated {raw_rows:,} row(s), conversion scan {validation_bytes / 1024 ** 3:.2f} GiB, "
            f"final scan {final_bytes / 1024 ** 3:.2f} GiB"
        )
        raw_retained = not bq_remove_table(project, dataset, raw_table, billing_project)
        if raw_retained:
            print(f"  safe-load final table is complete, but staging remains -> {bq_table_reference(project, dataset, raw_table)}")
        print(f"  safe-load complete -> {destination}")
        return True
    except Exception:
        if raw_retained:
            print(f"  safe-load staging retained for diagnosis -> {bq_table_reference(project, dataset, raw_table)}")
        raise
    finally:
        if probe_created:
            bq_remove_table(project, dataset, probe_table, billing_project)


def bq_table_exists(project: str, dataset: str, table: str, billing_project: str = BQ_BILLING_PROJECT) -> dict | None:
    """Returns bq show's parsed table info if the table already exists, else None.

    Used as a pre-flight check before a --replace (WRITE_TRUNCATE) load: a table name being new
    to *this pipeline's* manifest doesn't mean the table is new to BigQuery - someone/something
    else may have already created and populated it (see the assortment_plan incident, 2026-08-30:
    an inactive POC-era table from a different pipeline got silently replaced because we assumed
    "new S3 feed" meant "new BQ table" without checking first)."""
    result = subprocess.run(
        ["bq", "show", f"--project_id={billing_project}", "--format=json", f"{project}:{dataset}.{table}"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    return json.loads(result.stdout)


def _format_bq_epoch_ms(ms: str | None) -> str:
    if not ms:
        return "unknown"
    return datetime.fromtimestamp(int(ms) / 1000, tz=IST).strftime("%Y-%m-%d %H:%M IST")


_position_lock = threading.Lock()
_next_position = [0]
_thread_position = threading.local()


def get_thread_position(max_workers: int) -> int:
    """Assigns each worker THREAD (not each shard) a fixed tqdm row, reused for every shard that
    thread ever processes - ThreadPoolExecutor reuses the same pool of worker threads across all
    submitted tasks, so this gives each of the up-to-max_workers concurrent downloads its own
    stable terminal row instead of the bars fighting over the same line."""
    if not hasattr(_thread_position, "value"):
        with _position_lock:
            _thread_position.value = _next_position[0] % max_workers
            _next_position[0] += 1
    return _thread_position.value


def download_with_progress(s3, bucket: str, key: str, dest_path: Path, size: int, position: int, desc: str):
    """Downloads via boto3's Callback hook, driving a tqdm bar pinned to `position` so concurrent
    downloads each get their own stable terminal row instead of garbling each other's output."""
    with tqdm(total=size, unit="B", unit_scale=True, unit_divisor=1024, desc=desc,
              position=position, leave=False, dynamic_ncols=True) as bar:
        retry_call(lambda: s3.download_file(bucket, key, str(dest_path), Callback=bar.update))


def download_shard(s3, env: dict, shard: int, total: int, key: str, suffix: str,
                    sync_ts: str, size: int, max_workers: int) -> Path:
    """Downloads one shard and appends the sync timestamp, returning the local temp path.
    Upload happens separately (upload_shard), only after the whole batch's downloads finish -
    see sync_batch()."""
    print(f"[{shard}/{total}] downloading s3://{env['S3_BUCKET']}/{key}")
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp_path = Path(tmp.name)
    position = get_thread_position(max_workers)
    desc = f"[{shard}/{total}] {Path(key).name}"
    download_with_progress(s3, env["S3_BUCKET"], key, tmp_path, size, position, desc)
    append_sync_timestamp(tmp_path, sync_ts)
    return tmp_path


def upload_shard(shard: int, total: int, tmp_path: Path, dest_uri: str, dry_run: bool):
    """Uploads one already-downloaded-and-transformed shard via `gcloud storage cp` - deliberately
    NOT the google-cloud-storage Python client. That approach was tried and reverted: it lost
    `gcloud`'s automatic parallel-composite-upload for large files (transfer_manager's chunked-
    concurrent alternative has no progress-callback support), measured at roughly 5-8x slower on
    this session's own large shards (~1 MB/s vs 5-8+ MiB/s). No live upload percentage as a
    result - just start/done per shard - but real throughput matters more here than a bar."""
    print(f"[{shard}/{total}] uploading -> {dest_uri}")
    gcs_upload(tmp_path, dest_uri, dry_run)


def sync_batch(s3, env: dict, batch: list, files_total: int, sync_ts: str, dry_run: bool, max_workers: int):
    """Downloads every shard in `batch` concurrently and waits for ALL of them to finish, THEN
    uploads every successfully-downloaded shard in the batch concurrently - two clean phases per
    batch instead of each shard interleaving its own download and upload independently. Easier to
    watch (a batch is either 'downloading' or 'uploading', not a jumble of both), at the same
    aggregate concurrency as before.

    If a download fails, the rest of the batch's downloads still finish; whatever DID download
    successfully still gets uploaded (nothing wasted); the first error found (across either phase)
    is raised only after cleanup - safe because everything here is idempotent, so a resumed run
    just re-checks this same batch, including the shard whose download failed."""
    downloaded: dict[int, tuple[Path, str]] = {}
    errors = []

    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futures = {
            pool.submit(download_shard, s3, env, shard, files_total, key, suffix, sync_ts, size, max_workers): (shard, dest_uri)
            for shard, key, dest_uri, suffix, size in batch
        }
        for fut in as_completed(futures):
            shard, dest_uri = futures[fut]
            try:
                downloaded[shard] = (fut.result(), dest_uri)
            except Exception as e:  # noqa: BLE001 - collected, not swallowed; see docstring
                errors.append(e)

    try:
        with ThreadPoolExecutor(max_workers=max_workers) as pool:
            futures = [
                pool.submit(upload_shard, shard, files_total, tmp_path, dest_uri, dry_run)
                for shard, (tmp_path, dest_uri) in downloaded.items()
            ]
            for fut in as_completed(futures):
                try:
                    fut.result()
                except Exception as e:  # noqa: BLE001 - collected, not swallowed; see docstring
                    errors.append(e)
    finally:
        for tmp_path, _ in downloaded.values():
            tmp_path.unlink(missing_ok=True)

    if errors:
        raise errors[0]


def sync(s3, env: dict, s3_prefix: str, view: str, dry_run: bool, load_to_bq: bool,
         bq_project: str, bq_dataset: str, bq_table: str, bq_replace: bool, gcs_date: str = None,
         bq_billing_project: str = BQ_BILLING_PROJECT, max_workers: int = 6,
         confirm_replace_existing: bool = False, confirm_large_safe_cast: bool = False):
    """Pulls every file under the S3 prefix and uploads each to GCS.
    Optionally bq-loads the whole batch into BigQuery once the uploads finish.

    Idempotent by design - running this twice on the same source files never duplicates
    anything: batch_ts is derived from the source data (not wall-clock time), so re-runs
    compute the exact same GCS destinations; files already there are skipped, not re-uploaded;
    and a local manifest tracks what's already been bq-loaded so the same rows never append twice.

    Not-yet-uploaded shards are grouped into batches of --max-workers (default 6) and processed
    two phases per batch: download the whole batch concurrently, wait for all of it to finish,
    THEN upload the whole batch concurrently - see sync_batch(). If any shard in a batch fails,
    the rest of that batch still finishes before the first exception is raised - safe because
    everything here is idempotent, so a resumed run just re-checks that same batch."""
    files = list_source_files(s3, env["S3_BUCKET"], s3_prefix)
    if not files:
        print(f"(no objects under s3://{env['S3_BUCKET']}/{s3_prefix} - nothing to sync)")
        return

    date_str = gcs_date or datetime.now(timezone.utc).strftime("%Y-%m-%d")
    batch_ts = max(obj["LastModified"] for obj in files).strftime("%Y%m%d%H%M%S")
    sync_ts = datetime.now(IST).strftime("%Y-%m-%d %H:%M:%S")  # baked into every row as SYNCSTARTDATETIME

    prefix_uri = f"gs://{GCS_BUCKET}/{date_str}/{view}/{view}_{batch_ts}_"
    folder_uri = f"gs://{GCS_BUCKET}/{date_str}/{view}/"
    print(f"Found {len(files)} file(s). Target: {folder_uri}<exact S3 source filename>")
    # Destination uses the exact S3 source basename (see module docstring). A shard already
    # uploaded under the older generic <view>_<batch_ts>_<shard> name is still recognized as
    # done via that fallback - list the whole view folder and match by basename either way so
    # nothing gets mistaken for missing and re-uploaded under a second, duplicate name.
    existing_basenames = (
        {u.rsplit("/", 1)[-1] for u in list_existing_gcs_uris(folder_uri + "*")} if not dry_run else set()
    )

    all_uris = []
    todo = []
    for shard, obj in enumerate(files, start=1):
        key = obj["Key"]
        suffix = Path(key).suffix or ".csv"
        generic_name = f"{view}_{batch_ts}_{shard}{suffix}"
        source_name = Path(key).name
        if source_name in existing_basenames:
            found_name = source_name
        elif generic_name in existing_basenames:
            found_name = generic_name
        else:
            found_name = None
        dest_uri = f"{folder_uri}{found_name or source_name}"
        all_uris.append(dest_uri)
        if found_name:
            print(f"[{shard}/{len(files)}] s3://{env['S3_BUCKET']}/{key}")
            print(f"  [skip] already in GCS -> {dest_uri}")
            continue
        todo.append((shard, key, dest_uri, suffix, obj.get("Size", 0)))

    for i in range(0, len(todo), max_workers):
        batch = todo[i:i + max_workers]
        print(f"--- batch {i // max_workers + 1}/{-(-len(todo) // max_workers)}: downloading {len(batch)} shard(s) ---")
        sync_batch(s3, env, batch, len(files), sync_ts, dry_run, max_workers)

    if load_to_bq:
        table = bq_table or view
        table_key = f"{bq_project}.{bq_dataset}.{table}"
        manifest = load_bq_manifest()
        already_loaded = set(manifest.get(table_key, []))

        if bq_replace and table_key not in manifest:
            # First time THIS pipeline has touched table_key. If it already exists in BQ, it was
            # created by something else - never assume "new feed to us" means "safe to truncate".
            existing = bq_table_exists(bq_project, bq_dataset, table, bq_billing_project)
            if existing is not None:
                print(
                    f"\n  WARNING: {table_key} already exists in BigQuery, but this pipeline has no "
                    f"record of ever loading it (not in {BQ_LOAD_MANIFEST.name}).\n"
                    f"    Created: {_format_bq_epoch_ms(existing.get('creationTime'))}   "
                    f"Last modified: {_format_bq_epoch_ms(existing.get('lastModifiedTime'))}   "
                    f"Rows: {existing.get('numRows', '?')}\n"
                    f"    --load-to-bq's default --replace (WRITE_TRUNCATE) would wipe out whatever "
                    f"is there now - not recoverable afterward.\n"
                )
                if dry_run:
                    print("  [dry-run] would refuse without --confirm-replace-existing - stopping here.")
                    return
                if not confirm_replace_existing:
                    sys.exit(
                        f"Refusing to replace {table_key}: it already exists and wasn't created by this "
                        f"pipeline. Verify with the team it's safe to overwrite, then re-run with "
                        f"--confirm-replace-existing (or use --bq-append to add rows instead of truncating)."
                    )
                print("  --confirm-replace-existing passed - proceeding with replace.\n")

        if bq_replace:
            # Replace rebuilds the whole table every time - it must always load the FULL
            # current file set, never a partial "new only" subset, or a re-run would wipe
            # out rows whose source file isn't part of this run's batch.
            if already_loaded == set(all_uris):
                print(f"  bq load skipped -> {table_key} already reflects this exact {len(all_uris)}-file set")
                return
            new_uris = all_uris
        else:
            new_uris = [u for u in all_uris if u not in already_loaded]
            if not new_uris:
                print(f"  bq load skipped -> {table_key} already has all {len(all_uris)} file(s) loaded")
                return
        header = [*read_source_header(s3, env["S3_BUCKET"], files[0]["Key"]), "SYNCSTARTDATETIME"]
        bq_safe_load(
            new_uris, bq_project, bq_dataset, table, bq_replace, dry_run, header,
            bq_billing_project, confirm_large_safe_cast,
        )
        if not dry_run:
            # Replace truncates the table to exactly new_uris (== all_uris) - the manifest must
            # match, not union with already_loaded, or a later append run would think stale
            # pre-replace files are still present.
            manifest[table_key] = sorted(set(new_uris)) if bq_replace else sorted(already_loaded | set(new_uris))
            save_bq_manifest(manifest)


def run_discover(s3, env: dict, root_prefix: str, dry_run: bool, load_to_bq: bool,
                  bq_project: str, bq_dataset: str, bq_replace: bool, gcs_date: str = None,
                  bq_billing_project: str = BQ_BILLING_PROJECT, max_workers: int = 6,
                  confirm_replace_existing: bool = False, confirm_large_safe_cast: bool = False):
    """Discovers every real feed under root_prefix and syncs each one in turn.
    One bad feed doesn't abort the batch - failures are collected and summarized at the end."""
    feeds, skipped = discover_feeds(s3, env["S3_BUCKET"], root_prefix)

    if skipped:
        print(f"[discover] {len(skipped)} path(s) found with no 'new' ancestor - not synced, review manually:")
        for s in skipped:
            print(f"  {s['path']}  ({s['count']} file(s), {s['total_bytes']} bytes)")

    if not feeds:
        print(f"[discover] 0 feeds found under s3://{env['S3_BUCKET']}/{root_prefix} - nothing to sync")
        return

    print(f"[discover] {len(feeds)} feed(s) found under s3://{env['S3_BUCKET']}/{root_prefix}:")
    for f in feeds:
        print(f"  {f['view']}  <- {f['s3_prefix']}  ({f['count']} file(s), {f['total_bytes']} bytes)")

    results = []
    for f in feeds:
        try:
            sync(
                s3, env, f["s3_prefix"], f["view"], dry_run, load_to_bq,
                bq_project, bq_dataset, None, bq_replace, gcs_date, bq_billing_project, max_workers,
                confirm_replace_existing, confirm_large_safe_cast,
            )
            results.append((f["view"], True))
        except (ClientError, subprocess.CalledProcessError) as e:
            print(f"  [FAILED] {f['view']}: {e}")
            results.append((f["view"], False))

    ok = sum(1 for _, success in results if success)
    print(f"[discover] {ok}/{len(results)} feed(s) synced.")
    if ok < len(results):
        sys.exit(1)


def main():
    """Parses CLI args, loads secrets, and runs either --discover or a single manual sync.
    Translates AWS/gcloud/bq errors into a clean exit message instead of a raw traceback."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--discover", action="store_true",
                         help="Auto-discover every real feed under --discover-root and sync all of them")
    parser.add_argument("--discover-root", default=None,
                         help=f"Only valid with --discover. Default: {DEFAULT_DISCOVER_ROOT}")
    parser.add_argument("--s3-prefix", default=None, help="Source prefix inside the Lululemon bucket (manual mode)")
    parser.add_argument("--view", default=None, help="View/feed name used in the GCS filename (manual mode)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be copied/loaded without doing it")
    parser.add_argument("--load-to-bq", action="store_true",
                        help="Safely load through all-STRING staging, conversion validation, and typed final table")
    parser.add_argument("--bq-project", default=BQ_PROJECT, help=f"Default: {BQ_PROJECT}")
    parser.add_argument("--bq-dataset", default=BQ_DATASET, help=f"Default: {BQ_DATASET}")
    parser.add_argument("--bq-billing-project", default=BQ_BILLING_PROJECT,
                         help=f"Job submission/billing project for bq load. Default: {BQ_BILLING_PROJECT} "
                              "(this account often lacks bigquery.jobs.create on --bq-project itself)")
    parser.add_argument("--bq-table", default=None, help="Manual mode only. Default: same as --view")
    parser.add_argument("--bq-append", action="store_true", help="Append instead of the default WRITE_TRUNCATE (replace)")
    parser.add_argument("--confirm-replace-existing", action="store_true",
                         help="Required to --replace a BQ table this pipeline has never loaded before "
                              "(i.e. it already existed from some other source) - safety gate, see sync()")
    parser.add_argument("--confirm-large-safe-cast", action="store_true",
                        help="Allow safe conversion queries estimated above 500 GiB. Required only for very large feeds")
    parser.add_argument("--gcs-date", default=GCS_DATE_FOLDER,
                         help=f"GCS destination date-folder. Default: {GCS_DATE_FOLDER} (fixed - doesn't change day to day)")
    parser.add_argument("--max-workers", type=int, default=6,
                         help="Number of shards processed concurrently. Default: 6")
    args = parser.parse_args()

    if args.discover:
        if args.view or args.s3_prefix or args.bq_table:
            parser.error("--discover cannot be combined with --view/--s3-prefix/--bq-table")
        discover_root = args.discover_root or DEFAULT_DISCOVER_ROOT
    else:
        if args.discover_root is not None:
            parser.error("--discover-root only applies with --discover")
        if not args.view:
            parser.error("--view is required unless --discover is set")
        if not args.s3_prefix:
            parser.error("--s3-prefix is required in manual mode (no guessed fallback)")

    bq_replace = not args.bq_append

    env = load_env(ENV_FILE)
    try:
        s3 = get_s3_client(env)
        if args.discover:
            run_discover(
                s3, env, discover_root, args.dry_run, args.load_to_bq,
                args.bq_project, args.bq_dataset, bq_replace, args.gcs_date, args.bq_billing_project,
                args.max_workers, args.confirm_replace_existing, args.confirm_large_safe_cast,
            )
        else:
            sync(
                s3, env, args.s3_prefix, args.view, args.dry_run, args.load_to_bq,
                args.bq_project, args.bq_dataset, args.bq_table, bq_replace, args.gcs_date, args.bq_billing_project,
                args.max_workers, args.confirm_replace_existing, args.confirm_large_safe_cast,
            )
    except ClientError as e:
        sys.exit(f"AWS error: {e.response['Error']}")
    except subprocess.CalledProcessError as e:
        sys.exit(f"gcloud/bq command failed (exit {e.returncode}) - is gcloud authenticated for this project?")
    except SafeLoadApprovalRequired as e:
        sys.exit(str(e))


if __name__ == "__main__":
    main()
