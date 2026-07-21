# Lululemon Cursor rules

`Last updated: 2026-06-15.` Engagement revived; rules are scoped by file path, not always-on.

## How rules load in a multi-root workspace

When this folder is in the same Cursor workspace as Tapestry:

| When you work on… | Lululemon rules load? | Tapestry rules load? |
|---|---|---|
| `Lululemon/findings/**`, `queries/**`, etc. | Yes (globs match) | No |
| `Tapestry/findings/**`, `generic-data-ingestion/**`, etc. | No | Yes (globs match) |
| Unrelated files / empty editor | Neither client's scoped rules | Neither |

Global safety rules in `~/.cursor/rules/` still apply everywhere (`mcp-no-ddl`, `no-destructive-db-writes`, etc.).

## Key rules

| Rule | Triggers on |
|---|---|
| `lululemon-intermediate-builds-v2.mdc` | `queries/`, `findings/`, `PROJECT_CONTEXT.md`, `reference_docs/Lululemon/**` — **canonical v2 intermediate build logic** |
| `lululemon-bq-context.mdc` | `findings/`, `queries/`, `scripts/`, `reference_docs/`, `Self Notes/`, `PROJECT_CONTEXT.md` |
| `lululemon-postgres-ingestion.mdc` | `findings/`, `queries/`, `scripts/`, `reference_docs/` |
| `lululemon-knowledge-bank.mdc` | Agent-requestable via `/lulu-knowledge` or description match |
| `lululemon-sizesmart-archived.mdc` | **Always on** — do not load/search archived sizing work unless user asks |
| `lululemon-archived.mdc` | **Disabled** (`alwaysApply: false`) — kept for history only |

## Indexing

`.cursorignore` skips `archive/`, `site/`, and bulky binaries (PDF/PNG/DOCX/HTML). `findings/` and `reference_docs/` are indexed for active work.

## Workspace

Open both clients via **`/Users/ejazanwarmd/Desktop/Tapestry-Lululemon.code-workspace`** instead of manually adding folders each time.
