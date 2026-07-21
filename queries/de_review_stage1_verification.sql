-- ============================================================================
-- Stage 1 WIP verification — DE review package
-- ----------------------------------------------------------------------------
-- Paired with: findings/de_review_stage1_wip.md
--
-- Purpose: Run these in BQ console BEFORE handing the review doc to Ritik, so
-- you have the numbers ready when he reads the questions. Each block is
-- self-contained and writes its result into a common JSON-shaped output so
-- results can be stacked into one paste-friendly CSV.
--
-- Cost estimates (dry-run before running if unsure):
--   Q1: ~11K rows scan (small — location_group_hierarchy only)
--   Q2a: ~1.2M rows (sku_details)
--   Q2b: same ~1.2M rows
--   Q3a: 390M rows group-by (sales_transactions) — ~3 GB, ~1 min
--   Q3b: ONLY RUN IF Q3a > 0. 390M × 7 cols group-by — ~8 GB, ~3 min
--   Q4a: two COUNTs on product_group_hierarchy — ~few GB
--   Q4b: two DISTINCT + FULL OUTER JOIN — ~few GB, ~1 min
--
-- Total if all run: ~15–20 GB scan. ~$0.10 at BQ on-demand rate.
-- ============================================================================

-- ============================================================================
-- Q1 — store_master.active polarity check
-- ============================================================================
-- Goal: Confirm whether LOC_CLOSED_IND = 1 means "closed" or "active".

WITH q1 AS (
  SELECT
    'Q1-polarity'           AS check_id,
    LOC_CLOSED_IND          AS loc_closed_ind,
    COUNT(*)                AS stores,
    COUNTIF(OPERATIONAL_CLOSE_DAY_ID IS NOT NULL)                          AS stores_with_close_date,
    COUNTIF(SAFE_CAST(OPERATIONAL_CLOSE_DAY_ID AS DATE) < CURRENT_DATE())  AS stores_closed_in_past,
    COUNTIF(SAFE_CAST(OPERATIONAL_OPEN_DAY_ID  AS DATE) < CURRENT_DATE()
        AND (OPERATIONAL_CLOSE_DAY_ID IS NULL
             OR SAFE_CAST(OPERATIONAL_CLOSE_DAY_ID AS DATE) > CURRENT_DATE())) AS looks_open_today
  FROM `lululemon-01042025.lululemon_souricng_outbound.location_group_hierarchy_cleaned_20251119`
  GROUP BY LOC_CLOSED_IND
)
SELECT * FROM q1 ORDER BY loc_closed_ind;

-- Expected interpretation:
--   row LOC_CLOSED_IND=1 dominated by stores_closed_in_past  -> 1 means "closed"  (master column polarity INVERTED)
--   row LOC_CLOSED_IND=1 dominated by looks_open_today       -> 1 means "active"  (master column CORRECT)


-- ============================================================================
-- Q2a — sku_details grain: is there >1 row per SKU? (AVG semantic check)
-- ============================================================================

WITH rows_per_sku AS (
  SELECT sku_id_code, COUNT(*) AS n
  FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned`
  GROUP BY sku_id_code
)
SELECT
  'Q2a-sku_details-grain' AS check_id,
  n                       AS rows_per_sku,
  COUNT(*)                AS n_skus,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_skus
FROM rows_per_sku
GROUP BY n
ORDER BY n;

-- Expected interpretation:
--   100% with n=1  -> AVG is a no-op, semantic is safe
--   tail of n>1    -> AVG is blending history; mis-semantic possible


-- ============================================================================
-- Q2b — selling_price fractional truncation check
-- ============================================================================

SELECT
  'Q2b-selling_price-cast' AS check_id,
  COUNT(*)                                                                                     AS total_rows,
  COUNTIF(selling_price IS NULL OR CAST(selling_price AS STRING) IN ('', '\\N'))               AS null_or_blank,
  COUNTIF(SAFE_CAST(selling_price AS FLOAT64) IS NOT NULL
          AND SAFE_CAST(selling_price AS FLOAT64) != TRUNC(SAFE_CAST(selling_price AS FLOAT64))) AS fractional_rows,
  MIN(SAFE_CAST(selling_price AS FLOAT64)) AS min_price,
  MAX(SAFE_CAST(selling_price AS FLOAT64)) AS max_price
FROM `lululemon-01042025.lululemon_souricng_outbound.sku_details_cleaned`;

-- Expected interpretation:
--   fractional_rows = 0  -> CAST AS INT is harmless
--   fractional_rows > 0  -> silent truncation; every fractional price has been zeroed on the decimal part


-- ============================================================================
-- Q3a — sales_transactions duplication check (cheap)
-- ============================================================================

WITH order_counts AS (
  SELECT SALES_ORDER_ID, COUNT(*) AS n
  FROM `lululemon-01042025.lululemon_souricng_outbound.sales_transactions_4y_cleaned_20251119`
  GROUP BY SALES_ORDER_ID
)
SELECT
  'Q3a-order_id-dupes'                             AS check_id,
  COUNT(*)                                         AS total_order_ids,
  COUNTIF(n > 1)                                   AS duplicated_order_ids,
  SUM(CASE WHEN n > 1 THEN n ELSE 0 END)           AS rows_in_duplicated_orders,
  SUM(CASE WHEN n > 1 THEN n - 1 ELSE 0 END)       AS excess_rows_from_dupes,
  MAX(n)                                           AS max_rows_for_any_order
FROM order_counts;

-- Expected interpretation:
--   duplicated_order_ids ≈ 0          -> DISTINCT is defensive dead code
--   duplicated_order_ids > 0          -> need to run Q3b to see if they're full-row dupes


-- ============================================================================
-- Q3b — ONLY RUN IF Q3a shows duplicates. Full-row dupe fingerprint.
-- ============================================================================
-- Uncomment to run — it's a heavier scan.
--
-- WITH fp AS (
--   SELECT
--     sku_id_channel, location_id_sales, DATE_TRANSACTION, SALES_ORDER_ID,
--     units, PRICE_SALES_UNIT, PRICE_SALES_TOTAL,
--     COUNT(*) AS cnt
--   FROM `lululemon-01042025.lululemon_souricng_outbound.sales_transactions_4y_cleaned_20251119`
--   GROUP BY 1,2,3,4,5,6,7
--   HAVING COUNT(*) > 1
-- )
-- SELECT
--   'Q3b-full_row_dupes' AS check_id,
--   COUNT(*)             AS full_row_dupe_groups,
--   SUM(cnt - 1)         AS redundant_rows_removed_by_distinct,
--   SUM(cnt)             AS total_rows_in_dupe_groups
-- FROM fp;
--
-- Expected interpretation:
--   redundant_rows ≈ Q3a.excess_rows -> source is genuinely duplicated on every column; DISTINCT is justified (but fix upstream)
--   redundant_rows « Q3a.excess_rows -> rows differ on columns not in the fingerprint; DISTINCT wastes compute; grain is finer than documented


-- ============================================================================
-- Q4a — product_group_hierarchy live vs _20251119: METADATA comparison
-- ----------------------------------------------------------------------------
-- Uses __TABLES__ metadata so no column names are required. If the two tables
-- have identical row_count + size_bytes + last_modified_time, they are either
-- the same physical table (view/alias) or byte-for-byte copies. If they
-- differ, move on to Q4b for a column + content comparison.
-- ============================================================================

SELECT
  'Q4a-metadata' AS check_id,
  table_id,
  row_count,
  ROUND(size_bytes / POW(1024, 3), 2)                     AS size_gb,
  FORMAT_TIMESTAMP('%F %T', TIMESTAMP_MILLIS(creation_time))       AS created_at,
  FORMAT_TIMESTAMP('%F %T', TIMESTAMP_MILLIS(last_modified_time))  AS last_modified_at,
  CASE type WHEN 1 THEN 'TABLE' WHEN 2 THEN 'VIEW' WHEN 4 THEN 'EXTERNAL' ELSE CAST(type AS STRING) END AS kind
FROM `lululemon-01042025.lululemon_souricng_outbound.__TABLES__`
WHERE table_id IN (
  'product_group_hierarchy_cleaned',
  'product_group_hierarchy_cleaned_20251119'
)
ORDER BY table_id;

-- Expected interpretation:
--   row_count, size_gb, last_modified_at all identical -> same table (view or dup). Close S1.6 as Done.
--   any divergence                                     -> real drift; run Q4b.


-- ============================================================================
-- Q4b — schema comparison: which columns does each variant have?
-- ----------------------------------------------------------------------------
-- Note: the inventory_master build DDL joins product_group_hierarchy_cleaned
-- on sku_id_channel, but that column may not exist under that exact name —
-- hence this check. Also answers: what's the canonical join key we should use
-- if we need to diff contents.
-- ============================================================================

WITH live_cols AS (
  SELECT column_name, data_type
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'product_group_hierarchy_cleaned'
),
snap_cols AS (
  SELECT column_name, data_type
  FROM `lululemon-01042025.lululemon_souricng_outbound.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'product_group_hierarchy_cleaned_20251119'
)
SELECT
  'Q4b-schema-diff' AS check_id,
  COALESCE(l.column_name, s.column_name) AS column_name,
  l.data_type                             AS live_type,
  s.data_type                             AS snapshot_type,
  CASE
    WHEN l.column_name IS NULL                      THEN 'ONLY IN _20251119'
    WHEN s.column_name IS NULL                      THEN 'ONLY IN live'
    WHEN l.data_type != s.data_type                 THEN 'TYPE MISMATCH'
    ELSE 'match'
  END AS status
FROM live_cols l
FULL OUTER JOIN snap_cols s USING (column_name)
ORDER BY
  CASE
    WHEN l.column_name IS NULL OR s.column_name IS NULL THEN 0
    WHEN l.data_type != s.data_type                     THEN 1
    ELSE 2
  END,
  column_name;

-- Expected interpretation:
--   all rows status='match'           -> identical schema; any column works as the content-diff key
--   rows with 'ONLY IN *' or mismatch -> real schema drift; pick a column present in both (commonly a product/SKU id) for Q4c


-- ============================================================================
-- Q4c — content diff on a column confirmed to exist in both (optional)
-- ----------------------------------------------------------------------------
-- Run only if Q4a showed metadata differences AND Q4b gave you a column name
-- present in BOTH tables. Replace <JOIN_KEY> below with that column.
-- ============================================================================
/*
WITH a AS (
  SELECT DISTINCT <JOIN_KEY> AS k
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned`
),
b AS (
  SELECT DISTINCT <JOIN_KEY> AS k
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_group_hierarchy_cleaned_20251119`
)
SELECT
  'Q4c-content-diff'                                    AS check_id,
  COUNTIF(a.k IS NOT NULL AND b.k IS NULL)              AS in_live_only,
  COUNTIF(a.k IS NULL     AND b.k IS NOT NULL)          AS in_snapshot_only,
  COUNTIF(a.k IS NOT NULL AND b.k IS NOT NULL)          AS in_both
FROM a FULL OUTER JOIN b USING (k);
*/
