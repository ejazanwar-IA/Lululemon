# `product_intermediate.color_family` — candidate source found in raw GCS feed

`Found: 2026-07-21.`

## Status quo

`product_intermediate` v2 (`queries/Intermediate_table_builds/create_product_intermediate_historic_v2.sql`) hardcodes `color_family` to `NULL`. Per `findings/lululemon_intermediate_builds_v2_reference.md`, the stated reason is "no integer lookup in feeds."

## Finding

The raw `product_attribute_so` feed (Style Option level attributes) in GCS carries a **text** color family column that the v2 build never reads:

- Path: `gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_so/`
- Relevant columns: `COLOUR_BUCKET`, `COLOUR_EXECUTION`, **`COLOUR_FAMILY`**, `COLOUR_PRINT_TYPE`, `COLOUR_SEASONALITY`, `COLOUR_SHADE`
- Key column: `STYLE_OPTION_ID` (format `LW5AGFS-030084`, same shape as `product_intermediate.article`/`article_original`)

**Sample scan** (one shard, `product_attribute_so20251118_153538_0_0_0.csv`, streamed via `gcloud storage cat | python3`, not downloaded):

| Metric | Value |
|---|---|
| Rows scanned | 29,485 |
| `COLOUR_FAMILY` filled | 26,012 (88.22%) |
| Top values | Black (4,079), Blue (3,215), Grey (2,595), Green (2,562), Pink (2,420), Purple (2,365), Brown (1,363), Red (1,317), Navy (984), White (981) |

This is a **text** color family (Black/Blue/Grey/...), not the integer lookup the original schema expected — so wiring it in would mean either accepting a text `color_family`, or building a small text-to-integer lookup if the downstream schema requires INT64.

## The join gap

`product_attribute_so.PLANNING_STYLE_OPTION_ID` is **0% filled** in the sampled shard, so it cannot join directly to `product_intermediate.article_original` (which is `PLANNING_STYLE_OPTION_CODE`).

Bridge needed: `style_option.csv` has all three keys together (`STYLE_OPTION_ID`, `STYLE_ID`, `PLANNING_STYLE_OPTION_ID`), so the path would be:

```
product_attribute_so.STYLE_OPTION_ID
  → style_option.STYLE_OPTION_ID  (get PLANNING_STYLE_OPTION_ID)
  → product_intermediate.article_original  (= PLANNING_STYLE_OPTION_CODE)
```

This bridge join has not been validated yet — fill rate and cardinality (one-to-one vs one-to-many at the PSO grain) still need checking before this gets wired into a v3 build.

## Next steps (not yet done)

1. Validate the `style_option` bridge join fill rate and grain (does every `product_intermediate` PSO get exactly one `COLOUR_FAMILY`, or can a PSO have multiple style options with conflicting families?).
2. Decide text vs. integer `color_family` with whoever owns the downstream schema expectation.
3. If approved, wire into the next `product_intermediate` version (not a live-table edit — follow the `_tmp_YYYYMMDD` pre/post validation workflow in `lululemon-intermediate-builds-v2`).

## Related

- [`lululemon_intermediate_builds_v2_reference.md`](lululemon_intermediate_builds_v2_reference.md) — canonical v2 build reference (still lists `color_family` as blocked; update once this is wired in)
- `.claude/skills/lululemon-intermediate-builds-v2/SKILL.md`
