# Lululemon S3 Operations Quick Start

This folder is self-contained. Copy it anywhere. It does not need a Cursor folder or another user's home directory.

## Set up once, about 5 minutes

```bash
cd <wherever-you-copied-this-folder>/lululemon_s3_operations
python3 -m pip install -r requirements.txt
cp config/lulu_dev_s3.env.example config/lulu_dev_s3.env
chmod 600 config/lulu_dev_s3.env
gcloud auth login
```

Fill `config/lulu_dev_s3.env` with credentials received through the approved secret channel. Do not send this completed file through email, chat, Confluence, or Git.

## Five commands

| Run this | What it does |
|---|---|
| `./lulu-s3 whoami` | Confirms AWS access to the read-only Lululemon bucket. Run this first. |
| `./lulu-s3 list` | Lists all client feeds with their sizes and latest update time. |
| `./lulu-s3 list --prefix "Impact_Analytics/outbound/<feed>/new/" --files` | Lists every active source file in one feed, with exact key, bytes, and timestamp. |
| `./lulu-sync --view <target_view> --s3-prefix "Impact_Analytics/outbound/<feed>/new/<exact-batch-prefix>" --max-workers 3` | Transfers one approved batch to `gs://client_data_lululemon/2026-08-03/<target_view>/`, normalizes null markers, and adds `SYNCSTARTDATETIME`. |
| `./lulu-sync --view <target_view> --s3-prefix "Impact_Analytics/outbound/<feed>/new/<exact-batch-prefix>" --max-workers 3 --load-to-bq` | Safely loads the verified GCS batch into `lululemon-01042025.lulu_sourcing_dev.<target_view>`. |

## Version rule

Use `<feed>` the first time. Use `<feed>_v1` for its first re-share, then `_v2`, `_v3`, and so on. Never overwrite or append to an older version without explicit approval.

## Stop rules

1. The client S3 bucket is read-only. Never delete, move, overwrite, copy, or upload under `Impact_Analytics/outbound/`.
2. If `new/` contains more than one batch timestamp, stop and confirm the exact batch.
3. If schema, file count, version name, or BigQuery conversion result is unclear, stop before `--load-to-bq`.

## Fixes for common failures

| Error | Fix |
|---|---|
| GCP reauthentication error | Run `gcloud auth login`, then repeat the same command. |
| AWS AssumeRole error | Check `config/lulu_dev_s3.env` has all values, then request approved access. |
| BigQuery parsing or type error | Do not run a plain `bq load --autodetect`. Share the error with the engagement owner. |

**Next action:** fill `config/lulu_dev_s3.env`, then run `./lulu-s3 whoami`.
