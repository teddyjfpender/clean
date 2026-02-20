#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_FILE="$ROOT_DIR/tests/lean/eval_integer_width_semantics.lean"
export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "missing eval integer width semantics test file: $TEST_FILE"
  exit 1
fi

(
  cd "$ROOT_DIR"
  lake build LeanCairo.Compiler.Semantics.Eval
  lake env lean "$TEST_FILE"
)

echo "eval integer width semantics checks passed"
