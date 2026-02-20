#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_DIR="$ROOT_DIR/scripts/workflow"

# Review-lift generation is allowed in dedicated review tooling only.
# Compilation workflows must not reference rendered review artifacts directly.
if rg -n --glob 'run-*.sh' 'render_review_lift\.py|program\.review\.cairo|review\.cairo' "$WORKFLOW_DIR" >/dev/null; then
  echo "review-lift isolation violation: workflow scripts reference review-lift artifacts"
  rg -n --glob 'run-*.sh' 'render_review_lift\.py|program\.review\.cairo|review\.cairo' "$WORKFLOW_DIR"
  exit 1
fi

echo "review-lift isolation check passed"
