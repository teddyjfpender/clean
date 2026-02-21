#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY_REL="roadmap/capabilities/registry.json"
OBLIGATIONS_REL="roadmap/capabilities/obligations.json"
OUT_JSON_REL="roadmap/inventory/capability-obligation-report.json"
OUT_MD_REL="roadmap/inventory/capability-obligation-report.md"

python3 "$ROOT_DIR/scripts/roadmap/validate_capability_obligations.py" \
  --registry "$ROOT_DIR/$REGISTRY_REL" \
  --obligations "$ROOT_DIR/$OBLIGATIONS_REL"

(
  cd "$ROOT_DIR"
  python3 scripts/roadmap/project_capability_obligations.py \
    --registry "$REGISTRY_REL" \
    --obligations "$OBLIGATIONS_REL" \
    --out-json "$OUT_JSON_REL" \
    --out-md "$OUT_MD_REL"
  git diff --exit-code "$OUT_JSON_REL" "$OUT_MD_REL"
)

echo "capability obligation checks passed"
