#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ISSUE_DIR="$ROOT_DIR/roadmap/executable-issues"

TRACK=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --track)
      TRACK="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: $0 --track <primary|secondary>"
      exit 1
      ;;
  esac
done

if [[ "$TRACK" != "primary" && "$TRACK" != "secondary" ]]; then
  echo "usage: $0 --track <primary|secondary>"
  exit 1
fi

if [[ ! -d "$ISSUE_DIR" ]]; then
  echo "missing executable issues directory: $ISSUE_DIR"
  exit 1
fi

status_of_issue() {
  local issue_file="$1"
  grep -E '^[[:space:]]*-[[:space:]]+Overall status:[[:space:]]+(NOT DONE|DONE - [0-9a-f]{7,40})$' "$issue_file" \
    | head -n 1 \
    | sed -E 's/^[[:space:]]*-[[:space:]]+Overall status:[[:space:]]+//' || true
}

is_done() {
  local status="$1"
  [[ "$status" =~ ^DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]
}

FAILED=0
PASSED=0

report_pass() {
  local predicate="$1"
  local detail="$2"
  echo "PASS $predicate: $detail"
  PASSED=$((PASSED + 1))
}

report_fail() {
  local predicate="$1"
  local detail="$2"
  echo "FAIL $predicate: $detail"
  FAILED=$((FAILED + 1))
}

require_issue_done() {
  local predicate="$1"
  local rel_issue="$2"
  local issue_path="$ISSUE_DIR/$rel_issue"
  if [[ ! -f "$issue_path" ]]; then
    report_fail "$predicate" "missing issue file $rel_issue"
    return
  fi
  local status
  status="$(status_of_issue "$issue_path")"
  if is_done "$status"; then
    report_pass "$predicate" "$rel_issue is $status"
  else
    report_fail "$predicate" "$rel_issue is $status"
  fi
}

require_path_exists() {
  local predicate="$1"
  local rel_path="$2"
  local abs_path="$ROOT_DIR/$rel_path"
  if [[ -e "$abs_path" ]]; then
    report_pass "$predicate" "$rel_path exists"
  else
    report_fail "$predicate" "$rel_path missing"
  fi
}

if [[ "$TRACK" == "primary" ]]; then
  require_issue_done "P1.surface-closure" "01-canonical-upstream-surfaces.issue.md"
  require_issue_done "P2.architecture-closure" "02-target-compiler-architecture.issue.md"
  require_issue_done "P3.typed-ir-closure" "03-typed-ir-generalization-plan.issue.md"
  require_issue_done "P4.semantics-proof-closure" "04-semantics-proof-and-law-plan.issue.md"
  require_issue_done "P5.primary-function-track" "05-track-a-lean-to-sierra-functions.issue.md"
  require_issue_done "P6.low-level-optimization" "07-low-level-optimization-sierra-casm.issue.md"
  require_issue_done "P7.quality-gates" "08-quality-gates-bench-and-release.issue.md"
  require_path_exists "A1.proof-module" "src/LeanCairo/Compiler/Proof/OptimizeSound.lean"
  require_path_exists "A2.sierra-e2e-gate" "scripts/test/sierra_e2e.sh"
  require_path_exists "A3.failfast-gate" "scripts/test/sierra_failfast_unsupported.sh"
  require_path_exists "A4.benchmark-gate" "scripts/bench/check_optimizer_non_regression.sh"
  require_path_exists "A5.coverage-matrix" "roadmap/inventory/sierra-coverage-matrix.json"
else
  require_issue_done "S1.architecture-closure" "02-target-compiler-architecture.issue.md"
  require_issue_done "S2.typed-ir-closure" "03-typed-ir-generalization-plan.issue.md"
  require_issue_done "S3.semantics-proof-closure" "04-semantics-proof-and-law-plan.issue.md"
  require_issue_done "S4.secondary-function-track" "06-track-b-lean-to-cairo-functions.issue.md"
  require_issue_done "S5.quality-gates" "08-quality-gates-bench-and-release.issue.md"
  require_path_exists "B1.cairo-emitter" "src/LeanCairo/Backend/Cairo/EmitIRContract.lean"
  require_path_exists "B2.codegen-snapshot-gate" "scripts/test/codegen_snapshot.sh"
  require_path_exists "B3.diff-validation-gate" "scripts/test/e2e.sh"
fi

echo "completion contract summary: track=$TRACK pass=$PASSED fail=$FAILED"

if [[ "$FAILED" -ne 0 ]]; then
  exit 1
fi

exit 0
