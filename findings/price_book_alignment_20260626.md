# Price Book Alignment Findings

Date: 2026-06-26

## Verdict

Do not directly wire `price_book` into `transaction_intermediate` yet.

The price-book range join is technically safe from row multiplication, but two blockers remain:

- Normalizing return order IDs by stripping `|RETURNS` collides with the current transaction grain unless `txn_source` is included in the merge key, or the raw return transaction code is preserved as the durable transaction code.
- Price-book coverage is only 141,451,074 of 198,154,856 product-mapped transaction rows per source (71.38%). For returns overall, coverage is 141,451,074 of 215,551,141 rows (65.62%) once product-master misses are included.

Recommended path: first update the transaction spine design so sales and returns remain distinguishable, then add price-book fields as nullable enrichment fields after deciding whether 71.38% coverage is acceptable for the active transaction window.

## Price Book Profile

Source table: `lululemon-01042025.lululemon_souricng_outbound.price_book`

| Check | Result |
|---|---:|
| Rows | 440,496,318 |
| Distinct `STYLE_OPTION_ID` | 155,026 |
| Distinct `LOC_ID` | 1,565 |
| Distinct style-location pairs | 223,906,445 |
| Date range | 2003-01-01 to 9999-12-31 |
| Positive original price rows | 440,480,610 (100.00% of price-book rows) |
| Positive regular price rows | 440,487,340 (100.00% of price-book rows) |
| Positive clearance price rows | 163,707,634 (37.16% of price-book rows) |
| Duplicate interval groups | 0 (0.00% of price-book intervals) |
| Overlapping intervals | 0 (0.00% of price-book intervals) |

Key coverage:

| Check | Result |
|---|---:|
| Price-book style options found in `product_intermediate.article_original` | 146,506 of 155,026 (94.50%) |
| Price-book locations found in `store_intermediate.store_code` | 1,565 of 1,565 (100.00%) |

## Transaction Spine Check

Active window used: 2024-01-01 onward, matching the rolling "2 full prior years plus YTD" logic.

| Source | Rows | Zero-unit rows | Positive-unit rows | Negative-unit rows | Signed units | Signed revenue |
|---|---:|---:|---:|---:|---:|---:|
| `SALE` | 198,154,856 | 53,510,836 (27.00%) | 144,644,020 (73.00%) | 0 (0.00%) | 228,642,976 | 401,430,157,821.43 |
| `RETURN` | 215,551,141 | 188,503,122 (87.45%) | 27,008,720 (12.53%) | 39,299 (0.02%) | -31,601,610 | -52,004,682,825.53 |

Grain checks:

| Grain | Duplicate groups | Extra rows |
|---|---:|---:|
| `txn_source, normalized_transaction_code, product_code, store_code, business_date` | 0 (0.00% of combined rows) | 0 |
| `normalized_transaction_code, product_code, store_code, business_date` | 198,154,856 groups | 198,154,856 extra rows |

Implication: `txn_source` must be part of the logical transaction key if returns order IDs are normalized by stripping `|RETURNS`. Otherwise the returns skeleton rows collide with sales rows.

## Product Mapping Layer

| Source | Rows | Missing store channel | Missing product article |
|---|---:|---:|---:|
| `SALE` | 198,154,856 | 0 (0.00%) | 0 (0.00%) |
| `RETURN` | 215,551,141 | 0 (0.00%) | 17,396,285 (8.07%) |

The return product gap means price-book coverage should be measured separately for product-mapped returns and all returns.

## Price Book Coverage

Join used:

- `transaction.product_code -> product_intermediate.article_original`
- `article_original = price_book.STYLE_OPTION_ID`
- `store_code = LPAD(price_book.LOC_ID, 10, '0')`
- `business_date BETWEEN EFFECTIVE_FROM_DAY_ID AND EFFECTIVE_TO_DAY_ID`

Coverage on product-mapped transaction rows:

| Source | Product-mapped rows | Rows with price book | Rows without price book |
|---|---:|---:|---:|
| `SALE` | 198,154,856 | 141,451,074 (71.38%) | 56,703,782 (28.62%) |
| `RETURN` | 198,154,856 | 141,451,074 (71.38%) | 56,703,782 (28.62%) |

For returns including product-mapping misses:

| Return layer | Rows |
|---|---:|
| All return rows | 215,551,141 |
| Product-mapping misses | 17,396,285 (8.07%) |
| Product-mapped but no price-book match | 56,703,782 (26.31%) |
| Rows with price-book match | 141,451,074 (65.62%) |

Coverage by year and channel, same for sales and product-mapped returns because the return skeleton mirrors sales rows:

| Year | Channel | Product-mapped rows | Rows with price book | Rows without price book |
|---|---|---:|---:|---:|
| 2024 | ECOMM | 19,939,199 | 15,557,327 (78.02%) | 4,381,872 (21.98%) |
| 2024 | RETAIL | 85,405,384 | 57,528,348 (67.36%) | 27,877,036 (32.64%) |
| 2025 | ECOMM | 20,112,049 | 16,187,339 (80.49%) | 3,924,710 (19.51%) |
| 2025 | RETAIL | 72,698,224 | 52,178,060 (71.77%) | 20,520,164 (28.23%) |

## Row Multiplication Check

| Source | Pre-join rows | Post-join rows | Matched join rows | Extra rows from join |
|---|---:|---:|---:|---:|
| `SALE` | 198,154,856 | 198,154,856 | 141,451,074 (71.38%) | 0 (0.00%) |
| `RETURN` | 198,154,856 | 198,154,856 | 141,451,074 (71.38%) | 0 (0.00%) |

The date-range join does not multiply transaction rows because `price_book` has no overlapping intervals at `STYLE_OPTION_ID, LOC_ID`.

## Implementation Recommendation

Use a two-step implementation:

1. Normalize the transaction spine first.
   - Add or preserve `txn_source`.
   - Keep `transaction_code_raw`.
   - Add `transaction_code_normalized` for sales-return lineage.
   - Do not use normalized code alone in the merge key.

2. Add price-book enrichment only after the spine is stable.
   - Join through `product_intermediate.article_original`, store code, and transaction date.
   - Add nullable price fields such as `original_price`, `regular_price`, and `clearance_price`.
   - Keep transaction observed prices separate from price-book reference prices.
   - Document that price-book coverage is 71.38% on product-mapped rows in the active window.

I would not create a separate daily-expanded price dimension yet. The interval table is join-safe as-is. A separate dimension becomes useful only if the business needs a reusable price reference, precomputed unmatched diagnostics, or stronger null-handling before production.
