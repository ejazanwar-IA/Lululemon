#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="lululemon-01042025"
DATASET="lulu_sourcing_dev"

load_if_missing() {
  local table_name="$1"
  local source_uri="$2"

  if bq show --project_id="${PROJECT_ID}" "${DATASET}.${table_name}" >/dev/null 2>&1; then
    echo "Skipping ${DATASET}.${table_name}: table already exists"
    return 0
  fi

  echo "Loading ${DATASET}.${table_name} from ${source_uri}"
  bq load \
    --project_id="${PROJECT_ID}" \
    --source_format=CSV \
    --autodetect \
    --skip_leading_rows=1 \
    "${DATASET}.${table_name}" \
    "${source_uri}"
}

load_if_missing \
  "purchase_orders_full_review_20260629" \
  "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/purchase_orders/*.csv"

load_if_missing \
  "product_attribute_s_seasonal_full_review_20260629" \
  "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_s_seasonal/*.csv"

load_if_missing \
  "product_attribute_so_seasonal_full_review_20260629" \
  "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/product_attribute_so_seasonal/*.csv"

load_if_missing \
  "eligibility_full_review_20260629" \
  "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/eligibility/*.csv"

load_if_missing \
  "style_option_full_review_20260629" \
  "gs://client_data_lululemon/Historic/s3_to_gcs/consolidated/style_option/*.csv"

echo "Review table load commands completed."
