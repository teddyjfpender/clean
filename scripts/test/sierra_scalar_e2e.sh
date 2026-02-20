#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_scalar_e2e"
PROGRAM_JSON="$OUT_DIR/generated/sierra/program.sierra.json"
CASM_OUT="$OUT_DIR/generated/sierra/program.casm"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

(
  cd "$ROOT_DIR"
  lake exe leancairo-sierra-gen --module MyLeanSierraScalar --out "$OUT_DIR/generated" --optimize true
)

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  validate --input "$PROGRAM_JSON" >/dev/null

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  compile --input "$PROGRAM_JSON" --out-casm "$CASM_OUT" >/dev/null

test -s "$CASM_OUT"

echo "sierra scalar e2e (validate + compile) passed"
