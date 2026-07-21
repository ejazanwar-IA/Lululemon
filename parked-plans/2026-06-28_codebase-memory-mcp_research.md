# Parked plan: codebase-memory-mcp (Lululemon)

**Parked:** 2026-06-28  
**Status:** Not started — research complete, implementation deferred  
**Repo:** https://github.com/DeusData/codebase-memory-mcp  
**Scope:** Lululemon only (Tapestry out of scope)

---

## One-line summary

Optional **single MCP** for code/SQL navigation and cross-client pattern lookup. **Not needed for day-to-day BQ/GCS/Postgres work.** Try CLI-only pilot later; add to Cursor only if benchmarks pass.

---

## MCP footprint (important)

| | Count |
|---|------|
| New MCP servers if adopted | **1** (`codebase-memory-mcp`) |
| Tools inside that server | 14 (not 14 separate MCPs) |
| Lululemon `.cursor/mcp.json` today | 4 servers → would become 5 |

Install with `--skip-config` and test via CLI first — **zero MCP entries** until you decide.

---

## When to pick this up

- You are doing a lot of cross-client SQL pattern lookup (insideinsight reference repo).
- Grep/read cycles across `queries/` + reference codebase feel slow.
- You want MCP-native `trace_path` / semantic search without shell tools.

## When to skip

- Mostly BQ EDA, GCS scans, Postgres GSM, Confluence docs (current majority of work).
- Grep + findings + rules are enough.

---

## Final recommendation

**Worth a narrow pilot, with tempered expectations.** Strongest use case: cross-client pattern lookup (insideinsight + local `queries/sourcing/`). ROI ~10–20% of sessions for Lululemon.

---

## Resume checklist (when ready)

- [ ] **Phase 0:** `curl -fsSL .../install.sh | bash -s -- --skip-config` (no MCP config yet)
- [ ] **Phase 1:** Index `/Users/ejazanwarmd/Desktop/Lululemon` + `/Users/ejazanwarmd/Downloads/insideinsight-mtp-bigquery-3df90a9e5596`; add `.cbmignore` for secrets + `findings/`
- [ ] **Phase 2:** Run 5 benchmark tasks (see full plan below); need **3/5 pass** to adopt
- [ ] **Phase 3:** Only if pass — add one block to `Lululemon/.cursor/mcp.json` and optional `.cursor/rules/codebase-memory-mcp.mdc`

---

## Full research (copy for resume)

### What it is

Local MCP server that indexes repos into a knowledge graph (functions, calls, imports, SQL files). **Not** a database connector. Postgres/Atlassian/Notion MCPs stay as-is.

### Highest-value Lululemon use cases

1. **Cross-client reference** (~8.6k files) — "how did Signet/VS build transaction_intermediate MERGE?"
2. **`queries/` + `scripts/` discovery** — find intermediate SQL, GCS scan scripts
3. **Outbound field tracing** — ordertype, delivery_date (often in reference codebase)

### What it will NOT help with

BQ/Postgres EDA, GCS bucket scans, Confluence deliverables, BQ table lineage, session/chat recall.

### Benchmark tasks (score pass / partial / fail)

| # | Task |
|---|------|
| 1 | Find all SQL files building `inventory_intermediate` |
| 2 | Cross-client periodic transaction intermediate MERGE pattern |
| 3 | Trace `SYNCSTARTDATETIME` across Lululemon + reference SQL |
| 4 | Semantic search: "sku_details pricing zero cost" |
| 5 | `detect_changes` on edit to `create_product_intermediate_periodic.sql` |

### Decision gate

| Outcome | Action |
|---------|--------|
| 4–5 pass | Full adopt + Cursor rule |
| 3 pass | Narrow adopt (reference lookup only) |
| 0–2 pass | Skip; do not add MCP |

### Phase 0 install snippet

```bash
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash -s -- --skip-config
```

CLI trial example:

```bash
codebase-memory-mcp cli search_graph '{"name_pattern": "inventory_intermediate"}'
```

MCP entry (only after pilot passes):

```json
"codebase-memory-mcp": {
  "command": "/Users/ejazanwarmd/.local/bin/codebase-memory-mcp",
  "args": []
}
```

### `.cbmignore` (Lululemon root)

```
.cursor/secrets/
*.env
**/credentials*
findings/
deliverables/
reference_docs/Lululemon/InventorySmart_Handbook/_raw/
.git/
```

---

*Canonical Cursor plan file (if still present): `~/.cursor/plans/codebase-memory-mcp_research_6afec07c.plan.md`*
