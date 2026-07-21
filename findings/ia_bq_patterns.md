# IA BQ Patterns — the canonical recipes Lululemon must follow

> **Source of truth**: the production Signet repo, stashed read-only at
> `reference_docs/Signet Reference/{sourcing,ingestion}/`.
> Every pattern below is anchored to a specific file/line in that repo so it
> stays auditable when Signet's code evolves.
>
> **Why this file exists**: Lululemon ingestion is being set up *following*
> Signet, not invented from scratch. Until our own DAGs and SQL are in steady
> state, this doc is the reference card we check against whenever we write
> raw-loads, master-builds, or KPI tables.

---

## 1. Two SQL files per intermediate: regular + `_historic`

Every feed in Signet's `sourcing/` ships as **two near-identical files**:

| File | Run when | Behaviour |
|---|---|---|
| `create_<feed>.sql` | Steady-state weekly | Window-bounded rebuild + `MERGE` into the live table |
| `create_<feed>_historic.sql` | One-shot backfill | Full rebuild over the entire historic window |

**Anchor**: `reference_docs/Signet Reference/sourcing/create_product.sql`
vs `create_product_historic.sql` — same CTE shape, the historic adds extra
backfill columns (e.g. `Manufacture_Country`) and slightly different banner
mappings.

**Lululemon to-do**: every `findings/master_table_build_logic.md` entry
needs to be split into `<master>_weekly.sql` + `<master>_historic.sql` files
under `queries/master_build/` once we move out of EDA mode.

---

## 2. Steady-state writes use temp-table + `MERGE` upsert + `DROP TEMP`

Signet's weekly DAG never `CREATE OR REPLACE`s the live table. The pattern is:

```sql
-- 1. Build a fresh temp from the latest window
CREATE OR REPLACE TABLE `<dataset>.<feed>_intermediate_temp` AS
WITH /* big CTE chain */
SELECT ...;

-- 2. MERGE temp into the live intermediate, only inside the rolling window
MERGE `<dataset>.<feed>_intermediate` DL
USING (SELECT * FROM `<dataset>.<feed>_intermediate_temp`) V
ON (DATE(DL.SYNCSTARTDATETIME)
      BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE())
   AND DL.TRANS_ID = V.TRANS_ID AND DL.LINE_ID = V.LINE_ID
   AND DL.SKU = V.SKU AND DL.TRANS_DATE = V.TRANS_DATE
WHEN MATCHED THEN UPDATE SET DL.SKU = V.SKU, ...
WHEN NOT MATCHED THEN INSERT (...) VALUES (...);

-- 3. Cleanup
DROP TABLE IF EXISTS `<dataset>.<feed>_intermediate_temp`;
```

**Anchor**: `reference_docs/Signet Reference/sourcing/create_transaction.sql`
lines 472–481.

**Why it matters**: makes the weekly DAG **idempotent and safe to re-run**
without dropping the historic tail. The 90-day window is a deliberate
"rolling correction zone" — older rows are never updated.

**Lululemon to-do**: our master-build SQL is currently `CREATE OR REPLACE`
(see `findings/master_table_build_logic.md`). That's fine for EDA but must
flip to the temp-merge pattern before we register a weekly DAG.

---

## 3. Date-window driver = a `mapping` table inside the dataset

Signet does not hard-code dates in DAGs. Each weekly SQL reads its window
from a config table:

```sql
DECLARE filter_param DATETIME;
SET filter_param = (
  SELECT filter_param
  FROM `data-ingestion-342714.signet_sourcing_prod.mapping`
  WHERE intermediate_table = 'transaction_intermediate'
);
```

**Anchor**: `reference_docs/Signet Reference/sourcing/create_transaction.sql`
lines 1–6.

**Implication**: there is a single `mapping` table in `signet_sourcing_prod`
keyed by `intermediate_table` that the platform/Self-Help UI bumps each run.

**Lululemon to-do**: stand up `lulu_ingestion_dev.mapping` with one row per
master table. Sri Harsha question: who writes to it — Self-Help UI form,
Airflow callback, or manual?

---

## 4. Physical layout: `PARTITION BY DATE` + `CLUSTER BY` high-card columns

Every Signet `*_intermediate` table is partitioned and clustered:

```sql
CREATE OR REPLACE TABLE `<dataset>.product_intermediate`
PARTITION BY DATE(SYNCSTARTDATETIME)
CLUSTER BY Sub_SKU_Division, Planning_Ownership
AS ...;
```

**Anchor**: `reference_docs/Signet Reference/sourcing/create_product.sql`
line 5 (and again at line 412).

**Cluster keys are chosen for the most common downstream filter**, not just
"highest cardinality" — Signet clusters on division because every alert /
KPI query filters by banner.

**Lululemon mapping**:

| Master table | Partition key (proposed) | Cluster keys (proposed) |
|---|---|---|
| `product_master` | `DATE(SYNCSTARTDATETIME)` | `l1_name` (RETAIL/ECOMM), `l3_id` |
| `transaction_master` | `DATE(transaction_date)` | `l1_name`, `store_id` |
| `inventory_master` | `DATE(inventory_date)` | `l1_name`, `store_id` |
| `store_master` | _(unpartitioned, low row count)_ | `l1_name` |
| `events_master` | `DATE(event_start_date)` | `event_type` |
| `calendar_hierarchy` | _(unpartitioned)_ | `fiscal_year` |

These are proposals — confirm against actual query patterns before locking.

---

## 5. `SYNCSTARTDATETIME` is the universal load-lineage column

Every raw `ia_*` table and every `*_intermediate` table carries
`SYNCSTARTDATETIME`. It's used for:

- Dedup tie-breaking — `ROW_NUMBER() OVER (PARTITION BY <pk> ORDER BY SYNCSTARTDATETIME DESC)`
- Partition key — `PARTITION BY DATE(SYNCSTARTDATETIME)`
- Window filtering in MERGE upserts (Pattern 2)

**Anchor**: appears in every file in `reference_docs/Signet Reference/sourcing/`.

**Lululemon to-do**: today our raw tables use `_20251119` *as a suffix on the
table name*, not as a column. Decide before going to weekly cadence whether
to (a) emit a `load_dt` column on every raw load and follow Signet's pattern,
or (b) keep table-suffix versioning. **Strong recommendation: switch to the
column convention** — it's what every downstream IA tool expects.

---

## 6. Dedup recipe: `ROW_NUMBER` on natural key, ordered by load time

This is the *exact* CTE Signet uses to collapse multiple loads of the same
row to the latest one — copy verbatim:

```sql
prod_cleaned AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT DISTINCT *,
           ROW_NUMBER() OVER (
             PARTITION BY Sub_SKU
             ORDER BY SYNCSTARTDATETIME DESC
           ) AS rn
    FROM raw
  )
  WHERE rn = 1
)
```

**Anchor**: `reference_docs/Signet Reference/sourcing/create_product.sql`
lines 10–19.

The same recipe appears for stores (`PARTITION BY _store_number_`),
transactions (`PARTITION BY TRANS_ID, LINE_ID, SKU, TRANS_DATE`), inventory,
etc. — **the natural key changes, the recipe doesn't**.

---

## 7. Always `SAFE_CAST` numerics from raw

Signet treats all raw numeric strings as untrusted:

```sql
SAFE_CAST(QTY_SOLD            AS FLOAT64) AS QTY_SOLD,
SAFE_CAST(RETAIL_UNIT_PRICE   AS FLOAT64) AS RETAIL_UNIT_PRICE,
SAFE_CAST(TOTAL_DISCOUNT_AMT  AS FLOAT64) AS TOTAL_DISCOUNT_AMT,
SAFE_CAST(NET_SELLING_PRICE   AS FLOAT64) AS NET_SELLING_PRICE,
SAFE_CAST(COST                AS FLOAT64) AS COST,
```

**Anchor**: `reference_docs/Signet Reference/sourcing/create_transaction.sql`
lines 94–107.

**Why `SAFE_CAST` and not `CAST`**: NULL-on-failure instead of pipeline-kill.
Bad rows surface in QC dashboards, not in pager alerts.

**Lululemon**: we already document this in `.cursor/rules/lululemon-bq-context.mdc`.
This pattern *officially* aligns with platform standard.

---

## 8. Special-character escape via `__ia_char_NN` codes

Signet wraps every text column written to the tool through this UDF:

```sql
CREATE TEMP FUNCTION ReplaceSpecialCharacters(x string) RETURNS string AS (
  REPLACE(REPLACE(REPLACE(/* ...30+ replaces... */
    x,
    "'",  '__ia_char_01'),
    '"',  '__ia_char_02'),
    '/',  '__ia_char_03'),
    -- ... etc through __ia_char_32
);
```

**Anchor**: `reference_docs/Signet Reference/sourcing/create_product.sql`
line 410.

**Why**: the IA tool's PostgreSQL layer / URL routing chokes on certain
characters; the encoding is reversed at display time on the front-end.

**Lululemon to-do**: *do not* try to clean these up at master-build time
yourself — apply this UDF on every `STRING` column that's surfaced to the
user. Examples: `product_description`, `color_description`, `season_code`,
`design_line`, `planning_product_grouping`. The encoded characters look
ugly in BQ but are required by the downstream tool.

---

## 9. Banner / channel resolution lives in a giant CASE block

Signet doesn't ship banner/channel as a raw column — it's *derived* in SQL
from `CORP_DIV_NO + STORE_NUMBER + LOCATION_TYPE`:

```sql
CASE
  WHEN CORP_DIV_NO = '60'  AND LOCATION_TYPE = 'S' THEN 'PEOPLES'
  WHEN CORP_DIV_NO = '20'  AND STORE_NUMBER NOT IN ('A.2000','A.2033') THEN 'KAY'
  WHEN CORP_DIV_NO = '20'  AND STORE_NUMBER IN ('A.2000','A.2033')     THEN 'KAY.COM'
  /* ...20 more cases... */
END AS CHANNEL
```

**Anchor**: `reference_docs/Signet Reference/sourcing/create_transaction.sql`
lines 156–179.

**Implication for Lululemon**: our `l1_name` (`RETAIL` / `ECOMM`) is the
analogous derived banner column. If/when more channels appear (warehouse,
outlet, employee store), expect to grow a similar CASE block. **Don't push
this back to the client** — IA owns the banner taxonomy.

---

## 10. Notifications via HTTPS POST to `core-backend` Cloud Run

Pipeline completion emails are not sent by Airflow's built-in operator —
they're a templated JSON payload posted to an internal Cloud Run service:

```json
{
  "url": "https://core-backend-test-kzchvqggcq-uc.a.run.app/api/v2/notifications/send_email",
  "payload": {
    "emails": [{
      "subject":    "Signet prod - Update",
      "body":       "Pipeline name - Signet prod <br /> Status - DB sync done <br />",
      "recipients": ["manoj.solanki@impactanalytics.co", "..."]
    }]
  }
}
```

**Anchor**: `reference_docs/Signet Reference/ingestion/completion_mail.json`.

**Lululemon to-do**: register a `lululemon_completion_mail.json` (and the
historic variant) with our project-specific recipient list. **Sri Harsha
question**: is the Cloud Run service shared across clients (multitenant) or
client-scoped, and where is the registration form?

---

## 11. Project / dataset / table naming convention

| Layer | Signet | Lululemon today | Notes |
|---|---|---|---|
| GCP project | `data-ingestion-342714` | `ia-impactanalytics-1517919132` | Different projects per client |
| Raw dataset | `signet_sourcing_prod` | `lululemon_souricng_outbound` | **Note typo `souricng` is ours, not platform standard** — flag for cleanup |
| Raw table | `ia_product`, `ia_transaction`, `ia_inv` | `sku_details_cleaned_<date>`, `sales_transactions_4y_cleaned_<date>` | Lululemon today uses date-suffixed tables; Signet uses single-name tables with `SYNCSTARTDATETIME` (see Pattern 5) |
| Master table | `product_intermediate`, `transaction_intermediate` | `product_master`, `transaction_master` | Naming differs but role is identical |
| Master dataset | `signet_sourcing_prod` (same as raw) | `lulu_ingestion_dev` (separate) | Lululemon separates raw and master datasets — *cleaner*, keep this |

**The two real cleanup items**:

1. Fix the `souricng` typo before it bakes into 100 downstream queries.
2. Decide on raw-table naming — date-suffixed (Lululemon today) vs.
   `ia_<feed>` + load-time column (Signet). Pattern 5 says switch.

---

## How to use this doc

- When writing **new master-build SQL** for Lululemon, check it against
  patterns 2, 4, 5, 6, 7.
- When writing **new tool-facing columns**, check against pattern 8.
- When designing **the weekly DAG**, check against patterns 1, 2, 3, 10.
- When asking Sri Harsha about platform internals, the **gaps** in this doc
  are the questions:
  - Pattern 3 — who writes to `mapping`?
  - Pattern 10 — multitenant Cloud Run or per-client?
  - The unwritten patterns: Airflow DAG location, schema JSON location,
    GCS → BQ raw load mechanism, BQ → PG injection mechanism.

---

## Appendix — feed mapping Signet ↔ Lululemon

| # | Signet feed | Lululemon equivalent | Status |
|---|---|---|---|
| 1 | `product` | `sku_details_cleaned` + `product_attribute_s` + `product_group_hierarchy_cleaned` | **Lululemon splits 1:3** |
| 2 | `transaction` | `sales_transactions_4y_cleaned` | 1:1 |
| 3 | `inventory` | `inventory_snapshot_cleaned` | 1:1 |
| 4 | `store` | `store_master` + `location_group_hierarchy_cleaned` + `location_details_cleaned` | **Lululemon splits 1:3** |
| 5 | `ecom` | _(none)_ | Lululemon uses `l1_name` flag inside transactions |
| 6 | `mfp` | _(none yet)_ | Merch Financial Plan — out of current scope |
| 7 | `po` | _(none yet)_ | Purchase Orders — out of current scope |
| 8 | `receipt` | _(none yet)_ | Goods receipt — out of current scope |
| 9 | `productmindate` | _(none)_ | Signet-specific helper |
| 10 | `transaction_ada` | _(none)_ | Signet ADA channel — N/A |

**Net delta**: Lululemon uses **6 raw feeds Signet doesn't split** (the 1:3
splits on product and store) and is **missing 4 feeds** (ecom, mfp, po,
receipt). Of those, only `ecom` matters short-term — confirm with the
client whether ecom transactions are pre-merged or need a separate feed.
