#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_FILE="$ROOT_DIR/tests/lean/sierra_aggregate_branch_typing.lean"
export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "missing aggregate branch typing test file: $TEST_FILE"
  exit 1
fi

(
  cd "$ROOT_DIR"
  lake env lean "$TEST_FILE"
)

echo "aggregate branch typing checks passed"
