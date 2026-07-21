# Location / Store — Full Audit

**As of:** 2026-04-22
**Owner:** Ejaz Anwar
**Purpose:** One-stop reference for everything location-related in the `lululemon_souricng_outbound` dataset — tables, identifiers, hierarchy, build logic, quality issues, and gaps.

---

## 1. TL;DR

| | |
|---|---|
| Authoritative store table | `store_master` (1,853 rows, clone of `store_master_20251119`) |
| Raw upstream | `location_group_hierarchy_cleaned_20251119` (1,853) + `location_details_cleaned_20251119` (1,853) |
| Store universe | **1,020 physical retail + 129 DC + 30 E-COMMERCE + 65 VIRTUAL + ~609 other (inactive / OOS / non-retail)** |
| PK | `store_code` — perfectly clean, zero dupes |
| Status | 🟢 **Cleanest master in the dataset.** 4 P1s (standardization), 4 P2s (cosmetic), 1 suspected logic bug reframed as actually correct |
| Biggest open ask | Populate **`location_attrib_squareft`** + standardize `CMNTY`/`COMMUNITY` spelling + confirm `store_format_code` 21% NULLs |
| Biggest invisible gap | **Location Attributes** (demography, rent, mall traffic) — largely missing; `spatial_ai_cleaned` has partial coverage |

---

## 2. Location-aware tables (21 total)

Grouped by role. Every table that carries a store/location identifier is listed — this is the full dependency surface when anything location-shaped changes.

### 2a. Master / reference

| Table | Rows | Size | Role | Key |
|---|---:|---:|---|---|
| `store_master` | 1,853 | <1 MB | **Canonical**. 34 cols. Clone of `store_master_20251119`. | `store_code` |
| `location_group_hierarchy_cleaned_20251119` | 1,853 | — | Raw hierarchy, LAT/LONG, LOC_FORMAT, LOC_CLOSED_IND | `loc_id` |
| `location_details_cleaned_20251119` | 1,853 | — | Raw. Contributes `ws_channel` (= `TYPE_CODE`). LEFT JOIN on `id = loc_id` | `id` |
| `spatial_ai_cleaned` | 22,798 | 0.01 GB | Demography scores per location × quarter. 48 behavioral segments. | `LOCATION_ID`, `QUARTER_ID` |

### 2b. Mapping / attributes

| Table | Rows | Role | Key |
|---|---:|---|---|
| `dc_store_mapping_cleaned_20251119` | 1,110,005 | Primary/secondary DC per (store × subclass × quarter). Raw `dc_store_mapping` is EMPTY. | `QUARTER_ID`, `STORE_ID`, `SUBCLASS_ID` |
| `anaplan_store_priority_cleaned` | 8,828 | Priority flag per (store × division) | `store_code`, `division_code` |
| `anaplan_transit_calender_cleaned` | 51.3M | Transit lead-time per (DC × store × subclass × date) | `distribution_center_code`, `l5_store_code`, `Datestring` |

### 2c. Planning / eligibility (SKU × store)

| Table | Rows | Role | Key |
|---|---:|---|---|
| `eligibility_cleaned_20251119` | 2.3 B | SKU × store × week eligibility (🚨 10× the 242M `eligibility_20251119`) | `PLANNING_STYLE_OPTION_ID`, `STORE_ID`, `WEEK_ID` |
| `assortment_plan_cleaned` | 42.6M | Store-level buy qty per SKU × quarter | `quarter_id`, `store_id`, `style_option_id` |
| `anaplan_allocation_calendar_cleaned` | 39.2M | When to allocate per SKU × store | `store`, `planning_style_option`, `custom_quarter` |
| `anaplan_fdod_alloc_cleaned` | 16.0M | FDOD + WOS per SKU × store | `SKU_ID`, `store_code` |
| `anaplan_fdod_replen_cleaned` | 30.9M | Replen config per SKU × store | `SKU_ID`, `store_code` |
| `anaplan_min_pres_cleaned` | 8.8M | Min presentation qty per style × store × size | `store_code`, `planning_size_code` |
| `min_pres_eol` | 99 | EOL min-pres overrides | `store_id`, `style_option_id`, `Size` |

### 2d. Transactional (store_code or location_id)

| Table | Rows | Size | Location col | Notes |
|---|---:|---:|---|---|
| `inventory_master` | 7.2 B | 650 GB | `store_code` (cluster key) | Partition = `date`. Always filter. |
| `inventory_snapshot_cleaned` | 63.5 B | 3.3 TB | `LOCATION_ID` | Raw — full scan = 3.3 TB. |
| `transaction_master` | 389.9M | 74 GB | `store_code`, `channel_code` | Partition = `date`, cluster = `channel`. |
| `sales_transactions_4y_cleaned_20251119` | ~400M | — | `LOCATION_ID_SALES` | Raw. No channel column — infer via store_master. |
| `returns_transactions_20251119` | 733.7M | 79 GB | `LOCATION_ID_SALES` | Raw returns. |
| `transfer_orders_cleaned_20251119` | 710.3M | 69 GB | `LOCATION_ID_SENDING`, `LOCATION_ID_RECEIVING` | |
| `transfer_orders_new_cleaned` | 75.9M | 8 GB | `location_id_sending`, `location_id_receiving` (STRING) | |
| `purchase_orders_cleaned_20251119` | 20.8M | 3 GB | `LOCATION_ID_RECEIVING` | |
| `price_book` | 440.5M | 32 GB | `LOC_ID` | Clone. `EFFECTIVE_FROM/TO_DAY_ID` as STRING dates. |

### 2e. Events / holidays

| Table | Rows | Role | Key |
|---|---:|---|---|
| `events_master` | — | Projection of `promotional_events_cleaned`. Grain = store × event. | `store_code`, `name`, `start_date` |
| `promotional_events_cleaned_20251119` | 448,134 | Raw. Holidays + store closures. `LOCATION_CLOSED_FLAG` BOOL. | `LOC_ID`, `NAME`, `START_DATE` |

---

## 3. Identifier zoo — join key reference

**The same store appears under 5+ column names across tables.** Always cast on join.

| Column name | Type | Format | Appears in |
|---|---|---|---|
| `store_code` | STRING | `0000011043` (10-digit zero-padded) | `store_master`, `inventory_master`, `anaplan_*` |
| `STORE_ID` / `store_id` | INT64 | `11043` | `dc_store_mapping`, `assortment_plan`, `eligibility` |
| `store` | STRING | `0000011043` | Some Anaplan tables use this instead of `store_code` |
| `LOC_ID` / `loc_id` | STRING | `0000011043` | `location_group_hierarchy`, `price_book`, `promotional_events` |
| `LOCATION_ID` | STRING or INT64 | varies | `inventory_snapshot`, `spatial_ai`, `purchase_orders` |
| `LOCATION_ID_SALES` | INT64 | `11043` | `sales_transactions_4y_cleaned`, `returns_transactions` |
| `LOCATION_ID_SENDING` / `_RECEIVING` | INT64 (or STRING in `transfer_orders_new`) | `11043` | `transfer_orders_*` |
| `l5_store_code` | STRING | `PHL05\|0000011043` — **prefixed** | `anaplan_transit_calender_cleaned` |
| `channel_code` | STRING | `LLL_USA_RTL` | `store_master`, `transaction_master` |

**Join pattern (standard):**

```sql
LEFT JOIN `...store_master` sm
  ON sm.store_code = LPAD(CAST(t.LOCATION_ID_SALES AS STRING), 10, '0')
```

---

## 4. Location hierarchy (s0 → s4)

| Level | Column(s) | Distinct | Example | Notes |
|:-:|---|:-:|---|---|
| s0 | `s0_name` / `company_name` | 1 | LULULEMON | `company_name` is a dup of `s0_name` |
| s1 | `s1_name` / `channel` | 6 | RETAIL, ECOMM, FO, STRAT, CMNTY, COMMUNITY | ⚠️ CMNTY/COMMUNITY split |
| s2 | `s2_name` | 25 | USA, CANADA, CHINA, … | country groupings |
| s3 | `s3_name` / `district_name` / `s3_id` | 63 | Midwest, East, NorCal, … | `s3_id` has 2 IDs with multiple names |
| s4 | `s4_name` / `region` | 214 | Specific regions | `region` is a dup of `s4_name` |
| Store | `store_code` | 1,853 | `0000011043` | PK |

**Build DDL note** (from `location_group_hierarchy` → `store_master`):

```sql
SPLIT(SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)] AS s1_name
SPLIT(SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)] AS channel     -- same split, 2 columns
a.BRAND_NAME  AS s0_name
a.BRAND_NAME  AS company_name                                 -- same source, 2 columns
a.REGION_NAME AS s4_name
a.REGION_NAME AS region                                       -- same source, 2 columns
a.AREA_NAME   AS s3_name
a.AREA_NAME   AS district_name                                -- same source, 2 columns
```

→ 4 pairs are byte-identical duplicates. Pick one and drop the other in any derived view.

---

## 5. Store taxonomy (who is in / out of scope)

### By `dc_flag` (`loc_type_code='W'`)

| dc_flag | Count | Meaning |
|:-:|---:|---|
| 0 | 1,724 | Stores (retail, ecom, virtual, other) |
| 1 | 129 | **DCs** (warehouses) |

**`dc_flag=1`, `store_type='DC'`, `loc_type_code='W'` are all equivalent** — pick one. `dc_flag=1` is cleanest.

### By `store_format_code`

| Format | Count | Role |
|---|---:|---|
| MALL | 525 | Physical retail |
| POP-UP | 286 | Physical retail (short-term) |
| STREET | 200 | Physical retail |
| LIFESTYLE | 184 | Physical retail |
| OUTLET | 95 | Physical retail |
| **VIRTUAL** | 65 | **Digital** |
| SHOWROOM | 33 | Physical retail |
| **E-COMMERCE** | 30 | **Digital** |
| SHOP_IN_SHOP | 23 | Physical retail |
| (other — OPEN, CLOSED, other DC/hub codes) | ~20 | Mixed |
| **NULL** | **392 (21.15%)** | ⚠️ Unclassified — verified in raw (`LOC_FORMAT` is NULL upstream too) |

**95 digital stores total** (30 E-COMMERCE + 65 VIRTUAL), not the 10 that show up in transactions — the remaining 85 are not currently transacting.

### By `ws_channel` (the modeling filter)

| ws_channel | Count | Use |
|---|---:|---|
| RETAIL | 1,501 | Include in sales forecasting |
| **OUT_OF_SCOPE** | 208 | 🎯 **Pre-tagged exclusion** (CMNTY/STRAT/FO) — don't re-derive |
| ECOM | 64 | Digital |
| DC_ECOM | 50 | DC-ECOM hybrid |
| VIRTUAL_DC | 30 | Virtual distribution |

### The 10 virtual "transacting" stores

| store_code | Platform | Region |
|---|---|---|
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

**Actionable insight:** The 3 China stores are **3 distinct platforms** (Tmall, WeChat, JD) with very different customer/return profiles — should be modeled separately.

---

## 6. Build-logic quirks (from the DDL)

From `master_table_build_queries_20251119.csv` — `store_master_20251119` is built as:

```sql
SELECT DISTINCT
  ...
  0                                AS location_attrib_squareft,   -- hardcoded 0
  a.LOC_CLOSED_IND                 AS active,                     -- ⚠️ name/semantic mismatch
  NULL                             AS special_classification,     -- hardcoded NULL
  a.loc_id                         AS like_store_id,              -- = store_code (useless)
  CASE WHEN UPPER(a.LOC_TYPE)='S' THEN 'Store' ELSE 'DC' END AS store_type,
  CASE WHEN UPPER(a.LOC_TYPE)='W' THEN 1 ELSE 0 END        AS dc_flag,
  ...
FROM location_group_hierarchy_cleaned_20251119 a
LEFT JOIN location_details_cleaned_20251119 b ON a.loc_id = b.id
```

### Issues introduced by the build (not by source)

| # | Issue | Source | Action |
|:-:|---|---|---|
| B1 | `location_attrib_squareft` = 0 for all 1,853 stores | hardcoded `0` | Populate from real source or drop |
| B2 | `special_classification` = NULL for all | hardcoded `NULL` | Drop from schema unless populated |
| B3 | `like_store_id` = `store_code` (self-reference) | `a.loc_id AS like_store_id` | Wire up an actual like-store lookup |
| B4 | `company_name` duplicates `s0_name` | both = `a.BRAND_NAME` | Drop one |
| B5 | `district_name` duplicates `s3_name` | both = `a.AREA_NAME` | Drop one |
| B6 | `region` duplicates `s4_name` | both = `a.REGION_NAME` | Drop one |
| B7 | `channel` duplicates `s1_name` | both = `SPLIT(SUB_MARKET_CHANNEL_NAME, ' ')[OFFSET(1)]` | Drop one |
| B8 | `active` sourced from `LOC_CLOSED_IND` — name says "active", column says "closed" | Build DDL | **Verified in V5:** mapping is correct as-is. `LOC_CLOSED_IND=0` → 100% have close-date populated (truly closed); `=1` → 8% (truly open). **Not a polarity bug** — just confusing naming. |

---

## 7. Data-quality issues (verified 2026-04-21)

### P1 — source-side (client action)

| # | Issue | Scope | Raw verified? |
|:-:|---|---:|---|
| L1 | `CMNTY` (26) vs `COMMUNITY` (13) spelling split | 39 stores | ✅ V4 — in raw `SUB_MARKET_CHANNEL_NAME` |
| L2 | `store_format_code` NULL | 392 stores (21.15%) | ✅ V13 — `LOC_FORMAT` NULL upstream |
| L3 | `active` NULL (= `LOC_CLOSED_IND` NULL) | 199 stores (11%) | ✅ V5 — mostly new stores awaiting classification |
| L4 | 21 channel_codes appear in `store_master` but have 0 transactions | ~200 stores | ✅ Real cross-table. CMNTY/STRAT/FO mostly — expected. |

### P2 — cosmetic

| # | Issue | Scope |
|:-:|---|---|
| L5 | `latitude` / `longitude` stored as STRING, not FLOAT64 | 1,853 rows — CAST when used |
| L6 | `s3_id` → 2 IDs have multiple `s3_name` values | 2 IDs |
| L7 | Placeholder open_dates (WeChat = `1999-12-31`, platform didn't exist) | Some virtual |
| L8 | Geographic mismatches in virtual stores (KR ECOMM city = Hong Kong; EU ECOMM region = Switzerland, city = Netherlands) | Handful | Historical HQ artifacts |

### Reframed / no-ops

| # | Original flag | Resolution |
|:-:|---|---|
| L9 | `active = LOC_CLOSED_IND` polarity | ✅ V5 confirmed mapping is correct — just badly named. No action. |
| L10 | `special_classification` 100% NULL | 🛠️ Hardcoded in DDL. Not a feed gap. Decide: drop or populate. |
| L11 | `location_attrib_squareft` 100% zero | 🛠️ Hardcoded in DDL. Same. |

---

## 8. Cross-table integrity

Verified against transactions + inventory:

| Observation | Count | Interpretation |
|---|---:|---|
| Stores in `store_master` with **zero inventory rows** | 467 | Inactive / closed / never-stocked. Confirmed real. |
| Stores in `store_master` with **zero transactions** | 823 | = 129 DCs + 208 OUT_OF_SCOPE + 315 inactive + 199 NULL-active + CMNTY/STRAT/FO never-in-feed. Accounted for. |
| SKUs in `product_master` never seen in inventory | 23,782 | Placeholders / new launches |
| Stores in `transaction_master` not in `store_master` | 0 | ✅ Clean referential integrity |
| Stores in `inventory_master` not in `store_master` | 0 | ✅ Clean |

---

## 9. Modeling-ready filters (copy/paste)

```sql
-- Physical retail — for store-level sales forecasting
WHERE sm.dc_flag = 0
  AND sm.store_format_code NOT IN ('E-COMMERCE', 'VIRTUAL')
  AND sm.ws_channel NOT IN ('OUT_OF_SCOPE', 'VIRTUAL_DC')
  AND (sm.active = '1' OR sm.active IS NULL)

-- E-COMM / digital
WHERE sm.store_format_code IN ('E-COMMERCE', 'VIRTUAL')    -- 95 stores

-- DCs only (inventory analysis, not sales)
WHERE sm.dc_flag = 1                                       -- 129 stores

-- Exclude from main modeling
WHERE sm.ws_channel = 'OUT_OF_SCOPE'                       -- 208 stores
```

**Suggested reusable view** — `v_store_master_enriched`:

```sql
CREATE OR REPLACE VIEW `...v_store_master_enriched` AS
SELECT
  sm.*,
  SAFE_CAST(sm.latitude  AS FLOAT64) AS latitude_f,
  SAFE_CAST(sm.longitude AS FLOAT64) AS longitude_f,
  sm.dc_flag = 1                                   AS is_dc,
  sm.store_format_code IN ('E-COMMERCE','VIRTUAL') AS is_virtual,
  sm.dc_flag = 0
    AND sm.store_format_code NOT IN ('E-COMMERCE','VIRTUAL')
    AND sm.ws_channel NOT IN ('OUT_OF_SCOPE','VIRTUAL_DC') AS is_physical_retail,
  sm.ws_channel = 'OUT_OF_SCOPE'                   AS is_out_of_scope,
  UPPER(REGEXP_REPLACE(sm.s1_name, 'COMMUNITY', 'CMNTY')) AS s1_name_std
FROM `...store_master` sm;
```

---

## 10. Known gaps vs the Data Checklist

From `PROJECT_CONTEXT.md` + the Lululemon master checklist:

| Checklist item | In source? | In our pipeline? | Note |
|---|:-:|:-:|---|
| Location Master | ✅ | ✅ | `store_master` |
| Location Groups | ✅ | ✅ | Same table (s3/s4 hierarchy) |
| Store Clusters | ✅ | Partial | `spatial_ai_cleaned` = consumer demography only |
| **Location Attributes** (squareft, rent, traffic, mall tier) | ❓ | ❌ | `location_attrib_squareft` hardcoded 0. **MISSING.** |
| **Store Traffic / Web Traffic** | ❌ | ❌ | Missing entirely |
| **Store-Space Data** | ❌ | ❌ | Missing |
| **Product-Location Historic Pricing** | Partial | ❌ | `price_book` has `LOC_ID` — could fill this |
| **Vendor — DC/Store transit data** | ❌ | ❌ | Only DC→store transit via `anaplan_transit_calender` |
| Holidays & Store Closure | ✅ | ✅ | `events_master` / `promotional_events_cleaned` |

---

## 11. Asks for Uttkarsh / DE

### 🔴 P0 — blockers
_None. Location data is usable as-is._

### 🟡 P1 — source-side standardization
1. **Standardize `CMNTY` vs `COMMUNITY`** at source feed (2-minute fix).
2. **Populate `store_format_code`** for the 392 NULLs.
3. **Populate `active`/`LOC_CLOSED_IND`** for the 199 NULLs (mostly new stores).
4. **Populate `location_attrib_squareft`** — currently hardcoded to 0 in build. Is there a raw source (real-estate feed)?

### 🟡 P1 — build-script fixes
5. **`like_store_id = store_code`** is a self-reference. Either wire up a real like-store lookup, or drop the column.
6. **Drop the 4 duplicated columns** (`company_name`, `district_name`, `region`, `channel`) or keep explicitly as aliases.
7. **`special_classification`** — decide: populate or drop.

### 🟢 P2 — cosmetic
8. CAST `latitude`/`longitude` to FLOAT64 in canonical view.
9. Resolve `s3_id` → 2 IDs with multiple names.
10. Flag placeholder `open_date` = `1999-12-31` in UX.

### 🎯 Strategic
11. **China ECOMM:** model Tmall / WeChat / JD as **separate channels**, not one aggregate.
12. **95 digital stores, not 10** — re-classify the 85 non-transacting VIRTUAL stores (drop-ship? placeholders? new launches?).
13. **Gap to close:** Location Attributes feed (square-footage, rent, mall tier, foot-traffic). Currently absent. Ask client.

---

## 12. Source artifacts

- Store Master EDA → [`findings/store_master_eda.md`](store_master_eda.md)
- Build logic audit → [`findings/master_table_build_logic.md`](master_table_build_logic.md) (Section 4 store_master)
- Raw verification queries (V4, V5, V6, V13) → [`queries/raw_source_verification_phase1.sql`](../queries/raw_source_verification_phase1.sql)
- Schema reference → [`findings/schema_inventory.md`](schema_inventory.md)
- Dataset inventory (all 300+ tables) → [`findings/dataset_inventory.md`](dataset_inventory.md)
- Anomaly status table → [`findings/anomaly_status_with_verification_sql.md`](anomaly_status_with_verification_sql.md)
