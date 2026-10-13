#!/usr/bin/env python3
"""Talk to the shared Lululemon S3 bucket via the IA -> Lululemon cross-account role chain.

The bucket (lll-gpt-size-planning-prd) lives in Lululemon's AWS account. Reaching it
requires two chained sts:AssumeRole calls: IA user -> role in IA's own account -> role in
Lululemon's account (both hops need the same ExternalId - the trust policy's Condition
applies to the whole statement, not just the cross-account principal).

Config/secrets are read from config/lulu_dev_s3.env (see the .example in the same folder).

Usage:
  scripts/lulu_s3_client.py whoami
  scripts/lulu_s3_client.py list                                 # compact per-feed summary (bucket-wide)
  scripts/lulu_s3_client.py list --prefix PREFIX                  # one-level dir listing: folders + files right there
  scripts/lulu_s3_client.py list --prefix PREFIX --files          # full recursive per-file listing under PREFIX
  scripts/lulu_s3_client.py get KEY --out LOCAL_PATH
  scripts/lulu_s3_client.py sync [--prefix PREFIX] --out LOCAL_DIR
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time
from collections import defaultdict
from datetime import timedelta, timezone
from pathlib import Path

IST = timezone(timedelta(hours=5, minutes=30))

import boto3
from botocore.exceptions import ClientError, SSLError

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("LULU_S3_ENV_FILE", ROOT / "config/lulu_dev_s3.env"))
CA_BUNDLE_CACHE = ROOT / "config/.lulu_s3_ca_bundle.pem"


def load_env(path: Path) -> dict:
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
    env.setdefault("S3_PREFIX", "")
    env.setdefault("AWS_REGION", "us-east-1")
    return env


def build_zscaler_ca_bundle() -> str:
    """Merge certifi's CA bundle with the Zscaler root from the macOS System Keychain.

    Needed because this network runs Zscaler TLS inspection: macOS `curl` trusts it via
    the System Keychain automatically, but Python's OpenSSL/certifi stack does not, so
    boto3 fails with SSL: CERTIFICATE_VERIFY_FAILED unless the Zscaler root is added.
    """
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


def assume_role_chain(env: dict, verify) -> tuple[boto3.session.Session, str]:
    """Returns (final session, final identity ARN).

    The identity ARN comes straight from hop 2's AssumeRole response (AssumedRoleUser.Arn)
    rather than a separate get_caller_identity call - a 3rd consecutive call to the STS host
    in one run reliably trips the corporate Zscaler proxy's "Hosting Providers" block, so it's
    avoided entirely rather than retried around.
    """
    base = boto3.session.Session(
        aws_access_key_id=env["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=env["AWS_SECRET_ACCESS_KEY"],
    )
    sts1 = base.client("sts", region_name=env["AWS_REGION"], verify=verify)
    creds1 = sts1.assume_role(
        RoleArn=env["FIRST_ROLE_ARN"], RoleSessionName="lulu-s3-hop1",
        ExternalId=env["EXTERNAL_ID"],
    )["Credentials"]

    hop1 = boto3.session.Session(
        aws_access_key_id=creds1["AccessKeyId"],
        aws_secret_access_key=creds1["SecretAccessKey"],
        aws_session_token=creds1["SessionToken"],
    )
    sts2 = hop1.client("sts", region_name=env["AWS_REGION"], verify=verify)
    resp2 = sts2.assume_role(
        RoleArn=env["SECOND_ROLE_ARN"], RoleSessionName="lulu-s3-hop2",
        ExternalId=env["EXTERNAL_ID"],
    )
    creds2 = resp2["Credentials"]

    final_session = boto3.session.Session(
        aws_access_key_id=creds2["AccessKeyId"],
        aws_secret_access_key=creds2["SecretAccessKey"],
        aws_session_token=creds2["SessionToken"],
    )
    return final_session, resp2["AssumedRoleUser"]["Arn"]


def get_final_session(env: dict):
    """Run the two-hop assume-role chain, retrying once with a Zscaler-aware CA bundle on SSL failure.

    Returns (session, identity_arn, verify) so callers can build whichever client they need
    (s3, ...) from the same final assumed-role credentials and the same verify setting.
    """
    verify = None
    for attempt in (1, 2):
        try:
            session, arn = assume_role_chain(env, verify)
            return session, arn, verify
        except SSLError:
            if attempt == 2:
                raise
            verify = build_zscaler_ca_bundle()


def get_s3_client(env: dict):
    session, _arn, verify = get_final_session(env)
    return session.client("s3", region_name=env["AWS_REGION"], verify=verify)


def retry_call(fn, attempts=3, delay=1.5):
    """A couple of these AWS calls intermittently hit a corporate-proxy network block
    (unrelated to AWS permissions) that surfaces as a response-parsing error. Retrying
    the same call a couple times has reliably gone through in practice."""
    last_err = None
    for i in range(attempts):
        try:
            return fn()
        except Exception as e:  # noqa: BLE001 - deliberately broad, see docstring
            last_err = e
            if i < attempts - 1:
                time.sleep(delay)
    raise last_err


def cmd_whoami(env):
    _session, arn, _verify = get_final_session(env)
    print(arn)


def classify_key(key: str) -> tuple[str, str, str]:
    """Splits a key into (direction, feed, subfolder) for the compact summary view.

    Expects the Impact_Analytics/<inbound|outbound>/<feed>/<subfolder.../<file> convention
    every real feed follows. Falls back to '(unknown)'/'(root)' for anything that doesn't fit,
    rather than raising, since a stray key shouldn't break the whole listing."""
    parts = key.split("/")
    if len(parts) < 4 or parts[0] != "Impact_Analytics":
        return ("(unknown)", "(unknown)", "(root)")
    direction, feed = parts[1], parts[2]
    subfolder = "/".join(parts[3:-1]) or "(root)"
    return (direction, feed, subfolder)


def human_size(n: float) -> str:
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1024 or unit == "TB":
            return f"{n:,.2f} {unit}" if unit != "B" else f"{int(n)} B"
        n /= 1024
    return f"{n:,.2f} TB"


def cmd_list(env, args):
    s3 = get_s3_client(env)
    prefix = args.prefix if args.prefix is not None else env["S3_PREFIX"]
    paginator = s3.get_paginator("list_objects_v2")
    objects = [
        obj
        for page in retry_call(lambda: list(paginator.paginate(Bucket=env["S3_BUCKET"], Prefix=prefix)))
        for obj in page.get("Contents", [])
        if not obj["Key"].endswith("/")
    ]
    if not objects:
        print(f"(no objects under s3://{env['S3_BUCKET']}/{prefix})")
        return

    if args.files:
        for obj in objects:
            print(f"{obj['LastModified']}  {obj['Size']:>12}  {obj['Key']}")
        return

    if args.prefix is not None:
        cmd_list_dir(env, s3, prefix, objects)
        return

    groups: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
    for obj in objects:
        groups[classify_key(obj["Key"])].append(obj)

    latest_obj = max(objects, key=lambda o: o["LastModified"])
    _latest_direction, latest_feed, _latest_subfolder = classify_key(latest_obj["Key"])
    latest_ist = latest_obj["LastModified"].astimezone(IST)

    feed_groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for (direction, feed, _subfolder), items in groups.items():
        feed_groups[(direction, feed)].extend(items)

    header = ("Direction", "Feed", "Files", "Size", "Oldest", "Latest")
    computed = []
    for (direction, feed), items in feed_groups.items():
        total_bytes = sum(o["Size"] for o in items)
        oldest = min(o["LastModified"] for o in items)
        latest = max(o["LastModified"] for o in items)
        computed.append((latest, direction, feed, len(items), total_bytes, oldest))

    computed.sort(key=lambda c: c[0], reverse=True)  # most recently updated feed first

    rows = [
        (direction, feed, str(count), human_size(total_bytes), oldest.strftime("%Y-%m-%d"), latest.strftime("%Y-%m-%d %H:%M"))
        for latest, direction, feed, count, total_bytes, oldest in computed
    ]

    total_files = sum(int(r[2]) for r in rows)
    total_bytes = sum(o["Size"] for o in objects)

    print()
    print(f"Last updated: {latest_ist.strftime('%Y-%m-%d %H:%M IST')} ({latest_feed})")
    print(f"Total files in scope: {len(objects):,}")
    print(f"Total size: {human_size(total_bytes)}")
    print(f"Total feeds: {len(rows)}\n")

    widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(header)]

    def fmt_row(cells):
        return "  ".join(c.ljust(w) for c, w in zip(cells, widths))

    print(fmt_row(header))
    print(fmt_row(["-" * w for w in widths]))
    for row in rows:
        print(fmt_row(row))

    print("\n(use --files for the full per-file listing)")


def cmd_list_dir(env, s3, prefix, objects):
    """One-level directory view for an explicit --prefix: immediate subfolders (aggregated,
    recursively counted) plus any files directly at this prefix level - what actually lives
    right here, not an aggregate across the whole feed."""
    folders: dict[str, list[dict]] = defaultdict(list)
    direct_files: list[dict] = []
    for obj in objects:
        rel = obj["Key"][len(prefix):] if obj["Key"].startswith(prefix) else obj["Key"]
        if "/" in rel:
            top = rel.split("/", 1)[0]
            folders[top].append(obj)
        else:
            direct_files.append(obj)

    total_bytes = sum(o["Size"] for o in objects)
    latest_obj = max(objects, key=lambda o: o["LastModified"])

    print()
    print(f"s3://{env['S3_BUCKET']}/{prefix}")
    print(f"Last updated: {latest_obj['LastModified'].astimezone(IST).strftime('%Y-%m-%d %H:%M IST')}")
    print(f"Total files in scope: {len(objects):,}   Total size: {human_size(total_bytes)}")

    if folders:
        computed = []
        for name, items in folders.items():
            total = sum(o["Size"] for o in items)
            oldest = min(o["LastModified"] for o in items)
            latest = max(o["LastModified"] for o in items)
            computed.append((latest, name, len(items), total, oldest))
        computed.sort(reverse=True)  # most recently updated folder first

        header = ("Folder", "Files", "Size", "Oldest", "Latest")
        rows = [
            (f"{name}/", str(count), human_size(total), oldest.strftime("%Y-%m-%d"), latest.strftime("%Y-%m-%d %H:%M"))
            for latest, name, count, total, oldest in computed
        ]
        widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(header)]

        def fmt_row(cells):
            return "  ".join(c.ljust(w) for c, w in zip(cells, widths))

        print(f"\n{len(folders)} folder(s):")
        print(fmt_row(header))
        print(fmt_row(["-" * w for w in widths]))
        for row in rows:
            print(fmt_row(row))

    if direct_files:
        print(f"\n{len(direct_files)} file(s) directly under this prefix:")
        for obj in sorted(direct_files, key=lambda o: o["LastModified"], reverse=True):
            rel = obj["Key"][len(prefix):] if obj["Key"].startswith(prefix) else obj["Key"]
            print(f"  {obj['LastModified']}  {obj['Size']:>12}  {rel}")

    if not folders and not direct_files:
        print("(nothing found)")

    print("\n(use --files for the full recursive per-file listing under this prefix)")


def cmd_get(env, args):
    s3 = get_s3_client(env)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    retry_call(lambda: s3.download_file(env["S3_BUCKET"], args.key, str(out_path)))
    print(f"Downloaded s3://{env['S3_BUCKET']}/{args.key} -> {out_path}")


def cmd_sync(env, args):
    s3 = get_s3_client(env)
    prefix = args.prefix if args.prefix is not None else env["S3_PREFIX"]
    out_dir = Path(args.out)
    paginator = s3.get_paginator("list_objects_v2")
    downloaded = 0
    for page in retry_call(lambda: list(paginator.paginate(Bucket=env["S3_BUCKET"], Prefix=prefix))):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith("/"):
                continue
            rel = Path(key).relative_to(prefix) if prefix and key.startswith(prefix) else Path(key)
            dest = out_dir / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            retry_call(lambda k=key, d=dest: s3.download_file(env["S3_BUCKET"], k, str(d)))
            print(f"  {key} -> {dest}")
            downloaded += 1
    print(f"Synced {downloaded} object(s) from s3://{env['S3_BUCKET']}/{prefix} to {out_dir}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("whoami", help="Print the final assumed-role identity")

    p_list = sub.add_parser("list", help="List objects under a prefix")
    p_list.add_argument("--prefix", default=None)
    p_list.add_argument("--files", action="store_true", help="Full per-file listing instead of the compact summary")

    p_get = sub.add_parser("get", help="Download a single object")
    p_get.add_argument("key")
    p_get.add_argument("--out", required=True)

    p_sync = sub.add_parser("sync", help="Download every object under a prefix")
    p_sync.add_argument("--prefix", default=None)
    p_sync.add_argument("--out", required=True)

    args = parser.parse_args()
    env = load_env(ENV_FILE)

    try:
        if args.command == "whoami":
            cmd_whoami(env)
        elif args.command == "list":
            cmd_list(env, args)
        elif args.command == "get":
            cmd_get(env, args)
        elif args.command == "sync":
            cmd_sync(env, args)
    except ClientError as e:
        sys.exit(f"AWS error: {e.response['Error']}")


if __name__ == "__main__":
    main()
