# EDA — `lulu_sourcing_dev.location_details` (raw)

`Last updated: 2026-05-18.`

Source-level EDA for one of two raw inputs to `store_master`. Feeds the build via `LEFT JOIN ... ON a.loc_id = b.id` in `queries/store_master_intermediate_build.sql`.

## Phase 1 — Foundation

| Metric | Value |
|---|---|
| Project / dataset / table | `lululemon-01042025.lulu_sourcing_dev.location_details` |
| Created (IST) | 2026-05-14 15:32:09 |
| Last modified (IST) | 2026-05-14 15:32:18 (9s after create — single load, no later updates) |
| Row count | **1,853** |
| Size | 0.26 MB |
| Column count | 15 (14 STRING + 1 DATETIME) |

### Schema

| # | Column | Type | Nullable |
|---:|---|---|---|
| 1 | `ID` | STRING | YES |
| 2 | `DISPLAY_NAME` | STRING | YES |
| 3 | `TYPE_CODE` | STRING | YES |
| 4 | `COUNTRY_CODE` | STRING | YES |
| 5 | `CHANNEL_CODE` | STRING | YES |
| 6 | `STATE` | STRING | YES |
| 7 | `REGION` | STRING | YES |
| 8 | `CITY` | STRING | YES |
| 9 | `POSTAL_CODE` | STRING | YES |
| 10 | `FIRST_OPEN_DATE` | STRING | YES |
| 11 | `PERMANANENT_CLOSE_DATE` | STRING | YES |
| 12 | `LATITUDE` | STRING | YES |
| 13 | `LONGITUDE` | STRING | YES |
| 14 | `DELETE_IND` | STRING | YES |
| 15 | `SYNCSTARTDATETIME` | DATETIME | YES |

### Notable observations from schema + 5-row sample

| # | Observation | Implication |
|---|---|---|
| 1 | All raw fields are STRING (only `SYNCSTARTDATETIME` is properly typed) | Canonical Lululemon raw pattern. Type-cleaning (CAST, LPAD, NULLIF) happens downstream in `store_intermediate`. |
| 2 | `\N` sentinel observed in `PERMANANENT_CLOSE_DATE` (3 of 5 sample rows) | Cleaning must use `NULLIF(TRIM(<col>), '\\N')` — already in the canonical recipe. |
| 3 | Empty strings (not NULL) in `LATITUDE` / `LONGITUDE` | NULL-checks downstream must include `IS NULL OR <col> = ''`. |
| 4 | `DELETE_IND` is STRING `'false'` (lowercase) — not BOOL | Cleaning carries it as STRING. Downstream consumers should `LOWER(DELETE_IND) = 'true'` (not `= TRUE`). |
| 5 | Source typo preserved: `PERMANANENT_CLOSE_DATE` | Don't "fix" in queries — match the live name. |
| 6 | Future-dated row in sample: `FIRST_OPEN_DATE = '2027-02-01'` (Sapporo) | **Planned-but-not-yet-open stores exist.** Date filters must account for `FIRST_OPEN_DATE > today`. |
| 7 | `CHANNEL_CODE` has structure: `LLL_<REGION>_<TYPE>` (e.g. `LLL_APAC_RTL`, `LLL_EMEA_STRAT`, `LLL_APAC_FO`) | Composite identifier — could be split for region/channel-type analysis. Phase 4 will enumerate values. |
| 8 | `TYPE_CODE` values in sample: `RETAIL`, `OUT_OF_SCOPE` | Multiple location categories — Phase 4 will show full distribution. |
| 9 | `SYNCSTARTDATETIME` = `2026-05-08T00:00:00` (all sample rows) | Single sync batch — matches `extraction_sync_dt` in the platform Mapping table. |

### What downstream consumers can safely rely on (so far)

- Stable schema: 15 cols, all STRING except SYNCSTARTDATETIME (DATETIME)
- Row count is small (~1.8K) — full scans are cheap, no need for partition/cluster optimisation
- `ID` looks like the natural primary key (Phase 2 will confirm uniqueness)

## Phase 2 — Grain & uniqueness

| Check | Result | Verdict |
|---|---|---|
| Row count vs distinct IDs | 1,853 = 1,853 | `ID` is **perfectly unique** |
| Duplicate IDs | 0 | No dupes |
| NULL or blank IDs | 0 | Every row has an ID |
| ID format | 100% numeric, length 1–10 chars | Variable-length numeric strings |

**Conclusions:**

- `ID` is the natural primary key. Safe to use as join key downstream.
- Cleaning recipe `LPAD(CAST(ID AS STRING), 10, '0') AS ID` normalises to 10-char zero-padded format. Since BQ's `LPAD` doesn't truncate longer inputs, this is safe even if future clients send IDs longer than 10 chars (they'd pass through unchanged).
- For future data updates: if `dup_id_count > 0` ever, downstream JOINs to store_master will produce row-multiplication. Re-run query 2A as a regression check.

## Phase 3 — Completeness

Each "missing" value is one of: actual NULL, empty string `''`, or `\N` sentinel. Profile per column:

| Column | NULL | Empty `''` | `\N` | Total missing | % missing | Sentinel pattern |
|---|---:|---:|---:|---:|---:|---|
| PERMANANENT_CLOSE_DATE | 0 | 0 | 1,427 | 1,427 | 77.0% | `\N` — most stores still open |
| FIRST_OPEN_DATE | 0 | 390 | 0 | 390 | 21.0% | Empty string |
| LATITUDE | 0 | 343 | 0 | 343 | 18.5% | Empty string |
| LONGITUDE | 0 | 343 | 0 | 343 | 18.5% | Empty string |
| POSTAL_CODE | 0 | 0 | 285 | 285 | 15.4% | `\N` |
| STATE | 0 | 0 | 281 | 281 | 15.2% | `\N` |
| CITY | 0 | 0 | 279 | 279 | 15.1% | `\N` |
| REGION | 0 | 0 | 7 | 7 | 0.4% | `\N` |
| ID, DISPLAY_NAME, TYPE_CODE, COUNTRY_CODE, CHANNEL_CODE, DELETE_IND, SYNCSTARTDATETIME | 0 | 0 | 0 | 0 | 0% | Always populated |

**Key observations:**

1. **Zero actual NULLs anywhere.** Source data uses sentinels (`\N` or `''`), not NULL.
2. **Two distinct sentinel patterns coexist:**
   - `\N` used for: PERMANANENT_CLOSE_DATE, POSTAL_CODE, STATE, CITY, REGION
   - Empty string `''` used for: FIRST_OPEN_DATE, LATITUDE, LONGITUDE
   - No mixing — each column consistently uses one or the other.
3. **77% of stores have no PERMANENT_CLOSE_DATE** — expected (most stores are still operating).
4. **~15–18% of locations missing geo / city / postal_code** — likely virtual stores, DCs, or out-of-scope locations.

### Cleaning-recipe gap to flag

The canonical `location_details_cleaned` build only applies `NULLIF(TRIM(<col>), '\\N')` — it does **not** strip empty strings. So:

| Column | Source missing pattern | After cleaning | Downstream impact |
|---|---|---|---|
| PERMANANENT_CLOSE_DATE | `\N` (1,427 rows) | Properly NULL | OK |
| POSTAL_CODE, STATE, CITY, REGION | `\N` | Properly NULL | OK |
| **LATITUDE, LONGITUDE** | empty string (343 rows each) | **Still empty string** (not NULL) | `IS NULL` checks miss 343 rows. Consumers must `IS NULL OR <col> = ''`. |
| FIRST_OPEN_DATE | empty string (390 rows) | Still empty string | Same caveat — but not currently selected into store_master, so moot for that path. |

**Fix candidate** (not blocking, but worth filing): change `LATITUDE` / `LONGITUDE` passthrough in `queries/store_master_intermediate_build.sql` to `NULLIF(TRIM(LATITUDE), '')`. Would normalise empty-string-as-null across the entire downstream chain.

## Phase 4 — Distributions

### TYPE_CODE — 5 distinct values

| Value | Rows | % |
|---|---:|---:|
| RETAIL | 1,501 | 81.0% |
| OUT_OF_SCOPE | 208 | 11.2% |
| ECOM | 64 | 3.5% |
| DC_ECOM | 50 | 2.7% |
| VIRTUAL_DC | 30 | 1.6% |

**Observation:** 11% of locations are OUT_OF_SCOPE. Downstream analytics likely want to filter these out (`TYPE_CODE != 'OUT_OF_SCOPE'`) for active-store reporting.

### COUNTRY_CODE — top 10 (long tail)

| Country | Rows |
|---|---:|
| US | 854 (46%) |
| CN | 316 (17%) |
| CA | 206 (11%) |
| AU | 65 |
| KR | 46 |
| MX | 46 |
| GB | 44 |
| HK | 43 |
| JP | 38 |
| CH | 32 |

**Observation:** Heavy US concentration (~46%). North America (US + CA + MX) ≈ 60%.

### CHANNEL_CODE — systematic naming `LLL_<REGION>_<TYPE>`

| Channel | Rows | Note |
|---|---:|---|
| LLL_NAM_RTL | 951 (51.3%) | North America retail dominates |
| LLL_CHINA_RTL | 281 (15.2%) | |
| LLL_APAC_RTL | 205 (11.1%) | |
| LLL_EMEA_RTL | 94 (5.1%) | |
| LLL_NAM_FO | 67 | Factory outlet |
| LLL_*_ECOM (4 regions) | 114 combined | E-commerce |
| LLL_*_STRAT, *_CMNTY, *_FO | ~85 combined | Strategic / community / factory outlet |

**Observation:** Naming pattern is fully systematic:

- Regions: `NAM`, `CHINA`, `APAC`, `EMEA`
- Types: `RTL` (retail), `ECOM`, `FO` (factory outlet), `STRAT` (strategic), `CMNTY` (community)

Could be parsed into `region_code` + `channel_type` columns downstream if needed.

### DELETE_IND — single value

All 1,853 rows have `DELETE_IND = 'false'`. **No soft-deleted records in this snapshot.** Column is effectively useless for filtering today, but future data may include `'true'` values — downstream consumers should still respect it.

### Date sanity (FIRST_OPEN_DATE)

| Check | Count |
|---|---:|
| Future-dated (`FIRST_OPEN_DATE > today`) | 30 |
| Unparseable (non-empty but not a valid date) | 0 |
| Valid date or empty | 1,823 |

**Observations:**

1. **30 planned-but-not-yet-open stores** exist (FIRST_OPEN_DATE in the future). Downstream time-series queries should filter `FIRST_OPEN_DATE <= CURRENT_DATE()` if they want only currently-operating locations.
2. Zero unparseable dates — every non-empty `FIRST_OPEN_DATE` is a valid `YYYY-MM-DD`.

## Phase 5 — Cross-table integrity (vs `store_master`)

`location_details.ID` (after `LPAD(... 10, '0')` cleaning) should map 1:1 to `store_master.store_code`. Verified:

| Check | Count | Verdict |
|---|---:|---|
| `location_details` rows | 1,853 | — |
| Distinct padded IDs | 1,853 | Padding is bijective (no collisions from `LPAD`) |
| `store_master` distinct `store_code` | 1,853 | — |
| Matched (intersection) | 1,853 | All rows joined cleanly |
| `location_details`-only orphans | 0 | Every location made it to store_master |
| `store_master`-only orphans | 0 | Every store row backed by a location |

**Conclusion:** `location_details` → `store_intermediate` → `store_master` is a perfect 1:1 pass-through. No data loss, no spurious additions. The build SQL's `LEFT JOIN` is well-behaved.

**For future data updates:** if `ld_only_orphans > 0` after a future load, either the cleaning step changed, the LEFT JOIN spine (`location_group_hierarchy`) lost coverage, or someone filtered rows downstream. If `sm_only_orphans > 0`, the `store_master` build acquired rows from somewhere besides `location_details` (shouldn't happen, but worth detecting).

## Phase 6 — Business-logic checks

### Active-store funnel

| Filter | Count | % of total |
|---|---:|---:|
| Total rows | 1,853 | 100% |
| In-scope (`TYPE_CODE != 'OUT_OF_SCOPE'`) | 1,645 | 88.8% |
| In-scope AND not closed | 1,262 | 68.1% |
| **Active today** (in-scope, not closed, `FIRST_OPEN_DATE <= today`) | **912** | **49.2%** |
| Planned future opens (`FIRST_OPEN_DATE > today`) | 30 | 1.6% |
| Closed ever (PERMANENT_CLOSE_DATE populated) | 426 | 23.0% |

**Headline:** of 1,853 raw locations, only **~912 (~50%) represent operationally-active stores today**. Downstream retail-analytics filters need to reduce accordingly.

### CHANNEL_CODE × TYPE_CODE — channel naming is semantically meaningful

| Channel suffix | TYPE_CODEs that appear | Interpretation |
|---|---|---|
| `_RTL` | RETAIL + a few VIRTUAL_DC | Physical retail (NAM_RTL has 937 RETAIL + 14 VIRTUAL_DC) |
| `_ECOM` | ECOM + DC_ECOM | E-commerce stores + ecom distribution centres |
| `_FO` (factory outlet) | **100% OUT_OF_SCOPE** | All factory outlets excluded from scope |
| `_CMNTY` (community) | **100% OUT_OF_SCOPE** | All community stores excluded |
| `_STRAT` (strategic) | **100% OUT_OF_SCOPE** | All strategic accounts excluded |

**Headline:** `OUT_OF_SCOPE` correlates perfectly with channel suffix (`_FO`, `_CMNTY`, `_STRAT`). Filter logic could equivalently use `CHANNEL_CODE NOT LIKE '%_FO' AND CHANNEL_CODE NOT LIKE '%_CMNTY' AND CHANNEL_CODE NOT LIKE '%_STRAT'`.

### Date range — opens and closes

| Metric | Date |
|---|---|
| Earliest open | 1999-01-11 |
| Latest open (or planned) | 2028-02-18 |
| Earliest close | 1999-12-31 (worth investigating — might be a sentinel) |
| Latest close (planned closures exist) | 2029-09-29 |

**Headline:** location history spans 1999–2028+. Planned future closures also exist — downstream "still open" filters need to handle both `PERMANENT_CLOSE_DATE > today` and `PERMANENT_CLOSE_DATE IS NULL/\N`.

## Phase 6 → wrap-up summary

### What downstream queries can safely assume

1. **`ID` is unique, never NULL/blank, 1–10 char numeric string.** Padded to 10 chars in cleaning. Safe as primary join key.
2. **Schema is stable**: 15 cols, all STRING except `SYNCSTARTDATETIME`. Sentinels (`\N` or `''`) used in place of true NULLs.
3. **1:1 mapping to `store_master`** — every `location_details` row makes it through; cleaning + build don't lose or duplicate rows.

### Known data-quality flags

1. **Empty-string sentinels not cleaned** for `LATITUDE`, `LONGITUDE`, `FIRST_OPEN_DATE` (343, 343, 390 rows respectively). Downstream `IS NULL` checks miss them. See "Cleaning-recipe gap" in Phase 3.
2. **Only ~50% of rows are "operationally active today"** (912 / 1,853). Downstream analytics filters should account for OUT_OF_SCOPE, closed, and future-dated stores.
3. **OUT_OF_SCOPE locations** (208 rows, 11%) are systematically tied to specific channel suffixes (`_FO`, `_CMNTY`, `_STRAT`) — useful for double-validation.
4. **`DELETE_IND = 'false'` for all rows in this snapshot** — soft-delete column not exercised. Future loads may include `'true'`.

### What to re-check if the source feed grows or changes

| Re-run query | Watch for |
|---|---|
| Phase 2 (PK uniqueness) | `dup_id_count > 0` → join multiplication risk |
| Phase 3 (completeness) | New columns appearing with high NULL %; existing always-populated cols becoming sparse |
| Phase 4 (TYPE_CODE distribution) | New TYPE_CODE values that filter logic doesn't know about |
| Phase 4 (CHANNEL_CODE distribution) | New `LLL_<REGION>_<TYPE>` patterns; new regions or types |
| Phase 5 (cross-table integrity) | Orphans either side → cleaning/build broke |
| Phase 6 (active-store funnel) | Sudden drop in active-store count |


