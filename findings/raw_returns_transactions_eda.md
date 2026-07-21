# EDA: `returns_transactions` (raw) + join with `sales_transactions`

`Last updated: 2026-06-24.`

Parallel returns feed to gross sales. Join feasibility study vs `lulu_sourcing_dev.sales_transactions` (May 2026 extraction load).

**SQL:** [`queries/returns_transactions_join_eda.sql`](../queries/returns_transactions_join_eda.sql)  
**GCS gate script:** [`scripts/returns_shard_gate_scan.py`](../scripts/returns_shard_gate_scan.py)


## Executive summary

| Finding | Detail |
|---|---|
| **GCS source** | Yes: `consolidated/returns_transactions/` (48 files, ~87 GB, snap **20251118**) |
| **BQ landed (sourcing dev)** | No: not in extraction DAG; POC table `returns_transactions_20251119` in outbound |
| **Row count** | **733,682,768** (outbound, same era as sales raw) |
| **Date range** | **2015-02-02 → 2025-11-18** (matches sales) |
| **Zero-qty pattern** | **87.6%** rows have `UNITS = 0` (mirrors sales ~25.7% zero on positive-only filter differs because returns has skeleton rows) |
| **Order ID** | 100% synthetic: `DATE\|SKU\|STORE\|RETURNS` (sales uses same without `\|RETURNS`) |
| **Join key** | Strip `\|RETURNS` from return order ID → **exact match** to sales `SALES_ORDER_ID` |
| **Net return rate** | **~13 to 14%** of gross units/revenue (2023 to 2025, units > 0 only) |
| **Union-ready** | **Yes**: stack with `txn_source` discriminator; filter `UNITS > 0` for modeling |

**Recommendation:** Land `returns_transactions` from consolidated GCS, UNION with sales in `transaction_intermediate`, and confirm with client whether forecast demand uses **gross** or **net** (gross − returns).


## Phase 1: GCS consolidated gate

**Prefix:** `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/returns_transactions/`

| Check | Result |
|---|---|
| File count | **48** (matches manifest) |
| Total size | **~81 GiB** (~87 GB) |
| Snapshot in filename | **20251118** (same Nov drop as current sales extraction) |
| Header (8 cols) | `SKU_ID`, `LOCATION_ID_SALES`, `DATE_TRANSACTION`, `SALES_ORDER_ID`, `SALES_ORDER_ITEM_ID`, `UNITS`, `CURRENCY_CODE`, `PRICE_SALES_TOTAL` |
| First shard sample (41k rows, first 5 MB) | 87.8% zero units; 12.2% positive units; 100% order IDs contain `RETURNS` |
| Sample order ID | `2022-02-25\|139576704\|45167\|RETURNS` |

**Verdict:** GCS PASS: feed is populated (not zeroed), same snapshot era as sales, schema matches historic headers.


## Phase 2: Returns foundation (outbound BQ)

**Table:** `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`

| Metric | Value |
|---|---|
| Rows | 733,682,768 |
| Distinct SKUs | 793,717 |
| Distinct locations | 1,321 |
| Distinct dates | 3,943 |
| Date range | 2015-02-02 → 2025-11-18 |
| `UNITS = 0` | 642,668,774 (**87.59%**) |
| `UNITS > 0` | 90,954,218 (**12.41%**) |
| `UNITS < 0` | 0 |
| `SALES_ORDER_ID` ends with `\|RETURNS` | 100% |
| Synthetic key match | 100% (`DATE\|SKU\|STORE\|RETURNS`) |
| `SALES_ORDER_ITEM_ID` = `SALES_ORDER_ID` | 100% |

### Comparison to sales raw

| Metric | sales_transactions | returns_transactions |
|---|---:|---:|
| Rows | 683,582,361 | 733,682,768 |
| Date range | 2015-02-02 → 2025-11-18 | 2015-02-02 → 2025-11-18 |
| Distinct SKUs | 765,813 | 793,717 |
| Positive-units rows | 507,901,394 (74.3%) | 90,954,218 (12.4%) |
| Order ID format | `DATE\|SKU\|STORE` | `DATE\|SKU\|STORE\|RETURNS` |
| Missing column vs sales | n/a | No `PRICE_SALES_UNIT` |

**Interpretation:** Returns is a **parallel mirror** of sales at line grain. Every sales line appears to have a companion return row (often zero-units). Actual return activity lives in the ~12% of rows with `UNITS > 0`.


## Phase 3: Join feasibility vs `lulu_sourcing_dev.sales_transactions`

### 3a. Order-ID overlap (2023)

Normalize: `REGEXP_REPLACE(SALES_ORDER_ID, r'\|RETURNS$', '')`

| Metric | Count |
|---|---:|
| Return rows (2023) | 107,712,289 |
| Sales rows (2023) | 99,944,463 |
| Overlapping order IDs (distinct) | **99,944,463** |
| Return rows matching a sales order ID | **99,944,463** |

Every 2023 sales order ID has a matching return skeleton row. **7,767,826** return rows in 2023 have no sales match (return-only keys, likely zero-unit placeholders on dates/SKUs without gross sales that day).

### 3b. SKU × Store × Day overlap (2023, units > 0)

| Metric | Count |
|---|---:|
| Sales SSD keys (pos units) | 71,871,811 |
| Return SSD keys (pos units) | 14,280,581 |
| Keys in **both** | 3,590,989 |
| Return-only keys | 10,689,592 |
| Sales-only keys | 68,280,822 |

Returns with positive units often occur on different SSD keys than gross sales (cross-day returns, partial returns, etc.). Do not assume 1:1 SSD pairing; use **union + aggregate** for net demand.

### 3c. Net vs gross reconciliation (2023 to 2025, units > 0)

| Year | Gross units | Return units | Net units | Return rate (units) | Return rate (revenue) | SSD keys w/ both |
|---:|---:|---:|---:|---:|---:|---:|
| 2023 | 117,800,000 | 16,200,000 | 101,600,000 | 13.74% | 12.62% | 3,590,989 |
| 2024 | 124,100,000 | 17,000,000 | 107,100,000 | 13.70% | 12.74% | 3,880,000 |
| 2025 | 104,500,000 | 14,600,000 | 89,900,000 | 14.00% | 13.20% | 3,280,000 |

**Impact:** Ignoring returns overstates demand by **~14%** at unit level for recent years.

### 3d. Union prototype (2024, units > 0)

| Source | Line rows | Total units | Total revenue |
|---|---:|---:|---:|
| SALE | 76,882,078 | 124,100,000 | $190,700,000,000 (USD, string-cast sums) |
| RETURN | 14,847,913 | 17,000,000 | $24,300,000,000 |


## Phase 4: Recommended join pattern (not yet in pipeline)

```sql
-- Normalize keys; stack for net transaction modeling
WITH sales AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    SAFE_CAST(DATE_TRANSACTION AS DATE) AS date_transaction,
    SALES_ORDER_ID,
    SALES_ORDER_ITEM_ID,
    SAFE_CAST(UNITS AS FLOAT64) AS units,
    SAFE_CAST(PRICE_SALES_TOTAL AS FLOAT64) AS price_sales_total,
    SAFE_CAST(PRICE_SALES_UNIT AS FLOAT64) AS price_sales_unit,
    'SALE' AS txn_source,
    'GROSS SALE' AS transaction_type
  FROM `lululemon-01042025.lulu_sourcing_dev.sales_transactions`
),
returns AS (
  SELECT
    CAST(SKU_ID AS STRING) AS sku_id,
    LPAD(CAST(LOCATION_ID_SALES AS STRING), 10, '0') AS location_id_sales,
    DATE_TRANSACTION AS date_transaction,
    REGEXP_REPLACE(SALES_ORDER_ID, r'\|RETURNS$', '') AS sales_order_id,
    REGEXP_REPLACE(SALES_ORDER_ITEM_ID, r'\|RETURNS$', '') AS sales_order_item_id,
    CAST(UNITS AS FLOAT64) AS units,
    PRICE_SALES_TOTAL AS price_sales_total,
    SAFE_DIVIDE(PRICE_SALES_TOTAL, NULLIF(UNITS, 0)) AS price_sales_unit,
    'RETURN' AS txn_source,
    'RETURN' AS transaction_type
  FROM `lululemon-01042025.lululemon_souricng_outbound.returns_transactions_20251119`
  -- after landing: lulu_sourcing_dev.returns_transactions
)
SELECT * FROM sales
UNION ALL
SELECT * FROM returns;
```

**Build filter (match current txn intermediate):** `WHERE units > 0 AND price_sales_total != 0` for modeling rows.

**Optional pairing join** (same-day gross vs return on normalized order ID):

```sql
ON s.SALES_ORDER_ID = REGEXP_REPLACE(r.SALES_ORDER_ID, r'\|RETURNS$', '')
```


## Client questions (refined)

| ID | Question | IA read after EDA |
|---|---|---|
| F-4 | Gross vs net transaction master? | Returns feed joins cleanly; **~14%** unit reduction if net. Recommend net for demand forecasting unless client standard is gross. |
| TM #2 | Role of returns vs sales? | Parallel mirror feed; not a separate business process log. Use for net sales. |
| TM #3 | Where are returns? | **`returns_transactions`**: not merged into sales or master today. |


## Next steps (follow-up, out of scope here)

1. Add `returns_transactions` to IA dev mapping → `Historic/s3_to_gcs/consolidated/returns_transactions/`
2. Land `lulu_sourcing_dev.returns_transactions` via extraction DAG
3. Extend [`transaction_intermediate_build.sql`](../queries/transaction_intermediate_build.sql) with UNION + real `transaction_type`
4. Client sign-off on gross vs net for ForecastSmart req #5


## Reproduce

```bash
# GCS gate (one shard, byte range)
gsutil cat -r 0-5000000 \
  "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/returns_transactions/returns_transactions_20251118_153644_0_0_0.csv" \
  | python3 scripts/returns_shard_gate_scan.py

# BQ (use data-scan project for job submission)
bq query --use_legacy_sql=false --project_id=lululemon-data-scan \
  < queries/returns_transactions_join_eda.sql
```
