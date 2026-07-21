# Master Tables EDA — Status + Verification Queries

**As of:** 2026-04-21
**Owner:** Ejaz Anwar
**Convention:** Project/dataset `lululemon-01042025.lululemon_souricng_outbound` written out in full so each query is ready to paste. Date filters scoped to 1 year (2024) where the table is large.

**Legend:**

- ✅ Verified in raw (real upstream condition)
- 🔴 Critical — needs client / DE action
- 🛠️ Hardcoded in build DDL (not a raw issue)
- 🟡 Internal DE follow-up
- 🚨 Reframed — root cause changed after verification
- ⚠️ Confirmed missing / unavailable

---

## Master Tables

| Table | Rows | Size (GB) | # | Notes / Flags | Scope | Latest Update |
|---|---|---|:-:|---|---|---|
| **product_master** | 2.0M | 1.05 | 1 | `launch_date` 100% NULL | 1.97M rows | ⚠️ Confirmed unavailable — V8: no launch/date col in PGH, sku_details, or product_attribute_s. Defer or accept proxy. |
|  |  |  | 2 | Placeholder SKUs (1,248 short-code articles like HX, MV, NK) | 55K rows | ✅ V12: 18,104 short-code rows in raw PGH (×2 channels = ~55K master). Top: HX, MV, OM, NM, HA. |
|  |  |  | 3 | `fit_classification` 24.7% NULL | 489K rows | ✅ V2: actually 65.17% NULL in raw `product_attribute_s` (56,132 of 86,135). Source-side gap. |
|  |  |  | 4 | `size_scale` coded letters (B, E, I, WA, J2, L1…) | 1.9M rows | ✅ V3: 45 distinct codes; quirks include lowercase `c`, `DNU` (Do Not Use), and `M-XL`/`S-L`/`XS-XL`. Need lookup. |
| **transaction_master** | 389.9M | 73.53 | 1 | `cost` and `msrp` 100% zero | 389M rows | 🔴 V1: ALL 1.97M rows in `sku_details_cleaned` have COST_PRICE=0 AND SELLING_PRICE=0 (INT64 typed). Source feed gap. |
|  |  |  | 2 | Discount cols (`unit_discount_amount`, `total_discount_amount`, `clearance_price`) 100% zero | 389M rows | 🛠️ Hardcoded `0` in build DDL. Internal DE — derive from price_book? |
|  |  |  | 3 | Extreme outliers (max qty=31,047, max revenue=$20M, max price=$1M) | <50 rows | ✅ V9: 2024 sample max_revenue=$20.07M, max_unit_price=$654K, max_units=6,794. Real upstream. |
|  |  |  | 4 | 42 rows with negative price AND cost > price | 42 rows | ✅ V9: 5 negative-price rows in 2024 alone; min_revenue=−$57.91. Likely returns. |
|  |  |  | 5 | 12 columns 100% NULL (`line_id`, `launch_price`, `transaction_type`, …) | All rows | 🛠️ All 12 hardcoded `NULL` in build DDL. Internal DE. |
|  |  |  | 6 | `clearance` and `flagged_rows` always 0 | All rows | 🛠️ Hardcoded `0` in build DDL. |
|  |  |  | 7 | 9,290 rows with qty > 0 but price/revenue = 0 | 9,290 rows | ✅ V9: 853 free-item rows in 2024 (consistent with 9.3K over 4 yrs). Likely promo/free items. |
|  |  |  | 8 | 106M zero-qty rows (27%) — non-sale events | 106M rows | ✅ V9: 27.02% in raw 2024 sample (matches master). Filter `qty>0 AND revenue>0` safe. |
| **inventory_master** | 7.2B | 650.48 | 1 | 64M rows (0.89%) have `oh < 0`; min = −3,704,869 | 64M rows | ✅ V10: 28M neg-OH in 2024 alone (0.95%); min = −3,704,869 (identical). Real upstream. |
|  |  |  | 2 | Inventory history starts 2023-01; transactions back to 2021-11 | 14+ months missing | 🚨 REFRAMED — V7: pre-2023 raw EXISTS (9.33B rows back to 2016!). Build is dropping it. Internal DE. |
|  |  |  | 3 | `oo`, `wip`, `initial_oh_quantity` 100% zero across 7.2B rows | All rows | 🛠️ Hardcoded `0` in build DDL for all 3. |
|  |  |  | 4 | Max `oh` = 700,024 at single SKU-store-date | 1 row | ✅ V10: max_oh in 2024 = 472,994 (700K is in another year). |
|  |  |  | 5 | `total_units` 100% identical to `oh` — redundant | All rows | 🛠️ Hardcoded redundancy — both alias `A.UNITS_ON_HAND`. Drop. |
|  |  |  | 6 | 23,782 SKUs in product_master never had inventory | 23.8K SKUs | ✅ Real cross-table — likely placeholders/new launches. |
|  |  |  | 7 | 467 stores in store_master never had inventory | 467 stores | ✅ Real cross-table — likely inactive/closed. |
|  |  |  | 8 | 8M `ivivva` inventory rows (deprecated brand) | 8M rows | ✅ V11: 63,090 ivivva SKUs in raw PGH. Mostly stranded (79% zero-OH). |
| **store_master** | 1.9K | 0 | 1 | `CMNTY` (26) vs `COMMUNITY` (13) — same channel, two spellings | 39 stores | ✅ V4: 26 + 13 in raw `SUB_MARKET_CHANNEL_NAME`. Source standardization. |
|  |  |  | 2 | `store_format_code` 21% NULL | 392 stores | ✅ V13: 392 NULLs / 1,853 (21.15%). Full distribution surfaced (16 categories incl. VIRTUAL=65, E-COMMERCE=30). |
|  |  |  | 3 | `active` flag 11% NULL | 199 stores | ✅ V5: MAPPING IS CORRECT. LOC_CLOSED_IND=0 → 100% closed; =1 → 8% closed (open); NULL=199 (mostly new). |
|  |  |  | 4 | 21 channel_codes exist but have zero transactions | ~200 stores | ✅ Real cross-table. Likely non-txn channels (FO/CMNTY/STRAT). |
|  |  |  | 5 | `special_classification` 100% NULL | All rows | 🛠️ Hardcoded `NULL` in build DDL. |
|  |  |  | 6 | lat/long stored as STRING not FLOAT | 1,853 rows | ✅ V6: STRING in raw too. CAST when used. |
|  |  |  | 7 | Geographic mismatches in virtual stores (KR ECOMM city=Hong Kong) | Handful | ✅ Master-level confirmed. Historical HQ addresses. |
|  |  |  | 8 | `s3_id` has 2 IDs with multiple `s3_names` | 2 IDs | ✅ Master-level. Minor naming. |
|  |  |  | 9 | Placeholder `open_dates` (WeChat = 1999-12-31) | Some virtual | ✅ Master-level. Verify with client. |
| **calendar_hierarchy** | 4.7K | 0 | 1 | Seems Fine | — | ✅ Pristine through FY27. Need extension to FY2030. |

---

## New Items Discovered via Phase-1 Verification

| Table | # | Notes / Flags | Scope | Latest Update |
|---|:-:|---|---|---|
| transaction_master | N1 | Build script references `sku_details_cleaned_20251119` which **does not exist** | Build script | 🔴 Internal DE: is master being rebuilt? If not, cost/msrp won't auto-fix even when `sku_details` is populated. |
| inventory_master | N2 | Build dropping 9.3B pre-2023 rows that exist in raw | 9.3B rows | 🔴 Internal DE — highest leverage fix. |
| store_master | N3 | 95 virtual/digital stores (not 30) — VIRTUAL=65 + E-COMMERCE=30 | 95 stores | 🟡 Re-classify virtual stores. |
| product_master | N4 | `product_attribute_s` has 3 versions: `_20251119` (86K) / plain (83K) / `_cleaned` (80K) | 3 versions | 🟡 Internal DE — which is canonical? Build uses `_20251119`. |
| product_attribute_s | N5 | `gender` 83% NULL in raw (vs 73% in master) | 71,837 of 86,135 styles | 🟡 Source attribution gap. Workaround in place (l5_name parse → 99.96% coverage). |

---

**Source artifacts:**

- Verification queries: `queries/raw_source_verification_phase1.sql` (V1–V15, single stacked query)
- Master DDL audit: `findings/master_table_build_logic.md`
- Consolidated root-cause writeup: `findings/consolidated_p0_p1_issues.md`
