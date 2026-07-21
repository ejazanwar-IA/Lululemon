#!/usr/bin/env bash
# Lululemon lulu_dev Postgres ingestion preflight (read-only gates).
# Usage: ./scripts/postgres_ingestion_preflight.sh [--warn-only]
# Exit 0 = all fail-severity gates passed; exit 1 = at least one fail gate failed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${LULU_PG_ENV_FILE:-$ROOT/.cursor/secrets/lulu_dev_postgres.env}"
GATES_SQL="$ROOT/queries/postgres_ingestion_preflight_gates.sql"
WARN_ONLY=0

if [[ "${1:-}" == "--warn-only" ]]; then
  WARN_ONLY=1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

die() {
  echo -e "${RED}ERROR:${RESET} $*" >&2
  exit 1
}

if [[ ! -f "$ENV_FILE" ]]; then
  die "Missing env file: $ENV_FILE (copy .cursor/secrets/lulu_dev_postgres.env.example)"
fi

# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

: "${PG_HOST:?PG_HOST not set in env file}"
: "${PG_PORT:?PG_PORT not set in env file}"
: "${PG_NAME:?PG_NAME not set in env file}"
: "${PG_USER:?PG_USER not set in env file}"
: "${PG_PASSWORD:?PG_PASSWORD not set in env file}"

PSQL=""
for candidate in psql /opt/homebrew/bin/psql /usr/local/bin/psql; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PSQL="$(command -v "$candidate")"
    break
  fi
  if [[ -x "$candidate" ]]; then
    PSQL="$candidate"
    break
  fi
done
if [[ -z "$PSQL" ]]; then
  die "psql not found (brew install libpq && brew link --force libpq, or PostgreSQL.app client)"
fi

if [[ ! -f "$GATES_SQL" ]]; then
  die "Missing gates SQL: $GATES_SQL"
fi

export PGPASSWORD="$PG_PASSWORD"

echo -e "${BOLD}${CYAN}Lululemon Postgres ingestion preflight${RESET}"
echo -e "  database: ${PG_NAME} @ ${PG_HOST}:${PG_PORT}"
echo -e "  user:     ${PG_USER}"
echo ""

mapfile -t rows < <(
  "$PSQL" -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_NAME" \
    -v ON_ERROR_STOP=1 \
    -At -F '|' \
    -f "$GATES_SQL" 2>&1
) || die "psql failed (check VPN, host, credentials)"

fail_count=0
warn_fail_count=0

printf "  %-5s %-52s %8s %8s  %s\n" "ID" "Gate" "Actual" "Expect" "Result"
printf "  %-5s %-52s %8s %8s  %s\n" "-----" "----------------------------------------------------" "--------" "--------" "------"

for row in "${rows[@]}"; do
  [[ -z "$row" ]] && continue
  IFS='|' read -r gate_id gate_name actual expected severity passed <<<"$row"

  if [[ "$passed" == "t" || "$passed" == "true" ]]; then
    status="${GREEN}PASS${RESET}"
  else
    if [[ "$severity" == "fail" ]]; then
      status="${RED}FAIL${RESET}"
      ((fail_count++)) || true
    else
      status="${YELLOW}WARN${RESET}"
      ((warn_fail_count++)) || true
    fi
  fi

  printf "  %-5s %-52s %8s %8s  %b\n" "$gate_id" "$gate_name" "$actual" "$expected" "$status"
done

echo ""
if (( fail_count > 0 )); then
  echo -e "${RED}${BOLD}$fail_count fail-severity gate(s) failed.${RESET} Fix before CALL build_* / hierarchy tasks."
  echo "  See: queries/postgres_lulu_dev_diagnostics.sql, .cursor/rules/lululemon-postgres-ingestion.mdc"
  exit 1
fi

if (( warn_fail_count > 0 )); then
  echo -e "${YELLOW}$warn_fail_count warning gate(s) did not pass.${RESET} Review before production DAG."
  if (( WARN_ONLY == 0 )); then
    exit 0
  fi
fi

echo -e "${GREEN}${BOLD}All fail-severity gates passed.${RESET}"
exit 0
