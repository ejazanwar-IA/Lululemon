# DE Review — Stage 1 WIP Verification Queries

Paired SQL for the [DE Review Package (Stage 1 WIP)](../de_review_stage1_wip.md). Run these in BQ Console before handing the review doc to Ritik — the numbers from each block slot directly into the "closure criteria" of each question.

!!! tip "Estimated total scan"
    ~15–20 GB on-demand if all 6 blocks run (≈ \$0.10). Q3b is optional and gated by Q3a's output.

## Block index

| Block | Purpose | Related checklist item |
|---|---|---|
| Q1 | `store_master.active` polarity on `LOC_CLOSED_IND` | S1.2 |
| Q2a | `sku_details_cleaned` grain (1 row/SKU or more?) | S1.4 |
| Q2b | `selling_price` fractional truncation check | S1.4 |
| Q3a | `sales_transactions` duplicate-order-id check (cheap) | S1.5 |
| Q3b | Full-row duplicate fingerprint (**only if Q3a > 0**) | S1.5 |
| Q4a | `product_group_hierarchy_cleaned` live vs `_20251119` size diff | S1.6 |
| Q4b | Symmetric SKU diff between the two variants | S1.6 |

## Full SQL

??? example "View / copy the full script"
    ```sql
    --8<-- "queries/de_review_stage1_verification.sql"
    ```

## How to use

1. Paste the full SQL into a BQ Console tab.
2. Run blocks Q1, Q2a, Q2b, Q3a, Q4a, Q4b one at a time (highlight the block; Cmd+Enter).
3. Only run Q3b if Q3a shows duplicated order IDs.
4. Copy each result row into the corresponding **Evidence collected** cell below, then send the review doc to Ritik with the numbers already filled in.

## Evidence collection template

| Block | Result (fill in after running) |
|---|---|
| Q1 | `LOC_CLOSED_IND=0 → stores=..., closed_in_past=..., looks_open_today=...` &nbsp;/&nbsp; `LOC_CLOSED_IND=1 → stores=..., closed_in_past=..., looks_open_today=...` |
| Q2a | `% of SKUs with n=1:  ...` &nbsp;/&nbsp; `max rows_per_sku: ...` |
| Q2b | `fractional_rows: ...` &nbsp;/&nbsp; `null_or_blank: ...` |
| Q3a | `duplicated_order_ids: ...` &nbsp;/&nbsp; `excess_rows_from_dupes: ...` |
| Q3b | `full_row_dupe_groups: ...` &nbsp;/&nbsp; `redundant_rows: ...` (only if Q3a > 0) |
| Q4a | `live rows/skus: .../...` &nbsp;/&nbsp; `snapshot rows/skus: .../...` |
| Q4b | `in_live_only: ...` &nbsp;/&nbsp; `in_snapshot_only: ...` &nbsp;/&nbsp; `in_both: ...` |
