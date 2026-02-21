#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY_REL="roadmap/capabilities/registry.json"
OUT_JSON_REL="roadmap/inventory/capability-coverage-report.json"
OUT_MD_REL="roadmap/inventory/capability-coverage-report.md"

python3 "$ROOT_DIR/scripts/roadmap/validate_capability_registry.py" --registry "$ROOT_DIR/$REGISTRY_REL"
(
  cd "$ROOT_DIR"
  python3 scripts/roadmap/project_capability_reports.py \
    --registry "$REGISTRY_REL" \
    --out-json "$OUT_JSON_REL" \
    --out-md "$OUT_MD_REL"
)

(
  cd "$ROOT_DIR"
  git diff --exit-code "$OUT_JSON_REL" "$OUT_MD_REL"
)

echo "capability registry checks passed"
