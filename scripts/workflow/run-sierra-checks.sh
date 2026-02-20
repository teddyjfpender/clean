#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/roadmap/check_issue_statuses.sh"
"$ROOT_DIR/scripts/roadmap/check_issue_dependencies.sh"
"$ROOT_DIR/scripts/roadmap/check_architecture_boundaries.sh"
"$ROOT_DIR/scripts/test/architecture_boundaries.sh"
"$ROOT_DIR/scripts/roadmap/check_pin_consistency.sh"
"$ROOT_DIR/scripts/roadmap/check_inventory_freshness.sh"
"$ROOT_DIR/scripts/roadmap/check_coverage_matrix_freshness.sh"
"$ROOT_DIR/scripts/test/sierra_surface_codegen.sh"
"$ROOT_DIR/scripts/test/sierra_codegen_snapshot.sh"
"$ROOT_DIR/scripts/test/sierra_failfast_unsupported.sh"
"$ROOT_DIR/scripts/test/sierra_e2e.sh"

echo "all Sierra pipeline checks passed"
