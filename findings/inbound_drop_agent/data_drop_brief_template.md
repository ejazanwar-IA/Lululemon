# Data Drop Brief — {{VIEW_NAME}}

`Generated: {{GENERATED_AT}}.`  
`Agent run: {{AGENT_RUN_LINE}}.`

---

## Executive summary

| Field | Value |
|-------|-------|
| **GCS view** | `{{GCS_VIEW}}` |
| **Drop folder / file** | `{{GCS_PATH}}` |
| **Inferred SYNCSTARTDATETIME** | {{SYNCSTARTDATETIME}} |
| **BQ table profiled** | `{{BQ_TABLE_FQN}}` |
| **Verdict** | **{{VERDICT}}** — {{VERDICT_ONE_LINER}} |

---

## What arrived

| Check | Result |
|-------|--------|
| Table exists in BQ | {{TABLE_EXISTS}} |
| Row count | {{ROW_COUNT}} |
| Size (GB) | {{SIZE_GB}} |
| Last modified | {{LAST_MODIFIED}} |
| Column count | {{COLUMN_COUNT}} |

{{PARTITION_HINT}}

---

## Schema snapshot

{{SCHEMA_TABLE}}

---

## Grain & duplicates

{{GRAIN_SCOPE_NOTE}}

| Metric | Value |
|--------|------:|
| Rows in scope | {{GRAIN_TOTAL_ROWS}} |
| Distinct grain ({{GRAIN_LABEL}}) | {{DISTINCT_GRAIN}} |
| Duplicate rows (total − distinct grain) | {{DUPLICATE_ROWS}} |
| Duplicate % | {{DUPLICATE_PCT}} |

**Expected grain:** {{GRAIN_DESCRIPTION}}

---

## Date coverage

{{DATE_COVERAGE_SECTION}}

---

## Data quality — sentinels & nulls

{{SENTINEL_SECTION}}

---

## Join readiness (sample)

{{JOIN_SECTION}}

---

## Week-over-week (optional)

| Metric | Prior drop | This drop | Delta |
|--------|----------:|----------:|------:|
| Row count | {{PRIOR_ROW_COUNT}} | {{ROW_COUNT}} | {{ROW_DELTA_PCT}} |

_Prior drop: {{PRIOR_DROP_REF}}._

---

## Changes vs prior drop

{{CHANGES_VS_PRIOR_SECTION}}

---

## Anomalies & drift flags

{{ANOMALY_SECTION}}

---

## Blockers & recommendations

### Red (do not ingest)

{{RED_ITEMS}}

### Amber (ingest with caveats)

{{AMBER_ITEMS}}

### Green (cleared)

{{GREEN_ITEMS}}

---

## Suggested next actions

1. {{ACTION_1}}
2. {{ACTION_2}}
3. {{ACTION_3}}

---

## Reproduce

```bash
python3 scripts/inbound_drop_eda.py --view {{VIEW_KEY}} --gcs-path "{{GCS_PATH}}" --write-brief
# Or via drop watcher (auto-detect new files):
python3 scripts/drop_watch.py --once --source local
```

SQL pack: [`queries/eda/inbound_drop_eda_pack.sql`](../../queries/eda/inbound_drop_eda_pack.sql)

---

## Changelog

| Date | Author | Note |
|------|--------|------|
| {{GENERATED_DATE}} | inbound-drop-eda | Auto-generated metrics; narrative reviewed by {{REVIEWER}} |
