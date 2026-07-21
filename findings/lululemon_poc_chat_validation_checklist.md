# Lululemon POC-Derived Validation Checklist

This checklist translates the POC chat issues into current-state validation checks. Run these before relying on refreshed transaction, inventory, product, pricing, forecast, sizing, or allocation outputs.

All queries below are read-only patterns. Replace date ranges and table variants with the current run context before execution.

## 1. Product Master And Hierarchy

### 1.1 Check product master coverage and active rows

Purpose: confirm current product master size, active share, and channel suffix mix before joining downstream tables.

```sql
SELECT
  active_flag,
  REGEXP_EXTRACT(product_code, r'_(ECOMM|RETAIL)$') AS channel_suffix,
  COUNT(*) AS row_count,
  COUNT(DISTINCT product_code) AS distinct_product_codes,
  COUNT(DISTINCT article_original) AS distinct_articles
FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
GROUP BY ALL
ORDER BY active_flag, channel_suffix;
```

Pass condition: no unexpected missing channel suffixes for in-scope products, and active row counts align with the current feed refresh.

### 1.2 Quantify multiple SKUs per article-size / PSS

Purpose: validate the POC decision to handle multiple SKUs at article-size or PSS grain.

```sql
WITH article_size AS (
  SELECT
    article_original,
    size,
    COUNT(DISTINCT product_code) AS sku_count
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE active_flag = 1
  GROUP BY ALL
)
SELECT
  COUNT(*) AS article_size_count,
  COUNTIF(sku_count > 1) AS article_size_with_multiple_skus,
  SAFE_DIVIDE(COUNTIF(sku_count > 1), COUNT(*)) AS pct_article_size_with_multiple_skus
FROM article_size;
```

Pass condition: multiple-SKU cases are quantified and accepted for the chosen sizing grain.

### 1.3 Planned sales PSO coverage against product master

Purpose: detect planned-sales style options not found in product master, a known POC issue.

```sql
WITH planned_sales_styles AS (
  SELECT DISTINCT STYLE_OPTION_ID
  FROM `lululemon-01042025.lululemon_souricng_outbound.planned_sales_20251119`
  WHERE WEEK_ID > 202501
),
product_styles AS (
  SELECT DISTINCT REPLACE(l8_id, '_RETAIL', '') AS STYLE_OPTION_ID
  FROM `lululemon-01042025.lululemon_souricng_outbound.product_master`
  WHERE active_flag = 1
)
SELECT
  COUNT(*) AS planned_sales_style_options,
  COUNTIF(p.STYLE_OPTION_ID IS NULL) AS missing_from_product_master,
  SAFE_DIVIDE(COUNTIF(p.STYLE_OPTION_ID IS NULL), COUNT(*)) AS pct_missing_from_product_master
FROM planned_sales_styles ps
LEFT JOIN product_styles p USING (STYLE_OPTION_ID);
```

Pass condition: missing styles are small enough to accept or have a documented client question.

## 2. Transaction Master

### 2.1 Weekly sales coverage by geography and channel

Purpose: catch refresh deltas like the POC's US retail reduction.

```sql
SELECT
  sm.s2_name,
  sm.channel,
  fd.fiscal_year_week,
  SUM(t.qty) AS gross_units,
  SUM(CASE WHEN t.qty > 0 THEN t.qty ELSE 0 END) AS positive_units,
  COUNT(*) AS transaction_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master` t
JOIN `lululemon-01042025.lululemon_souricng_outbound.fiscal_date_mapping` fd
  USING (date)
JOIN `lululemon-01042025.lululemon_souricng_outbound.store_master` sm
  USING (store_code)
WHERE t.date BETWEEN '2025-01-01' AND '2025-12-31'
  AND sm.s2_name IN ('United States', 'China', 'Canada')
  AND UPPER(sm.channel) IN ('RETAIL', 'ECOMM')
  AND COALESCE(sm.dc_flag, FALSE) = FALSE
GROUP BY ALL
ORDER BY sm.s2_name, sm.channel, fd.fiscal_year_week;
```

Pass condition: no unexplained step changes after feed refresh; any decline is documented with client confirmation.

### 2.2 Canonical transaction filter count

Purpose: quantify the share retained by the POC modeling filter.

```sql
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(
    qty > 0
    AND total_discount_amount >= 0
  ) AS rows_after_sales_filter,
  SAFE_DIVIDE(
    COUNTIF(qty > 0 AND total_discount_amount >= 0),
    COUNT(*)
  ) AS pct_rows_after_sales_filter
FROM `lululemon-01042025.lululemon_souricng_outbound.transaction_master`
WHERE date BETWEEN '2025-01-01' AND '2025-12-31';
```

Pass condition: retained share is understood and does not conflict with the intended actuals definition.

## 3. Inventory Master

### 3.1 Inventory date coverage

Purpose: catch partial-feed mistakes like t-20 instead of t-120.

```sql
SELECT
  MIN(date) AS min_date,
  MAX(date) AS max_date,
  COUNT(*) AS row_count,
  COUNT(DISTINCT store_code) AS distinct_stores,
  COUNT(DISTINCT product_code) AS distinct_products
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master`
WHERE date BETWEEN '2023-01-01' AND CURRENT_DATE();
```

Pass condition: min/max dates match the claimed delivered feed and the modeling period.

### 3.2 Weekly inventory trend by geography and channel

Purpose: detect 2x to 4x inventory inflation or unexplained post-refresh deltas.

```sql
SELECT
  sm.s2_name,
  sm.channel,
  fd.fiscal_year_week,
  SUM(CASE WHEN inv.oh >= 0 THEN inv.oh ELSE 0 END) AS on_hand_units,
  COUNT(*) AS inventory_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master` inv
JOIN `lululemon-01042025.lululemon_souricng_outbound.fiscal_date_mapping` fd
  USING (date)
JOIN `lululemon-01042025.lululemon_souricng_outbound.store_master` sm
  USING (store_code)
WHERE inv.date BETWEEN '2025-01-01' AND '2025-12-31'
  AND sm.s2_name IN ('United States', 'China', 'Canada')
  AND UPPER(sm.channel) IN ('RETAIL', 'ECOMM')
  AND COALESCE(sm.dc_flag, FALSE) = FALSE
GROUP BY ALL
ORDER BY sm.s2_name, sm.channel, fd.fiscal_year_week;
```

Pass condition: weekly pattern is explainable and not a duplicate-ingestion artifact.

### 3.3 Compare current inventory to backup

Purpose: reproduce the POC delta style when `inventory_master_old` is available.

```sql
WITH current_inv AS (
  SELECT
    fd.fiscal_year_week,
    sm.s2_name,
    sm.channel,
    SUM(CASE WHEN inv.oh >= 0 THEN inv.oh ELSE 0 END) AS current_oh
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master` inv
  JOIN `lululemon-01042025.lululemon_souricng_outbound.fiscal_date_mapping` fd USING (date)
  JOIN `lululemon-01042025.lululemon_souricng_outbound.store_master` sm USING (store_code)
  WHERE inv.date BETWEEN '2025-01-01' AND '2025-12-31'
  GROUP BY ALL
),
old_inv AS (
  SELECT
    fd.fiscal_year_week,
    sm.s2_name,
    sm.channel,
    SUM(CASE WHEN inv.oh >= 0 THEN inv.oh ELSE 0 END) AS old_oh
  FROM `lululemon-01042025.lululemon_souricng_outbound.inventory_master_old` inv
  JOIN `lululemon-01042025.lululemon_souricng_outbound.fiscal_date_mapping` fd USING (date)
  JOIN `lululemon-01042025.lululemon_souricng_outbound.store_master` sm USING (store_code)
  WHERE inv.date BETWEEN '2025-01-01' AND '2025-12-31'
  GROUP BY ALL
)
SELECT
  *,
  current_oh - old_oh AS delta_oh,
  SAFE_DIVIDE(current_oh - old_oh, old_oh) AS pct_delta_oh
FROM current_inv
JOIN old_inv USING (fiscal_year_week, s2_name, channel)
ORDER BY ABS(delta_oh) DESC;
```

Pass condition: high-delta weeks are understood and documented before downstream model runs.

## 4. Price Book And Discount Inputs

### 4.1 Price book MSRP outliers

Purpose: detect anomalies like MSRP 60,000 vs 59.

```sql
SELECT
  STYLE_OPTION_ID,
  LOC_ID,
  MIN(SAFE_CAST(ORIGINAL_PRICE AS FLOAT64)) AS min_original_price,
  MAX(SAFE_CAST(ORIGINAL_PRICE AS FLOAT64)) AS max_original_price,
  COUNT(*) AS price_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.price_book`
WHERE DATE(EFFECTIVE_TO_DAY_ID) >= '2024-10-14'
GROUP BY ALL
HAVING max_original_price > 1000
   OR SAFE_DIVIDE(max_original_price, NULLIF(min_original_price, 0)) > 10
ORDER BY max_original_price DESC;
```

Pass condition: all extreme prices are explained, capped, or excluded by the agreed logic.

### 4.2 Future discount table sanity

Purpose: validate final discount table grain, week range, and bounds.

```sql
SELECT
  MIN(fiscal_year_week) AS min_week,
  MAX(fiscal_year_week) AS max_week,
  MIN(final_discount_pct) AS min_discount_pct,
  MAX(final_discount_pct) AS max_discount_pct,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CONCAT(product_code, '|', store_code, '|', CAST(fiscal_year_week AS STRING))) AS distinct_product_store_weeks,
  COUNTIF(final_discount_pct < 0 OR final_discount_pct > 100) AS out_of_bounds_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.future_discount_selection_v2`;
```

Pass condition: one row per intended product-store-week-discount selection and no values outside 0 to 100.

### 4.3 Discount fallback mix

Purpose: understand how much of the table is true SKU/store history vs hierarchy fallback.

```sql
SELECT
  discount_selection_code,
  COUNT(*) AS row_count,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) AS pct_rows
FROM `lululemon-01042025.lululemon_souricng_outbound.future_discount_selection_v2`
GROUP BY ALL
ORDER BY row_count DESC;
```

Pass condition: fallback mix is acceptable for the forecast scenario.

## 5. Forecast And Simulation Outputs

### 5.1 IA vs Anaplan forecast comparison

Purpose: reproduce the POC comparison at aligned grain.

```sql
WITH anaplan_results AS (
  SELECT
    a.l5_code AS store_code,
    fd.fiscal_year_week,
    a.size_code,
    SUM(a.reg_demand_daily_forecast + a.discount_demand_daily_forecast) AS anaplan_forecast
  FROM `lululemon-01042025.lululemon_souricng_outbound.anaplan_demand_forecast_cleaned` a
  JOIN `lululemon-01042025.lululemon_souricng_outbound.fiscal_date_mapping` fd
    ON a.parsed_date = fd.date
  WHERE fd.fiscal_year_week BETWEEN 202538 AND 202601
  GROUP BY ALL
),
ia_results AS (
  SELECT
    CONCAT(pm.l8_id, '-', pm.size) AS size_code,
    sim.store_code,
    sim.fiscal_year_week,
    SUM(sim.ss_pred_qty) AS ia_forecast
  FROM `lululemon-01042025.lululemon_souricng_outbound.lululemon_sims_out` sim
  JOIN `lululemon-01042025.lululemon_souricng_outbound.product_master` pm
    USING (product_code)
  WHERE sim.fiscal_year_week BETWEEN 202538 AND 202601
  GROUP BY ALL
)
SELECT
  size_code,
  store_code,
  fiscal_year_week,
  anaplan_forecast,
  ia_forecast,
  ia_forecast - anaplan_forecast AS forecast_delta
FROM anaplan_results
JOIN ia_results USING (size_code, store_code, fiscal_year_week)
ORDER BY ABS(forecast_delta) DESC
LIMIT 100;
```

Pass condition: example selection for decks is based on aligned grain and not a join artifact.

### 5.2 Day-level forecast spike check

Purpose: identify whether daily spikes are caused by day split, price/MSRP, discount, or weekly forecast changes.

```sql
SELECT
  product_code,
  store_code,
  percent_off,
  date,
  ds_pred_qty
FROM `lululemon-01042025.lululemon_souricng_outbound.lululemon_sims_out_day_level_w_date`
WHERE product_code LIKE '152975195%'
  AND store_code = '0000050070'
  AND percent_off = 0.1
  AND date BETWEEN '2025-12-20' AND '2026-01-15'
ORDER BY date;
```

Pass condition: spikes are explainable by input price, weekly forecast, events, or day split assumptions.

## 6. LSI And External Context

### 6.1 LSI impact by week

Purpose: show sales with and without LSI around known decline weeks such as 202518.

```sql
SELECT
  fiscal_year_week,
  SUM(qty_without_returns) AS actual_units,
  SUM(qty_without_returns_imputed) AS lsi_units,
  SUM(qty_without_returns_imputed) - SUM(qty_without_returns) AS lsi_incremental_units,
  SAFE_DIVIDE(
    SUM(qty_without_returns_imputed) - SUM(qty_without_returns),
    SUM(qty_without_returns)
  ) AS pct_lsi_incremental_units
FROM `lululemon-01042025.lululemon_souricng_outbound.master_input_imputed`
WHERE date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY ALL
ORDER BY fiscal_year_week;
```

Pass condition: LSI explains part of the trend but is not used to hide feed defects.

### 6.2 Event source check

Purpose: capture whether client-provided events include localized events needed for modeling.

Known event labels from chat:

- `SEAWHEEZE`
- `AFLFNL`
- `GrandFinal`
- `OLYSUM24`
- `PARAOLYSUM24`
- `MLBCUP`
- `YOGADAY`

Pass condition: current event master or feature table contains the needed event dates for historical and future periods, or a client question is raised.

## Go / No-Go Summary

Before current forecast or sizing outputs are used in a client deck, confirm:

- Product hierarchy and planned-sales gaps are quantified.
- Transaction and inventory feeds have current coverage and no unexplained refresh deltas.
- Price book outliers and discount table bounds are checked.
- Forecast comparison uses aligned product-store-week-size grain.
- `master_input_imputed` is used for LSI unless a newer table is confirmed.
- Every accepted data caveat has a one-line client-facing explanation.
