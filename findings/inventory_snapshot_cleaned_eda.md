# Inventory Snapshot Cleaned EDA

`Last updated: 2026-05-06.`

## Purpose

This note documents the raw inventory table:

```sql
`lululemon-01042025.lululemon_souricng_outbound.inventory_snapshot_cleaned`
```

This is the upstream source for `inventory_master` and the new sourcing `inventory_intermediate` workbench. It should be treated separately from `inventory_master`: the raw table is much larger, has longer history, carries `UNITS_AVAILABLE`, and preserves raw `SNAPSHOT_TIME` load behavior.

Companion query workbook:

```text
queries/inventory_snapshot_cleaned_eda.sql
```

---

## 1. Table Shape

Metadata from BigQuery `bq show`:

| Field | Value |
|---|---:|
| Rows | 16,424,322,768 |
| Logical size | ~1.27 TB |
| Physical size | ~75 GB |
| Partitioning | None shown |
| Clustering | `SKU_ID` |
| Columns | 9 |

All-history summary from a full-table aggregate run by Ejaz on 2026-05-06:

| Metric | Value |
|---|---:|
| Total rows | 16,424,322,768 |
| Distinct `SKU_ID` | 1,274,570 |
| Distinct `LOCATION_ID` | 1,592 |
| Min business `DATE` | 2016-03-01 |
| Max business `DATE` | 2025-09-02 |
| Distinct inventory dates | 3,473 |
| Distinct `CHANNEL` values | 6 |
| Distinct `SKU_ID_CHANNEL` | 7,313,504 |
| Null `SKU_ID` | 0 |
| Null `LOCATION_ID` | 0 |
| Null `DATE` | 0 |
| Null `SNAPSHOT_TIME` | 0 |
| Missing `SKU_ID_CHANNEL` | 33,723,661 |
| Missing `CHANNEL` | 33,723,661 |
| Negative `UNITS_ON_HAND` rows | 134,328,726 |
| Zero `UNITS_ON_HAND` rows | 5,734,274,243 |
| Positive `UNITS_ON_HAND` rows | 10,555,719,799 |
| Negative `UNITS_AVAILABLE` rows | 176,499,552 |
| Negative `UNITS_INBOUND` rows | 2,362,509 |
| `UNITS_AVAILABLE > UNITS_ON_HAND` rows | 4,627,576 |
| `UNITS_ON_HAND > 0 AND UNITS_AVAILABLE = 0` rows | 832,617,180 |
| Min `SNAPSHOT_TIME` | 2016-03-02 01:32:47 UTC |
| Max `SNAPSHOT_TIME` | 2025-09-03 11:15:22 UTC |

Important interpretation:

- Raw inventory has complete required base keys for `SKU_ID`, `LOCATION_ID`, `DATE`, and `SNAPSHOT_TIME`.
- The only widespread key gap is channel-related: `CHANNEL` and `SKU_ID_CHANNEL` are missing on the same 33.7M rows.
- Negative on-hand is real at raw-source level: 134.3M rows, not just a master-table artifact.
- `UNITS_AVAILABLE` needs separate treatment from `UNITS_ON_HAND`: 832.6M rows have positive on-hand but zero available units.

Schema:

| Column | Type | Meaning |
|---|---|---|
| `SKU_ID` | INTEGER | Bare SKU ID. |
| `LOCATION_ID` | STRING | Raw location/store ID. |
| `DATE` | DATE | Business inventory date. |
| `UNITS_ON_HAND` | INTEGER | Raw on-hand inventory. |
| `UNITS_AVAILABLE` | INTEGER | Available inventory. This can be lower than on-hand. |
| `UNITS_INBOUND` | INTEGER | Inbound / in-transit units. |
| `SNAPSHOT_TIME` | TIMESTAMP | Raw load/update timestamp. |
| `CHANNEL` | STRING | Raw channel, e.g. `RETAIL`, `ECOMM`, `FO`. |
| `SKU_ID_CHANNEL` | STRING | SKU-channel key, e.g. `145328501_RETAIL`. |

Cost note: because the table is not partitioned by `DATE`, date filters may not prune the same way they do on `inventory_master`. Use narrow probes first.

---

## 2. Relationship To `inventory_master`

Documented build logic maps raw columns into `inventory_master` as:

| Raw `inventory_snapshot_cleaned` | `inventory_master` |
|---|---|
| `DATE` | `date` |
| `UNITS_ON_HAND` | `oh` |
| `UNITS_INBOUND` | `it` |
| hardcoded `0` | `oo` |
| hardcoded `0` | `wip` |
| hardcoded `0` | `initial_oh_quantity` |
| `UNITS_ON_HAND` | `total_units` |
| `LOCATION_ID` | `store_code` |
| `SKU_ID_CHANNEL` | `product_code` |

`inventory_master` also joins raw inventory to `product_group_hierarchy_cleaned` to attach brand and keep rows with product-hierarchy coverage.

Known open issue from lineage docs: `inventory_master` starts in 2023, while raw `inventory_snapshot_cleaned` contains pre-2023 business dates. This means the raw source has historical inventory that the master table drops.

---

## 3. Existing Validated Checks

From the inventory sourcing workbench, a validated raw profile for business date `2025-08-28` returned:

| Metric | Value |
|---|---:|
| Raw rows | 5,539,053 |
| Null `SKU_ID` | 0 |
| Null `LOCATION_ID` | 0 |
| Null `DATE` | 0 |
| Null `SNAPSHOT_TIME` | 0 |
| Missing `SKU_ID_CHANNEL` | 120,222 |
| Missing `CHANNEL` | 120,222 |
| Negative `UNITS_ON_HAND` rows | 33,774 |
| Negative `UNITS_INBOUND` rows | 712 |
| Negative `UNITS_AVAILABLE` rows | 42,444 |

Channel derivation for the 120,222 rows missing raw channel/product key:

| Derived channel | Rows |
|---|---:|
| `RETAIL` | 117,016 |
| `STRAT` | 3,206 |
| Unclassified | 0 |

This was used to build `lulu_sourcing_dev.inventory_intermediate_temp` with derived product/channel fallback fields.

---

## 4. Findings From The 100-Row Sample

The random sample reinforces several raw-source behaviors:

1. Raw history reaches well before 2023. Examples include business dates from 2016, 2017, 2018, 2019, 2020, 2021, and 2022.
2. Some old business dates have much later `SNAPSHOT_TIME`, especially `2022-08-02`, which suggests a bulk historical backfill or reload.
3. `CHANNEL` includes more than `RETAIL` and `ECOMM`; `FO` appears in the sample and should be profiled separately.
4. `UNITS_AVAILABLE` is not always equal to `UNITS_ON_HAND`. For some ECOM rows, on-hand is positive while available is zero.
5. Negative inventory exists in raw, e.g. `UNITS_ON_HAND = -1` and `UNITS_AVAILABLE = -1` in the sample. This supports the existing conclusion that negative `oh` in `inventory_master` is inherited from source.

---

## 5. EDA Workbook Sections

The query workbook is organized as:

| Section | Purpose |
|---|---|
| Section 0 | Metadata and schema checks. |
| Section 1 | Business-date availability and `SNAPSHOT_TIME` load behavior. |
| Section 2 | Narrow-window raw profile and anomalies. |
| Section 3 | Grain and duplicate checks. |
| Section 4 | Key consistency and channel derivation checks. |
| Section 5 | Quantity quality over a selected recent window. |
| Section 6 | Location/product coverage checks. |
| Section 7 | Raw-to-master reconciliation. |
| Section 8 | Representative sample extracts. |

Recommended first run:

1. Section 0: metadata and schema.
2. Section 1A/1B/1C: business date and load behavior.
3. Section 2A/2B: raw profile for `2025-08-28`.
4. Section 3A: grain duplicate summary.
5. Section 7A/7B: raw-to-master reconciliation for the same date.

---

## 6. Working Hypotheses To Validate

| Hypothesis | Evidence so far | Workbook section |
|---|---|---|
| Raw has pre-2023 inventory history dropped by master. | Sample rows and existing lineage docs. | Section 7C |
| Old business dates were bulk backfilled. | Many sample rows with old `DATE` and `SNAPSHOT_TIME = 2022-08-02`. | Section 1D |
| Raw grain is effectively SKU × location × date × channel. | Sourcing workbench produced no duplicate groups on 2025-08-28. | Section 3 |
| Missing `CHANNEL` / `SKU_ID_CHANNEL` can be derived from location metadata. | 120,222 missing rows on 2025-08-28 all derived to `RETAIL` or `STRAT`. | Section 4B |
| Negative inventory is source-native. | Raw sample and 2025-08-28 raw profile show negative units. | Section 5 |
| Product hierarchy coverage is channel-dependent. | Prior `inventory_intermediate` checks showed non-core channels have weaker PGH match. | Section 6B |

---

## 7. Current Recommendations

- For master-table modeling, keep using `inventory_master` when the 2023+ filtered, partitioned table is sufficient.
- For pre-2023 history, backfill analysis, or `UNITS_AVAILABLE`, use raw `inventory_snapshot_cleaned`.
- Do not treat missing rows as zero inventory until we confirm raw write semantics. The master EDA suggests sparse inventory rows are meaningful.
- Use `SKU_ID_CHANNEL` for product joins when present; derive with `CONCAT(CAST(SKU_ID AS STRING), '_', derived_channel)` only when raw channel is missing and derivation is validated.
- Keep `UNITS_AVAILABLE` in sourcing-layer work where possible; it is lost in the documented `inventory_master` build.
- Escalate the pre-2023 master drop and negative inventory behavior as client/DE questions.

---

## 8. Cross-References

- SQL workbook: [`../queries/inventory_snapshot_cleaned_eda.sql`](../queries/inventory_snapshot_cleaned_eda.sql)
- Derived master EDA: [`inventory_master_eda.md`](inventory_master_eda.md)
- Raw-to-master lineage: [`raw_to_master_lineage.md`](raw_to_master_lineage.md)
- Master build logic: [`master_table_build_logic.md`](master_table_build_logic.md)
- Inventory sourcing workbench: [`../queries/inventory_sourcing_stepwise.sql`](../queries/inventory_sourcing_stepwise.sql)
