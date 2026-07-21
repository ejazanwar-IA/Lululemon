# Fiscal Calendar - EDA Findings

| Field | Value |
|-------|-------|
| **Table** | `lululemon-01042025.lululemon_souricng_outbound.calendar_hierarchy` |
| **Total Rows** | 4,746 | **Size:** 1.5 MB | **Columns:** 37 |
| **Status** | ✅ Complete — table is pristine |
| **Owner** | Ejaz Anwar | **Last Updated** | 2026-04-20 |

---

## 🎯 Executive Summary (for Uttkarsh)

**Status:** 🟢 **Pristine. Use with confidence. One forward-looking gap.**

**TL;DR:**

1. **100% clean** — zero nulls across 37 columns, zero duplicates, perfect hierarchy, 13 years of daily data with no gaps.
2. **One gap:** Spec requires 5 years future calendar; we have 2 (FY26-FY27). **Need to extend to FY2030**.
3. **`SEASON_CODE` matches product_master** — direct join works. Current product_master season `25-4WI` = Nov 3, 2025 → Feb 1, 2026.
4. **53-week years identified: FY2018 and FY2024.** Modeling must handle these (next one is FY2030).

**What you need to decide, Uttkarsh:**

- **Request FY2030 calendar extension from client** — we can't forecast 3-year horizon without it.
- **Nothing else** — this table requires no internal work.

---

## 💡 My Recommendations (as analyst)

1. **Join transactions → calendar via `date = DAY_ID`** (both native DATE, trivial).
2. **For YoY comparisons: use `ADJUSTED_LY_WEEK_ID`** (it correctly handles the 53-week-year shift that would throw off a naive year-diff). **BUT** 371 rows (7.8%) have the sentinel value `201401` — those weeks have no valid LY comp. Treat as NULL in modeling.
3. **Don't hardcode season list.** Use `SEASON_CODE` from this table as the authoritative set. Currently 52 seasons (BP09 → BP60 covering FY15-FY27).
4. **Extend calendar ASAP if Forecast Smart horizon is 3+ years.** Spec (Data Requirements sheet) said 5 future years. Current max is Jan 2028. Go-live 2026/2027 means we need FY2030+ for out-of-sample modeling.

---

## Key Findings

### Shape

| Metric | Value |
|--------|------:|
| Total rows | 4,746 |
| **PK** | `DAY_ID` (DATE) |
| Date range | 2015-02-02 → 2028-01-30 |
| Distinct dates | 1,460 (**zero gaps ✅**) |
| Years | 2015-2027 (13 full FY years) |
| Seasons | 52 (BP09 → BP60) |

Full schema (37 columns) → [`schema_inventory.md`](schema_inventory.md)

### Fiscal Calendar Structure (confirmed)

- **Standard retail 4-5-4 pattern**, weeks **Mon-Sun** (DAY_NUMBER 1=Mon, 7=Sun, all consistent)
- **Quarter = Season mapping:** Q1=Spring, Q2=Summer, Q3=Fall, Q4=Winter
- **53-week years:** FY2018, FY2024, (next: FY2030)
- `SEASON_CODE` format: `YY-NSS` (e.g., `25-4WI` = FY2025 Q4 Winter)
- `BUYING_PERIOD`: sequential per season, BP01-BP08 missing (predate data)

### Data Quality — 100% Clean

- ✅ Zero nulls across all 37 columns
- ✅ Zero duplicates at DAY_ID
- ✅ All 7 hierarchy integrity checks pass (day→week→month→quarter→season→year→buying_period)
- ✅ DAY_NUMBER ↔ actual weekday: 100% consistent

### Current Season Alignment

| Product Master `season_code` | Calendar `SEASON_CODE` | Dates |
|-----------------------------|------------------------|-------|
| **`25-4WI`** (current) | Matches | Nov 3, 2025 → Feb 1, 2026 |
| `BUYING_PERIOD` | BP52 | |

### Coverage vs Data Requirements Spec

| Requirement | Have | Gap |
|-------------|------|-----|
| 3 years historic | **10 years** (FY15-24) | ✅ Exceeds |
| Current year | ✅ | ✅ |
| 5 years future | **2 years** (FY26-27) | 🟡 **3 years short** |

### ADJUSTED_LY_WEEK_ID — Sentinel Pattern

- 626 distinct values across 4,746 rows (column varies — not the same value)
- 371 rows (7.8%) have `201401` sentinel — edge-case weeks with no valid LY comp
- Handle as NULL in modeling: `WHERE ADJUSTED_LY_WEEK_ID != 201401`

---

## Action Items

### 🟡 P1
| # | Issue | Ask |
|---|-------|-----|
| C1 | Calendar ends FY2027. Spec requires 5 years future. | Extend to FY2030 (or FY2031 for safety buffer) |

### 🟢 P2
| # | Issue |
|---|-------|
| C2 | Clarify `ADJUSTED_LY_WEEK_ID=201401` / `ADJUSTED_2LY_WEEK_ID=201301` sentinel meaning |

---

## Ready-to-Use Derivations

```sql
-- Join transactions → fiscal calendar
FROM transaction_master t
JOIN calendar_hierarchy c ON c.DAY_ID = t.date

-- Fiscal week rollup
GROUP BY c.WEEK_ID        -- integer, e.g. 202548

-- Season filter (current)
WHERE c.SEASON_CODE = '25-4WI'

-- YoY comparison (53-week-safe)
JOIN calendar_hierarchy ly ON ly.WEEK_ID = c.ADJUSTED_LY_WEEK_ID
WHERE c.ADJUSTED_LY_WEEK_ID != 201401  -- skip sentinel rows

-- Detect 53-week years
HAVING COUNT(DISTINCT WEEK_ID) = 53
```

---

## Next Step

None. Table is done. Move on to other EDAs.
