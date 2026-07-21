# Store Master - EDA Findings

| Field | Value |
|-------|-------|
| **Table** | `lululemon-01042025.lululemon_souricng_outbound.store_master` |
| **Total Rows** | 1,853 | **Size:** <1 MB | **Columns:** 34 |
| **Status** | ✅ Phase 1 Complete (no further phases needed) |
| **Owner** | Ejaz Anwar | **Last Updated** | 2026-04-20 |

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🟢 **Clean table, usable as-is. Minor standardization fixes needed.**

**TL;DR:**

1. **Perfectly clean PK** (`store_code`), 1,853 stores, zero duplicates, zero structural issues.
2. **1,020 physical retail stores + 129 DCs + 30 virtual ECOMM stores + remainder inactive/OOS.** All classifiable via `store_format_code`, `dc_flag`, `ws_channel`.
3. **Key discovery:** The 10 ECOMM virtual stores in transactions are formally flagged `store_format_code='E-COMMERCE'` in master. And **3 "China ECOMM" stores are actually 3 platforms: Tmall, WeChat, JD.com**.
4. **Minor QA: `CMNTY` vs `COMMUNITY`** — same channel spelled two ways (26 + 13 stores). Fix at source.
5. **The 823 stores without transactions are explained** — 129 DCs + 208 out-of-scope (CMNTY/STRAT/FO) + 315 inactive + 199 NULL active + FO/STRAT/CMNTY never-in-feed stores.

**What you need to decide, Uttkarsh:**

- **Standardize `CMNTY`/`COMMUNITY` at source** — 2-minute feed fix. Worth asking.
- **Surface China ECOMM platform breakdown to forecasting team** — Tmall/WeChat/JD should be modeled separately, not as "China ECOMM" aggregate.

---

## 💡 My Recommendations (as analyst)

1. **This table is the gold standard among the 5 masters.** Clean PK, clean hierarchy, useful flags (`dc_flag`, `loc_type_code`, `store_format_code`, `ws_channel`). Use it with confidence.

2. **Use `ws_channel = 'OUT_OF_SCOPE'` as the modeling exclusion filter.** 208 stores are pre-tagged not-in-scope (CMNTY, STRAT, FO). No need for us to derive this — it's done.

3. **Always use IDs for joins, not names.** Applies to `s3_id` (2 IDs have multiple names — minor but real).

4. **`dc_flag`, `store_type`, `loc_type_code` are all equivalent** — each identifies the same 129 DCs. Pick one (I recommend `dc_flag = 1` — cleanest boolean).

5. **Store lifecycle data is imperfect but usable:** 1,339 active / 315 inactive / 199 NULL active. For modeling "open-at-date-X", combine: `active = '1' AND (close_date IS NULL OR close_date > '<as-of-date>')`.

6. **The China ECOMM platform discovery matters strategically:**
   - `0000045186` = **JD.com** (62% zero-qty)
   - `0000045187` = **WeChat** (31% zero-qty)
   - `0000045189` = **Tmall/Alibaba** (57% zero-qty)
   - Each platform has very different customer acquisition, order patterns, return behavior. **Treat as separate channels in modeling, not one "China ECOMM".**

---

## Key Findings

### Shape & Structure

| Metric | Value | Note |
|--------|------:|------|
| Total rows | 1,853 | |
| **PK** | `store_code` | Unique, zero dups |
| Distinct stores | 1,853 | |
| Distinct channels | 6 | RETAIL / ECOMM / FO / STRAT / CMNTY / COMMUNITY |
| Distinct channel_codes | 33 | Much more granular than transactions (12) |

Full schema (34 columns) → [`schema_inventory.md`](schema_inventory.md)

### Store Classification

**By store type:**
- 1,724 Stores (`dc_flag=0`)
- 129 DCs (`dc_flag=1`, `loc_type_code='W'`, `store_type='DC'` — all equivalent)

**By format (15 values, top):**
- MALL 525 | POP-UP 286 | STREET 200 | LIFESTYLE 184 | OUTLET 95 | **VIRTUAL 65** | SHOWROOM 33 | **E-COMMERCE 30** | SHOP_IN_SHOP 23 | NULL 392 (21%, unclassified)

**Non-physical stores: 95** (30 E-COMMERCE + 65 VIRTUAL)

**By `ws_channel` (the modeling filter):**

| ws_channel | count | Role |
|------------|-----:|------|
| RETAIL | 1,501 | Physical retail stores |
| OUT_OF_SCOPE | 208 | 🎯 **Pre-tagged exclusion** (CMNTY/STRAT/FO) |
| ECOM | 64 | Digital stores |
| DC_ECOM | 50 | DC-ECOM hybrid |
| VIRTUAL_DC | 30 | Virtual distribution |

### Virtual Store Identification — CONFIRMED

The 10 virtual stores flagged in Transaction Master Phase 3 all have `store_format_code='E-COMMERCE'` in store_master:

| store_code | Platform | Region |
|-----------:|----------|--------|
| 0000009198 | LULULEMON ECOMM USA | USA |
| 0000009188 | LULULEMON ECOMM STORE CANADA | Canada |
| **0000045189** | **CN TMALL STORE** | China (Alibaba) |
| **0000045187** | **WECHAT STORE** | China |
| **0000045186** | **JD ECOMM STORE** | China (JD.com) |
| 0000044188 | KR ECOMM STORE | Korea |
| 0000059188 | AU ECOMM STORE | Australia |
| 0000060188 | UK ECOMM STORE | UK |
| 0000065188 | DE ECOMM STORE | Germany |
| 0000066188 | EU ECOMM STORE | Netherlands |

### Data Quality Issues (all minor)

| Issue | Scope | Severity |
|-------|------:|:--------:|
| `CMNTY` vs `COMMUNITY` (same channel, 2 spellings) | 39 stores | 🟡 P1 |
| `store_format_code` NULL | 392 stores (21%) | 🟡 P1 |
| `active` NULL | 199 stores (11%) | 🟡 P1 |
| 21 channel_codes exist but have ZERO transactions | ~200 stores | 🟡 P1 |
| `special_classification` 100% NULL | All rows | 🟢 P2 |
| `latitude`/`longitude` stored as STRING | 1,853 rows | 🟢 P2 |
| s3_id: 2 IDs with multiple s3_names | 2 IDs | 🟢 P2 |

### Hierarchy (s0 → s4)

| Level | Distinct |
|:-----:|---------:|
| s0 | 1 (LULULEMON) |
| s1 | 6 (channels) |
| s2 | 25 (country groupings) |
| s3 | 63 (region groups) — 2 IDs have multiple names |
| s4 | 214 (specific regions) |

---

## Action Items

### 🟡 P1 (Client)
| # | Issue | Ask |
|---|-------|-----|
| S1 | `CMNTY` vs `COMMUNITY` spelling inconsistency (26 + 13 stores) | Standardize in next refresh |
| S3 | `store_format_code` 21% NULL (392 stores) | Populate for all stores |
| S4 | `active` 11% NULL (199 stores) | Every store should have active flag |
| S5 | 21 channel_codes with zero transactions (CMNTY/STRAT/FO/MEX_RTL) | Expected or feed gap? |

### 🟢 P2 (Cosmetic)
| Issue | Detail |
|-------|--------|
| `special_classification` 100% NULL | Legacy field; drop or populate |
| `latitude`/`longitude` as STRING | Type inconsistency |
| Geographic mismatches in virtual stores | KR ECOMM city = Hong Kong; EU ECOMM region = Switzerland, city = Netherlands. Historical HQ artifacts, not functional. |
| Placeholder open_dates | WeChat store shows `1999-12-31` (platform didn't exist then) |

---

## Modeling Filters — Ready to Use

```sql
-- Physical retail stores (for store-level sales forecasting)
WHERE dc_flag = 0
  AND store_format_code NOT IN ('E-COMMERCE', 'VIRTUAL')
  AND ws_channel NOT IN ('OUT_OF_SCOPE', 'VIRTUAL_DC')
  AND (active = '1' OR active IS NULL)

-- ECOMM virtual stores (for digital/marketplace modeling)
WHERE store_format_code = 'E-COMMERCE'   -- 30 stores

-- DCs (for inventory-level analysis, not sales)
WHERE dc_flag = 1                         -- 129 stores

-- Out of scope (exclude from main modeling)
WHERE ws_channel = 'OUT_OF_SCOPE'         -- 208 stores
```

---

## Next Step

No further EDA needed. Store Master is ready for use. Consider building a `store_master_clean` view that adds `is_virtual`, `is_dc`, `is_physical_retail`, `is_in_scope` boolean flags pre-computed — small convenience, but removes clutter from downstream queries.
