---
name: lululemon-intermediate-builds-v2
description: Canonical v2 intermediate build logic for Lululemon product, store, inventory, and transaction masters. Use when editing sourcing SQL, explaining intermediate lineage, comparing to old workbench builds, or promoting periodic scripts.
---

# Lululemon intermediate builds v2 (locked reference)

`Locked: 2026-07-17.` `product_intermediate.color_family` resolved 2026-07-21 (validated on `_tmp_` only, not yet promoted to live). `inventory_intermediate.oo` resolved 2026-07-22 (validated on `_tmp_` at full 4.42B-row scale, script committed to GitHub, not yet promoted to live). 2026-07-23: `oo`'s attach mechanism rewritten (range join → merge/forward-fill, ~5x faster, verified byte-identical at full scale) and `source_product_code`/`source_channel`/`product_code_was_derived`/`channel_was_derived` dropped (they only ever carried real lineage info in the periodic script's fallback path, never in historic's). **Both changes are historic-v2-script only** — user explicitly deprioritized the periodic script for now. `create_inventory_intermediate_periodic.sql` still has the old range-join `oo` mechanism *and* the four now-dropped columns; **historic and periodic are intentionally out of schema and logic sync as of 2026-07-23.** This is a deliberate, known exception to hard rule 5 below; don't "fix" the periodic script to match without asking first, and don't assume the two builds produce the same schema.

**2026-07-24: `product_intermediate` channel dropped.** Grain changed from SKU × channel (2 rows/SKU) to SKU only (1 row/SKU); `product_code` is now a bare `SKU_ID`, not `{SKU_ID}_{channel}`. Verified: RETAIL/ECOMM rows were already 100% identical on every real attribute pre-change, and the new build matches a fresh prechange rebuild's RETAIL rows with 0 diffs at full scale. **This directly breaks hard rule 2 below** — `inventory_intermediate` and `transaction_intermediate` still build/expect `{SKU_ID}_{channel}`-format product codes when joining to product. Not reconciled; user's call to fix product now and handle the downstream join mismatch in a later pass. Don't assume product joins cleanly to inventory/transaction on `product_code` right now.

## Source of truth

Read **`findings/lululemon_intermediate_builds_v2_reference.md`** first. Executable authority is the four historic v2 SQL files:

| Intermediate | SQL |
|---|---|
| `store_intermediate` | `queries/Intermediate_table_builds/create_store_intermediate_historic_v2.sql` |
| `product_intermediate` | `queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql` |
| `inventory_intermediate` | `queries/Intermediate_table_builds/create_inventory_intermediate_historic_v2.sql` |
| `transaction_intermediate` | `queries/Intermediate_table_builds/create_transaction_intermediate_historic_v2.sql` |

## Do not treat as current

- `queries/store_master_intermediate_build.sql`
- `queries/transaction_intermediate_build.sql`
- `queries/inventory_intermediate_build.sql`
- v1 `queries/Intermediate_table_builds_v1/create_*_intermediate_historic.sql` (baseline for diff only — moved out of `Intermediate_table_builds/` on 2026-07-22 so that directory holds only current v2 logic)

## Build order

store → product → (inventory parallel) → transaction (needs product + store)

## Hard rules when changing logic

1. **Date window:** `DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR), YEAR)` for inventory + transaction historic builds.
2. **`product_code`:** `{SKU_ID}_{ECOMM|RETAIL}` for `inventory_intermediate`/`transaction_intermediate` (txn joins `store_intermediate.channel` for its own channel). **Exception:** `product_intermediate` itself dropped the channel suffix on 2026-07-24 — its `product_code` is now bare `SKU_ID`. The two conventions are currently mismatched across builds; see the 2026-07-24 note above.
3. **No live promotion without `_tmp_` pre/post comparison** unless the user explicitly asks to rebuild production tables.
4. **Blocked stubs stay blocked** until the reference doc and user sign-off say otherwise (e.g. `cost`, `location_attrib_squareft`, `special_classification`). `color_family` resolved 2026-07-21 — see below.
5. **Periodic scripts** must be updated in the same change set when historic v2 logic changes.
6. **GitHub is the source of truth.** Any change to these files must be committed and pushed to `main` on [github.com/ejazanwar-IA/lululemon-forecasting-engagement](https://github.com/ejazanwar-IA/lululemon-forecasting-engagement) in the same turn once verified — don't leave a verified change sitting locally-only or only as a `_tmp` BigQuery table.

## Quick blocked-column reminder

| Table | Blocked |
|---|---|
| Store | `location_attrib_squareft` (0), `special_classification` (NULL) |
| Product | none remaining — `color_family` resolved 2026-07-21 via `product_attribute_so.COLOUR_FAMILY` bridged through `style_option` (STRING, ~92% fill; see `findings/product_intermediate_color_family_source_found.md`). Channel dropped 2026-07-24 — see the note above; `l1_name` is now always `NULL` (had no source once channel was removed). |
| Inventory | `wip` (0, no source identified yet). `oo` resolved 2026-07-22 — open `REPLEN`/`ALLOC` transfer-order pipeline from `lulu_sourcing_dev.transfer_orders`, closed on `DATE_RECEIVED` (see `findings/po_transfer_cleaning_audit.md` R2 and `findings/lululemon_intermediate_builds_v2_reference.md` Section 3). Known limitation: cannot be cleanly separated from `it` (in-transit) — no reliable ship-date signal exists. |
| Transaction | `cost` (zero feed), `launch_price`, `line_id`, freight/workstream/discount-adjacent stubs listed in v2 SQL header |

When answering lineage or build questions, cite the reference doc and the relevant v2 SQL file; do not reconstruct logic from memory or old platform CSVs.
