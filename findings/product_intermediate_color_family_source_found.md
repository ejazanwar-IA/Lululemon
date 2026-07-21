# `product_intermediate.color_family` — found, validated, and wired into v2

`Found: 2026-07-21.` `Resolved: 2026-07-21` (validated on `_tmp_` tables; not yet promoted to the live table).

## Status quo (as of discovery)

`product_intermediate` v2 (`queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql`) hardcoded `color_family` to `NULL` (typed `INT64`). Per `findings/lululemon_intermediate_builds_v2_reference.md`, the stated reason was "no integer lookup in feeds."

**Note:** a separate, older note in `findings/lululemon_client_open_questions.md` ("Self-resolved (no ask): ... color_family from color_description") proposed deriving `color_family` by parsing `color_description` instead. Checked `queries/product_master_clean_view.sql` — that derivation was never implemented. Decided with the user (2026-07-21) to use the `product_attribute_so` join below instead: real client-labeled attribute data beats an unvalidated text-parsing heuristic.

## Finding

The raw `product_attribute_so` feed (Style Option level attributes) in GCS carries a **text** color family column that the v2 build never reads:

- Path: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_so/`
- Relevant columns: `COLOUR_BUCKET`, `COLOUR_EXECUTION`, **`COLOUR_FAMILY`**, `COLOUR_PRINT_TYPE`, `COLOUR_SEASONALITY`, `COLOUR_SHADE`
- Key column: `STYLE_OPTION_ID` (format `LW5AGFS-030084`, same shape as `product_intermediate.article`/`article_original`)

**Full population scan** (all 16 shards, streamed via `gcloud storage cat | python3`, not downloaded — 2026-07-21):

| Metric | Value |
|---|---|
| Rows scanned | 472,141 |
| Distinct `STYLE_OPTION_ID` | 472,141 (no dupes — clean grain) |
| `COLOUR_FAMILY` filled | 416,975 (88.32%) |
| Top values | Black, Blue, Grey, Green, Pink, Purple, Brown, Red, Navy, White |

This is a **text** color family (Black/Blue/Grey/...), not the integer lookup the original schema expected. **Decided with the user (2026-07-21):** change `color_family` from `INT64` to `STRING` rather than invent an integer lookup — the IA platform's own OOTB Confluence reference for `product_master` (`reference_docs/IA_Platform/Sourcing_Tables/966295603_product_master.md`) treats `Color_Family` as a plain string, and no real integer lookup exists anywhere in the repo to justify manufacturing codes.

## The join gap — validated 2026-07-21

`product_attribute_so.PLANNING_STYLE_OPTION_ID` is **0% filled**, so it cannot join directly to `product_intermediate.article_original` (`PLANNING_STYLE_OPTION_CODE`). Bridge: `style_option` (already a BQ table in `lulu_sourcing_dev`) has all three keys (`STYLE_OPTION_ID`, `STYLE_ID`, `PLANNING_STYLE_OPTION_ID`):

```
product_attribute_so.STYLE_OPTION_ID
  → style_option.STYLE_OPTION_ID  (get PLANNING_STYLE_OPTION_ID, filtered to IS_PRIMARY_STYLE_OPTION = 'true')
  → product_intermediate.article_original  (= PLANNING_STYLE_OPTION_CODE)
```

**Bridge validated against the full `style_option` BQ table (469,512 rows):**

| Check | Result |
|---|---|
| `STYLE_OPTION_ID` uniqueness in `style_option` | 100% unique (469,512 rows = 469,512 distinct) |
| `PLANNING_STYLE_OPTION_ID` fill in `style_option` | 100% (469,512 / 469,512) |
| PSOs with more than one style option | 2,331 of 466,026 (0.50%) — up to 12 style options for one PSO in rare cases |
| Of those, PSOs with exactly one `IS_PRIMARY_STYLE_OPTION = 'true'` row | 100% (2,331 / 2,331) — filtering on primary cleanly resolves every fan-out case |

**Full join, `product_attribute_so` → `style_option` (primary only):**

| Metric | Value |
|---|---|
| `product_attribute_so` rows matched to a PSO | 466,010 of 472,141 (98.70%) |
| Matched **and** `COLOUR_FAMILY` populated | 413,523 of 472,141 (87.58%) |
| Conflicting `COLOUR_FAMILY` across a PSO's join | **0** |

**Conclusion: the bridge join is clean.** Filtering `style_option` to `IS_PRIMARY_STYLE_OPTION = 'true'` gives exactly one row per PSO with zero grain conflicts, and the join delivers a populated `color_family` for 87.58% of the raw feed — close to the source column's own 88.32% fill rate, so the bridge itself loses almost nothing.

**Platform gap found during validation:** `product_attribute_so` (base table) is **not yet ingested into BigQuery** — only `product_attribute_so_seasonal` exists in `lulu_sourcing_dev` today (checked via `bq ls`). `style_option` and `product_group_hierarchy` are already there. Wiring this into a BQ-based `product_intermediate` build needs the sourcing DAG to bring `product_attribute_so` into BQ first; until then this can only be validated from the raw GCS CSVs.

## Implementation (2026-07-21)

Added a `color_family_lookup` CTE (the same join validated above, plus a sentinel-cleaning filter) to both:

- `queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql` — `CAST(NULL AS INT64) AS color_family` replaced with `cfl.color_family AS color_family` (now `STRING`).
- `queries/sourcing/create_product_intermediate_periodic.sql` — same CTE and column swap in the staging build (MERGE `UPDATE`/`INSERT` clauses needed no change; they already reference `color_family` generically by name).

**Known limitation (periodic only):** `product_attribute_so` has no `SYNCSTARTDATETIME` (it's a manual load, not yet in the Sourcing DAG — see platform gap below), so its own changes can't trigger a periodic re-pull. `color_family` only refreshes for SKUs already re-pulled via `product_group_hierarchy`/`sku_details`/`product_attribute_s` changes. Documented inline in the periodic SQL's header comment.

## Validation (`_tmp_20260721`)

The live table itself turned out to be stale versus a fresh v2 run (unrelated pre-existing issue — e.g. its `ordering`/`gender` values already didn't match a fresh v2 build), so a direct live-vs-new comparison would have been invalid. Built a clean **unedited-v2 baseline** from the exact pre-edit SQL (via `git show HEAD:...`) against the same fresh raw data, then compared that against the edited version:

| Check | Result |
|---|---|
| Row count | 1,977,528 in both (unchanged) |
| Any other column drifted (all 45 non-`color_family` columns, compared by name) | **0 rows differ** in either direction — isolates the change cleanly |
| `color_family` fill: baseline → post | 0% → **92.18%** (1,822,928 of 1,977,528 rows) |
| Duplicate/conflicting `color_family` per `product_code` | **0** |
| Value distribution | Real color names only (Black 297,814; Blue 228,782; Grey 199,704; ...); no garbage values |

Temp tables left in `lulu_sourcing_dev` as an audit trail: `product_intermediate_baseline_v2_tmp_20260721`, `product_intermediate_postchange_v2_tmp_20260721`, `product_intermediate_prechange_tmp_20260721` (live snapshot — also the evidence that the live table is stale, see above).

**Not yet done:** promote to the live `lulu_sourcing_dev.product_intermediate` table (rerun the historic v2 SQL against the real target) and run the periodic script's next cycle. Per the intermediate-builds-v2 hard rule, this needs an explicit go-ahead rather than happening automatically off this validation pass.

## Platform gap (separate from this change)

`product_attribute_so` (base table) was **not in BigQuery** prior to 2026-07-21 — only `product_attribute_so_seasonal` existed in `lulu_sourcing_dev`. Loaded it manually via `LOAD DATA INTO ... FROM FILES(...)` from the GCS consolidated folder (472,141 rows, matches the GCS scan exactly) so this join could be validated and wired in. This is a **one-time snapshot**, not a live pipeline, and carries no `SYNCSTARTDATETIME` lineage column unlike its DAG-ingested siblings. Getting it added to the real Sourcing DAG is still an open follow-up, separate from the SQL change above.

## Related

- [`lululemon_intermediate_builds_v2_reference.md`](lululemon_intermediate_builds_v2_reference.md) — canonical v2 build reference, updated 2026-07-21 to reflect this change
- `.claude/skills/lululemon-intermediate-builds-v2/SKILL.md` / `.cursor/rules/lululemon-intermediate-builds-v2.mdc` — both updated 2026-07-21
