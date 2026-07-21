# Transaction Master — SQL Queries

All 3 EDA phases for `transaction_master` (389.9M rows, 74 GB). **Always filter by `date`** or `channel` — this table is partitioned on date and clustered on channel.

See findings: [`transaction_master_eda.md`](../transaction_master_eda.md)

---

## Phase 1 — shape, nulls, outliers

??? example "`transaction_master_eda_phase1_consolidated.sql`"
    ```sql
    --8<-- "queries/transaction_master_eda_phase1_consolidated.sql"
    ```

---

## Phase 2 — zero-qty row concentration

106M rows (27%) have `qty=0`. This phase maps the concentration by channel / date / SKU.

??? example "`transaction_master_eda_phase2_zero_qty.sql`"
    ```sql
    --8<-- "queries/transaction_master_eda_phase2_zero_qty.sql"
    ```

---

## Phase 3 — cross-table integrity

Joins to `product_master` and `store_master` to find orphans and identify the 10 virtual / China ECOMM stores.

??? example "`transaction_master_eda_phase3_cross_table.sql`"
    ```sql
    --8<-- "queries/transaction_master_eda_phase3_cross_table.sql"
    ```
