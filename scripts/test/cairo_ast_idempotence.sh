#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_FILE="$ROOT_DIR/tests/lean/cairo_ast_idempotence.lean"
export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "missing Cairo AST idempotence test file: $TEST_FILE"
  exit 1
fi

(
  cd "$ROOT_DIR"
  lake build LeanCairo.Backend.Cairo.EmitIRFunction
  lake env lean "$TEST_FILE"
)

echo "cairo AST idempotence checks passed"
