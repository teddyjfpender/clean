#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_structural_optimization"
BASE_PROGRAM="$OUT_DIR/generated/sierra/program.sierra.json"
OPT_PROGRAM="$OUT_DIR/generated/sierra/program.optimized.sierra.json"
BASE_CASM="$OUT_DIR/generated/sierra/program.casm"
OPT_CASM="$OUT_DIR/generated/sierra/program.optimized.casm"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

cd "$ROOT_DIR"
lake exe leancairo-sierra-gen --module MyLeanSierraSubset --out "$OUT_DIR/generated" --optimize true

python3 "$ROOT_DIR/scripts/sierra/optimize_structural.py" --input "$BASE_PROGRAM" --out "$OPT_PROGRAM"

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  validate --input "$BASE_PROGRAM" >/dev/null
cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  compile --input "$BASE_PROGRAM" --out-casm "$BASE_CASM" >/dev/null

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  validate --input "$OPT_PROGRAM" >/dev/null
cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  compile --input "$OPT_PROGRAM" --out-casm "$OPT_CASM" >/dev/null

test -s "$BASE_CASM"
test -s "$OPT_CASM"

echo "sierra structural optimization e2e checks passed"
