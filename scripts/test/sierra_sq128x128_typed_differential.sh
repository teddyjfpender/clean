#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_FILE="$ROOT_DIR/tests/lean/sierra_sq128x128_typed_differential.lean"
MODULE_NAME="sq128x128_u128.Example"
CONTRACT_NAME="SQ128x128TypedLaneContract"
export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "missing sq128 typed differential test file: $TEST_FILE"
  exit 1
fi

(
  cd "$ROOT_DIR"
  lake build LeanCairo.Compiler.Semantics.Eval sq128x128_u128
  lake env lean "$TEST_FILE"
)

"$ROOT_DIR/scripts/test/run_backend_parity_case.sh" \
  "$MODULE_NAME" \
  "$CONTRACT_NAME" \
  "sq128x128 typed differential"

echo "sierra sq128 typed differential checks passed"
