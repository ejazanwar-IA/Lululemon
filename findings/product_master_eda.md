# Product Master - EDA Findings

| Field | Value |
|-------|-------|
| **Table** | `lululemon-01042025.lululemon_souricng_outbound.product_master` |
| **Total Rows** | 1,977,528 | **Size:** 1.05 GB | **Columns:** 46 |
| **Status** | ✅ Phase 1-3 Complete |
| **Owner** | Ejaz Anwar | **Last Updated** | 2026-04-20 |

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🟡 **Usable for modeling today with derivations. One P0 blocker (historical snapshots) needs client input.**

**TL;DR:**

1. **Clean fundamentals** — PK confirmed (`product_code`), referential integrity perfect, hierarchy structurally clean (l2-l8 all zero integrity violations)
2. **Self-resolved 3 P0/P1 items** via derivations — gender (99.96% coverage from `l5_name` prefix), active filter (use `flex_status`), color family (parse `color_description`). **Saved weeks of client wait.**
3. **One hard blocker:** product master is a **current-season snapshot only** (`25-4WI`). No historical product records. Blocks joins to 2023-2024 transactions.
4. **Low-severity findings:** 4 columns 100% NULL (including `launch_date`), `fit_classification` 25% null (Size Smart input), placeholder SKU pattern worth clarifying.

**What you need to decide, Uttkarsh:**

- Should we **escalate historical product_master request to client now**, or bundle with the other 4 P0s across tables?
- **Deprecate ivivva brand at source?** 100% of 63K SKUs never sold in 4 years. We're carrying dead weight.
- **Approval to build `product_master_clean` view** — pre-applies derivations and filters. One-time build, all downstream work benefits.

---

## 💡 My Recommendations (as analyst)

1. **Ship modeling on current data.** With gender derivation + active filter + color derivation, we have 99%+ usable product records. Don't wait on the 4 NULL columns.
2. **Historical product snapshots (P0) should be the #1 ask to client.** It's the only item that blocks multi-year modeling. Everything else has a workaround.
3. **Placeholder SKU investigation (P1) is a 15-min conversation, not a feed fix.** The 1,248 short-code articles (HX, MV, OVV, NK, HA, DA) are likely competitor benchmarks or internal test codes. Worth asking Ritik or Sri Harsha directly — saves weeks.
4. **Drop ivivva brand from modeling.** 100% of SKUs never sold in 4 years (and same for transactions). It's deprecated. Flag for removal at source.
5. **Don't trust `l8_name`** — 260K IDs have multiple names (87% of l8_ids!). Always use `l8_id` for joins and grouping. Names are for display only.
6. **`designed_for_activity` and `global_merch_team` are near-duplicates** — both have same Social/Run/Yoga/Train/... values. Pick `designed_for_activity` as canonical (slightly better populated).
7. **Use `channel_code` not `channel`** everywhere — 12 granular region×channel values vs 2 redundant ones. More useful for modeling.

---

## Key Findings

### Shape & Structure

| Metric | Value | Note |
|--------|------:|------|
| Total rows | 1,977,528 | |
| **PK** | `product_code` | Unique per row, zero duplicates |
| Distinct products | 988,764 | Each appears once RETAIL + once ECOMM |
| Channel split | 988,764 / 988,764 | Perfect 50/50 RETAIL vs ECOMM |
| Hierarchy integrity | 0 violations | l2-l8 all 1-to-1 structurally clean |

Full schema (46 columns) → [`schema_inventory.md`](schema_inventory.md)

### Critical Column Findings

| Column | Issue | % | Action |
|--------|-------|--:|--------|
| `launch_date` | 100% NULL | 100% | 🟢 Deferred (per user) |
| `color_family` | 100% NULL | 100% | ✅ Workaround: parse `color_description` |
| `ordering` | 100% NULL | 100% | 🟢 Legacy, drop |
| `season_code` | Single value `25-4WI` | 100% | 🔴 **P0** — need historical snapshots |
| `gender` | 73.4% null/`\N` | 73% | ✅ Derive from `l5_name` prefix (99.96% coverage) |
| `fit_classification` | NULL | 25% | 🟡 P1 — needed for Size Smart |
| `active_flag` / `article_status` | Uniformly ACTIVE | 100% | ✅ Use `flex_status` instead |
| `l8_name` | 260K IDs have multiple names | — | 🟡 Use `l8_id` for joins |

### Self-Resolved Derivations

**Gender (99.96% coverage):**
```sql
CASE
  WHEN gender IS NOT NULL AND gender NOT IN ('\\N', '') THEN gender
  WHEN l5_name LIKE 'Womens%'     THEN 'Womens'
  WHEN l5_name LIKE 'Mens%'       THEN 'Mens'
  WHEN l5_name LIKE 'ivivva%'     THEN 'Girls'
  WHEN l5_name LIKE 'Lab Womens%' THEN 'Womens'
  WHEN l5_name LIKE 'Lab Mens%'   THEN 'Mens'
  ELSE 'Unisex'
END AS derived_gender
```

**Active filter:** `flex_status IN ('Active', 'Drop')` covers 1.89M products (95.6% in sell-cycle)
- Active: 1,317,860 (66.6%) | Drop: 572,036 (28.9%) | Inactive: 36 | NULL: 87,596

**Color name:** `color_description` is 100% populated with perfect 1:1 mapping to `color_code` (26,480 codes). For multi-color variants: `SPLIT(color_description, '/')[SAFE_OFFSET(0)]` gets primary color.

### Interesting Distributions

**By l2 (division):** lulu Womens 36% | lulu Mens 23% | lulu Accessories 10% | lulu Footwear 5% | Lab Womens 7% | Lab Mens 4% | ivivva 3%

**97.8% of Lab line products never sold** in 4 years (22K SKUs). Lab = small/boutique experimental line.

**Placeholder pattern:** 1,248 short-code articles covering 54,598 rows (2.76%). Examples: `HX` (206 rows), `MV` (186), `OVV` (186), `OM` (170), `NK` (134), `HA` (150). Distinct from real SKUs (`LU9ADVS-036716_RETAIL` format).

### Cross-Table Integrity (verified against transactions)

- **Zero orphan SKUs** — every product_code in transactions exists in product_master ✅
- 1,054,585 SKUs never sold in 4 years (53%) — but **not because they're missing from master**. Most are inactive Lab / ivivva / placeholder / recent launches
- 716K "Active" products never sold → `flex_status='Active'` alone is not enough for "currently selling". Combine with transaction recency.

---

## Action Items

### 🔴 P0 (Client)
| # | Issue | Ask |
|---|-------|-----|
| PM-1 | Product master has no historical seasons (only `25-4WI`) | Provide per-season snapshots OR append-only product log for pre-2025 data |

### 🟢 Deferred / Resolved
- `launch_date` 100% NULL — deferred per user direction
- Gender / active / color family — self-resolved via derivations

### 🟡 P1 (Client or internal)
| # | Issue | Suggested Action |
|---|-------|------------------|
| PM-4 | Placeholder SKUs (1,248 short codes, 55K rows) | 15-min call with Ritik/Sri — what are these? |
| PM-7 | `fit_classification` 25% NULL (489K rows) | Improve coverage for Size Smart |
| PM-9 | `flex_status='Drop'` semantics | Confirm — sell-down or discontinued? |
| PM-11 | `size_scale` coded letters (B, E, I, WA...) | Provide lookup mapping |

### 🟢 P2 (Low priority)
- Deprecate ivivva brand at source (0 transactions in 4 years)
- Decide canonical `designed_for_activity` vs `global_merch_team`
- `l8_name` inconsistency — cosmetic, use IDs for joins

---

## Next Step

Build `product_master_clean` view with derived gender, is_active, is_placeholder, primary_color, and canonical channel. Enables all downstream work to start from a clean input. Query ready in `queries/product_master_clean_view.sql`.
