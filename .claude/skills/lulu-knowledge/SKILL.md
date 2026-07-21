---
name: lulu-knowledge
description: >-
  Append or update Lululemon client facts in the morning knowledge bank with
  mandatory dedupe. Use when the user invokes /lulu-knowledge, asks to add to
  the knowledge bank, update the go-to revision doc, or append Lululemon client
  context for daily review.
disable-model-invocation: true
---

# Lululemon knowledge bank (`/lulu-knowledge`)

Ejaz's curated **morning client-context** doc. Invoke with **`/lulu-knowledge`** in chat, then put the fact(s) in the same message.

## Canonical paths (Lululemon repo root)

| Role | Path |
|------|------|
| **Edit this** | `findings/lululemon_knowledge_bank.md` |
| **Visual go-to** | `findings/assets/lululemon_masters_reference_guide_stacked.png` |
| **PDF** | `findings/assets/lululemon_masters_reference_guide.pdf` |

Never append prose into PNG/PDF. Regenerate visuals only if hierarchy/channel **images** change: `python3 scripts/combine_lululemon_reference_pdf.py`.

## Modes

**If the message has facts to save** → Append workflow (below).

**If the message is empty or only `/lulu-knowledge`** → Read the bank + stacked PNG path; reply with a 5–10 bullet morning recap from the bank (no file edits).

**If the user says "show bank" / "morning recap"** → Same as empty invoke (read-only recap).

## Append workflow (required)

1. Read `findings/lululemon_knowledge_bank.md` in full.
2. **Dedupe** — skip any bullet that already states the same fact (any section). If a fact **supersedes** an old one (new counts, changed verdict), **edit the existing line** in the stable section; do not keep two conflicting truths.
3. **Place content:**
   - Durable client facts → stable section (Environment, Masters, Channels, Postgres, etc.) when they fit.
   - Session-specific or new topics → `## Entries log`:
     ```markdown
     ### YYYY-MM-DD — <short topic>
     - <one atomic fact per bullet>
     ```
4. Bump `` `Last updated: YYYY-MM-DD.` `` at the top when anything changes.
5. **Reply** with: Added / Updated in place / Skipped (duplicate) — list each item.

## Quality bar

- One idea per bullet; tables only when they aid scanning.
- No essays, no duplicate of `lululemon-bq-context.mdc` / `lululemon-postgres-ingestion.mdc` — pointer + net-new summary only.
- No section sign `§`.
- No transient noise (one-off typos, single-file fixes).

## Self Notes

Long SQL or deep pitfalls → `Self Notes/` + optional one-line link from the bank. Do not paste full gotcha lists into the bank.

## Examples

**Append:**
```
/lulu-knowledge Inv X3 orphans are channel-suffix only; bare SKU always in PM. RETAIL/ECOMM inv strict-join 100%.
```

**Morning recap (no edits):**
```
/lulu-knowledge
```

**Supersede:**
```
/lulu-knowledge product_master row count is now 2,100,000 (2026-05-21 rebuild)
```
→ Update the Four masters table row; do not add a second count elsewhere.
