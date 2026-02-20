#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_FILE="$ROOT_DIR/tests/lean/optimizer_pipeline_regression.lean"
export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "missing optimizer regression test file: $TEST_FILE"
  exit 1
fi

(
  cd "$ROOT_DIR"
  lake build LeanCairo.Compiler.Optimize.Pipeline LeanCairo.Compiler.Optimize.IRSpec
  lake build LeanCairo.Compiler.Proof.OptimizeSound LeanCairo.Compiler.Proof.CSELetNormSound
  lake env lean "$TEST_FILE"
)

echo "optimizer pass regression checks passed"
