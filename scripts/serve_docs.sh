#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# serve_docs.sh
#
# Launch the MkDocs Material docs site locally with live-reload.
#
# Usage:
#   ./scripts/serve_docs.sh              # serve on 127.0.0.1:8765
#   ./scripts/serve_docs.sh --build      # one-shot build into ./site/
#   ./scripts/serve_docs.sh --deploy     # push to GitHub Pages (needs gh remote)
#
# First-time setup:
#   pip3 install --user mkdocs-material mkdocs-glightbox
# -----------------------------------------------------------------------------
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"

if ! command -v mkdocs >/dev/null 2>&1; then
  echo "mkdocs not found. Installing…" >&2
  pip3 install --user mkdocs-material mkdocs-glightbox
fi

MODE="${1:-serve}"

case "$MODE" in
  --build|build)
    mkdocs build
    echo ""
    echo "Built into: $PROJECT_ROOT/site"
    ;;
  --deploy|deploy)
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "ERROR: Not a git repository. Run 'git init' and add a remote first." >&2
      exit 1
    fi
    mkdocs gh-deploy --clean --force
    ;;
  --serve|serve|"")
    mkdocs serve -a 127.0.0.1:8765
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    echo "Usage: $0 [--serve|--build|--deploy]" >&2
    exit 1
    ;;
esac
