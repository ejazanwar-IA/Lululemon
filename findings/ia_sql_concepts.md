# IA BigQuery — SQL Concepts Catalogue

`Last updated: 2026-04-29.`

> **Purpose**: a comprehensive reference of every SQL/BigQuery-scripting idiom actually
> used across the IA platform's client codebase, ranked by how many clients use it.
> Use this to read **any** `create_*.sql`, alert/KPI table SQL, or preprocessing
> job in the IA repo without hitting an unfamiliar construct.
>
> **Source repo**: `~/Downloads/insideinsight-mtp-bigquery-3df90a9e5596/` —
> 38 client folders, 8,110 SQL files, three layers per client (`sourcing/`,
> `ingestion/`, `preprocessing/` where present).
>
> **How frequencies were derived**: one `grep` pass per concept across the whole
> repo, counting distinct client folders that contain at least one match
> (script: `/tmp/iaconcepts/scan.sh`, output: `/tmp/iaconcepts/freq.txt`).
>
> **How to use**: read **Tier 1** end-to-end (these are universal — required to
> read anything). Skim **Tier 2** for fluency on the most common ingestion
> patterns. Treat **Tier 3** as a glossary you consult when a specific file
> uses something unusual. **Tier 4** is BQ-specific gotchas tied to the
> numbered G-rules in `.cursor/rules/lululemon-bq-context.mdc`.

## Frequency at-a-glance

The 38 client folders in scope:

```
arhaus aritzia balsam briscoes carters cbl cenomi ck dg figs gap leslies
levi-lsa levi-lse lovisa mns mns-mena pacsun pacsun-erp partycity pm psp
puma rl-apac rl-eu rl-eu-is rl-na saks sb scarpe signet sm spanx tapestry
tb tommy vb vs
```

Each entry below tags **Seen in: N/38** clients. Counts come from
`/tmp/iaconcepts/freq.txt`.

---

## Table of contents

- [Tier 1 — Universal (30+/38 clients)](#tier-1--universal-3038-clients)
- [Tier 2 — Common (10-29/38 clients)](#tier-2--common-10-2938-clients)
- [Tier 3 — Selective (2-9/38 clients)](#tier-3--selective-2-938-clients)
- [Tier 4 — BQ quirks / gotchas (cross-ref to G1-G10)](#tier-4--bq-quirks--gotchas)
- [Suggested reading order](#suggested-reading-order)
- [What to skip](#what-to-skip)
- [Cross-references](#cross-references)

---

## Tier 1 — Universal (30+/38 clients)

These appear in nearly every file. If any are unfamiliar, fix that first.

### 1. CTE chaining (`WITH ... AS`)

**Why:** every non-trivial file is one big CTE pipeline (raw → dedup → join → derive → final SELECT). Sometimes 50+ CTEs in one file.
**Seen in:** 37/38 clients.
**Example:**

```sql
WITH raw AS (
  SELECT a.* FROM `data-ingestion-342714.signet_sourcing_prod.ia_product` a
), prod_cleaned AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT DISTINCT *,
           ROW_NUMBER() OVER (PARTITION BY Sub_SKU ORDER BY SYNCSTARTDATETIME DESC) AS rn
    FROM raw
  ) WHERE rn = 1
), full_raw_pm AS ( ... )
SELECT * FROM full_raw_pm;
```

**Anchor:** `signet/sourcing/create_product.sql` lines 6-19.

### 2. `CASE WHEN ... THEN ... END`

**Why:** banner/channel resolution, status flags, derived buckets — these CASE blocks are often 20+ branches and the bulk of a file's business logic.
**Seen in:** 37/38 clients.
**Example:**

```sql
CASE WHEN CORP_DIV_NO = '60' AND LOCATION_TYPE = 'S' AND (STORE_NUMBER != 'D.5999') THEN 'PEOPLES'
     WHEN CORP_DIV_NO = '20' AND STORE_NUMBER NOT IN ('A.2000','A.2033') THEN 'KAY'
     WHEN CORP_DIV_NO = '20' AND STORE_NUMBER IN ('A.2000','A.2033')     THEN 'KAY.COM'
     WHEN CORP_DIV_NO = '90' AND STORE_NUMBER NOT IN ('A.2032')          THEN 'KAY OUTLET'
     ELSE 'Other'
END AS CHANNEL
```

**Anchor:** `signet/sourcing/create_transaction.sql` lines 156-179.

### 3. `COALESCE(a, b, c, ...)`

**Why:** the universal NULL-fallback (and `\N`/`''`/0 fallback in dirty raw data). Appears more than any other function in the repo.
**Seen in:** 38/38 clients.
**Example:**

```sql
SELECT
  COALESCE(price, price_day, price_week, price_week_over, price_month_over) AS price_imputed,
  COALESCE(msrp,  msrp_day,  msrp_week,  msrp_week_over,  msrp_month_over)  AS msrp_imputed,
  COALESCE(cost,  cost_day,  cost_week,  cost_week_over,  cost_month_over)  AS cost_imputed
FROM master_table;
```

**Anchor:** `pacsun/preprocessing/queries.json` (procedure `create_master_input_imputed_*`).

### 4. `CAST(... AS type)`

**Why:** raw fields land as STRING; almost every join key, integer aggregate, or date operation needs an explicit cast first.
**Seen in:** 38/38 clients.
**Example:**

```sql
SELECT
  CAST(site_no AS STRING) AS store_code,
  CAST(CONCAT(m.fiscal_year, LPAD(m.fiscal_week, 2, '0')) AS INT64) AS fiscal_year_week,
  CAST(cluster_name AS INT64) AS cluster_name
FROM raw;
```

**Anchor:** `signet/ingestion/oms_otb.sql` (banner-channel CASE block uses `CAST(RIGHT(CAST(m.fiscal_year_month AS string), 2) AS int64)`).

### 5. `SAFE_CAST(... AS type)`

**Why:** raw numerics are STRING with `'\N'` and `''` sentinels. `SAFE_CAST` returns `NULL` on failure instead of killing the pipeline (Pattern 7 in `docs/ia_bq_patterns.md`).
**Seen in:** 30/38 clients.
**Example:**

```sql
SELECT
  SAFE_CAST(QTY_SOLD            AS FLOAT64) AS QTY_SOLD,
  SAFE_CAST(RETAIL_UNIT_PRICE   AS FLOAT64) AS RETAIL_UNIT_PRICE,
  SAFE_CAST(TOTAL_DISCOUNT_AMT  AS FLOAT64) AS TOTAL_DISCOUNT_AMT,
  SAFE_CAST(NET_SELLING_PRICE   AS FLOAT64) AS NET_SELLING_PRICE,
  SAFE_CAST(COST                AS FLOAT64) AS COST
FROM TRXN_Clean_2;
```

**Anchor:** `signet/sourcing/create_transaction.sql` lines 94-107.

### 6. `SELECT * EXCEPT(col1, col2, ...)`

**Why:** BQ-specific. Used everywhere in dedup recipes (`SELECT * EXCEPT(rn)`) and to drop helper columns before downstream consumers see them.
**Seen in:** 38/38 clients.
**Example:**

```sql
SELECT * EXCEPT(rn) FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY Sub_SKU ORDER BY SYNCSTARTDATETIME DESC) AS rn
  FROM raw
) WHERE rn = 1;
```

**Anchor:** `signet/sourcing/create_product.sql` line 12.

### 7. `INNER JOIN` / `LEFT JOIN` / `CROSS JOIN` / `FULL OUTER JOIN`

**Why:** master-build SQL stitches 5-15 raw tables. The choice of join semantics drives whether NULLs flow through to downstream `COALESCE` blocks.
**Seen in:** LEFT 38/38 (truly universal); INNER 36/38; CROSS 37/38; FULL OUTER 37/38.
**Example:**

```sql
SELECT t.*, p.product_description, s.banner
FROM transaction_master t
INNER JOIN product_master p USING (product_code)
LEFT JOIN store_master s ON t.store_code = s.store_code
CROSS JOIN UNNEST(t.line_items) AS line
FULL OUTER JOIN inventory_snapshot i USING (product_code, store_code, date);
```

**Anchor:** every Tier-1 file. See `signet/sourcing/create_transaction.sql` lines 142-153 for a clean LEFT JOIN block.

### 8. `USING (col1, col2, ...)`

**Why:** the IA repo's strong preference over `ON a.col = b.col` when join keys share names. Reduces typos and makes hierarchy joins (l1_name, l2_name, l3_name, ...) readable.
**Seen in:** 36/38 clients.
**Example:**

```sql
LEFT JOIN temp_l4_name USING (l1_name, l2_name, l3_name, l4_name, date)
LEFT JOIN temp_l3_name USING (l1_name, l2_name, l3_name, date)
LEFT JOIN temp_l2_name USING (l1_name, l2_name, date)
LEFT JOIN temp_l1_name USING (l1_name, date)
LEFT JOIN temp_l0_name USING (date)
```

**Anchor:** `pacsun/preprocessing/queries.json` (in `create_master_input_imputed_historic`, the `iterm_with_imp1` CTE).

### 9. `UNION ALL`

**Why:** stitching multiple historical periods, multiple channels, or staged-then-final blocks together. Almost always `UNION ALL` (preserve all rows); `UNION DISTINCT` is Tier 2.
**Seen in:** 37/38 clients.
**Example:**

```sql
SELECT * FROM transactions_2024
UNION ALL
SELECT * FROM transactions_2025;
```

### 10. `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`

**Why:** **the dedup recipe** (Pattern 6). Same shape every feed; only the natural key changes.
**Seen in:** 37/38 clients.
**Example:**

```sql
SELECT * EXCEPT(rn) FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY TRANS_ID, LINE_ID, SKU, TRANS_DATE
                            ORDER BY SYNCSTARTDATETIME DESC) AS rn
  FROM raw_transactions
) WHERE rn = 1;
```

**Anchor:** `signet/sourcing/create_transaction.sql` (transaction dedup CTE) and `signet/sourcing/create_product.sql` lines 10-19.

### 11. `LAG(col) OVER (PARTITION BY ... ORDER BY ...)`

**Why:** week-over-week / period-over-period deltas, lost-sales calc, supersession lookups. Showed up in nearly every imputation and KPI file.
**Seen in:** 32/38 clients.
**Example:**

```sql
SELECT *,
       COALESCE(LAG(qty) OVER (PARTITION BY l9_name, store_code ORDER BY fiscal_year_quarter),
                qty) AS lag_qt_qty
FROM yt;
```

**Anchor:** `pacsun/preprocessing/queries.json` (`master_aggregate__l9_name_historic` SP, `sp_l9` CTE).

### 12. `MERGE ... USING ... ON ... WHEN MATCHED / WHEN NOT MATCHED`

**Why:** the steady-state upsert (Pattern 2 in `docs/ia_bq_patterns.md`). Distinct from `INSERT` / `UPDATE` / `CREATE OR REPLACE`. The `ON` clause carries both the **match key** and the **rolling-window predicate** that scopes which rows can be touched.
**Seen in:** 32/38 clients.
**Example:**

```sql
MERGE `signet_sourcing_prod.transaction_intermediate` DL
USING (SELECT * FROM `signet_sourcing_prod.transaction_intermediate_temp`) V
ON (DATE(DL.SYNCSTARTDATETIME) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE())
   AND DL.TRANS_ID = V.TRANS_ID AND DL.LINE_ID = V.LINE_ID
   AND DL.SKU = V.SKU AND DL.TRANS_DATE = V.TRANS_DATE
WHEN MATCHED THEN UPDATE
SET DL.SKU = V.SKU, DL.TRANS_DATE = V.TRANS_DATE, ... -- 30+ columns
WHEN NOT MATCHED THEN
INSERT (SKU, TRANS_DATE, TRANS_ID, ...) VALUES (v.SKU, v.TRANS_DATE, v.TRANS_ID, ...);
```

**Anchor:** `signet/sourcing/create_transaction.sql` lines 472-479.

### 13. `WHEN MATCHED THEN UPDATE` / `WHEN NOT MATCHED THEN INSERT`

**Why:** the two clauses that complete the MERGE pattern. Often one of each per MERGE; rarely both with conditions (`WHEN MATCHED AND ... THEN`).
**Seen in:** 37/38 clients (counted independently of `MERGE` itself).
**Example:** see #12 above. The `WHEN MATCHED THEN UPDATE SET DL.col = V.col` block is typically the longest single line in any sourcing file.

### 14. `CREATE OR REPLACE TABLE ... PARTITION BY ... CLUSTER BY ... AS`

**Why:** Pattern 4 — the universal DDL shape for every master/intermediate. Partitioning = storage layout (free pruning); clustering = sort order within partition (cheaper filters).
**Seen in:** 37/38 clients.
**Example:**

```sql
CREATE OR REPLACE TABLE `data-ingestion-342714.signet_sourcing_prod.product_intermediate`
PARTITION BY DATE(SYNCSTARTDATETIME)
CLUSTER BY Sub_SKU_Division, Planning_Ownership AS
WITH raw AS ( SELECT a.* FROM `data-ingestion-342714.signet_sourcing_prod.ia_product` a )
...
```

**Anchor:** `signet/sourcing/create_product.sql` line 5 (and again line 412).

### 15. `PARTITION BY ...` (table-level) and `CLUSTER BY ...`

**Why:** call out separately because the same `PARTITION BY` keyword also appears at window-function level (#10) and reading them as the same thing causes confusion.
**Seen in:** PARTITION 33/38; CLUSTER 32/38.
**Example:** see #14.

### 16. `DECLARE var TYPE [DEFAULT ...]`

**Why:** scripting variable for the rolling window driver (Pattern 3) or filter param. Sometimes a date, sometimes a STRING used as a dynamic table path.
**Seen in:** 32/38 clients.
**Example:**

```sql
DECLARE max_inv_date DATE DEFAULT (
  SELECT MAX(PARSE_DATE('%Y%m%d', CAST(INV_DATE AS STRING)))
  FROM `data-ingestion-342714.signet_sourcing_prod.ia_inv`
);
```

**Anchor:** `signet/sourcing/create_product.sql` lines 1-3.

### 17. `CALL <procedure>(args)`

**Why:** every preprocessing/queries.json file ends with a `CALL` to the procedure it just defined. Often the trigger that the platform invokes from Airflow.
**Seen in:** 35/38 clients.
**Example:**

```sql
CALL `pacsun-09012025`.pacsun_ingestion_prod.create_master_input_imputed_historic();
```

**Anchor:** `pacsun/preprocessing/queries.json` (final line of each procedure entry).

### 18. `CONCAT(a, b, c, ...)`

**Why:** composite keys (`l0_name || '_' || l1_name`), formatted strings, hierarchy paths. Used heavily in aggregation tables.
**Seen in:** 37/38 clients.
**Example:**

```sql
CONCAT(l0_name, '_', l1_name, '_', l2_name, '_', l3_name) AS l3_name,
CONCAT(l0_name, '_', l1_name, '_', l2_name, '_', l3_name, '_', brand, '_', ladder, '_', fit) AS l9_name
```

**Anchor:** `pacsun/preprocessing/queries.json` (`fmt_aggr` CTE).

### 19. `LOWER(...)` / `UPPER(...)`

**Why:** normalising banner names, status flags, hierarchy strings before joining or comparison.
**Seen in:** 33/38 clients.
**Example:**

```sql
WHERE LOWER(channel) = 'ecomm'
  AND UPPER(active_flag) = 'Y'
```

### 20. `SAFE_DIVIDE(numerator, denominator)`

**Why:** returns NULL instead of raising "division by zero". The default for any ratio in the repo.
**Seen in:** 37/38 clients.
**Example:**

```sql
SAFE_DIVIDE(SUM(price * qty_imputed), SUM(qty_imputed)) AS price_avg,
SAFE_DIVIDE(stores_with_inv, total_stores) AS stores_with_inv_prop
```

**Anchor:** `pacsun/preprocessing/queries.json` (used >50 times in one procedure).

### 21. `ROUND(x, n)` / `ROUND(x)`

**Why:** rounding ratios, percentages, currency. Almost always seen alongside `SAFE_DIVIDE`.
**Seen in:** 36/38 clients.
**Example:**

```sql
ROUND(SAFE_DIVIDE(qty, quantity_sold_higher), 4) AS quantity_sold_ratio,
ROUND(SAFE_DIVIDE(oh,  inventory_higher),     4) AS inventory_ratio
```

### 22. `COUNT(DISTINCT col)`

**Why:** distinct-count aggregations (eligible SKUs, store counts) — appears more than `COUNT(*)` in many ingestion files.
**Seen in:** 36/38 clients.
**Example:**

```sql
SELECT
  COUNT(DISTINCT product_code) AS sku_count,
  COUNT(DISTINCT store_code)   AS store_count
FROM master;
```

### 23. `SUM(...)` / `AVG(...)` / `MIN(...)` / `MAX(...)` (basic aggregates)

**Why:** the bread-and-butter aggregates. Often combined with `OVER (PARTITION BY ...)` for analytic windows (see #10, #11).
**Seen in:** 38/38 clients (implicit baseline).
**Example:**

```sql
SUM(qty_imputed) AS qty,
AVG(oh)          AS avg_oh,
MIN(date)        AS first_seen,
MAX(date)        AS last_seen
GROUP BY 1, 2, 3;
```

### 24. `IFNULL(a, b)`

**Why:** two-arg shorthand for `COALESCE(a, b)`. Common when only one fallback is needed.
**Seen in:** 34/38 clients.
**Example:**

```sql
IFNULL(inv,             0)  AS oh,
IFNULL(b.sales_index,   0)  AS sales_index,
IFNULL(c.store_penetration, 0) AS store_penetration
```

### 25. `UNNEST(array)` (also as `, UNNEST(...)` lateral / `CROSS JOIN UNNEST(...)`)

**Why:** flatten ARRAY/STRUCT columns to rows, expand `IN`-list literals, and cross-join with `GENERATE_*_ARRAY` results.
**Seen in:** 34/38 clients.
**Example:**

```sql
-- Flatten an aggregated array back to rows
SELECT * EXCEPT (c) REPLACE(c AS SKU)
FROM (SELECT * FROM cte), UNNEST(SKU) c;
```

**Anchor:** `signet/sourcing/create_productmindate.sql` line 1 (the lateral unnest).

### 26. `DATE_SUB`, `DATE_ADD`, `DATE_TRUNC`, `DATE_DIFF`, `DATE(...)`

**Why:** the standard date toolkit. `DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)` is the rolling-window pattern; `DATE(SYNCSTARTDATETIME)` derives the partition key.
**Seen in:** DATE_SUB 33/38; DATE_ADD 34/38; DATE_TRUNC 27/38; DATE_DIFF 30/38.
**Example:**

```sql
SELECT
  DATE(SYNCSTARTDATETIME)                                  AS load_date,
  DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)                AS window_start,
  DATE_TRUNC(DATE(TRANS_DATE), WEEK(MONDAY))               AS fiscal_week_start,
  DATE_DIFF(CURRENT_DATE(), DATE(TRANS_DATE), DAY)         AS days_since_txn
FROM raw;
```

### 27. `CURRENT_DATE()` / `CURRENT_TIMESTAMP()`

**Why:** the "now" reference for rolling windows, audit columns, lineage.
**Seen in:** CURRENT_DATE 37/38; CURRENT_TIMESTAMP 24/38.
**Example:**

```sql
WHERE date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR) AND CURRENT_DATE()
```

### 28. `INTERVAL N <unit>`

**Why:** always paired with `DATE_SUB`/`DATE_ADD`/`TIMESTAMP_*`. Unit is one of `DAY`, `WEEK`, `MONTH`, `QUARTER`, `YEAR`.
**Seen in:** 35/38 clients.
**Example:**

```sql
DATE_ADD(CURRENT_DATE(), INTERVAL 7 MONTH)
DATE_SUB(CURRENT_DATE(), INTERVAL 786 DAY)
```

### 29. `EXTRACT(<part> FROM <date_or_ts>)`

**Why:** pull `YEAR`, `MONTH`, `QUARTER`, `ISOWEEK`, `ISOYEAR`, `DAYOFWEEK` from a date. ISOweek is the fiscal-week shortcut for some clients.
**Seen in:** 32/38 clients.
**Example:**

```sql
EXTRACT(ISOYear FROM txn.date) AS Year,
EXTRACT(ISOWeek FROM txn.date) AS Week
```

**Anchor:** `puma/ingestion/ia_reco_imputed_data_temp.sql` (`Historical_period_base` CTE).

### 30. `SPLIT(str, delim)`

**Why:** breaking a `'__'`-joined composite key apart, parsing CSV-in-a-cell. Returns ARRAY<STRING>.
**Seen in:** 30/38 clients.
**Example:**

```sql
SPLIT(l1_name, '_')[OFFSET(0)] AS l1_id,
SPLIT(pfs_year_season, '.')[SAFE_OFFSET(0)] AS pfs_year
```

**Anchor:** `signet/ingestion/oms_otb.sql` (`SPLIT(l2_name,'_')[OFFSET(0)]`).

### 31. `TRIM(...)`

**Why:** strip whitespace before joining/comparing. Often combined with `LOWER()` to normalise.
**Seen in:** 29/38 clients (borderline T1).
**Example:**

```sql
WHERE LOWER(TRIM(channel)) IN ('ecomm', 'retail')
```

### 32. `HAVING`

**Why:** post-aggregation filter. Common for "groups with at least N rows" or eligibility tests.
**Seen in:** 29/38 clients.
**Example:**

```sql
SELECT fiscal_month, INITCAP(fiscal_month_name) AS fiscal_month_name
FROM `signet_ingestion_prod.fiscal_date_mapping`
GROUP BY fiscal_month, fiscal_month_name
HAVING COUNT(calendar_date) > 15
```

**Anchor:** `signet/ingestion/oms_otb.sql` (`month_name_table` CTE).

### 33. `IS NULL` / `IS NOT NULL`

**Why:** literally universal. `= NULL` doesn't work in SQL — use these.
**Seen in:** 38/38 clients.
**Example:**

```sql
WHERE qty IS NOT NULL AND oh IS NOT NULL
```

### 34. `BETWEEN low AND high` (inclusive both ends)

**Why:** the canonical date-window predicate. Always inclusive of both endpoints.
**Seen in:** 37/38 clients.
**Example:**

```sql
WHERE date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
WHERE fiscal_year_week BETWEEN 202401 AND 202552
```

### 35. `IN (SELECT ...)` / `NOT IN (SELECT ...)` (subquery membership)

**Why:** filter by an inline subquery list. The repo's preferred form for "rows matching a configured list".
**Seen in:** IN (SELECT ...) 37/38; NOT IN (SELECT ...) 36/38.
**Example:**

```sql
WHERE store_code IN (
  SELECT store_code FROM `pacsun-09012025.pacsun_ingestion_prod.store_master` WHERE channel = 'OUTLET'
)
AND product_code NOT IN (SELECT distinct product_code FROM excluded_skus)
```

> **Note:** for very large NOT-IN lists, `LEFT JOIN ... WHERE rhs IS NULL` (anti-join) is more efficient. Both shapes appear in the repo.

### 36. `LIKE` / `NOT LIKE`

**Why:** glob-style string matching. `%` matches any-length, `_` matches single char.
**Seen in:** LIKE 34/38; NOT LIKE 22/38.
**Example:**

```sql
WHERE product_code LIKE '%_ECOMM'
  AND store_name NOT LIKE 'TEST%'
```

### 37. `ABS(x)` / `CEIL(x)` / `FLOOR(x)` / `TRUNC(x)`

**Why:** standard numeric primitives. `ABS` is heavily used in discount/cost imputation; `CEIL`/`FLOOR` for bucket math; `TRUNC` to drop decimals.
**Seen in:** ABS 33/38; CEIL 27/38; FLOOR 17/38; TRUNC 32/38.
**Example:**

```sql
ABS(COALESCE(msrp,0) - COALESCE(price,0))                              AS discount_abs,
CAST(CEIL(fiscal_week / 2) AS INT64)                                   AS fiscal_bi_week,
FLOOR(SAFE_DIVIDE(qty, factor))                                        AS qty_floor
```

**Anchor:** `pacsun/preprocessing/queries.json` (`fmt_aggr` CTE — uses CEIL for bi-week bucketing).

### 38. `INT64` / `FLOAT64` / `NUMERIC` / `STRING` / `BOOL` / `DATE` / `DATETIME` / `TIMESTAMP` (BQ types)

**Why:** the BQ type names you'll see in `CAST(... AS <type>)` and `DECLARE var <type>`. Note they're capitalised by convention but BQ is case-insensitive on type names.
**Seen in:** INT64 37/38; rest universal.
**Example:**

```sql
CAST(cluster_name AS INT64)
SAFE_CAST(QTY_SOLD AS FLOAT64)
DECLARE table_exists BOOL;
DECLARE max_inv_date DATE DEFAULT (...);
```

---

## Tier 2 — Common (10-29/38 clients)

These you'll hit within the first few clients. Skim now; come back when you see them.

### 39. `DENSE_RANK() OVER (...)` and `RANK() OVER (...)`

**Why:** tied-aware ranking. `DENSE_RANK` skips no positions on ties; `RANK` does. Used in priority logic, "first/best/highest" selection.
**Seen in:** DENSE_RANK 28/38; RANK 21/38.
**Example:**

```sql
DENSE_RANK() OVER (PARTITION BY old_article, new_article ORDER BY new_product_code) AS non_null_pc
```

**Anchor:** `rl-na/sourcing/create_product.sql`.

### 40. `LEAD(col) OVER (...)`

**Why:** pair with `LAG` for next-value lookups (e.g. next allocation cycle date). Less common than LAG but appears in 21 clients.
**Seen in:** 21/38 clients.
**Example:**

```sql
LEAD(calendar_date) OVER (PARTITION BY product_code ORDER BY calendar_date) AS next_cycle_date
```

**Anchor:** `signet/ingestion/oms_order_cycle.sql`.

### 41. `FIRST_VALUE(col IGNORE NULLS) OVER (...)` / `LAST_VALUE(col IGNORE NULLS) OVER (...)`

**Why:** forward/backward fill for sparse time series (price/cost/msrp imputation). Almost always combined with explicit window frames (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`).
**Seen in:** FIRST_VALUE 21/38; LAST_VALUE 16/38.
**Example:**

```sql
COALESCE(
  msrp_imputed,
  LAST_VALUE(msrp_imputed IGNORE NULLS) OVER (
    PARTITION BY product_code ORDER BY date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
  FIRST_VALUE(msrp_imputed IGNORE NULLS) OVER (
    PARTITION BY product_code ORDER BY date
    ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
) AS msrp
```

**Anchor:** `pacsun/preprocessing/queries.json` (`final_table` CTE).

### 42. Window frame clauses — `ROWS BETWEEN ... AND ...` / `UNBOUNDED PRECEDING/FOLLOWING`

**Why:** explicit framing for running totals, rolling averages, and the IGNORE-NULLS fill (see #41).
**Seen in:** ROWS BETWEEN 29/38; UNBOUNDED PRECEDING 24/38.
**Example:**

```sql
SUM(qty) OVER (PARTITION BY product_code ORDER BY date
               ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_qty
```

### 43. `STRING_AGG(col [, delim] [ORDER BY ...])`

**Why:** collapse a group's strings to a delimited list. Used for "list all SKUs that match this article" and similar.
**Seen in:** 26/38 clients.
**Example:**

```sql
STRING_AGG(DISTINCT style_color_id, '__ia_char_30' ORDER BY style_color_id) AS style_color_id,
STRING_AGG(DISTINCT style,           '__ia_char_30' ORDER BY style)           AS style
```

**Anchor:** `rl-na/sourcing/create_product.sql` (`art_level` CTE; note the `__ia_char_30` separator — that's the IA encoded character for `,`).

### 44. `ARRAY_AGG([DISTINCT] col [ORDER BY ...] [LIMIT ...])`

**Why:** collapse a group to an array (often `DISTINCT ... ORDER BY`). Frequently followed immediately by `UNNEST` to re-flatten — that pattern dedups while preserving sort.
**Seen in:** 23/38 clients.
**Example:**

```sql
SELECT
  Latest_SKU,
  t.CHANNEL                                  AS CHANNEL,
  ARRAY_AGG(DISTINCT m.SKU ORDER BY m.SKU)   AS SKU,
  MIN(FINAL_DATE)                            AS min_final_date
FROM mainsubsku_raw m
LEFT JOIN transaction_intermediate t ON m.SKU = t.SKU
GROUP BY 1, 2;
```

**Anchor:** `signet/sourcing/create_productmindate.sql` line 1.

### 45. `EXISTS (SELECT 1 FROM ... WHERE ...)` / `NOT EXISTS`

**Why:** semi-join / anti-join semantics — "rows that have a match" / "rows that don't". Often cleaner than `WHERE col IN (...)` for big subqueries.
**Seen in:** 20/38 clients.
**Example:**

```sql
ASSERT EXISTS (
  SELECT 1 FROM `victorias-secret-393308.vs_ingestion_prod.__TABLES__`
  WHERE table_id = 'forecast_store_sku'
);
```

**Anchor:** `vs/ingestion/ada_visual_daily_refresh.sql` line 1.

### 46. `CROSS JOIN UNNEST(array)` / `, UNNEST(array)` (lateral)

**Why:** explicit flattening of an array column. Shows up after `GENERATE_DATE_ARRAY`, after `ARRAY_AGG`, and in JSON parsing.
**Seen in:** 20/38 clients.
**Example:**

```sql
-- Generate one row per day in a date range
SELECT day
FROM UNNEST(GENERATE_DATE_ARRAY(start_date, end_date, INTERVAL 1 DAY)) AS day;
```

### 47. `UNION DISTINCT`

**Why:** like `UNION ALL` but de-duplicates. Used when stitching scenarios where the same key may appear in multiple branches.
**Seen in:** 24/38 clients.
**Example:**

```sql
SELECT *, 'base' AS mapping_type FROM prod_wo_supersession
UNION DISTINCT
SELECT *, 'base and sup A' FROM sup_scn_A
UNION DISTINCT
SELECT * EXCEPT(new_product_code), 'sup B 1' FROM scn_B_part_1 WHERE new_product_code IS NOT NULL
UNION DISTINCT
SELECT *, 'supB 2' FROM sup_scn_B;
```

**Anchor:** `rl-na/sourcing/create_product.sql` (`sup_final` CTE).

### 48. `RIGHT JOIN`

**Why:** rare but present. Usually appears when the "outer" side is conceptually right-hand (e.g. you want all template rows + matched fact rows).
**Seen in:** 10/38 clients.
**Example:**

```sql
... RIGHT JOIN reqd_products ON week = fiscal_week_in_month
                            AND order_cycle_day_assumed = INITCAP(fiscal_day_name)
```

**Anchor:** `signet/ingestion/oms_order_cycle.sql`.

### 49. `NULLIF(a, b)`

**Why:** turns `a` into NULL when `a = b`. Combined with `COALESCE` to collapse sentinel values back to NULL before fallback chains.
**Seen in:** 23/38 clients.
**Example:**

```sql
COALESCE(NULLIF(NULLIF(gender, ''), '\\N'), 'Unisex') AS gender_clean
```

### 50. `IF(cond, a, b)` (the function form, not the script form)

**Why:** ternary-style conditional. Equivalent to `CASE WHEN cond THEN a ELSE b END` but shorter.
**Seen in:** 20/38 clients.
**Example:**

```sql
IF(qty IS NULL, 0, qty) AS qty_safe,
IF(date >= CURRENT_DATE(), 'future', 'past') AS time_bucket
```

### 51. `SAFE.<function>(...)` namespace

**Why:** any function prefixed with `SAFE.` returns NULL instead of raising on bad input. Used with `PARSE_DATE`, `DIVIDE`, etc.
**Seen in:** 13/38 clients.
**Example:**

```sql
SAFE.PARSE_DATE('%Y%m%d', CAST(INV_DATE AS STRING))
SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S', raw_ts)
```

### 52. `PARSE_DATE` / `PARSE_TIMESTAMP` / `PARSE_DATETIME`

**Why:** raw dates land as strings in `'%Y%m%d'`, `'%m/%d/%Y'`, etc. Always `PARSE_*` (or `SAFE.PARSE_*`) before doing date math.
**Seen in:** PARSE_DATE 23/38; PARSE_TIMESTAMP 11/38; PARSE_DATETIME 7/38.
**Example:**

```sql
SELECT MAX(PARSE_DATE('%Y%m%d', CAST(INV_DATE AS STRING)))
FROM `data-ingestion-342714.signet_sourcing_prod.ia_inv`;
```

**Anchor:** `signet/sourcing/create_product.sql` line 2.

### 53. `FORMAT_DATE` / `FORMAT_TIMESTAMP` / `FORMAT(...)` (general format)

**Why:** date → string for display / logging / dynamic SQL. `FORMAT(...)` is the general printf-style; `FORMAT_DATE` is date-only.
**Seen in:** FORMAT_DATE 18/38; FORMAT_TIMESTAMP 5/38; FORMAT (general) 17/38.
**Example:**

```sql
EXECUTE IMMEDIATE FORMAT("DROP TABLE IF EXISTS %s", target_path);
EXECUTE IMMEDIATE FORMAT("CREATE OR REPLACE TABLE %s CLONE %s", target_path, source_path);
```

**Anchor:** `sb/ingestion/mondaysmart_historic_clone_historic.sql` lines 21-24.

### 54. `SUBSTR` / `LEFT` / `RIGHT`

**Why:** prefix/suffix extraction. Commonly used to derive `fiscal_year` from a `YYYYMM` STRING or strip a `_ECOMM` suffix.
**Seen in:** SUBSTR 21/38; LEFT 24/38; RIGHT 28/38.
**Example:**

```sql
RIGHT(CAST(m.fiscal_year_month AS string), 2)               -- get '03' from '202403'
LEFT(version, 2) = 'LY'                                     -- LY/TY year flag
SUBSTRING(l1_name, 1, 4)                                    -- first 4 chars
```

**Anchor:** `signet/ingestion/oms_otb.sql` and `partycity/ingestion/store_bucket_master.sql`.

### 55. `LPAD(str, len, pad)`

**Why:** zero-pad single-digit weeks/months when building composite keys like `YYYYWW`. RPAD is rare.
**Seen in:** 18/38 clients.
**Example:**

```sql
CAST(CONCAT(m.fiscal_year, LPAD(m.fiscal_week, 2, '0')) AS INT64) AS fiscal_year_week
```

**Anchor:** `signet/ingestion/oms_otb.sql`.

### 56. `LENGTH(str)`

**Why:** validation (e.g. "SKU code must be exactly 9 chars"), filtering on string length.
**Seen in:** 25/38 clients.

### 57. `REGEXP_CONTAINS` / `REGEXP_EXTRACT` / `REGEXP_REPLACE`

**Why:** parsing the IA platform's multi-format SKU/article codes. `REGEXP_CONTAINS` for predicates, `REGEXP_EXTRACT` for capture groups, `REGEXP_REPLACE` for substitution.
**Seen in:** REGEXP_EXTRACT 23/38; REGEXP_REPLACE 19/38; REGEXP_CONTAINS 13/38.
**Example:**

```sql
REGEXP_CONTAINS(product_code, r'_ECOMM$')                       AS is_ecomm,
REGEXP_EXTRACT(product_code, r'^(\d+)_')                        AS bare_code,
REGEXP_REPLACE(product_code, r'_(ECOMM|RETAIL)$', '')           AS stripped
```

### 58. `GREATEST(a, b, c, ...)` / `LEAST(a, b, c, ...)`

**Why:** N-arg max/min on the row. Used for "the latest of multiple date columns" or "the lowest of available prices".
**Seen in:** GREATEST 25/38; LEAST 20/38.
**Example:**

```sql
GREATEST(launch_date, available_from_date, supersede_date) AS effective_start,
LEAST(price, msrp, launch_price)                            AS lowest_price
```

### 59. `MOD(a, b)` (the function form; not the operator)

**Why:** modulo on integers. Used for bucketing, even/odd checks, and "every Nth row" patterns.
**Seen in:** 27/38 clients.
**Example:**

```sql
WHERE MOD(fiscal_week, 2) = 0   -- even weeks only
```

### 60. `INSERT INTO`

**Why:** plain insert. Used in scripted/procedural files where MERGE isn't appropriate (e.g. accumulating into a partition by quarter).
**Seen in:** 21/38 clients.
**Example:**

```sql
IF table_exists THEN
  INSERT INTO `pacsun-09012025.pacsun_ingestion_prod.master_input_imputed_validated_table` (
    SELECT * FROM `pacsun-09012025.pacsun_ingestion_prod.required_master_input_imputed_3`
  );
ELSE
  CREATE OR REPLACE TABLE ...
END IF;
```

**Anchor:** `pacsun/preprocessing/queries.json` (the `IF table_exists THEN` branch).

### 61. `DELETE FROM ... WHERE ...`

**Why:** clear a partition or window before re-inserting. The MERGE alternative for some use cases.
**Seen in:** 15/38 clients.

### 62. `DROP TABLE IF EXISTS`

**Why:** cleanup of `*_temp` tables after MERGE upserts (Pattern 2 final step), or guard before a `CREATE TABLE ... CLONE`.
**Seen in:** 11/38 clients.
**Example:**

```sql
DROP TABLE IF EXISTS `data-ingestion-342714.signet_sourcing_prod.transaction_intermediate_temp`;
```

**Anchor:** `signet/sourcing/create_transaction.sql` line 481.

### 63. `IF cond THEN ... [ELSE ...] END IF;` (script form)

**Why:** procedural branching inside a `BEGIN ... END;` block. Distinct from `IF(...)` the function (#50).
**Seen in:** 18/38 clients.
**Example:**

```sql
IF latest_table_name IS NULL THEN
    RAISE USING MESSAGE = 'No matching table found!';
END IF;
```

**Anchor:** `tb/ingestion/iaf_intermediate_preseason.sql`.

### 64. `FOR var IN (subquery) DO ... END FOR;`

**Why:** iterate over a result set inside a procedure. Used to loop over fiscal quarters/weeks and rebuild a partition per iteration.
**Seen in:** 11/38 clients.
**Example:**

```sql
FOR record IN (
  SELECT table_name FROM `<project>.<dataset>.INFORMATION_SCHEMA.TABLES`
  WHERE table_type = 'BASE TABLE'
) DO
  SET table_name = record.table_name;
  EXECUTE IMMEDIATE FORMAT("CREATE OR REPLACE TABLE %s CLONE %s", target_path, source_path);
END FOR;
```

**Anchor:** `sb/ingestion/mondaysmart_historic_clone_historic.sql` lines 8-30.

### 65. `SET var = (subquery)`

**Why:** procedural assignment, paired with `DECLARE`. Often used to fetch the rolling-window driver from the `mapping` table (Pattern 3).
**Seen in:** 24/38 clients.
**Example:**

```sql
DECLARE filter_param DATETIME;
SET filter_param = (
  SELECT filter_param
  FROM `data-ingestion-342714.signet_sourcing_prod.mapping`
  WHERE intermediate_table = 'transaction_intermediate'
);
```

**Anchor:** `signet/sourcing/create_transaction.sql` lines 1-6.

### 66. `QUALIFY` clause

**Why:** filter on a window-function result without the wrapping subquery. Cleaner replacement for `WHERE rn = 1` after `ROW_NUMBER`.
**Seen in:** 19/38 clients.
**Example:**

```sql
SELECT *
FROM `pacsun-09012025.pacsun_ingestion_prod.latest_inventory`
QUALIFY ROW_NUMBER() OVER (PARTITION BY fiscal_year_week ORDER BY date DESC) = 1
ORDER BY ...;
```

**Anchor:** `pacsun/ingestion/latest_inventory_with_txn.sql` lines 16-17, and `pacsun/ingestion/mondaysmart_woi_master_historic.sql` lines 48-50.

### 67. `GENERATE_DATE_ARRAY(start, end, INTERVAL N <unit>)`

**Why:** synthesise a complete date series, typically `CROSS JOIN UNNEST`-ed against products/stores to get a full Cartesian grid.
**Seen in:** 11/38 clients.
**Example:**

```sql
SELECT day
FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2024-01-01', CURRENT_DATE(), INTERVAL 1 DAY)) AS day;
```

**Anchor:** `signet/ingestion/vendor_lead_time.sql` and `pacsun/sourcing/create_inventory.sql`.

### 68. `GENERATE_ARRAY(start, end, step)`

**Why:** integer/numeric ranges. Useful to enumerate weeks 1..53 or store buckets.
**Seen in:** 21/38 clients.

### 69. `JSON_VALUE` / `JSON_EXTRACT` / `JSON_EXTRACT_SCALAR`

**Why:** parse JSON STRING columns (typically OMS order-cycle policies, attribute payloads). `JSON_VALUE` returns scalar STRING; `JSON_EXTRACT` returns JSON-as-STRING.
**Seen in:** JSON_VALUE 11/38; JSON_EXTRACT 13/38.
**Example:**

```sql
SELECT
  product_code,
  CAST(JSON_VALUE(order_cycle.week) AS int64)        AS week,
  JSON_VALUE(order_cycle.day)                        AS order_cycle_day_assumed
FROM (
  SELECT *EXCEPT(order_cycle), PARSE_JSON(order_cycle) AS order_cycle
  FROM `signet_ingestion_prod.oms_constraints_order_policy`
);
```

**Anchor:** `signet/ingestion/oms_order_cycle.sql` line 1.

### 70. `PARSE_JSON(string)` and `TO_JSON_STRING(value)`

**Why:** convert between STRING and the `JSON` type. `PARSE_JSON` is the inverse of `TO_JSON_STRING`.
**Seen in:** PARSE_JSON 12/38; TO_JSON_STRING 13/38.
**Example:** see #69 (`PARSE_JSON(order_cycle)`).

### 71. `STRUCT(field1 [AS name1], field2, ...)`

**Why:** ad-hoc record construction inline. Often seen inside `ARRAY_AGG(STRUCT(...))` to nest line-items per transaction.
**Seen in:** 10/38 clients.
**Example:**

```sql
ARRAY_AGG(STRUCT(LINE_ID, SKU, QTY_SOLD) ORDER BY LINE_ID) AS lines
```

### 72. `ARRAY_LENGTH(array)`

**Why:** count of elements; used in JSON-parsed arrays and in conditional pruning.
**Seen in:** 16/38 clients.

### 73. `OFFSET(n)` / `ORDINAL(n)` / `SAFE_OFFSET(n)` (array indexing)

**Why:** index into an array. `OFFSET` is 0-indexed; `ORDINAL` is 1-indexed; `SAFE_OFFSET` returns NULL for out-of-bounds (the safe variant).
**Seen in:** SAFE_OFFSET 7/38; OFFSET (in SPLIT)[OFFSET(0)] is widespread.
**Example:**

```sql
SPLIT(pfs_year_season, '.')[SAFE_OFFSET(0)] AS pfs_year,
SPLIT(pfs_year_season, '.')[SAFE_OFFSET(1)] AS pfs_season_id,
SPLIT(pfs_year_season, '.')[SAFE_OFFSET(2)] AS pfs_season
```

**Anchor:** `rl-na/sourcing/create_product.sql` (`final_mid` CTE).

### 74. `RANGE_BUCKET(point, boundaries_array)`

**Why:** map a numeric `point` into a discrete bucket index defined by an ordered boundaries array. Used in size-curve / price-band logic.
**Seen in:** 13/38 clients.

### 75. `GROUP BY ALL`

**Why:** BQ-specific shortcut. Equivalent to `GROUP BY <every non-aggregate column>`. Saves typing in wide aggregation queries; fragile if you later add a non-aggregate column.
**Seen in:** 23/38 clients.
**Example:**

```sql
SELECT
  channel, l0_name, l1_name, fiscal_year, fiscal_week,
  SUM(qty_imputed) AS qty,
  SUM(oh) AS inv,
  SAFE_DIVIDE(SUM(msrp*qty_imputed), SUM(qty_imputed)) AS msrp
FROM mii
GROUP BY ALL;
```

**Anchor:** `pacsun/preprocessing/queries.json` (`fmt_aggr` CTE uses `GROUP BY all`).

### 76. `SUBSTRING(str, start [, length])`

**Why:** alias of `SUBSTR`. Both work; some clients prefer the longer form. Same arguments.
**Seen in:** 16/38 clients (separately countable from `SUBSTR`).
**Example:**

```sql
SUBSTRING(l1_name, 1, 4)  AS l1_id
```

**Anchor:** `signet/ingestion/oms_otb.sql`.

---

## Tier 3 — Selective (2-9/38 clients)

Glossary territory. Skim now; consult when you see them.

### 77. `EXECUTE IMMEDIATE <string>` (also `EXECUTE IMMEDIATE FORMAT(...)`)

**Why:** execute SQL built dynamically as a STRING. Used for cross-dataset table cloning and any DDL that varies per iteration.
**Seen in:** 5/38 clients.
**Example:**

```sql
EXECUTE IMMEDIATE FORMAT("DROP TABLE IF EXISTS %s", target_path);
EXECUTE IMMEDIATE FORMAT("CREATE OR REPLACE TABLE %s CLONE %s", target_path, source_path);

EXECUTE IMMEDIATE sql_stmt INTO cnt;        -- read scalar back into a variable
```

**Anchor:** `sb/ingestion/mondaysmart_historic_clone_historic.sql` lines 21-24, and `vs/ingestion/daily_sims_pink_ecom_part2.sql` line 58.

### 78. `CREATE OR REPLACE PROCEDURE <name>(...) BEGIN ... END;`

**Why:** wrap a multi-statement script in a callable procedure; the platform then `CALL`s it. Common in `preprocessing/queries.json`.
**Seen in:** 9/38 clients.
**Example:**

```sql
CREATE OR REPLACE PROCEDURE `pacsun-09012025`.pacsun_ingestion_prod.create_master_input_imputed_historic()
BEGIN
  DECLARE table_exists BOOL;
  DROP TABLE `...master_input_imputed_validated_table`;
  FOR iterator IN (SELECT fiscal_year_quarter, MIN(date) AS start_date, MAX(date) AS end_date
                   FROM `...fiscal_date_mapping` GROUP BY 1) DO
    SET table_exists = (SELECT COUNT(*) > 0 FROM `...INFORMATION_SCHEMA.TABLES`
                        WHERE table_name = 'master_input_imputed_validated_table');
    -- ... per-quarter rebuild ...
  END FOR;
END;

CALL `pacsun-09012025`.pacsun_ingestion_prod.create_master_input_imputed_historic();
```

**Anchor:** `pacsun/preprocessing/queries.json` (line 4-5).

### 79. `CREATE OR REPLACE VIEW`

**Why:** rare. The platform prefers materialised tables. Views appear mostly as cosmetic aliases or query-time filtering layers.
**Seen in:** 4/38 clients.

### 80. `BEGIN ... END;` (script block)

**Why:** wraps multiple statements that share scope (`DECLARE`, `SET`, `FOR ... DO ... END FOR`). All script files are one big BEGIN/END.
**Seen in:** appears wherever scripting does. Roughly 18-32/38 depending on flavour.
**Example:** see #78 above.

### 81. `RAISE USING MESSAGE = '...'`

**Why:** abort a procedure with an error. Only `tb` uses it in this repo.
**Seen in:** 1/38 clients (`tb`).
**Example:**

```sql
IF latest_table_name IS NULL THEN
    RAISE USING MESSAGE = 'No matching table found!';
END IF;
```

**Anchor:** `tb/ingestion/iaf_intermediate_preseason.sql`.

### 82. `ASSERT <expr> [AS '<msg>']`

**Why:** preflight check that aborts the script if the predicate is false. Only `vs` uses it.
**Seen in:** 1/38 clients (`vs`, ~22 files).
**Example:**

```sql
ASSERT EXISTS (
  SELECT 1
  FROM `victorias-secret-393308.vs_ingestion_prod.__TABLES__`
  WHERE table_id = 'forecast_store_sku'
);
```

**Anchor:** `vs/ingestion/ada_visual_daily_refresh.sql` line 1.

### 83. `WITH RECURSIVE`

**Why:** essentially unused (only `vs/ingestion/anr_total_dc_forecast*.sql`). Mention here so you recognise it's exotic, not normal.
**Seen in:** 1/38 clients.

### 84. `CREATE TEMP FUNCTION ... RETURNS ... AS (...)` (SQL UDF)

**Why:** the special-character escape function (Pattern 8 in `docs/ia_bq_patterns.md`). 30+ nested `REPLACE`s wrapped as a UDF for reuse.
**Seen in:** 8/38 clients (signet, levi-lse, levi-lsa, lovisa, dg, leslies, puma, saks).
**Example:**

```sql
CREATE TEMP FUNCTION ReplaceSpecialCharacters(x string) RETURNS string AS (
  REPLACE(REPLACE(REPLACE(REPLACE( /* ... 30+ replacements ... */
    x,
    "'", '__ia_char_01'),
    '"', '__ia_char_02'),
    '/', '__ia_char_03'),
    '\\', '__ia_char_04')
);

SELECT ReplaceSpecialCharacters(Sig_Dept) AS Sig_Dept FROM raw;
```

**Anchor:** `signet/sourcing/create_product.sql` line 410.

### 85. `PIVOT (agg_func(col) FOR pivot_col IN (...))`

**Why:** wide-to-tall transformation. Used for "actual vs estimated" splits and "by-banner" matrices.
**Seen in:** 4/38 clients (signet, briscoes, lovisa, partycity).
**Example:**

```sql
SELECT *
FROM (
  SELECT t.tag, t.l2_name, ..., SUM(t.Total_cost) AS Total_cost
  FROM ...
  GROUP BY ...
) k
PIVOT (SUM(Total_cost) FOR tag IN ('actual', 'estimated'))
GROUP BY l2_name, planning_ownership, ...;
```

**Anchor:** `signet/ingestion/oms_otb.sql` (the `po_pm_fm_piv` CTE).

### 86. `UNPIVOT (val_col FOR pivot_col IN (...))`

**Why:** tall-to-wide reversed (i.e. wide → tall). Used for "all comp flags" → "(year_offset, comp_status)" pairs.
**Seen in:** 5/38 clients.
**Example:**

```sql
SELECT site_no, site_group_id, tran_dt, fiscal_year, fiscal_week,
       fiscal_year_week AS compared_week, version, comp_status
FROM step_3
UNPIVOT (comp_status FOR version IN (TY_COMP_FLAG, LY_COMP_FLAG, LY2_COMP_FLAG))
ORDER BY version, comp_status;
```

**Anchor:** `partycity/ingestion/store_bucket_master.sql` line 1.

### 87. `EXCEPT DISTINCT`

**Why:** rows in left side not in right. Used in QC / drift queries between historic and steady-state builds.
**Seen in:** 4/38 clients (carters, pacsun, signet, vs).
**Example:**

```sql
SELECT TRANS_ID, LINE_ID FROM transaction_intermediate
EXCEPT DISTINCT
SELECT TRANS_ID, LINE_ID FROM transaction_intermediate_historic;
```

### 88. `SELECT * REPLACE (expr AS col)`

**Why:** BQ-specific. Replace a single column in a `SELECT *` projection without listing the rest.
**Seen in:** 3/38 clients.
**Example:**

```sql
SELECT * EXCEPT (c) REPLACE(c AS SKU)
FROM (SELECT * FROM cte), UNNEST(SKU) c;
```

**Anchor:** `signet/sourcing/create_productmindate.sql` line 1.

### 89. `INFORMATION_SCHEMA.<view>`

**Why:** schema introspection. Mostly `INFORMATION_SCHEMA.TABLES` (in `FOR ... IN`), occasionally `INFORMATION_SCHEMA.COLUMNS`.
**Seen in:** 9/38 clients.
**Example:**

```sql
FOR record IN (
  SELECT table_name FROM `starboard-13022025.mondaysmart_sb_ingestion_uat.INFORMATION_SCHEMA.TABLES`
  WHERE table_type = 'BASE TABLE'
) DO ...
```

**Anchor:** `sb/ingestion/mondaysmart_historic_clone_historic.sql` line 10.

### 90. Legacy `__TABLES__`

**Why:** older schema-introspection view (gives `row_count`, `size_bytes`, `last_modified_time` for free). The newer API is `INFORMATION_SCHEMA.TABLES`. Mixing the two trips error G3.
**Seen in:** 2/38 clients (signet, vs).

### 91. `CREATE TABLE ... CLONE <other_table>`

**Why:** zero-cost copy (BQ "table clones"). Used in vs/sb cross-environment promotion.
**Seen in:** appears inside `EXECUTE IMMEDIATE` strings, hard to count separately.
**Example:** see #77.

### 92. `ALTER TABLE`

**Why:** very rare. Mostly `ALTER TABLE ... SET OPTIONS(...)` or `ADD COLUMN`. Two clients use it.
**Seen in:** 2/38 clients (figs, vs).

### 93. `TRUNCATE TABLE`

**Why:** wipe a table without dropping it. One client (vs) uses it for ada simulation reset.
**Seen in:** 1/38 clients.

### 94. `OPTIONS(description=..., labels=..., expiration_timestamp=...)` clause on DDL

**Why:** table-level metadata. Set automatically for some platform tables.
**Seen in:** 7/38 clients.

### 95. `MATERIALIZED VIEW`

**Why:** essentially absent. One occurrence (signet/sourcing/create_ecom_historic.sql).
**Seen in:** 1/38 clients.

### 96. `ANY_VALUE(col)`

**Why:** "give me any non-NULL value of col in this group" without imposing an ordering. Cheaper than `MAX(col)` when you don't care which.
**Seen in:** 6/38 clients.
**Example:**

```sql
SELECT product_code, ANY_VALUE(po_inbound) AS po_inbound
FROM raw GROUP BY 1;
```

**Anchor:** `vs/ingestion/anr_total_dc_forecast.sql` line 50.

### 97. `COUNTIF(predicate)`

**Why:** `COUNT(*) FILTER (WHERE predicate)` shorthand — count rows matching a condition. Equivalent to `SUM(IF(pred, 1, 0))`.
**Seen in:** 6/38 clients.
**Example:**

```sql
COUNTIF(col IS NULL OR CAST(col AS STRING) IN ('', '\\N')) AS null_or_blank
```

### 98. `LOGICAL_AND(bool)` / `LOGICAL_OR(bool)`

**Why:** aggregate AND/OR over a group. Used for "all rows pass this check" / "any row passes".
**Seen in:** LOGICAL_AND 2/38; LOGICAL_OR 3/38.

### 99. `APPROX_QUANTILES(col, N)[OFFSET(k)]`

**Why:** approximate percentile aggregator. `[OFFSET(N/2)]` gives the median.
**Seen in:** 3/38 clients.
**Example:**

```sql
APPROX_QUANTILES(elasticity, 2)[OFFSET(1)] AS median_elasticity
```

**Anchor:** `mns/ingestion/tb_point_elasticity.sql` line 19.

### 100. `APPROX_TOP_COUNT(col, k)`

**Why:** approximate top-k by frequency, returns ARRAY<STRUCT<value, count>>.
**Seen in:** 3/38 clients (psp, spanx, vs).

### 101. `PERCENTILE_CONT(col, fraction) OVER (...)` (analytic, not aggregate)

**Why:** continuous percentile (interpolated). Always called as a window function in this repo. `0.5` → median.
**Seen in:** 5/38 clients.
**Example:**

```sql
PERCENTILE_CONT(transit_time_og, 0.5) OVER (PARTITION BY store_code) AS median_store_truck_lt_og,
PERCENTILE_CONT(processing_time, 0.5) OVER (PARTITION BY store_code) AS median_store_truck_pt
```

**Anchor:** `vs/ingestion/dc_transit_time.sql` lines 33-35.

### 102. `SUM(DISTINCT col)`

**Why:** sum after dedup. Rare; usually a sign of a grain bug upstream that the author "fixed" with DISTINCT.
**Seen in:** 2/38 clients.

### 103. `NTILE(k) OVER (...)`

**Why:** divide rows into k roughly-equal buckets. Used for store-tier clustering and quantile bucketing.
**Seen in:** 2/38 clients (puma, tapestry).
**Example:**

```sql
NTILE(4) OVER (PARTITION BY l1_name ORDER BY sales DESC) AS quartile
```

### 104. `TIMESTAMP_SUB` / `TIMESTAMP_ADD` / `TIMESTAMP_DIFF` / `TIMESTAMP_TRUNC`

**Why:** TIMESTAMP-flavour of the DATE_* family. Rare in this repo because most date logic uses DATE.
**Seen in:** TIMESTAMP_SUB 3/38; TIMESTAMP_ADD 1/38; TIMESTAMP_TRUNC 1/38; TIMESTAMP_DIFF 0.

### 105. `EXTRACT(ISOWeek FROM date)` / `EXTRACT(ISOYear FROM date)`

**Why:** when the client's fiscal calendar is just ISO weeks (rather than a custom mapping table), this is the shortcut.
**Seen in:** 6/38 clients.
**Example:**

```sql
EXTRACT(ISOYear FROM txn.date) AS Year,
EXTRACT(ISOWeek FROM txn.date) AS Week
```

**Anchor:** `puma/ingestion/ia_reco_imputed_data_temp.sql` (`Historical_period_base` CTE).

### 106. `ARRAY_CONCAT(arr1, arr2, ...)`

**Why:** concatenate two arrays. Rare.
**Seen in:** 2/38 clients (carters, leslies).

### 107. `DIV(a, b)` (function form)

**Why:** integer division. Equivalent to `CAST(FLOOR(a/b) AS INT64)` but explicit.
**Seen in:** 9/38 clients.

### 108. `IS_NAN(x)` / `IS_INF(x)`

**Why:** detect NaN / Infinity in FLOAT64 results. Used in cleanup/QC blocks.
**Seen in:** IS_NAN 1/38; IS_INF 0.

### 109. `ML.<function>(...)` (BigQuery ML)

**Why:** BQML model invocation. Only one client (briscoes) has it.
**Seen in:** 1/38 clients.

### 110. `INITCAP(str)`

**Why:** title-case a string ("first letter of each word uppercased"). Used to normalise day names / month names when matching against parsed JSON like `'monday'`.
**Seen in:** 10/38 clients.
**Example:**

```sql
... AND order_cycle_day_assumed = INITCAP(fiscal_day_name)
```

**Anchor:** `signet/ingestion/oms_order_cycle.sql`.

### 111. `STDDEV(col)` / `STDDEV_SAMP(col)` (sample stddev)

**Why:** standard deviation aggregator. Used in outlier detection (e.g. `mean + 3*sd` thresholds).
**Seen in:** 9/38 clients.
**Example:**

```sql
AVG(Qty_clr)    OVER (PARTITION BY product_code, store_code) AS Mean_Qty_Historical_clr,
STDDEV(Qty_clr) OVER (PARTITION BY product_code, store_code) AS SD_Qty_Historical_clr
```

**Anchor:** `puma/ingestion/ia_reco_imputed_data_temp.sql` (`Historical_proportion` CTE).

### 112. `SAFE_MULTIPLY(a, b)` / `SAFE_ADD(a, b)` / `SAFE_SUBTRACT(a, b)` / `SAFE_NEGATE(x)`

**Why:** overflow-safe arithmetic; returns NULL on overflow rather than raising.
**Seen in:** SAFE_MULTIPLY 3/38; rest 0.
**Example:**

```sql
SAFE_MULTIPLY(p.rcvd_quantity, m.cost) AS Total_cost
```

**Anchor:** `signet/ingestion/oms_otb.sql`.

### 113. `SQRT(x)` / `POWER(base, exponent)`

**Why:** numeric primitives for distance, growth-rate, and statistical formulas. Rare.
**Seen in:** SQRT 5/38; POWER 4/38.

### 114. `WITH OFFSET` (in `UNNEST(...) WITH OFFSET`)

**Why:** when unnesting an array, also expose the 0-based position. Used to preserve "rank within array".
**Seen in:** 2/38 clients (balsam).
**Example:**

```sql
SELECT element, position
FROM UNNEST(['a','b','c']) AS element WITH OFFSET AS position;
```

---

## Tier 4 — BQ quirks / gotchas

These don't add new concepts — they're the things that break first when you try to write your own. Headlines below; full details in
[`.cursor/rules/lululemon-bq-context.mdc`](../.cursor/rules/lululemon-bq-context.mdc) Section 4.

### G1. Reserved keywords as bare aliases

`AS rows`, `AS range`, `AS order`, etc. break at the *reference* site. Use `AS row_count`, etc., or backtick: `` AS `rows` ``.

```sql
SELECT COUNT(*) AS row_count FROM t;       -- good
SELECT COUNT(*) AS rows      FROM t;       -- breaks elsewhere
```

### G2 / G5 / G10. STRING vs INT64 sentinel handling

`'\N'` and `''` only make sense on STRING columns. JSON sample output quotes everything, so you can't infer the type from a sample. Always check `INFORMATION_SCHEMA.COLUMNS` first.

```sql
COUNTIF(col IS NULL OR CAST(col AS STRING) IN ('', '\\N')) AS null_or_blank
```

### G3. `__TABLES__` uses `table_id`, not `table_name`

Mixing the two APIs (`__TABLES__` and `INFORMATION_SCHEMA.TABLES`) in the same UNION fails on column-name mismatch.

### G4. Multi-level aggregation requires a `GROUP BY` modifier

`SUM(COUNT(*))` and `ARRAY_AGG(COUNT(*) OVER ...)` need to be split into two CTEs.

```sql
WITH per_store AS (SELECT store_number, COUNT(*) AS cnt FROM t GROUP BY store_number)
SELECT AVG(cnt) FROM per_store;
```

### G6. `SELECT DISTINCT *` over a wide projection is a smell

Either upstream has full-row dupes (document the cause) or DISTINCT is masking grain bugs. Diagnose first; don't paper over.

### G7. (merged into G1.)

### G8. `_20251119` suffix is not reliable on raw tables

The PC team's master-build DDL references date-suffixed raw tables that don't exist. Always sanity-check existence with `SELECT 1 FROM <tbl> LIMIT 0` before authoring.

### G9. Master-build DDL is not a trustworthy schema reference

Columns may have been renamed since the DDL was written. Run `INFORMATION_SCHEMA.COLUMNS` for the exact table before using any raw column.

### G10. `col IN ('', '\N')` fails on INT64

JSON sample output quotes every value, so a sample showing `"ID": "158768468"` may be INT64 in BQ. Defensive pattern: `CAST(col AS STRING) IN ('', '\\N')`.

---

## Suggested reading order

To go from zero to fluent in the IA repo's SQL with minimum wasted time:

1. **`signet/sourcing/create_product.sql`** — the canonical source-of-truth file. Has CTE chaining (#1), dedup (#10), partition/cluster DDL (#14), the special-char UDF (#84), and `DECLARE`/`SET` (#16, #65). Covers most of Tier 1 in one file.
2. **`signet/sourcing/create_transaction.sql`** — adds the MERGE upsert (#12-13), the 20-branch banner CASE (#2), `SAFE_CAST` (#5), and `DROP TABLE IF EXISTS` (#62). Covers the rest of Tier 1.
3. **`pacsun/preprocessing/queries.json`** — the most concept-dense single file in the repo. Procedure (#78), `BEGIN ... END;` (#80), `FOR ... IN ... DO` (#64), `IF table_exists THEN INSERT ELSE CREATE OR REPLACE` (#60, #63), every window-frame variant (#41-42), every `COALESCE`/`SAFE_DIVIDE` flavour (#3, #20). One read here = ~70% of Tier 2.
4. **`sb/ingestion/mondaysmart_historic_clone_historic.sql`** — the small-and-clean dynamic-SQL example. `EXECUTE IMMEDIATE FORMAT(...)` (#77), `INFORMATION_SCHEMA.TABLES` loop (#89). 30 lines, full coverage of Tier 3 scripting.
5. **`signet/ingestion/oms_otb.sql`** — pivot-and-aggregate example. `PIVOT` (#85), nested aggregations, `LPAD`/`RIGHT`/`SUBSTRING` (#54-55), `HAVING` (#32). The "ingestion file shape" archetype.
6. **`signet/ingestion/oms_order_cycle.sql`** — JSON-parsing example. `PARSE_JSON` (#70), `JSON_VALUE` (#69), `LEAD()` (#40), `RIGHT JOIN` (#48), `INITCAP`. Useful for seeing how OMS policies are unpacked.

After steps 1-3 you'll recognise ~95% of the SQL surface area. Steps 4-6 cover the remaining 5%.

---

## What to skip

These either don't appear in the repo or are so rare it's not worth pre-loading them. If you hit one, look it up then.

- **Recursive CTEs** (`WITH RECURSIVE`) — 1 client (vs).
- **`NTH_VALUE`, `CUME_DIST`, `PERCENT_RANK`** — 0 clients.
- **Named windows** (`WINDOW w AS (...)`) — 0 clients.
- **`GROUPING SETS`, `ROLLUP`, `CUBE`** — 0 clients.
- **`APPROX_COUNT_DISTINCT`, `PERCENTILE_DISC`, `BIT_AND/OR/XOR`** — 0 clients.
- **`INTERSECT DISTINCT`** — 0 clients.
- **`IFERROR`, `IS DISTINCT FROM`** — 0 clients.
- **`RPAD`, `STARTS_WITH`, `ENDS_WITH`, `CONTAINS_SUBSTR`** — near-zero (one outlier each).
- **`GENERATE_TIMESTAMP_ARRAY`, `JSON_QUERY`** — 0 clients.
- **`TABLESAMPLE`, `_TABLE_SUFFIX`, wildcard tables** — 0 clients (the repo uses one table per feed, no `prefix_*` wildcards).
- **`IEEE_DIVIDE`, `IS_INF`** — 0 clients.
- **JS UDFs** (`LANGUAGE js`) — 0 clients (only SQL UDFs).
- **`ST_*` (geospatial)** — 0 clients.
- **`ELSEIF`, `WHILE ... DO`, `LOOP/END LOOP`, `BREAK`/`CONTINUE`, `BEGIN ... EXCEPTION`** — 0 clients (the only branching idioms are `IF ... THEN`, `IF ... THEN ... ELSE`, and `FOR ... IN ... DO`).
- **`CREATE TABLE ... LIKE`** — 0 clients (use `CREATE OR REPLACE TABLE ... AS SELECT * FROM ...` or `... CLONE ...` instead).
- **`UPDATE ... SET ... FROM`** — 1 client (scarpe). The MERGE pattern is preferred.

---

## Cross-references

- [`docs/ia_bq_patterns.md`](../docs/ia_bq_patterns.md) — the 11 IA-platform patterns (P1-P11) that the universal concepts map to (especially MERGE upsert, partition/cluster DDL, dedup recipe, SAFE_CAST, special-char UDF, banner CASE).
- [`.cursor/rules/lululemon-bq-context.mdc`](../.cursor/rules/lululemon-bq-context.mdc) Section 4 — the G1-G10 gotchas (Tier 4 here).
- [`findings/master_table_build_logic.md`](master_table_build_logic.md) — Lululemon's current master-build SQL, useful side-by-side reading once these concepts click.
- [`findings/lululemon_ingestion_end_to_end.md`](lululemon_ingestion_end_to_end.md) — the wider ingestion picture this SQL fits into.

---

## Appendix — frequency map (raw)

The full per-concept frequency output lives at `/tmp/iaconcepts/freq.txt` (regenerate with `/tmp/iaconcepts/scan.sh`). 162 concept probes; format is `label|files|clients|client_list|exemplars`. Top-level summary (clients-with-at-least-one-match):

| Tier | Count of concepts | Frequency band |
|---|---|---|
| Tier 1 — Universal | 38 | 30+/38 |
| Tier 2 — Common | 38 | 10-29/38 |
| Tier 3 — Selective | 38 | 2-9/38 |
| (Skipped) | 27 | 0-1/38 |

If a concept you expect isn't catalogued here, run:

```sh
grep -rliE --include='*.sql' --include='*.json' '<your regex>' \
  /Users/ejazanwarmd/Downloads/insideinsight-mtp-bigquery-3df90a9e5596 \
  | awk -F/ '{print $7}' | sort -u
```

(`$7` is the client-folder field for absolute paths starting with `/Users/ejazanwarmd/Downloads/...`.)
