---
name: inbound-drop-eda
description: >-
  Run the Inbound Drop Agent on a client GCS view / BQ table: auto EDA metrics
  and a Data Drop Brief with Green/Amber/Red verdict. Use when the user invokes
  /inbound-drop-eda, says a file landed in GCS, needs a drop sign-off pack, or
  wants inbound drop agent / data drop brief.
---

# Inbound Drop Agent (`/inbound-drop-eda`)

**Phase 1:** Manual trigger — CLI and/or agent fill narrative on top of BQ metrics.  
**Drop Watcher:** `scripts/drop_watch.py` scans local/GCS for files newer than `last_seen`, then runs the same EDA + Tier 5 diff.

## Invoke

```
/inbound-drop-eda view=inventory_snapshot gcs_path=gs://<bucket>/2026-05-28/inventory_snapshot_20260528143000.csv
```

| Parameter | Required | Notes |
|-----------|----------|-------|
| `view` | Yes | Key in `findings/inbound_drop_agent/view_profiles.yaml` |
| `gcs_path` | No | Full `gs://` path; drives SYNCSTARTDATETIME + folder date |
| `sample_date` | No | Defaults to profile `join_checks[].sample_date` |

## Agent workflow (required)

1. **Read profile** — `findings/inbound_drop_agent/view_profiles.yaml` for `view`.
2. **Run runner** (if `bq` CLI available and user approves cost):
   ```bash
   python3 scripts/inbound_drop_eda.py --view <view> --gcs-path "<gcs_path>" --write-brief
   ```
3. **If CLI unavailable** — run Tier 0–2 from `queries/eda/inbound_drop_eda_pack.sql` via BQ MCP / `bq query` with `--project_id=lululemon-data-scan`; never assume column names without `INFORMATION_SCHEMA`.
4. **Open brief** — `findings/inbound_drop_agent/briefs/<view>_<date>.md` (or create from `data_drop_brief_template.md`).
5. **Apply verdict rules** (README) — includes **Tier 5 diff** vs `metrics_history.json`:
   - **Red:** table missing; grain dup % &gt; 0.1%; join orphan &gt; 50%; row Δ &gt; 30%; **column type change** vs prior
   - **Amber:** new/dropped columns; sentinel spike; join orphan drift &gt; 5 pp; row Δ 10–30%
   - **Green:** otherwise
6. **Drop watcher** (optional — new landings):
   ```bash
   python3 scripts/drop_watch.py --once --source local
   ```
   Config: `watcher_config.yaml` (copy from `watcher_config.example.yaml`). State: `drop_watcher_state.json`.
7. **Edit brief** — Set `{{REVIEWER}}`, flesh out blockers, client-specific actions; bump changelog.
8. **Reply** with: verdict, path to brief, top 3 blockers, suggested DAG action.

## Cost guardrails

- Run `__TABLES__` / `INFORMATION_SCHEMA` first (free/cheap).
- **Always** filter large raw tables on `date_column` + `sample_date` for grain, sentinels, joins.
- Do not full-scan `inventory_snapshot_cleaned` without a date filter.

## Add a new view

1. Add block under `view_profiles.yaml` (`gcs_view`, `bq_table`, `grain_columns`, optional `date_column`, `join_checks`).
2. Test: `python3 scripts/inbound_drop_eda.py --view <key> --write-brief`
3. Optional deep SQL in `queries/<table>_eda.sql` for Tier 3+.

## Canonical paths

| Role | Path |
|------|------|
| Runbook | `findings/inbound_drop_agent/README.md` |
| Profiles | `findings/inbound_drop_agent/view_profiles.yaml` |
| Template | `findings/inbound_drop_agent/data_drop_brief_template.md` |
| Forum deck | `findings/inbound_drop_agent/forum_deck_outline.md` |
| SQL pack | `queries/eda/inbound_drop_eda_pack.sql` |
| Runner | `scripts/inbound_drop_eda.py` |
| Watcher | `scripts/drop_watch.py` |
| Shared lib | `scripts/lib/inbound_drop_lib.py` |

## GCS naming (IA)

`YYYY-MM-DD/<view>_YYYYMMDDHHMMSS.csv` → `SYNCSTARTDATETIME` from filename or folder date. See `reference_docs/Training/DI_Course_3_Ingestion_Basics_for_Analytics_Teams.md`.

## Do not

- Commit GCS credentials or bucket paths with secrets.
- `CALL` Postgres sync or alter GSM without explicit user approval.
- Mark **Green** without join + grain checks when profile defines them.
