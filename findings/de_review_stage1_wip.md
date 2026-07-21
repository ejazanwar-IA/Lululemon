# DE Review Request — Stage 1 WIP Items

> **To:** Ritik (DE) &nbsp;|&nbsp; **From:** Ejaz Anwar &nbsp;|&nbsp; **Date:** 2026-04-22
> **Priority:** Medium — these are build-logic questions, not data bugs. Resolving them closes 4 of the 4 remaining Stage 1 items in our master-table validation checklist and tightens the client-facing story.
>
> **What I need from you:** a short answer to each of the 4 questions below (1–2 lines each is enough). Verification SQL provided if helpful — expected runtime is seconds to minutes, no large scans.
>
> **Reference:** Full build logic doc — `findings/master_table_build_logic.md` · Checklist context — `findings/master_table_checklist.md`

---

## TL;DR — the four questions

| # | Master | Item | Question |
|---|---|---|---|
| 1 | `store_master_20251119` | `active = LOC_CLOSED_IND` | What does `LOC_CLOSED_IND = 1` actually mean — store is *closed*, or store is *active*? |
| 2 | `transaction_master_20251119` | `all_skus` CTE uses `AVG(COST_PRICE)` and `AVG(selling_price)` | Is an average per-SKU the intended semantic, or should it be most-recent / weighted / effective-at-txn-date? |
| 3 | `transaction_master_20251119` | `SELECT DISTINCT` across the full projection | Is `sales_transactions_4y_cleaned_20251119` duplicated upstream? If not, the DISTINCT is hiding a grain issue. |
| 4 | `inventory_master` | Joins `product_group_hierarchy_cleaned` (no `_20251119` suffix), while every other master uses `_20251119` | Intentional (different snapshot) or oversight? |

All four are quick to answer. Questions + context + evidence + proposed SQL below.

---

## Question 1 — `store_master.active` polarity

### Context

`store_master_20251119` build logic contains:

```sql
a.LOC_CLOSED_IND AS active
```

So a column semantically named **"active"** is being sourced from a field semantically named **"closed indicator."** The polarity may be inverted.

### Why it matters

- Inventory-to-closed-store check (`inventory_master` row where `store.active = 0`) depends on this being right.
- "How many active stores?" in every dashboard we hand over depends on this.
- If polarity is wrong, every downstream consumer of `store_master.active` gets the opposite answer.

### What I need from you

**One line:** In `location_group_hierarchy_cleaned_20251119.LOC_CLOSED_IND`, does `1` mean "store is closed" or "store is active/open"?

### Verification SQL (for my own records — optional for you to run)

```sql
-- If LOC_CLOSED_IND=1 means "closed", then stores with =1 should correlate with an OPERATIONAL_CLOSE_DAY_ID in the past
SELECT
  LOC_CLOSED_IND,
  COUNT(*)                                         AS stores,
  COUNTIF(OPERATIONAL_CLOSE_DAY_ID IS NOT NULL)    AS stores_with_close_date,
  COUNTIF(OPERATIONAL_CLOSE_DAY_ID < CURRENT_DATE) AS stores_closed_in_past,
  COUNTIF(OPERATIONAL_OPEN_DAY_ID  < CURRENT_DATE
          AND (OPERATIONAL_CLOSE_DAY_ID IS NULL OR OPERATIONAL_CLOSE_DAY_ID > CURRENT_DATE))
                                                   AS looks_open_today
FROM `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119`
GROUP BY LOC_CLOSED_IND
ORDER BY LOC_CLOSED_IND;
```

**Interpretation rule:**
- If the row where `LOC_CLOSED_IND = 1` has mostly `stores_closed_in_past`, polarity is as the name suggests (1 = closed). → The master column `active` is **inverted**; we'll flip it with `1 - LOC_CLOSED_IND` or rename the column to `closed_flag`.
- If the row where `LOC_CLOSED_IND = 1` has mostly `looks_open_today`, the field is mis-named in the source and the current master is correct.

### Closure criteria

Your answer on polarity → I update the checklist (`S1.2` → Done), either:
- flag the master column as a logic bug and ask you to patch, **or**
- document that the column is correctly sourced and move on.

---

## Question 2 — `transaction_master` cost/msrp averaging semantics

### Context

`transaction_master_20251119` build uses this CTE:

```sql
WITH all_skus AS (
  SELECT
    a.sku_id_code                    AS sku_id_channel,
    AVG(b.COST_PRICE)                AS cost_price,
    AVG(CAST(selling_price AS INT))  AS selling_price
  FROM product_group_hierarchy_cleaned_20251119 a
  LEFT JOIN sku_details_cleaned_20251119 b
    ON a.sku_id_code = b.sku_id_code
  GROUP BY 1
)
SELECT ..., sd.COST_PRICE AS cost, sd.SELLING_PRICE AS msrp ...
```

Then `cost` and `msrp` are joined to every txn row via the SKU.

### Two concerns

1. **`AVG` over what?** There's no time dimension — it's a flat average across all rows per SKU in `sku_details_cleaned`. If the source has price history (multiple rows per SKU over time), this blends old and new prices into one number that matches no actual transaction.
2. **`CAST(selling_price AS INT)`** — if any `selling_price` value is fractional (e.g. 49.99), this truncates it. A $49.99 MSRP becomes $49.

### Why it matters

- Margin = `revenue - cost × qty`. If `cost` is a blended average across 3 years of price changes, margin is systematically biased.
- Forecast/Sizesmart downstream will see nonsense cost/msrp at the txn level.
- If the model later trains on `msrp` as a feature, the INT truncation injects a ~1% bias across the board.

### What I need from you

**Two lines:**
- Is `AVG` per-SKU the intended semantic, or should we join to `sku_details` at a more specific grain (e.g. effective price at txn date, most-recent price, or price_book join)?
- Is the `CAST(selling_price AS INT)` intentional (e.g. selling_price is always integer in source) or an accidental truncation?

### Verification SQL

```sql
-- 2a: How many distinct COST_PRICE / SELLING_PRICE rows exist per SKU? (If >1, AVG is collapsing history.)
-- Note: raw table is sku_details_cleaned (no _20251119 suffix — the suffix variant doesn't exist in BQ
-- despite the master-build DDL referencing it).
SELECT
  rows_per_sku,
  COUNT(*) AS n_skus
FROM (
  SELECT sku_id_code, COUNT(*) AS rows_per_sku
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned`
  GROUP BY sku_id_code
)
GROUP BY rows_per_sku
ORDER BY rows_per_sku;

-- 2b: Are any selling_price values fractional? (If yes, the CAST AS INT is a silent truncation.)
SELECT
  COUNTIF(SAFE_CAST(selling_price AS FLOAT64) != TRUNC(SAFE_CAST(selling_price AS FLOAT64))) AS fractional_rows,
  COUNTIF(selling_price IS NULL)                                                             AS null_rows,
  COUNT(*)                                                                                   AS total_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned`;
```

### Closure criteria

Your answer → I update `S1.4` to one of:
- **Done (intended):** `sku_details` is 1-row-per-SKU and `selling_price` is always integer. Note as "intentional; masters reflect source faithfully."
- **Logic bug, patch planned:** document the fix you're planning and re-run txn master when it lands.

### Bonus finding (worth flagging to you regardless)

The DDL for `transaction_master_20251119` (and `product_master`) literally references `sku_details_cleaned_20251119`, but that table **does not exist in BQ today** — only the unsuffixed `sku_details_cleaned` does. Running the DDL as-written raises `Not found: Table sku_details_cleaned_20251119 was not found in location US`.

Either the suffixed variant was dropped after the masters were built, or the masters were actually built from `sku_details_cleaned` despite what the DDL says (with a later rename/alias), or there's a view somewhere doing the indirection. Could you confirm which and share the actual build trail? This also affects Q4 below.

---

## Question 3 — `transaction_master` `SELECT DISTINCT` justification

### Context

The build uses `SELECT DISTINCT` across all 32 columns of the output projection:

```sql
SELECT DISTINCT
  lm.s1_name AS channel,
  ...
  txn.PRICE_SALES_UNIT AS price
FROM sales_transactions_4y_cleaned_20251119 AS txn
JOIN product_group_hierarchy_cleaned_20251119 AS pgh ON ...
JOIN all_skus AS sd ON ...
JOIN store_master_20251119 AS lm ON ...
```

### Evidence from our EDA

- `sales_transactions_4y_cleaned_20251119` — 390,532,103 total rows, 389,872,378 distinct `SALES_ORDER_ID` → **660K row gap**.
- After DISTINCT in the master, `transaction_master.transaction_code` has the same 660K gap.

Two possible explanations:
1. The source is duplicated (same order_id appears more than once with identical payload) — DISTINCT is a defensive de-dup.
2. The source has legitimate multi-row orders (e.g. one order_id with 2 SKUs on different lines), and DISTINCT isn't actually removing anything because rows differ on SKU/qty — meaning DISTINCT is wasted work AND the grain is actually `order × line` not `order`.

### Why it matters

- If it's case 1, we should document the upstream dup and fix there, not paper over it with DISTINCT.
- If it's case 2, the grain statement is wrong and downstream users will mis-aggregate.
- Either way, blanket `DISTINCT` on a 390M-row join is expensive BQ compute — worth clarifying.

### What I need from you

**One line:** Is `sales_transactions_4y_cleaned_20251119` known to have duplicate rows, or is the DISTINCT a defensive coding pattern without evidence of duplication?

### Verification SQL

```sql
-- 3a: Are there genuine full-row duplicates in sales_transactions, or do duplicated SALES_ORDER_IDs differ on line/SKU?
WITH dups AS (
  SELECT SALES_ORDER_ID, COUNT(*) AS n
  FROM `lululemon-01042025.lululemon_souricng_outbound.sales_transactions_4y_cleaned_20251119`
  GROUP BY SALES_ORDER_ID
  HAVING COUNT(*) > 1
)
SELECT
  COUNT(*)                                            AS duplicated_order_ids,
  SUM(n)                                              AS total_rows_in_dupes,
  SUM(n) - COUNT(*)                                   AS excess_rows
FROM dups;

-- 3b: For the duplicated IDs, how many are true full-row dupes vs differ on SKU/qty/date?
-- Takes longer — only run if 3a shows dupes exist.
SELECT
  COUNT(*) AS full_row_dupe_groups,
  SUM(cnt - 1) AS redundant_rows
FROM (
  SELECT sku_id_channel, location_id_sales, DATE_TRANSACTION, SALES_ORDER_ID,
         units, PRICE_SALES_UNIT, PRICE_SALES_TOTAL, COUNT(*) AS cnt
  FROM `lululemon-01042025.lululemon_souricng_outbound.sales_transactions_4y_cleaned_20251119`
  GROUP BY 1, 2, 3, 4, 5, 6, 7
  HAVING COUNT(*) > 1
);
```

### Closure criteria

- If **3a > 0 and 3b ≈ 3a**: source has true dupes; DISTINCT is justified but should be fixed upstream. We keep a note in the client brief.
- If **3a > 0 but 3b « 3a**: source isn't duplicated on all columns; DISTINCT is a no-op and the actual grain is finer than we documented. We need to update the grain statement.
- If **3a = 0**: DISTINCT is defensive dead code. We can drop it in future rebuilds.

---

## Question 4 — `inventory_master` snapshot consistency

### Context

`inventory_master` build logic:

```sql
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned` AS A
JOIN `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned` AS B
  ON A.sku_id_channel = B.sku_id_channel
```

Note **no `_20251119` suffix** on `product_group_hierarchy_cleaned`.

Every other master uses the suffixed snapshot:
- `product_master` → `product_group_hierarchy_cleaned_20251119`
- `transaction_master` → `product_group_hierarchy_cleaned_20251119`
- `store_master` → `location_group_hierarchy_cleaned_20251119` (suffix present)
- `events_master` → `promotional_events_cleaned` (no suffix, but no corresponding `_20251119` variant exists)

### Why it matters

- If `product_group_hierarchy_cleaned` and `product_group_hierarchy_cleaned_20251119` are different snapshots, `inventory_master` is joined to a different version of the product universe than `product_master` is built from. SKUs present in one could be absent in the other, inflating the "SKU in inventory but not in product master" count we flagged.
- It also complicates reproducibility — re-running the inventory build tomorrow may produce different results than re-running product_master, because the non-suffixed view may refresh while the `_20251119` is frozen.

### What I need from you

**Two lines:**
- Is `product_group_hierarchy_cleaned` (unsuffixed) intentionally a newer/live version vs the `_20251119` snapshot used elsewhere?
- If intentional, should we re-build `inventory_master` against `_20251119` to align with product_master, or keep the live version by design?

### Verification SQL

```sql
-- 4a: Do the two tables have the same row count and same set of SKUs?
WITH live AS (
  SELECT COUNT(*)                         AS rows,
         COUNT(DISTINCT sku_id_channel)   AS skus
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned`
),
snap AS (
  SELECT COUNT(*)                         AS rows,
         COUNT(DISTINCT sku_id_channel)   AS skus
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119`
)
SELECT 'live' AS src, rows, skus FROM live
UNION ALL
SELECT 'snapshot', rows, skus FROM snap;

-- 4b: How many SKUs are in one but not the other?
SELECT
  COUNTIF(a.sku_id_channel IS NOT NULL AND b.sku_id_channel IS NULL) AS in_live_only,
  COUNTIF(a.sku_id_channel IS NULL     AND b.sku_id_channel IS NOT NULL) AS in_snapshot_only,
  COUNTIF(a.sku_id_channel IS NOT NULL AND b.sku_id_channel IS NOT NULL) AS in_both
FROM (
  SELECT DISTINCT sku_id_channel
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned`
) a
FULL OUTER JOIN (
  SELECT DISTINCT sku_id_channel
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119`
) b
USING (sku_id_channel);
```

### Closure criteria

- **Identical row/SKU counts + zero symmetric diff** → the two tables are views on the same underlying source; the suffix is cosmetic. Close `S1.6` as Done.
- **Different counts or symmetric diffs > 0** → real snapshot drift. Either re-build inventory against `_20251119` for consistency, or document the mismatch as a known non-issue with justification.

---

## Summary — what I'll do once you respond

For each answer you give, I'll update the `master_table_checklist.md` status:

| Item | If answer is "intended / not a bug" | If answer exposes a bug |
|---|---|---|
| S1.2 `active` polarity | Close as Done; document the correct interpretation | Flag as a logic bug; agree on patch plan |
| S1.4 `AVG` cost/msrp | Close as Done; document semantic (e.g. "source is 1 row/SKU, AVG is a no-op") | Flag as a logic bug; DE to patch |
| S1.5 `DISTINCT` | Close as Done; document upstream dup and accept DISTINCT as defensive | Flag as dead code or grain-statement error; update doc |
| S1.6 snapshot consistency | Close as Done; document equivalence | Open a small action to rebuild inventory against `_20251119` |

Then the client-facing story becomes unambiguous: every Stage 1 observation is either a confirmed-intentional design choice or a tracked bug — nothing dangling.

---

## One ask on format

If you can, reply inline with just:

> **1.** Closed = ... &nbsp;&nbsp; (1 line)
> **2.** AVG semantic = ... &nbsp;&nbsp; (2 lines)
> **3.** DISTINCT = ... &nbsp;&nbsp; (1 line)
> **4.** Snapshot = ... &nbsp;&nbsp; (2 lines)

Total expected response size: ~6 lines. Thanks!

— Ejaz
