#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY_REL="roadmap/capabilities/registry.json"
SIERRA_OUT_REL="src/LeanCairo/Backend/Sierra/Generated/LoweringScaffold.lean"
CAIRO_OUT_REL="src/LeanCairo/Backend/Cairo/Generated/LoweringScaffold.lean"

(
  cd "$ROOT_DIR"
  python3 scripts/roadmap/generate_lowering_scaffolds.py \
    --registry "$REGISTRY_REL" \
    --out-sierra "$SIERRA_OUT_REL" \
    --out-cairo "$CAIRO_OUT_REL"
  git diff --exit-code "$SIERRA_OUT_REL" "$CAIRO_OUT_REL"
)

echo "lowering scaffold sync checks passed"
