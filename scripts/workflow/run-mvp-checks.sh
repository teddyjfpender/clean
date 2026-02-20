#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/lint/pedantic.sh"
(
  cd "$ROOT_DIR"
  lake build
)
"$ROOT_DIR/scripts/test/codegen_snapshot.sh"
"$ROOT_DIR/scripts/test/e2e.sh"

echo "all MVP quality checks passed"
