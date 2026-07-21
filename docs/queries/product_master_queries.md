# Product Master — SQL Queries

All EDA phases for `product_master` (1.97M rows) plus the proposed clean view.

See findings: [`product_master_eda.md`](../product_master_eda.md)

---

## Phase 1 — initial

??? example "`product_master_eda_phase1.sql` — first pass, simplest"
    ```sql
    --8<-- "queries/product_master_eda_phase1.sql"
    ```

??? example "`product_master_eda_phase1_consolidated.sql` — full Phase-1 battery (16 queries stacked)"
    ```sql
    --8<-- "queries/product_master_eda_phase1_consolidated.sql"
    ```

---

## Phase 2 — duplicates, orphans, short-code SKUs

??? example "`product_master_eda_phase2_consolidated.sql`"
    ```sql
    --8<-- "queries/product_master_eda_phase2_consolidated.sql"
    ```

---

## Phase 3 — hierarchy integrity, gender derivation

??? example "`product_master_eda_phase3_consolidated.sql`"
    ```sql
    --8<-- "queries/product_master_eda_phase3_consolidated.sql"
    ```

??? example "`product_master_eda_phase3_diagnostic.sql` — targeted spot-checks"
    ```sql
    --8<-- "queries/product_master_eda_phase3_diagnostic.sql"
    ```

---

## Clean view (proposed)

See the dedicated page → [Product Master Clean View](product_master_clean_view.md)
