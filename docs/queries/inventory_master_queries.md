# Inventory Master — SQL Queries

Phase 1 EDA for `inventory_master` (7.2B rows, 650 GB). **Scoped to 2024** to keep cost under control.

See findings: [`inventory_master_eda.md`](../inventory_master_eda.md)

!!! warning "Cost"
    `inventory_snapshot_cleaned` raw = 3.3 TB. `inventory_master` = 650 GB. Always filter on `date` BETWEEN clauses.

---

## Phase 1

??? example "`inventory_master_eda_phase1_consolidated.sql`"
    ```sql
    --8<-- "queries/inventory_master_eda_phase1_consolidated.sql"
    ```
