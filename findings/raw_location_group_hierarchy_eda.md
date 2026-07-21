# EDA — `lulu_sourcing_dev.location_group_hierarchy` (raw)

`Last updated: 2026-05-18.`

Source-level EDA for the second raw input to `store_master`. Feeds the build as the spine via `FROM ... AS a LEFT JOIN location_details ... AS b ON a.loc_id = b.id` in `queries/store_master_intermediate_build.sql`. Provides the BRAND / MARKET / CHANNEL / REGION / AREA hierarchy that becomes `s0_name..s5_name` in store_master.

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_sourcing_dev.location_group_hierarchy` |
| Created (IST) | 2026-05-14 15:32:12 |
| Last modified (IST) | 2026-05-14 15:32:21 (9s after create — single load, same batch as location_details) |
| Row count | **1,853** (matches `location_details` exactly) |
| Size | 0.71 MB |
| Column count | 44 (43 STRING + 1 DATETIME) |

### Schema

Grouped by semantic category for readability:

| Category | Columns |
|---|---|
| Brand | `BRAND_ID`, `BRAND_NAME` |
| Market | `MARKET_ID`, `MARKET_NAME`, `PLANNING_MARKET_CURRENCY` |
| Channel (3 levels) | `MARKET_CHANNEL_ID`, `MARKET_CHANNEL_NAME`, `SUB_MARKET_CHANNEL_ID`, `SUB_MARKET_CHANNEL_NAME`, `GEO_REGION_CHANNEL_ID`, `GEO_REGION_CHANNEL_NAME` |
| Location identity | `LOC_ID`, `LOC_NAME`, `LOC_TYPE`, `LOC_FORMAT`, `EXTERNAL_ID` |
| Country / locale | `COUNTRY_ID`, `COUNTRY_NAME`, `CURRENCY_ID`, `POSTAL_CODE`, `PHYSICAL_COUNTRY_ID`, `SERVICE_COUNTRY_ID` |
| Geography | `REGION_ID`, `REGION_NAME`, `AREA_ID`, `AREA_NAME`, `GEO_REGION_ID`, `GEO_REGION_NAME`, `CITY`, `STATE`, `LONGITUDE`, `LATITUDE` |
| Distribution / planning | `PRIMARY_DC_ID`, `PHYSICAL_DC_ID`, `MFP_PLANNING_TYPE`, `DC_DIRECT_DEMAND`, `PLACEHOLDER_FLAG` |
| Operational dates | `OPERATIONAL_OPEN_DAY_ID`, `OPERATIONAL_CLOSE_DAY_ID`, `MPA_OPEN_DAY_ID`, `MPA_CLOSE_DAY_ID` |
| Flags | `LOC_CLOSED_IND`, `DELETE_IND` |
| System | `SYNCSTARTDATETIME` |

### Notable observations from schema + 5-row sample

| # | Observation | Implication |
|---|---|---|
| 1 | All 44 raw fields are STRING (only SYNCSTARTDATETIME is properly typed) | Canonical Lululemon raw pattern. Type-cleaning happens in `store_intermediate`. |
| 2 | All sample rows are `BRAND_ID = LULU`, `BRAND_NAME = LULULEMON` | Likely single-brand table — verify in Phase 4 distributions. |
| 3 | Two-level channel hierarchy: `MARKET_CHANNEL_ID` (e.g. `LLL_APAC_CMNTY`) and `SUB_MARKET_CHANNEL_ID` (e.g. `LLL_ASIA_CMNTY`) | Different region abbreviations (APAC vs ASIA). Worth investigating. |
| 4 | `MARKET_CHANNEL_ID` value matches `location_details.CHANNEL_CODE` | Same identifier surfaced under different column names across the two tables. |
| 5 | `LOC_TYPE` uses single chars (`S`/`W`) vs `location_details.TYPE_CODE` uses words (`RETAIL`/`OUT_OF_SCOPE`) | Two different categorization systems coexist for the same locations. |
| 6 | `LOC_NAME` format matches `location_details.DISPLAY_NAME` (`<LOC_ID>:<NAME>`) | Likely 1:1 duplicate column across the two tables. |
| 7 | **Inconsistent sentinel format:** `PHYSICAL_DC_ID` shows `\\N` (double backslash) vs other cols using `\N` (single backslash) | Possible data quality issue — `NULLIF(TRIM(...), '\\N')` may not catch the double-backslash version. Verify in Phase 3. |
| 8 | `LOC_CLOSED_IND = '1'` (numeric string) vs `DELETE_IND = 'false'` (boolean string) | Different boolean conventions in the same table. |
| 9 | Many redundant `_ID` + `_NAME` pairs (MARKET/REGION/AREA/GEO_REGION/etc.) | Classic denormalized hierarchy — informative for one-pass scans but noisy. |
| 10 | `PLANNING_MARKET_CURRENCY` (USD) ≠ `CURRENCY_ID` (local HKD/JPY/MYR/KRW) | Planning currency standardized to USD; transactional currency is local. |
| 11 | `EXTERNAL_ID` (e.g. 2000187, 2000191) | Additional ID system, source unclear — may be an external system's identifier. Worth a one-off check. |
| 12 | `SYNCSTARTDATETIME = 2026-05-08T00:00:00` (all sample rows) | Same sync batch as location_details. Single batch. |

### What downstream consumers can rely on (so far)

- 44 columns, all STRING except SYNCSTARTDATETIME
- Same 1,853-row grain as location_details (1:1 mapping expected — confirmed in Phase 5 of location_details EDA)
- `LOC_ID` is the join key into `location_details.ID`

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Row count vs distinct LOC_IDs | 1,853 = 1,853 | `LOC_ID` is **perfectly unique** |
| Duplicate LOC_IDs | 0 | No dupes |
| NULL or blank LOC_IDs | 0 | Every row has a LOC_ID |
| LOC_ID format | 100% numeric, length 1–10 chars | Identical format to `location_details.ID` |
| Bijection with `location_details.ID` (after LPAD) | 1,853 = 1,853 matched, 0 orphans either side | **Perfect parity** — both tables describe the same set of locations |

**Conclusions:**

- `LOC_ID` is the natural primary key; same identifier system as `location_details.ID`.
- Cleaning recipe `LPAD(CAST(LOC_ID AS STRING), 10, '0')` aligns with `location_details` cleaning — guaranteed JOIN-compatible.
- Since both source tables have identical row sets, the LEFT JOIN in `store_master_intermediate` is structurally an INNER JOIN — no orphans introduced.

## Phase 3 — Completeness

| Column | NULL | Empty | `\N` | `\\N` | Total | % | Sentinel pattern |
|---|---:|---:|---:|---:|---:|---:|---|
| `PHYSICAL_DC_ID` | 0 | 0 | 0 | **1,724** | 1,724 | 93.0% | `\\N` |
| `MPA_CLOSE_DAY_ID` | 0 | 0 | 1,682 | 0 | 1,682 | 90.8% | `\N` |
| `OPERATIONAL_CLOSE_DAY_ID` | 0 | 0 | 1,427 | 0 | 1,427 | 77.0% | `\N` |
| `MPA_OPEN_DAY_ID` | 0 | 0 | 705 | 0 | 705 | 38.0% | `\N` |
| `LOC_FORMAT` | 0 | 0 | 392 | 0 | 392 | 21.2% | `\N` |
| `OPERATIONAL_OPEN_DAY_ID` | 0 | 0 | 390 | 0 | 390 | 21.0% | `\N` |
| `LATITUDE` | 0 | 0 | 343 | 0 | 343 | 18.5% | `\N` (vs empty string in location_details — inconsistent!) |
| `LONGITUDE` | 0 | 0 | 343 | 0 | 343 | 18.5% | `\N` |
| `POSTAL_CODE` | 0 | 0 | 285 | 0 | 285 | 15.4% | `\N` |
| `STATE` | 0 | 0 | 281 | 0 | 281 | 15.2% | `\N` |
| `CITY` | 0 | 0 | 279 | 0 | 279 | 15.1% | `\N` |
| `MFP_PLANNING_TYPE` | 0 | 0 | 278 | 0 | 278 | 15.0% | `\N` |
| `LOC_CLOSED_IND` | 0 | 0 | 199 | 0 | 199 | 10.7% | `\N` |
| `AREA_ID` | 0 | 0 | 0 | **7** | 7 | 0.4% | `\\N` |
| `AREA_NAME` | 0 | 0 | 7 | 0 | 7 | 0.4% | `\N` (note: paired with AREA_ID's `\\N` — sentinels split by ID vs NAME) |
| `REGION_ID` | 0 | 0 | 0 | **7** | 7 | 0.4% | `\\N` |
| `REGION_NAME` | 0 | 0 | 7 | 0 | 7 | 0.4% | `\N` |
| `EXTERNAL_ID` | 0 | 0 | 0 | **4** | 4 | 0.2% | `\\N` |
| Remaining 25 cols | 0 | 0 | 0 | 0 | 0 | 0% | Always populated |

### Big takeaway — double-backslash sentinel is a cleaning gap

The canonical cleaning recipe `NULLIF(TRIM(<col>), '\\N')` strips the SINGLE-backslash `\N` only. Columns that use `\\N` (double backslash) pass through to `store_master` as literal `\\N` strings:

| Column | Affected rows | % | Impact in store_master |
|---|---:|---:|---|
| `PHYSICAL_DC_ID` | 1,724 | **93%** | Not currently selected into store_master — no immediate impact, but if downstream consumers pick it up, they'll see `\\N` strings instead of NULL |
| `AREA_ID` | 7 | 0.4% | Lands as `\\N` in store_master.s3_id (since cleaning passes it through) — 7 stores have `\\N` instead of a real area_id |
| `REGION_ID` | 7 | 0.4% | Used in `location_hierarchy_region_code` build (`CONCAT(REGION_ID, '_', COALESCE(REGION_NAME, ''))`) — these 7 stores get a code like `\\N_<region_name>` |
| `EXTERNAL_ID` | 4 | 0.2% | Not selected into store_master |

### Pattern observation — sentinels split by ID vs NAME

Where both `_ID` and `_NAME` columns exist for the same dimension (AREA, REGION), the `_ID` uses `\\N` and the `_NAME` uses `\N`. Same logical "missing", different sentinel representations.

### Cleaning-recipe fix candidate

Extend the canonical cleaning to handle both sentinels:

```sql
NULLIF(NULLIF(TRIM(<col>), '\\N'), '\\\\N') AS <col>
```

(Two-pass `NULLIF` — first stripping `\N`, then `\\N`.) Worth applying in `queries/store_master_intermediate_build.sql` to AREA_ID, REGION_ID, EXTERNAL_ID and (defensively) every other `_ID` column.

### Other observations

- **25 columns are 100% populated** — mostly BRAND, MARKET, CHANNEL, COUNTRY, GEO_REGION hierarchy. These are reliable for downstream JOINs and groupings.
- **90.8% of stores have no MPA_CLOSE_DAY_ID, 77% no OPERATIONAL_CLOSE_DAY_ID** — most stores still open. Note these track DIFFERENT close events (MPA = Market Plan / Allocation; Operational = actual store closure).
- **LOC_FORMAT 21% missing** — includes the DC rows (warehouses don't have a "store format").
- **LOC_CLOSED_IND missing on 199 rows (10.7%)** — when LOC_CLOSED_IND is set, sample shows `'1'` (numeric string). Effectively a 3-state field: present (`'1'`), present (`'0'`), or `\N`.

## Phase 4 — Distributions

### BRAND_NAME — single-brand table confirmed

| Value | Rows | % |
|---|---:|---:|
| LULULEMON | 1,853 | 100% |

→ BRAND_ID/BRAND_NAME are pure constants. Drop them from any downstream group-by; they add zero information.

### MARKET_NAME — 4 markets

| Market | Rows | % |
|---|---:|---:|
| LULULEMON NAM | 1,106 | 59.7% |
| LULULEMON CHINA | 317 | 17.1% |
| LULULEMON APAC | 272 | 14.7% |
| LULULEMON EMEA | 158 | 8.5% |

NAM dominates. **China is a separate market from APAC** (likely reflects org structure / planning autonomy).

### MARKET_CHANNEL_NAME — 20 distinct values

Pattern: `LULULEMON <TYPE> <REGION>`. Same 20-value count as `location_details.CHANNEL_CODE` (likely the same identifier set, just different naming conventions).

**Naming inconsistency:** NAM and EMEA use `CMNTY` (abbreviation), APAC and CHINA use `COMMUNITY` (full word):

| Region | Community channel name |
|---|---|
| NAM | LULULEMON CMNTY NAM (22) |
| EMEA | LULULEMON CMNTY EMEA (4) |
| APAC | LULULEMON COMMUNITY APAC (10) |
| CHINA | LULULEMON COMMUNITY CHINA (3) |

→ Filter logic using `LIKE '%CMNTY%'` will miss APAC/CHINA community channels. Same for `LIKE '%COMMUNITY%'` missing NAM/EMEA. Use the underlying ID (`MARKET_CHANNEL_ID`) which is more consistent.

### SUB_MARKET_CHANNEL_NAME — 25+ values (more granular split)

Pattern: `LULULEMON <TYPE> <SUB_REGION>`. Splits NAM into USA / CAN / MEX, APAC into ASIA / AUS_NZ, etc. CHINA and EUR are single (no sub-split).

| Top values | Rows |
|---|---:|
| LULULEMON RETAIL USA | 756 |
| LULULEMON RETAIL CHINA | 281 |
| LULULEMON RETAIL CAN | 155 |
| LULULEMON RETAIL ASIA | 144 |
| LULULEMON RETAIL EUR | 94 |

→ Use SUB_MARKET_CHANNEL_NAME for country-level / sub-region analytics; MARKET_CHANNEL_NAME for region-level.

### LOC_TYPE — coarse 2-value categorization

| Value | Rows | % |
|---|---:|---:|
| S (store) | 1,724 | 93.0% |
| W (warehouse / DC) | 129 | 7.0% |

→ This is the **coarser** categorization; `location_details.TYPE_CODE` had 5 finer values (RETAIL / OUT_OF_SCOPE / ECOM / DC_ECOM / VIRTUAL_DC). 1,724 stores here = 1,501 RETAIL + 64 ECOM + 30 VIRTUAL_DC + 129 OUT_OF_SCOPE (... math doesn't quite add up — confirms 1 store can have S type but be OUT_OF_SCOPE per location_details).

### LOC_FORMAT — 16 distinct values + sentinel

| Value | Rows |
|---|---:|
| MALL | 525 (28%) |
| `\N` | 392 (21%) — missing |
| POP-UP | 286 |
| STREET | 200 |
| LIFESTYLE | 184 |
| OUTLET | 95 |
| VIRTUAL | 65 |
| SHOWROOM | 33 |
| E-COMMERCE | 30 |
| SHOP_IN_SHOP | 23 |
| ... long tail | < 10 each |
| **N/A** (literal string) | **2** |

→ Mostly self-explanatory. **`N/A` (literal) appears 2 times — different from `\N` sentinel.** Worth knowing for completeness checks: `LOC_FORMAT IS NULL OR LOC_FORMAT IN ('\\N', 'N/A')` covers all "missing" forms.

### PLANNING_MARKET_CURRENCY vs CURRENCY_ID

| PLANNING_MARKET_CURRENCY | Distinct local CURRENCY_IDs | Rows |
|---|---:|---:|
| USD | 24 | 1,853 |

→ **Planning currency is uniformly USD across all locations**; local currency varies across 24 countries. So PLANNING_MARKET_CURRENCY is effectively a constant — drop from any group-by.

## Phase 5 — Cross-table integrity

### 5A. LOC_ID → store_master.store_code coverage

| Metric | Value |
|---|---:|
| Distinct LOC_IDs (LPAD'd) | 1,853 |
| Distinct store_codes in store_master | 1,853 |
| Matched | **1,853** |
| LGH-only (orphans) | 0 |
| store_master-only | 0 |

→ **Perfect bijection.** Every location in this raw table is preserved into `store_master`, and store_master contains no synthetic rows. The build SQL's LEFT JOIN behaves like an INNER JOIN by data shape.

### 5B. Market → Channel → Sub-channel hierarchy

| Market | Distinct channels | Distinct sub-channels | Rows |
|---|---:|---:|---:|
| LULULEMON NAM | 5 | 14 | 1,106 |
| LULULEMON CHINA | 5 | 5 | 317 |
| LULULEMON APAC | 5 | 9 | 272 |
| LULULEMON EMEA | 5 | 5 | 158 |

→ **Clean 4×5 matrix** — every market has the same 5 channel types (RETAIL / FO / ECOMM / STRAT / CMNTY-or-COMMUNITY). Sub-channel split varies by geo granularity:

- NAM: 14 sub-channels (USA / CAN / MEX × multiple channels)
- APAC: 9 (ASIA / AUS_NZ × multiple)
- CHINA: 5 (no sub-split — CHINA is its own atomic sub-region)
- EMEA: 5 (EUR is the only sub-region)

### 5C. PRIMARY_DC_ID referential integrity (self-join)

| Metric | Value |
|---|---:|
| Distinct PRIMARY_DC_IDs (excluding `\N` / `\\N`) | 130 |
| Matched to a LOC_ID in same table | 129 |
| **Orphan PRIMARY_DC_IDs** | **1** |

→ **1 data-quality issue:** one store's PRIMARY_DC_ID points to a DC that does not exist in the location universe. Downstream consumers building DC→store maps will silently lose this one store. Worth filing as a known issue.

## Phase 6 — Business-logic checks

### 6A. PHYSICAL_DC_ID is a perfect partition by LOC_TYPE

| LOC_TYPE | PHYSICAL_DC_ID = `\\N` | PHYSICAL_DC_ID populated | Rows |
|---|---:|---:|---:|
| S (store) | 1,724 | 0 | 1,724 |
| W (warehouse) | 0 | 129 | 129 |

→ The `\\N` sentinel in PHYSICAL_DC_ID is **structural, not erroneous** — it means "this location is not a DC, so there's no physical DC ID to record." Cleaning should:

```sql
NULLIF(NULLIF(TRIM(PHYSICAL_DC_ID), '\\N'), '\\\\N') AS physical_dc_id
```

(Two-pass NULLIF to strip both sentinel formats — see Phase 3 fix candidate.)

### 6B. LOC_CLOSED_IND — INVERTED / misleading semantics

| LOC_CLOSED_IND | close_date present? | Rows |
|---|---|---:|
| 0 | has close date | 315 |
| 1 | has close date | 107 |
| 1 | **no close date** | **1,232** |
| `\N` | has close date | 4 |
| `\N` | no close date | 195 |

**The field name suggests `1=closed, 0=open`, but the data says the opposite:**

- `LOC_CLOSED_IND='1'` dominates (1,339 rows) AND is overwhelmingly paired with NO close date (1,232 / 1,339 = 92%)
- `LOC_CLOSED_IND='0'` rows ALL have a close date (315 / 315 = 100%)

→ Most likely interpretation: `LOC_CLOSED_IND='1'` means "**operational / open**" and `='0'` means "**not operational / closed**". The field is named backwards. **Naming trap for downstream consumers — verify with business owners.**

A possible alternative: `LOC_CLOSED_IND` may be referring to "is currently closed for the business day" (open/closed indicator) rather than permanently closed, but that's speculative.

### 6C. MARKET_CHANNEL_ID = location_details.CHANNEL_CODE (per-LOC_ID match)

| Metric | Value |
|---|---:|
| Exact match | **1,853** |
| Mismatch | 0 |
| Total | 1,853 |

→ **Confirmed:** `MARKET_CHANNEL_ID` in this table and `CHANNEL_CODE` in `location_details` are the **same identifier** with different column names. Either can be used interchangeably for channel-based joins or filters.

## Summary — what store_master inherits from this table

| Category | Reliable for downstream? | Notes |
|---|---|---|
| BRAND, MARKET, CHANNEL, SUB_CHANNEL, GEO_REGION hierarchy | Yes — 100% populated, clean 4×5 matrix | Use IDs not names (naming inconsistencies: CMNTY vs COMMUNITY) |
| COUNTRY_ID, COUNTRY_NAME, CURRENCY_ID | Yes — 100% populated | 24 distinct currencies; planning currency always USD |
| LOC_TYPE (S/W) | Yes — clean 2-value | Coarser than location_details.TYPE_CODE |
| LOC_FORMAT | Mostly (79%) | 21% `\N`; 2 rows have literal `'N/A'` |
| Geo fields (CITY, STATE, LAT, LONG) | 85% | Same gaps as location_details for the same rows |
| Operational dates | Sparse | Most stores have OPEN date, very few have CLOSE date |
| PHYSICAL_DC_ID | DC rows only (7%) | `\\N` (double backslash) for stores — cleaning gap if used directly |
| AREA_ID, REGION_ID, EXTERNAL_ID | Yes, but `\\N` sentinel | Affects 7/7/4 rows — cleaning gap if recipe only strips `\N` |
| LOC_CLOSED_IND | **Avoid until semantics confirmed** | Field name is misleading — `'1'` appears to mean "open" not "closed" |

## Action items for `store_master_intermediate_build.sql`

1. **Extend cleaning to strip `\\N`** (double-backslash) in addition to `\N`: especially for `AREA_ID`, `REGION_ID`, `EXTERNAL_ID`, `PHYSICAL_DC_ID` if these get added.
2. **Document the `LOC_CLOSED_IND` naming trap** in build comments — and confirm semantics with business before using as a filter.
3. **`PLANNING_MARKET_CURRENCY` is a constant (USD)** — drop from any group-by.
4. **`BRAND_NAME` is a constant (LULULEMON)** — drop from any group-by.
5. **Treat `MARKET_CHANNEL_ID` and `location_details.CHANNEL_CODE` as the same field** — pick one source of truth.
