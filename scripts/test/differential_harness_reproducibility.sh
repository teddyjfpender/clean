#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

python3 "$ROOT_DIR/scripts/examples/generate_differential_harness.py" \
  --manifest "$ROOT_DIR/config/examples-manifest.json" \
  --out-script "$TMP_A/run_manifest_differential.sh" \
  --out-json "$TMP_A/differential-harness.json"

python3 "$ROOT_DIR/scripts/examples/generate_differential_harness.py" \
  --manifest "$ROOT_DIR/config/examples-manifest.json" \
  --out-script "$TMP_B/run_manifest_differential.sh" \
  --out-json "$TMP_B/differential-harness.json"

diff -u "$TMP_A/run_manifest_differential.sh" "$TMP_B/run_manifest_differential.sh" >/dev/null
diff -u "$TMP_A/differential-harness.json" "$TMP_B/differential-harness.json" >/dev/null

echo "differential harness reproducibility checks passed"
