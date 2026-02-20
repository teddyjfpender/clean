#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/.elan/bin:$PATH"

"$ROOT_DIR/scripts/lint/pedantic.sh"
(
  cd "$ROOT_DIR"
  lake build
)
"$ROOT_DIR/scripts/test/codegen_snapshot.sh"
"$ROOT_DIR/scripts/test/e2e.sh"
"$ROOT_DIR/scripts/bench/check_optimizer_non_regression.sh"
"$ROOT_DIR/scripts/bench/check_optimizer_non_regression.sh" MyLeanContractCSEBench CSEBenchContract
"$ROOT_DIR/scripts/bench/check_artifact_passes.sh"

echo "all MVP quality checks passed"
