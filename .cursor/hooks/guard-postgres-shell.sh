#!/usr/bin/env bash
# Cursor beforeShellExecution: warn on Postgres CALL without SET ROLE "mtp-dev".
# Reads hook JSON from stdin; writes permission JSON to stdout.

set -euo pipefail

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  command_text="$(printf '%s' "$input" | jq -r '.command // empty')"
else
  command_text="$(printf '%s' "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || true)"
fi

emit() {
  python3 -c 'import json,sys; print(json.dumps({"permission":sys.argv[1],"user_message":sys.argv[2] if len(sys.argv)>2 else None,"agent_message":sys.argv[3] if len(sys.argv)>3 else None}, skipkeys=True))' "$@"
}

[[ -z "$command_text" ]] && { emit allow; exit 0; }

cmd_lower="$(printf '%s' "$command_text" | tr '[:upper:]' '[:lower:]')"

if ! printf '%s' "$cmd_lower" | grep -qE 'call[[:space:]]+(global\.(build_|sync_)|public\.sync_)'; then
  emit allow
  exit 0
fi

if printf '%s' "$cmd_lower" | grep -qE 'set[[:space:]]+role[[:space:]]+("mtp-dev"|mtp-dev)'; then
  emit allow
  exit 0
fi

emit ask \
  'Postgres CALL without SET ROLE "mtp-dev" in the same command. Email logins break temp table names (@ in current_user). Prefer: SET ROLE "mtp-dev"; then CALL ... — or approve if the session already has that role.' \
  'Hook flagged CALL global/public sync or build without SET ROLE mtp-dev. Run scripts/postgres_ingestion_preflight.sh first; see Self Notes/postgres_ingestion_gotchas.md.'
