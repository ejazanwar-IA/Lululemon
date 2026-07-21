# Parked plan: supermemory (Lululemon)

**Parked:** 2026-06-28  
**Status:** Not started — research complete, implementation deferred  
**Repo:** https://github.com/supermemoryai/supermemory  
**Scope:** Lululemon only; **local self-host only** (no hosted MCP for client work)

**Related:** [codebase-memory-mcp](2026-06-28_codebase-memory-mcp_research.md) = code navigation (different problem). Complementary, not substitutes.

---

## One-line summary

Session **memory and recall** across Cursor chats (decisions, project context, open questions). **Higher fit than codebase-memory-mcp** for "what did we already decide?" — but **local setup has no Cursor MCP**; needs LLM API key for extraction (Ollama not required). **Zero new MCPs** if you stay local-only.

---

## Without Ollama (your setup)

| Component | Where |
|-----------|--------|
| Memory storage + search | **Local** (`./.supermemory`, `localhost:6767`) |
| Embeddings | **Local** |
| Fact extraction from text | **Your LLM API key** (OpenAI, Anthropic, Gemini, Groq) — not Ollama |

Ollama is optional for fully offline extraction only. Without it, memories stay on disk locally; extraction calls go to whichever provider key you configure at first boot.

**Do not store:** credentials, raw PII, full query result dumps. Only distilled verdicts and decisions.

---

## MCP footprint (important)

| Deployment | New Cursor MCP servers |
|------------|------------------------|
| **Local self-host** (this plan) | **0** — Memory API only; Cursor MCP is platform-only per official docs |
| Hosted (`mcp.supermemory.ai`) | +1 (not in scope for Lululemon client work) |

Hosted MCP tools would be: `memory`, `recall`, `whoAmI`, `/context`. Not available from self-hosted binary.

---

## When to pick this up

- New chats often need prior context ("recall sales_transactions append vs snapshot", "what did we decide on ordertype").
- Knowledge bank + transcript grep feel slow or incomplete.
- You accept an extraction LLM API key (or install Ollama later) and running `supermemory-server` in the background.

## When to skip

- Same long thread every time; rarely start fresh chats.
- Knowledge bank + `search-historical-chats` + findings are enough.
- You want plug-and-play Cursor MCP without hosted cloud (local cannot do that today).
- You do not want another background server or LLM API cost for extraction.

---

## Final recommendation (parked verdict)

**Tempered interest.** Good on paper for session recall (~25–35% of sessions), but **local-only + no Cursor MCP** makes it a manual API workflow unless you later accept hosted MCP for non-sensitive prefs only.

**Keep canonical:** `lululemon_knowledge_bank.md`, `lululemon-bq-context.mdc` (G1–G18), `findings/`. Supermemory would be **working memory** only; promote to bank/findings when you explicitly ask.

---

## Resume checklist (when ready)

- [ ] **Phase 0:** `curl -fsSL https://supermemory.ai/install | bash` → `supermemory-server`; wizard for OpenAI/Anthropic/Gemini/Groq key (not Ollama)
- [ ] **Phase 1:** Create `lululemon` container; manually seed 10–15 facts from knowledge bank (controlled pilot)
- [ ] **Phase 2:** Run 5 benchmarks vs knowledge bank + transcript grep; need **3/5 pass**
- [ ] **Phase 3:** If pass — `.cursor/rules/supermemory-local.mdc` for API recall; **do not** add hosted MCP for client facts unless policy changes

---

## Benchmark tasks

| # | Task |
|---|------|
| 1 | New chat: sales_transactions Aug vs Nov — full re-extract vs append verdict |
| 2 | Inject project focus + BQ discipline prefs (API profile/recall; `/context` only on hosted MCP) |
| 3 | Open questions on returns_transactions join |
| 4 | Save fact mid-session; retrieve in new chat |
| 5 | Forget superseded fact; no conflict with knowledge bank |

---

## vs codebase-memory-mcp (parked sibling)

| | supermemory | codebase-memory-mcp |
|---|-------------|---------------------|
| Problem | Remember decisions / context | Navigate code & SQL structure |
| Your ROI | ~25–35% sessions | ~10–20% sessions |
| Local Cursor MCP | **No** | Yes (+1 server if pilot passes) |
| Priority | Higher if recall pain | Higher if cross-client grep pain |

---

## Install snippet (Phase 0)

```bash
curl -fsSL https://supermemory.ai/install | bash
supermemory-server   # http://localhost:6767
```

Docs: https://supermemory.ai/docs/self-hosting/overview

---

*Canonical Cursor plan file (if still present): `~/.cursor/plans/supermemory_research_df27b616.plan.md`*
