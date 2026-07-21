# Product Master — Clean View

Proposed reusable view that resolves the observed quality issues in `product_master`:

- Parses `color_family` from `color_description` (instead of the hardcoded NULL stub)
- Derives `gender` from `l5_name` (99.96% coverage vs 27% in raw)
- Flags placeholder / short-code SKUs
- Normalises `size_scale` codes
- Surfaces the `ivivva` deprecated-brand flag

---

## View DDL

??? example "`product_master_clean_view.sql`"
    ```sql
    --8<-- "queries/product_master_clean_view.sql"
    ```

---

## Validation query

Validates the clean view output matches expected row counts and that all derivations are populated.

??? example "`product_master_clean_validation.sql`"
    ```sql
    --8<-- "queries/product_master_clean_validation.sql"
    ```
