#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_NAME="${1:-MyLeanContract}"
CONTRACT_NAME="${2:-HelloContract}"
INLINE_STRATEGY="${3:-default}"
MAX_REGRESSION_PCT="${4:-0}"
MODULE_SAFE_NAME="$(printf '%s' "$MODULE_NAME" | tr -c 'A-Za-z0-9_' '_')"
OUT_BASE="$ROOT_DIR/.artifacts/bench/$MODULE_SAFE_NAME"
BASELINE_DIR="$OUT_BASE/baseline"
OPTIMIZED_DIR="$OUT_BASE/optimized"

rm -rf "$BASELINE_DIR" "$OPTIMIZED_DIR"
mkdir -p "$OUT_BASE"

cd "$ROOT_DIR"
export PATH="$HOME/.elan/bin:$PATH"

lake exe leancairo-gen --module "$MODULE_NAME" --out "$BASELINE_DIR" --emit-casm true --optimize false --inlining-strategy "$INLINE_STRATEGY"
lake exe leancairo-gen --module "$MODULE_NAME" --out "$OPTIMIZED_DIR" --emit-casm true --optimize true --inlining-strategy "$INLINE_STRATEGY"

(
  cd "$BASELINE_DIR"
  scarb build
)
(
  cd "$OPTIMIZED_DIR"
  scarb build
)

baseline_index="$(find "$BASELINE_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
optimized_index="$(find "$OPTIMIZED_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"

baseline_metrics="$(python3 "$ROOT_DIR/scripts/bench/compute_sierra_cost.py" --index "$baseline_index" --contract-name "$CONTRACT_NAME")"
optimized_metrics="$(python3 "$ROOT_DIR/scripts/bench/compute_sierra_cost.py" --index "$optimized_index" --contract-name "$CONTRACT_NAME")"

baseline_score="$(printf '%s' "$baseline_metrics" | python3 -c 'import json,sys; print(json.load(sys.stdin)["score"])')"
optimized_score="$(printf '%s' "$optimized_metrics" | python3 -c 'import json,sys; print(json.load(sys.stdin)["score"])')"

echo "Benchmark target: module=$MODULE_NAME contract=$CONTRACT_NAME inlining=$INLINE_STRATEGY"
echo "Baseline metrics:"
echo "$baseline_metrics"
echo "Optimized metrics:"
echo "$optimized_metrics"

if (( optimized_score > baseline_score )); then
  if ! python3 - "$baseline_score" "$optimized_score" "$MAX_REGRESSION_PCT" <<'PY'
import math
import sys

baseline = int(sys.argv[1])
optimized = int(sys.argv[2])
max_regression_pct = float(sys.argv[3])
allowed = math.floor(baseline * (1.0 + (max_regression_pct / 100.0)))
if optimized <= allowed:
    sys.exit(0)
print(
    f"optimizer regression: optimized score ({optimized}) exceeds allowed "
    f"threshold ({allowed}) derived from baseline ({baseline}) and "
    f"max regression pct ({max_regression_pct})",
    file=sys.stderr,
)
sys.exit(1)
PY
  then
    exit 1
  fi
fi

echo "optimizer non-regression passed: optimized score ($optimized_score) <= allowed threshold [baseline=$baseline_score max_regression_pct=$MAX_REGRESSION_PCT module=$MODULE_NAME contract=$CONTRACT_NAME inlining-strategy=$INLINE_STRATEGY]"
