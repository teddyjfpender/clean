#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ISSUE_DIR="$ROOT_DIR/roadmap/executable-issues"

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

# Dependencies are expressed as: issue -> required completed issues.
deps_for_issue() {
  local rel_issue="$1"
  case "$rel_issue" in
    02-target-compiler-architecture.issue.md)
      echo "00-charter-and-completion-definition.issue.md 01-canonical-upstream-surfaces.issue.md"
      ;;
    03-typed-ir-generalization-plan.issue.md)
      echo "02-target-compiler-architecture.issue.md"
      ;;
    04-semantics-proof-and-law-plan.issue.md)
      echo "03-typed-ir-generalization-plan.issue.md"
      ;;
    05-track-a-lean-to-sierra-functions.issue.md)
      echo "01-canonical-upstream-surfaces.issue.md 02-target-compiler-architecture.issue.md 03-typed-ir-generalization-plan.issue.md 04-semantics-proof-and-law-plan.issue.md"
      ;;
    06-track-b-lean-to-cairo-functions.issue.md)
      echo "02-target-compiler-architecture.issue.md 03-typed-ir-generalization-plan.issue.md 04-semantics-proof-and-law-plan.issue.md"
      ;;
    07-low-level-optimization-sierra-casm.issue.md)
      echo "03-typed-ir-generalization-plan.issue.md 04-semantics-proof-and-law-plan.issue.md 05-track-a-lean-to-sierra-functions.issue.md"
      ;;
    08-quality-gates-bench-and-release.issue.md)
      echo "04-semantics-proof-and-law-plan.issue.md 05-track-a-lean-to-sierra-functions.issue.md 06-track-b-lean-to-cairo-functions.issue.md 07-low-level-optimization-sierra-casm.issue.md"
      ;;
    09-milestones-and-execution-order.issue.md)
      echo "00-charter-and-completion-definition.issue.md"
      ;;
    10-risk-register-and-mitigations.issue.md)
      echo "00-charter-and-completion-definition.issue.md 08-quality-gates-bench-and-release.issue.md"
      ;;
    inventory/README.issue.md)
      echo "01-canonical-upstream-surfaces.issue.md"
      ;;
    inventory/corelib-src-inventory.issue.md)
      echo "inventory/README.issue.md"
      ;;
    inventory/sierra-extensions-inventory.issue.md)
      echo "inventory/README.issue.md"
      ;;
    inventory/compiler-crates-inventory.issue.md)
      echo "inventory/README.issue.md"
      ;;
    *)
      echo ""
      ;;
  esac
}

ERRORS=0

ISSUE_FILES="$(find "$ISSUE_DIR" -type f -name '*.issue.md' | sort)"
while IFS= read -r issue_file; do
  [[ -z "$issue_file" ]] && continue
  rel_issue="${issue_file#"$ISSUE_DIR/"}"
  issue_status="$(status_of_issue "$issue_file")"

  if ! is_done "$issue_status"; then
    continue
  fi

  deps="$(deps_for_issue "$rel_issue")"
  for dep in $deps; do
    dep_file="$ISSUE_DIR/$dep"
    if [[ ! -f "$dep_file" ]]; then
      echo "dependency file missing for $rel_issue: $dep"
      ERRORS=$((ERRORS + 1))
      continue
    fi
    dep_status="$(status_of_issue "$dep_file")"
    if ! is_done "$dep_status"; then
      echo "dependency violation: $rel_issue is done but dependency $dep is not done"
      ERRORS=$((ERRORS + 1))
    fi
  done
done <<<"$ISSUE_FILES"

if [[ "$ERRORS" -ne 0 ]]; then
  echo "executable issue dependency checks failed with $ERRORS error(s)"
  exit 1
fi

echo "executable issue dependency checks passed"
