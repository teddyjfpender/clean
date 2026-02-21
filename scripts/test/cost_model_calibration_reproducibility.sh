#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUMMARY_REL="generated/examples/benchmark-summary.json"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

(
  cd "$ROOT_DIR"
  python3 scripts/bench/generate_cost_model_calibration.py \
    --summary "$SUMMARY_REL" \
    --out-json "$TMP_A/calibration.json" \
    --out-md "$TMP_A/calibration.md"
  python3 scripts/bench/generate_cost_model_calibration.py \
    --summary "$SUMMARY_REL" \
    --out-json "$TMP_B/calibration.json" \
    --out-md "$TMP_B/calibration.md"
)

diff -u "$TMP_A/calibration.json" "$TMP_B/calibration.json" >/dev/null
diff -u "$TMP_A/calibration.md" "$TMP_B/calibration.md" >/dev/null

echo "cost model calibration reproducibility checks passed"
