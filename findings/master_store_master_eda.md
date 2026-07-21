# EDA — `lulu_ingestion_dev.store_master` (canonical master)

`Last updated: 2026-05-18.` — **Health check (2026-05-20):** [`master_bq_health_check_2026-05-20.md`](master_bq_health_check_2026-05-20.md) — 1,853 rows; grain PASS.

Master-level EDA for the IA Platform–ingested store dimension. Built from `store_intermediate` (see `queries/store_master_intermediate_build.sql`) via Generic Schema Mapping.

**Important:** The live ingested table has **17 columns**, not the full 34-column intermediate shape. GSM controls which fields land in Postgres/BQ master.

## Quick Notes — column headers

Use **`channel`** in filters; **`s1_name`** is the same value (duplicate). Not the same as product `product_code` channel suffix (`_RETAIL` / `_ECOMM`).

| Column | What it is |
|---|---|
| `channel` / `s1_name` | Location **channel type** from hierarchy (2nd token of `SUB_MARKET_CHANNEL_NAME`). |
| `channel_code` | Full channel ID (e.g. `LLL_NAM_RTL`). Suffix uses **`RTL`**, not `RETAIL` — do not parse `channel` from `SPLIT(channel_code, '_')` without a map. |
| `store_format_code` | Physical format (MALL, OUTLET, E-COMMERCE, VIRTUAL, …). **Not** the same as `channel`. |
| `loc_type_code` | `S` = store, `W` = warehouse/DC. Aligns with `store_type` and `dc_flag`. |
| `active` | From raw `LOC_CLOSED_IND`; name is misleading. `'0'` ≈ closed store; **do not** assume `'1'` means closed. |
| `dc_flag` | `0` = store, `1` = DC (INT64 in master — compare to `0`/`1`, not bare BOOL literals). |

### `channel` values (~1,853 locations)

| Value | Meaning | Share |
|---|---|---:|
| RETAIL | Brick-and-mortar retail | ~83% |
| ECOMM | E-commerce (online + ecom DCs) | ~6% |
| FO | Factory outlet | ~6% |
| STRAT | Strategic accounts | ~3% |
| CMNTY | Community (NAM/EMEA naming) | ~1.4% |
| COMMUNITY | Same as CMNTY (APAC/China naming) | ~0.7% |

FO / STRAT / CMNTY / COMMUNITY rows are mostly **out of scope** in raw `location_details` (`TYPE_CODE = 'OUT_OF_SCOPE'`). For in-scope brick-and-mortar retail: `dc_flag = 0 AND channel = 'RETAIL'` (1,501 rows). See [`raw_location_details_eda.md`](raw_location_details_eda.md) for `CHANNEL_CODE` × `TYPE_CODE`.

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_ingestion_dev.store_master` |
| Created (IST) | 2026-05-15 15:38:14 |
| Last modified (IST) | 2026-05-15 15:38:14 (single load) |
| Row count | **1,853** |
| Size | 0.31 MB |
| Column count | **17** (16 STRING + 1 INT64) |

### Schema (live ingested)

| # | Column | Type | Maps from intermediate (semantic) |
|---:|---|---|---|
| 1 | `s0_name` | STRING | BRAND_NAME |
| 2 | `s1_name` | STRING | 2nd token of SUB_MARKET_CHANNEL_NAME |
| 3 | `s2_name` | STRING | COUNTRY_NAME |
| 4 | `s3_name` | STRING | AREA_NAME |
| 5 | `s4_name` | STRING | REGION_NAME |
| 6 | `channel` | STRING | Same as s1_name (channel type token) |
| 7 | `store_name` | STRING | LOC_NAME |
| 8 | `store_format_code` | STRING | LOC_FORMAT |
| 9 | `loc_type_code` | STRING | LOC_TYPE (S/W) |
| 10 | `store_code` | STRING | LPAD(LOC_ID, 10) |
| 11 | `s3_id` | STRING | AREA_ID |
| 12 | `company_name` | STRING | BRAND_NAME |
| 13 | `channel_code` | STRING | SUB_MARKET_CHANNEL_ID |
| 14 | `store_type` | STRING | Store / DC (from LOC_TYPE) |
| 15 | `company_code` | STRING | BRAND_ID |
| 16 | `active` | STRING | LOC_CLOSED_IND (misleading name) |
| 17 | `dc_flag` | INT64 | 1 if W else 0 |

### Columns in intermediate but NOT in ingested master

`longitude`, `latitude`, `ws_channel`, `location_num_store_name`, `zipcode`, `location_hierarchy_region_code`, `open_date`, `close_date`, `geography`, `special_classification`, `district_name`, `region`, `like_store_id`, `is_deleted`, `city`, `state`, `location_attrib_squareft`

→ Explains prior `Unrecognized name: like_store_id` errors — column exists in intermediate SQL but was not mapped in GSM.

### Notable observations from sample

| # | Observation | Implication |
|---|---|---|
| 1 | `s0_name` / `company_name` always LULULEMON | Constants — drop from group-bys |
| 2 | `channel` = `s1_name` always (RETAIL, ECOMM, FO, STRAT, CMNTY, COMMUNITY) | Duplicate columns in master |
| 3 | `store_code` is zero-padded 10-char (e.g. `0000050596`) | Join key for transaction/inventory masters |
| 4 | `active` is STRING (`'0'`/`'1'`/NULL), not BOOL | Use string comparison; `dc_flag` is INT64 (G14) |
| 5 | `store_type` = Store / DC aligns with `loc_type_code` S/W | Clean CASE mapping from build |

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Row count vs distinct store_code | 1,853 = 1,853 | **Perfect PK** |
| Duplicate store_codes | 0 | No dupes |
| NULL or blank store_code | 0 | Every row has a store_code |

## Phase 3 — Completeness

| Column | Missing (NULL or `''`) | % | Notes |
|---|---:|---:|---|
| `store_format_code` | 392 | 21.2% | Cleaned from raw `\N` → NULL |
| `active` | 199 | 10.7% | From raw LOC_CLOSED_IND `\N` |
| `s3_name`, `s4_name` | 7 each | 0.4% | AREA/REGION missing in raw |
| All other STRING cols | 0 | 0% | Fully populated |
| `dc_flag` | 0 NULL | 0% | Always 0 or 1 |

### Sentinel leftovers (cleaning gaps)

| Column | `\N` / `\\N` / `N/A` literal | Rows |
|---|---|---:|
| `s3_id` | literal `\\N` (double backslash) | **7** |
| `store_format_code` | literal `N/A` | 2 |
| `active` | none | 0 |

→ **7 stores have `s3_id = '\\N'`** — double-backslash sentinel passed through cleaning (see raw LGH EDA). `s3_name` / `s4_name` are NULL for same rows.

## Phase 4 — Distributions

### Hierarchy (s0–s4)

| Level | Column | Cardinality | Top values |
|---|---|---:|---|
| s0 | `s0_name` | 1 | LULULEMON (100%) |
| s1 / channel | `s1_name` / `channel` | 6 | RETAIL (82.6%), ECOMM (6.2%), FO (6.0%), STRAT (3.1%), CMNTY (1.4%), COMMUNITY (0.7%) |
| s2 | `s2_name` | ~24 countries | US (46%), China (17%), Canada (11%) |
| s3 | `s3_name` | many | 7 NULL |
| s4 | `s4_name` | many | 7 NULL |

### store_type × dc_flag × loc_type_code

| store_type | dc_flag | loc_type_code | Rows | % |
|---|---|---|---:|---:|
| Store | 0 | S | 1,724 | 93.0% |
| DC | 1 | W | 129 | 7.0% |

→ Perfect alignment — no contradictory combinations.

### store_format_code

MALL (28%), NULL (21%), POP-UP, STREET, LIFESTYLE, OUTLET, VIRTUAL, E-COMMERCE, etc. Two literal `'N/A'` rows (distinct from NULL).

### active (LOC_CLOSED_IND carried through)

| active | Rows | % |
|---|---:|---:|
| `'1'` | 1,339 | 72.3% |
| `'0'` | 315 | 17.0% |
| NULL | 199 | 10.7% |

→ Semantics likely inverted vs field name — see Phase 6 and raw LGH EDA. **Do not filter `active = '1'` assuming "closed".**

## Phase 5 — Cross-table integrity

### Raw source coverage

| Comparison | Matched | Orphans |
|---|---:|---:|
| store_master.store_code ↔ location_group_hierarchy (LPAD LOC_ID) | 1,853 | 0 |
| store_master.store_code ↔ location_details (LPAD ID) | 1,853 | 0 |

→ Full lineage preserved; no synthetic or dropped locations.

### channel vs channel_code

`channel` is derived from SUB_MARKET_CHANNEL_NAME token (e.g. `RETAIL`). `channel_code` is the full ID (e.g. `LLL_USA_RTL`). Suffix abbreviations differ (`RTL` vs `RETAIL`) — **do not equate** `channel` to `SPLIT(channel_code, '_')[2]` without a mapping table.

### s3_id sentinel rows (7 stores)

All are RETAIL channel_code (CAN/USA/EUR), `s3_id = '\\N'`, `s3_name`/`s4_name` NULL — Canada/US/Europe retail locations missing area/region in source.

## Phase 6 — Business-logic checks

### active semantics (sanity)

| active | store_type | Rows |
|---|---|---:|
| `'1'` | Store | 1,211 |
| `'0'` | Store | 315 |
| NULL | Store | 198 |
| `'1'` | DC | 128 |
| NULL | DC | 1 |

→ `'0'` only on Store rows (315) — consistent with "closed store" interpretation. `'1'` on both Store and DC. NULL mostly Store (198/199).

### Filter recipes (adapted — no ws_channel in master)

| Filter intent | SQL (on live master) | Count |
|---|---|---:|
| Retail stores (simple) | `dc_flag = 0 AND channel = 'RETAIL'` | 1,501 |
| Physical retail (approximate) | `dc_flag = 0 AND store_format_code NOT IN ('E-COMMERCE', 'VIRTUAL')` | 1,366 |

→ Full Section 5.2 recipe needs `ws_channel` from intermediate — **not available in ingested master**. Add `ws_channel` to GSM if OUT_OF_SCOPE filtering is required on master.

### store_intermediate vs store_master

| Table | Columns | Location |
|---|---|---|
| `lulu_sourcing_dev.store_intermediate` | 34 | Full build shape |
| `lulu_ingestion_dev.store_master` | 17 | IA Platform ingested subset |

## Summary — what consumers can rely on

| Reliable | Use with caution | Not in master |
|---|---|---|
| `store_code` as PK | `active` (inverted/misleading semantics) | `like_store_id`, `open_date`, `close_date` |
| `dc_flag` (INT64 0/1) | `s3_id` (7 rows = `\\N`) | `ws_channel`, `latitude`, `longitude` |
| `channel` / `channel_code` for channel splits | `store_format_code` (21% NULL) | `city`, `state`, `zipcode` |
| `s2_name` for country | `s3_name`/`s4_name` (7 NULL) | |

## Action items

1. **Extend GSM** to include columns needed by downstream SQL (`like_store_id` → use `store_code`; or map explicitly; add `ws_channel`, geo, dates if required).
2. **Fix double-backslash cleaning** in `store_master_intermediate_build.sql` for AREA_ID (→ `s3_id`).
3. **Clarify `active` semantics** with client before using as open/closed filter.
4. **Deduplicate** `channel` vs `s1_name` in master if platform allows schema trim.
