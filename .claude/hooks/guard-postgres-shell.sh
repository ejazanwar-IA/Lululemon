#!/usr/bin/env bash
# Claude Code PreToolUse (Bash): warn on Postgres CALL without SET ROLE "mtp-dev".
# Ported from .cursor/hooks/guard-postgres-shell.sh (Cursor beforeShellExecution).
# Reads hook JSON from stdin; writes PreToolUse permission-decision JSON to stdout.

set -euo pipefail

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  command_text="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
else
  command_text="$(printf '%s' "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)"
fi

allow() {
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
}

[[ -z "$command_text" ]] && { allow; exit 0; }

cmd_lower="$(printf '%s' "$command_text" | tr '[:upper:]' '[:lower:]')"

if ! printf '%s' "$cmd_lower" | grep -qE 'call[[:space:]]+(global\.(build_|sync_)|public\.sync_)'; then
  allow
  exit 0
fi

if printf '%s' "$cmd_lower" | grep -qE 'set[[:space:]]+role[[:space:]]+("mtp-dev"|mtp-dev)'; then
  allow
  exit 0
fi

python3 -c '
import json, sys
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": sys.argv[1],
    },
    "systemMessage": sys.argv[2],
}))
' \
  'Postgres CALL without SET ROLE "mtp-dev" in the same command. Email logins break temp table names (@ in current_user). Prefer: SET ROLE "mtp-dev"; then CALL ... or approve if the session already has that role.' \
  'Hook flagged CALL global/public sync or build without SET ROLE mtp-dev. Run scripts/postgres_ingestion_preflight.sh first; see Self Notes/postgres_ingestion_gotchas.md.'
