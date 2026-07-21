---
name: lululemon-knowledge-bank
description: Lululemon knowledge bank (findings/lululemon_knowledge_bank.md). Use when the user asks to add to the knowledge bank, morning revision, /lulu-knowledge, or update go-to client facts.
---

# Lululemon knowledge bank

Ejaz's **go-to client context** for morning revision. Text lives in one file; visuals live in paired assets.

**Related skill:** `lulu-knowledge` — full append/dedupe workflow.

## Canonical files

| Role | Path |
|------|------|
| **Knowledge bank (append here)** | `findings/lululemon_knowledge_bank.md` |
| **Visual go-to** | `findings/assets/lululemon_masters_reference_guide_stacked.png` |
| **PDF** | `findings/assets/lululemon_masters_reference_guide.pdf` |

Do **not** append prose into PNG/PDF files. Update markdown first; regenerate visuals only when hierarchy/channel **images** need to change (`scripts/combine_lululemon_reference_pdf.py`).

## When the user asks to add to the knowledge bank

Trigger phrases (non-exhaustive): "add to knowledge bank", "add to my go-to", "append to lululemon knowledge", "update the morning revision doc", "add this to the PNG file" (interpret as **knowledge bank**, then confirm visual regen only if needed).

### Required workflow

1. **Read** `findings/lululemon_knowledge_bank.md` in full.
2. **Dedupe** — do not add a bullet if the same fact already appears (same meaning, any section). If the fact **supersedes** an older one (e.g. new row counts), **edit the existing line** and bump `Last updated` at the top; do not leave two conflicting truths.
3. **Append** new facts under `## Entries log` as:
   ```markdown
   ### YYYY-MM-DD — <short topic>
   - <one atomic fact per bullet>
   ```
   If the fact belongs in a stable section above (Environment, Masters, Channels, Postgres), add it there **and** skip duplicate in Entries log, or move consolidated content up and delete redundant log lines.
4. **Keep it scannable** — bullets, tables, no essays. One idea per bullet.
5. **Reply** with what was added, skipped as duplicate, or updated in place.

### What not to do

- Do not duplicate content already in the `lululemon-bq-context` / `lululemon-postgres-ingestion` skills unless the user wants a **morning-summary** copy; prefer a one-line pointer plus only net-new client facts.
- Do not append transient chat noise (one-off query results, typos fixed in a single file).
- Do not use the section sign `§` (see the Writing Conventions section in CLAUDE.md).

## Relation to Self Notes

| | Knowledge bank | Self Notes |
|---|----------------|--------------|
| **Who drives updates** | User asks to append | Agent may suggest |
| **Audience** | Morning client context revision | Personal learning deep-dives |
| **Dedupe** | Mandatory before every append | Check README + existing notes |

When both apply, add **short** fact to knowledge bank; put long SQL/pitfall detail in `Self Notes/` with a link from the bank if useful.

## On new Lululemon tasks

Skim `findings/lululemon_knowledge_bank.md` (and open the stacked PNG if hierarchy/channels matter) before deep-diving BQ/Postgres skills.
