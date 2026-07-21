# Parked plans

Research and implementation plans saved for later. Nothing here is active work until you explicitly pick one up.

## How to use

1. **Find a plan** — scan the index below or open a file by date/topic.
2. **Resume** — tell Cursor something like: "Resume the parked plan on codebase-memory-mcp" or paste the file path.
3. **Add new plans** — save as `YYYY-MM-DD_<short-topic>.md` and add a row to the index.

## Index

| Parked | Topic | Verdict / next step |
|--------|-------|---------------------|
| 2026-07-07 | [S3 to GCS platform connector](2026-07-07_s3_gcs_platform_connector.md) | **Hybrid B+A:** Airflow `connector=s3` for steady-state; STS for TB backfills; pitch client-direct-to-GCS first on onboarding |
| 2026-06-28 | [codebase-memory-mcp research](2026-06-28_codebase-memory-mcp_research.md) | Worth a narrow CLI pilot later; **do not install MCP until benchmark passes** (+1 server only) |
| 2026-06-28 | [supermemory research](2026-06-28_supermemory_research.md) | Session recall fit ~25–35%; **local = 0 MCPs**, needs LLM API key for extraction; park until recall pain warrants API workflow |

## Conventions

- One markdown file per plan; include scope, recommendation, and concrete next steps.
- Prefer **CLI-only trial first** for tooling plans before adding Cursor MCP entries.
- Original Cursor plan files may also live under `~/.cursor/plans/`; this folder is the Lululemon-local copy you can grep and share.
