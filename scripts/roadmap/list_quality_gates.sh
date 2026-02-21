#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_FILES=(
  "$ROOT_DIR/scripts/workflow/run-sierra-checks.sh"
  "$ROOT_DIR/scripts/workflow/run-mvp-checks.sh"
  "$ROOT_DIR/scripts/workflow/run-release-candidate-checks.sh"
)
MANDATORY_GATES=(
  "scripts/lint/pedantic.sh"
  "scripts/roadmap/check_issue_statuses.sh"
  "scripts/roadmap/check_issue_dependencies.sh"
  "scripts/roadmap/check_milestone_dependencies.py"
  "scripts/roadmap/check_issue_evidence.sh"
  "scripts/roadmap/check_pin_consistency.sh"
  "scripts/roadmap/check_inventory_reproducibility.sh"
  "scripts/roadmap/check_inventory_freshness.sh"
  "scripts/roadmap/check_capability_registry.sh"
  "scripts/roadmap/check_capability_projection_usage.sh"
  "scripts/roadmap/check_capability_closure_slo.sh"
  "scripts/roadmap/check_mir_family_contract.sh"
  "scripts/roadmap/check_lowering_scaffold_sync.sh"
  "scripts/roadmap/check_corelib_parity_freshness.sh"
  "scripts/roadmap/check_crate_dependency_matrix_freshness.sh"
  "scripts/roadmap/check_coverage_matrix_freshness.sh"
  "scripts/roadmap/check_sierra_coverage_report_freshness.sh"
  "scripts/roadmap/check_subset_ledger_sync.py"
  "scripts/roadmap/check_risk_controls.sh"
  "scripts/roadmap/check_release_reports_freshness.sh"
  "scripts/test/sierra_e2e.sh"
  "scripts/test/sierra_scalar_e2e.sh"
  "scripts/test/sierra_u128_range_checked_e2e.sh"
  "scripts/test/sierra_differential.sh"
  "scripts/test/sierra_u128_wrapping_differential.sh"
  "scripts/test/backend_parity.sh"
  "scripts/test/optimizer_pass_regression.sh"
  "scripts/test/capability_registry_negative.sh"
  "scripts/test/capability_closure_slo_negative.sh"
  "scripts/test/mir_family_contract_negative.sh"
  "scripts/test/lowering_scaffold_reproducibility.sh"
  "scripts/test/lowering_scaffold_sync_negative.sh"
  "scripts/test/sierra_failfast_unsupported.sh"
  "scripts/bench/check_optimizer_non_regression.sh"
  "scripts/bench/check_optimizer_family_thresholds.sh"
)

VALIDATE=0
if [[ "${1:-}" == "--validate-workflows" ]]; then
  VALIDATE=1
fi

echo "quality gate inventory (${#MANDATORY_GATES[@]} total):"
for gate in "${MANDATORY_GATES[@]}"; do
  echo "- $gate"
done

if [[ "$VALIDATE" -ne 1 ]]; then
  exit 0
fi

ERRORS=0
for gate in "${MANDATORY_GATES[@]}"; do
  if [[ ! -e "$ROOT_DIR/$gate" ]]; then
    echo "missing mandatory gate artifact: $gate"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  FOUND=0
  for workflow in "${WORKFLOW_FILES[@]}"; do
    if [[ ! -f "$workflow" ]]; then
      echo "missing workflow script: ${workflow#"$ROOT_DIR"/}"
      ERRORS=$((ERRORS + 1))
      continue
    fi
    if rg -q --fixed-strings "$gate" "$workflow"; then
      FOUND=1
      break
    fi
  done

  if [[ "$FOUND" -ne 1 ]]; then
    echo "mandatory gate is not referenced by any workflow: $gate"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ "$ERRORS" -ne 0 ]]; then
  echo "quality gate validation failed with $ERRORS error(s)"
  exit 1
fi

echo "quality gate validation passed"
