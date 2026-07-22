# Lululemon (Impact Analytics engagement)

Client: Lululemon. Owner: Ejaz Anwar (Impact Analytics). Current phase: Data Cleaning and EDA (Forecasting).

Full engagement history, team, and architecture context lives in [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) and `Self Notes/` — read those on demand, they are not loaded automatically. Don't inline their contents here.

Specialized workflows (BigQuery, Postgres ingestion, Confluence/Notion docs, sourcing table lineage, client reference codebase, knowledge bank, Self Notes capture) live as Skills under `.claude/skills/` and load on demand when the topic matches — see that directory rather than duplicating them here.

## Scope guardrail

SizeSmart / size-curve work is **out of scope** (archived 2026-06-16). Do not proactively read, search, or summarize `archive/sizesmart/` or moved sizing paths, and don't suggest SizeSmart workshops or sizing client questions unless the user explicitly asks to reopen archived sizing work. Active work is forecasting data prep, master EDA, ingestion, and SOW grains (PSS x Store/DC x Week/Day). Index of archived material: [archive/sizesmart/README.md](archive/sizesmart/README.md).

`product_master` fields `size_scale`, `product_size_definition`, and L2 to L5 hierarchy still matter for forecasting grain (PSS/PSO) — see [findings/product_master_hierarchy_decoded.md](findings/product_master_hierarchy_decoded.md), not the archived sizing note.

## GCS bucket scan workflow

When asked to scan, check, or verify raw files in the GCS bucket (`gs://client_data_lululemon/`, project `lululemon-01042025`), do not download full files or read entire CSVs with the Read tool.

- File pattern: `YYYY-MM-DD/<view>_YYYYMMDDHHMMSS_<shard>.csv`.
- Discover batches first with `gcloud storage ls`, grouping by the timestamp embedded in the filename; count shards per batch.
- Scan one shard (lexicographically first) per batch before scanning all shards — enough to gate pricing/completeness for a drop.
- Stream, never load a whole file: `gcloud storage cat gs://... | python3` row-by-row (`csv.DictReader`), or `scripts/sku_details_price_scan.py`.
- Never paste CSV bodies in chat — report aggregates only (row count, percent populated, top season/currency, 2-3 sample rows max).
- Save artifacts to `findings/<feed>_gcs_batch_*_scan.csv` plus a short `.md` of takeaways.
- If the one-shard gate is ambiguous, use a BQ external table on `gs://.../prefix*` with a single `COUNTIF` aggregate instead of downloading everything.
- Generalize `scripts/sku_details_price_scan.py` (or add a sibling script) for other feeds (`inventory_snapshot`, `sales_transactions`, etc.) rather than inventing a one-off full-file read.

## Intermediate build logic: single source of truth

Any change to intermediate table build logic (`product_intermediate`, `store_intermediate`, `inventory_intermediate`, `transaction_intermediate`) must be made in `queries/Intermediate_table_builds/` (historic v2 SQL) and the matching periodic script in `queries/sourcing/`, then **committed and pushed to `main`** on [github.com/ejazanwar-IA/lululemon-forecasting-engagement](https://github.com/ejazanwar-IA/lululemon-forecasting-engagement) in the same turn — that repo path is the canonical source of truth, not a local-only edit or a `_tmp` table. Do not leave intermediate-logic changes uncommitted or unpushed once verified; do not fork the logic into a different path or a one-off script elsewhere in the repo.

This doesn't relax the v2 hard rules (no live promotion without a `_tmp` pre/post comparison; periodic scripts updated in the same change set) — it's in addition to them. See [lululemon-intermediate-builds-v2](.claude/skills/lululemon-intermediate-builds-v2/SKILL.md) for the build-order and verification rules themselves.

## Table list formatting

When listing Lululemon database tables in chat, docs, or generated markdown: put the schema/dataset in the column header, not repeated per row; use bare table names unless fully qualified names are explicitly requested; skip the project name by default since `lululemon-01042025` is the assumed project. Header style: `Raw table (lulu_sourcing_dev)`, `Intermediate table (lulu_sourcing_dev)`, `Outbound table (lululemon_souricng_outbound)`.

## Confluence tables

Any table created or edited on a Confluence page (via Atlassian MCP or otherwise) must render full width: set `data-layout="full-width"` on every `<table>` element, including tables nested in expand macros/panels/columns (note: `full-width` only visibly breaks out for top-level tables — nested tables are capped at their container width regardless of the attribute).

## Latest reference documents (authoritative over older versions)

- **Timelines:** Forecasting Timelines v3 — `reference_docs/Lululemon/Timeline/lululemon_forecasting_timelines_v3.xlsx` (searchable extract: same folder, `.md`; index: `README.md` in that folder). Authoritative over the May 4 SOW timeline chart and older workplan sheets. If the `.md` extract conflicts with the `.xlsx`, the `.xlsx` wins.
- **Scope/contract:** Jun 24 2026 redlines SOW (Demand Forecasting) — `reference_docs/Lululemon/Contract/lululemon_impact_analytics_sow_2026-06-24_redlines_demand_forecasting.docx` (searchable extract in the same folder; index: `README.md`). Authoritative over the Jun 25 2026 final draft, May 4 redline PDF, and older summaries/timeline charts. If the `.md` extract conflicts with the `.docx`, the `.docx` wins.

## Writing conventions and pre-work preamble

See `~/.claude/CLAUDE.md` (global) for writing conventions (no `§`, no em dash, scale-word counts, percentage pairing) and the pre-work preamble rule — these apply here too but aren't Lululemon-specific, so they live in the global file.

One Lululemon-specific exception: auto-generated HTML under `site/` is exempt from the writing conventions since it mirrors source markdown - fix the source instead.
