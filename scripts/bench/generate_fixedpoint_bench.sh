#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_NAME="MyLeanFixedPointBench"
CODEGEN_DIR="$ROOT_DIR/.artifacts/bench/fixedpoint_lean_codegen"
BASELINE_DIR="$CODEGEN_DIR/baseline"
OPTIMIZED_DIR="$CODEGEN_DIR/optimized"
OUTPUT_PATH="$ROOT_DIR/packages/fixedpoint_bench/src/lib.cairo"

mkdir -p "$CODEGEN_DIR"
if [[ -d "$BASELINE_DIR" ]]; then
  rm -r "$BASELINE_DIR"
fi
if [[ -d "$OPTIMIZED_DIR" ]]; then
  rm -r "$OPTIMIZED_DIR"
fi

cd "$ROOT_DIR"
export PATH="$HOME/.elan/bin:$PATH"

lake build "$MODULE_NAME"

lake exe leancairo-gen \
  --module "$MODULE_NAME" \
  --out "$BASELINE_DIR" \
  --emit-casm false \
  --optimize false

lake exe leancairo-gen \
  --module "$MODULE_NAME" \
  --out "$OPTIMIZED_DIR" \
  --emit-casm false \
  --optimize true

python3 "$ROOT_DIR/scripts/bench/build_fixedpoint_bench_from_lean.py" \
  --baseline-lib "$BASELINE_DIR/src/lib.cairo" \
  --optimized-lib "$OPTIMIZED_DIR/src/lib.cairo" \
  --out "$OUTPUT_PATH"
