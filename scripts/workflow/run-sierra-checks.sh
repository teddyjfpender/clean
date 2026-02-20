#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/test/sierra_surface_codegen.sh"
"$ROOT_DIR/scripts/test/sierra_codegen_snapshot.sh"
"$ROOT_DIR/scripts/test/sierra_failfast_unsupported.sh"
"$ROOT_DIR/scripts/test/sierra_e2e.sh"

echo "all Sierra pipeline checks passed"
