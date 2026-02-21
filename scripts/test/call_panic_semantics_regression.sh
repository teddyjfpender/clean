#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_FILE="$ROOT_DIR/tests/lean/call_panic_semantics_regression.lean"
export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "missing call/panic semantics regression test file: $TEST_FILE"
  exit 1
fi

(
  cd "$ROOT_DIR"
  lake build LeanCairo.Backend.Sierra.Generated.LoweringScaffold LeanCairo.Backend.Cairo.Generated.LoweringScaffold LeanCairo.Compiler.Semantics.Eval
  lake env lean "$TEST_FILE"
)

echo "call/panic semantics regression checks passed"
