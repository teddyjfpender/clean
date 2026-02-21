#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GEN="$ROOT_DIR/scripts/bench/generate_cost_model_calibration.py"
CHECK="$ROOT_DIR/scripts/bench/check_cost_model_calibration_thresholds.py"
SUMMARY="$ROOT_DIR/generated/examples/benchmark-summary.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$GEN" --summary "$SUMMARY" --out-json "$TMP_DIR/calibration.json" --out-md "$TMP_DIR/calibration.md" >/dev/null

STRICT="$TMP_DIR/strict-thresholds.json"
cat > "$STRICT" <<'JSON'
{
  "version": 1,
  "global": {
    "min_case_count": 999,
    "max_mean_abs_pct_error": 0.0,
    "max_max_abs_pct_error": 0.0
  }
}
JSON

if python3 "$CHECK" --calibration "$TMP_DIR/calibration.json" --thresholds "$STRICT" >"$TMP_DIR/negative.log" 2>&1; then
  echo "expected cost model calibration threshold checker to fail for strict thresholds"
  exit 1
fi

if ! rg -q "case_count below threshold" "$TMP_DIR/negative.log"; then
  echo "strict-threshold diagnostic was not reported"
  cat "$TMP_DIR/negative.log"
  exit 1
fi

echo "cost model calibration negative checks passed"
