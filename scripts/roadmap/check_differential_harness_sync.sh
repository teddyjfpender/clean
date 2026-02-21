#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/examples-manifest.json"
OUT_SCRIPT_REL="scripts/test/generated/run_manifest_differential.sh"
OUT_JSON_REL="generated/examples/differential-harness.json"

(
  cd "$ROOT_DIR"
  python3 scripts/examples/generate_differential_harness.py \
    --manifest "$MANIFEST_REL" \
    --out-script "$OUT_SCRIPT_REL" \
    --out-json "$OUT_JSON_REL"
  git diff --exit-code "$OUT_SCRIPT_REL" "$OUT_JSON_REL"
)

echo "differential harness sync checks passed"
