# Schema &amp; Inventory Queries

Dataset-wide reference queries — listing tables, dumping schemas, sampling rows.

---

## `list_all_tables.sql`

Row counts + sizes for every table in the `lululemon_souricng_outbound` dataset. The starting point for `findings/dataset_inventory.md`.

??? example "View SQL"
    ```sql
    --8<-- "queries/list_all_tables.sql"
    ```

---

## `schema_dump_all_canonical.sql`

INFORMATION_SCHEMA.COLUMNS dump for the 26 canonical tables. Feeds `findings/schema_inventory.md`.

??? example "View SQL"
    ```sql
    --8<-- "queries/schema_dump_all_canonical.sql"
    ```

---

## `sample_rows_all_canonical.sql`

One random row per canonical table via `ORDER BY RAND()`. Avoids the natural-order bias of `LIMIT 1` on partitioned tables.

??? example "View SQL"
    ```sql
    --8<-- "queries/sample_rows_all_canonical.sql"
    ```
