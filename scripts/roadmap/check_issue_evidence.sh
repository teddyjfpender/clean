#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ISSUE_DIR="$ROOT_DIR/roadmap/executable-issues"

if [[ ! -d "$ISSUE_DIR" ]]; then
  echo "missing executable issues directory: $ISSUE_DIR"
  exit 1
fi

ERRORS=0

extract_backtick_values() {
  local line="$1"
  awk -F'`' '{ for (i = 2; i <= NF; i += 2) print $i }' <<< "$line"
}

validate_path_ref() {
  local ref="$1"
  local context="$2"
  if [[ "$ref" == "N/A" ]]; then
    return 0
  fi
  local rel_path="$ref"
  if [[ "$rel_path" == ./* ]]; then
    rel_path="${rel_path#./}"
  fi
  if [[ ! -e "$ROOT_DIR/$rel_path" ]]; then
    echo "evidence path missing ($context): $ref"
    ERRORS=$((ERRORS + 1))
  fi
}

validate_command_ref() {
  local cmd="$1"
  local context="$2"
  local first_token
  first_token="$(awk '{print $1}' <<< "$cmd")"
  if [[ -z "$first_token" ]]; then
    echo "empty evidence command ($context)"
    ERRORS=$((ERRORS + 1))
    return
  fi

  if [[ "$first_token" == "python3" || "$first_token" == "bash" || "$first_token" == "sh" ]]; then
    local remainder
    remainder="$(sed -E 's/^[^[:space:]]+[[:space:]]+//' <<< "$cmd")"
    first_token="$(awk '{print $1}' <<< "$remainder")"
  fi

  if [[ "$first_token" == ./* ]]; then
    first_token="${first_token#./}"
  fi

  if [[ "$first_token" == */* ]]; then
    if [[ ! -e "$ROOT_DIR/$first_token" ]]; then
      echo "evidence command path missing ($context): $first_token"
      ERRORS=$((ERRORS + 1))
    fi
  fi
}

validate_evidence_line() {
  local line="$1"
  local mode="$2"
  local context="$3"

  local refs
  refs="$(extract_backtick_values "$line")"
  if [[ -z "$(printf '%s\n' "$refs" | sed '/^$/d')" ]]; then
    echo "missing backtick evidence references ($context)"
    ERRORS=$((ERRORS + 1))
    return
  fi

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    if [[ "$mode" == "proof" ]]; then
      validate_path_ref "$ref" "$context"
    else
      validate_command_ref "$ref" "$context"
    fi
  done <<< "$refs"
}

check_overall_evidence() {
  local issue_file="$1"

  local overall_done_line
  overall_done_line="$(grep -E '^[[:space:]]*-[[:space:]]+Overall status:[[:space:]]+DONE - [0-9a-f]{7,40}$' "$issue_file" | head -n 1 || true)"
  if [[ -z "$overall_done_line" ]]; then
    return
  fi

  local tests_line proofs_line
  tests_line="$(grep -E '^[[:space:]]*-[[:space:]]+Completion evidence tests:' "$issue_file" | head -n 1 || true)"
  proofs_line="$(grep -E '^[[:space:]]*-[[:space:]]+Completion evidence proofs:' "$issue_file" | head -n 1 || true)"

  if [[ -z "$tests_line" ]]; then
    echo "missing completion evidence tests line in $issue_file"
    ERRORS=$((ERRORS + 1))
  else
    validate_evidence_line "$tests_line" "test" "$issue_file overall"
  fi

  if [[ -z "$proofs_line" ]]; then
    echo "missing completion evidence proofs line in $issue_file"
    ERRORS=$((ERRORS + 1))
  else
    validate_evidence_line "$proofs_line" "proof" "$issue_file overall"
  fi
}

check_milestone_evidence() {
  local issue_file="$1"
  local current_milestone=""
  local milestone_done=0
  local tests_line=""
  local proofs_line=""

  flush_milestone() {
    if [[ -z "$current_milestone" || "$milestone_done" -eq 0 ]]; then
      return
    fi

    local context="$issue_file $current_milestone"
    if [[ -z "$tests_line" ]]; then
      echo "missing evidence tests line for DONE milestone ($context)"
      ERRORS=$((ERRORS + 1))
    else
      validate_evidence_line "$tests_line" "test" "$context"
    fi
    if [[ -z "$proofs_line" ]]; then
      echo "missing evidence proofs line for DONE milestone ($context)"
      ERRORS=$((ERRORS + 1))
    else
      validate_evidence_line "$proofs_line" "proof" "$context"
    fi
  }

  while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+([^:]+): ]]; then
      flush_milestone
      current_milestone="${BASH_REMATCH[1]}"
      milestone_done=0
      tests_line=""
      proofs_line=""
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+Status:[[:space:]]+DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]; then
      milestone_done=1
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+Evidence[[:space:]]tests: ]]; then
      tests_line="$line"
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+Evidence[[:space:]]proofs: ]]; then
      proofs_line="$line"
      continue
    fi
  done < "$issue_file"

  flush_milestone
}

ISSUE_FILES="$(find "$ISSUE_DIR" -type f -name '*.issue.md' | sort)"
while IFS= read -r issue_file; do
  [[ -z "$issue_file" ]] && continue
  check_overall_evidence "$issue_file"
  check_milestone_evidence "$issue_file"
done <<< "$ISSUE_FILES"

if [[ "$ERRORS" -ne 0 ]]; then
  echo "executable issue evidence checks failed with $ERRORS error(s)"
  exit 1
fi

echo "executable issue evidence checks passed"
