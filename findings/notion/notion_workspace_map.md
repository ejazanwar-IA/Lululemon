# Notion workspace map — Lululemon

`Last updated: 2026-05-21 (user moved IS docs — use this file + live fetch).`

**Rule for agents:** Page **IDs and URLs stay the same** when you drag pages in Notion. Always `notion-fetch` before create/update to confirm current `ancestor-path`. Update this file when the user announces a move.

---

## Inventory Smart documentation (canonical)

| Page | Page ID | URL |
|------|---------|-----|
| **Inventory Smart -Tool** (hub) | `367389502e7981af959bd4eb1d05db4b` | https://www.notion.so/367389502e7981af959bd4eb1d05db4b |
| **Decision Dashboard — UI Walkthrough** (live doc) | `367389502e79811798dcc2896a695563` | https://www.notion.so/367389502e79811798dcc2896a695563 |

### Where to write

| Action | Target |
|--------|--------|
| Append Decision Dashboard sections (KPIs, alerts, etc.) | **`367389502e79811798dcc2896a695563`** via `notion-update-page` → `insert_content` |
| New Inventory Smart module page (CNA, Configuration, …) | **Child of hub** `367389502e7981af959bd4eb1d05db4b` — confirm parent with `notion-fetch` on hub first |
| Offline backup before/after Notion sync | `findings/notion/*.md` |

### Hierarchy (verified 2026-05-21 via `notion-fetch`)

```text
Inventory Smart -Tool (367389502e7981af959bd4eb1d05db4b)   ← top-level (user moved out of Lululemon EDA)
└── Decision Dashboard — UI Walkthrough (367389502e79811798dcc2896a695563)
```

**Lululemon EDA** (`364389502e7981c3b1ccfbe05861b00d`) remains the hub for **master-table EDA** only — not Inventory Smart UI docs.

---

## Lululemon EDA (master tables — separate track)

| Page | ID | URL |
|------|-----|-----|
| Lululemon EDA (hub) | `364389502e7981c3b1ccfbe05861b00d` | https://www.notion.so/364389502e7981c3b1ccfbe05861b00d |
| store_master | `364389502e79818fbdffe3fa3c08df94` | https://www.notion.so/364389502e79818fbdffe3fa3c08df94 |
| Product_Master | `364389502e7981c59301ebcf3705da67` | https://www.notion.so/364389502e7981c59301ebcf3705da67 |
| inventory_master | `364389502e79818e9917e5b376e92485` | https://www.notion.so/364389502e79818e9917e5b376e92485 |
| transaction_master | `364389502e7981c8befcc48c7f9c823c` | https://www.notion.so/364389502e7981c8befcc48c7f9c823c |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-05-21 | User moved **Inventory Smart -Tool** to **top-level** (no longer under Lululemon EDA) |
| 2026-05-21 | Created IS hub + Decision Dashboard walkthrough |
