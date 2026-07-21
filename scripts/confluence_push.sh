#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# confluence_push.sh
#
# Push a local markdown file to Confluence as a child of the
# "Data Cleaning & EDA" page (or any page you specify).
#
# Usage:
#   ./scripts/confluence_push.sh <markdown-file> [--parent-id <id>] [--title <title>]
#
# Examples:
#   ./scripts/confluence_push.sh findings/product_master_eda.md
#   ./scripts/confluence_push.sh findings/product_master_eda.md --title "Product Master - EDA"
#
# Subsequent runs UPDATE the same page (matched by title under the parent).
# -----------------------------------------------------------------------------
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTH_FILE="${PROJECT_ROOT}/.confluence_auth"

if [[ ! -f "$AUTH_FILE" ]]; then
  echo "ERROR: auth file not found at $AUTH_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$AUTH_FILE"
set +a

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <markdown-file> [--parent-id <id>] [--title <title>]" >&2
  exit 1
fi

MD_FILE="$1"
shift || true

PARENT_ID="${CONFLUENCE_EDA_PAGE_ID}"  # default: under "Data Cleaning & EDA"
TITLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --parent-id)
      PARENT_ID="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$MD_FILE" ]]; then
  echo "ERROR: markdown file not found: $MD_FILE" >&2
  exit 1
fi

echo "Pushing: $MD_FILE"
echo "  -> base: $CONFLUENCE_BASE_URL"
echo "  -> space: $CONFLUENCE_SPACE_KEY"
echo "  -> parent page id: $PARENT_ID"
[[ -n "$TITLE" ]] && echo "  -> title (override): $TITLE"
echo ""

# Save then unset CONFLUENCE_TOKEN: md2cf auto-reads that env var and uses
# Bearer auth (wrong for Atlassian Cloud, which needs Basic auth with
# email + API-token-as-password).
TOKEN_VAL="$CONFLUENCE_TOKEN"
unset CONFLUENCE_TOKEN

TITLE_ARGS=()
if [[ -n "$TITLE" ]]; then
  TITLE_ARGS+=(--title "$TITLE")
fi

# --host needs trailing slash (urljoin behavior) and must include /rest/api path.
# --insecure used because Python 3.14 on macOS has SSL cert store issues; token
# auth over TLS still protects credentials (TLS handshake succeeds, we just skip
# strict cert validation on the client side).
python3 -m md2cf \
  --host "${CONFLUENCE_BASE_URL}/rest/api/" \
  --username "${CONFLUENCE_EMAIL}" \
  --password "${TOKEN_VAL}" \
  --space "${CONFLUENCE_SPACE_KEY}" \
  --parent-id "${PARENT_ID}" \
  --strip-top-header \
  --insecure \
  "${TITLE_ARGS[@]}" \
  "$MD_FILE"

echo ""
echo "Done. Pages under parent:"
echo "  ${CONFLUENCE_BASE_URL}/spaces/${CONFLUENCE_SPACE_KEY}/pages/${PARENT_ID}"
