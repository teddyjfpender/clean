#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/roadmap/check_issue_statuses.sh"
"$ROOT_DIR/scripts/roadmap/check_issue_dependencies.sh"
"$ROOT_DIR/scripts/roadmap/check_issue_evidence.sh"
"$ROOT_DIR/scripts/roadmap/check_architecture_boundaries.sh"
"$ROOT_DIR/scripts/test/architecture_boundaries.sh"
"$ROOT_DIR/scripts/test/sierra_primary_cairo_coupling_guard.sh"
"$ROOT_DIR/scripts/test/sierra_primary_without_cairo.sh"
"$ROOT_DIR/scripts/roadmap/check_pin_consistency.sh"
"$ROOT_DIR/scripts/roadmap/check_inventory_freshness.sh"
"$ROOT_DIR/scripts/roadmap/check_coverage_matrix_freshness.sh"
"$ROOT_DIR/scripts/roadmap/check_effect_isolation.sh"
"$ROOT_DIR/scripts/test/type_universe_regression.sh"
"$ROOT_DIR/scripts/test/effect_resource_regression.sh"
"$ROOT_DIR/scripts/test/sierra_surface_codegen.sh"
"$ROOT_DIR/scripts/test/sierra_codegen_snapshot.sh"
"$ROOT_DIR/scripts/test/deterministic_codegen.sh"
"$ROOT_DIR/scripts/test/sierra_hash_policy.sh"
"$ROOT_DIR/scripts/roadmap/check_failfast_policy_lock.sh"
"$ROOT_DIR/scripts/test/sierra_e2e.sh"

echo "all Sierra pipeline checks passed"
