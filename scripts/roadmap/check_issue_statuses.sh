#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ISSUE_DIR="$ROOT_DIR/roadmap/executable-issues"

if [[ ! -d "$ISSUE_DIR" ]]; then
  echo "missing executable issues directory: $ISSUE_DIR"
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  FIND_MATCHES="rg"
else
  FIND_MATCHES="grep"
fi

ISSUE_FILES="$(find "$ISSUE_DIR" -type f -name '*.issue.md' | sort)"
ISSUE_FILE_COUNT="$(printf '%s\n' "$ISSUE_FILES" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$ISSUE_FILE_COUNT" == "0" ]]; then
  echo "no issue files found under $ISSUE_DIR"
  exit 1
fi

ERRORS=0
DONE_COUNT=0
NOT_DONE_COUNT=0

validate_commit() {
  local commit_hash="$1"
  if ! git -C "$ROOT_DIR" cat-file -e "${commit_hash}^{commit}" 2>/dev/null; then
    echo "invalid commit reference in status: $commit_hash"
    ERRORS=$((ERRORS + 1))
  fi
}

run_match() {
  local pattern="$1"
  local file="$2"
  if [[ "$FIND_MATCHES" == "rg" ]]; then
    rg -n "$pattern" "$file" || true
  else
    grep -nE "$pattern" "$file" || true
  fi
}

line_count() {
  local text="$1"
  printf '%s\n' "$text" | sed '/^$/d' | wc -l | tr -d ' '
}

while IFS= read -r issue_file; do
  [[ -z "$issue_file" ]] && continue

  OVERALL_LINES="$(run_match '^[[:space:]]*-[[:space:]]+Overall status:' "$issue_file")"
  OVERALL_VALID="$(run_match '^[[:space:]]*-[[:space:]]+Overall status:[[:space:]]+(NOT DONE|DONE - [0-9a-f]{7,40})$' "$issue_file")"
  MILESTONE_LINES="$(run_match '^[[:space:]]*-[[:space:]]+Status:' "$issue_file")"
  MILESTONE_VALID="$(run_match '^[[:space:]]*-[[:space:]]+Status:[[:space:]]+(NOT DONE|DONE - [0-9a-f]{7,40})$' "$issue_file")"

  OVERALL_LINES_COUNT="$(line_count "$OVERALL_LINES")"
  OVERALL_VALID_COUNT="$(line_count "$OVERALL_VALID")"
  MILESTONE_LINES_COUNT="$(line_count "$MILESTONE_LINES")"
  MILESTONE_VALID_COUNT="$(line_count "$MILESTONE_VALID")"

  if [[ "$OVERALL_LINES_COUNT" -ne 1 ]]; then
    echo "expected exactly one overall status line in $issue_file"
    ERRORS=$((ERRORS + 1))
  fi

  if [[ "$OVERALL_LINES_COUNT" -ne "$OVERALL_VALID_COUNT" ]]; then
    echo "invalid overall status format in $issue_file"
    ERRORS=$((ERRORS + 1))
  fi

  if [[ "$MILESTONE_LINES_COUNT" -ne "$MILESTONE_VALID_COUNT" ]]; then
    echo "invalid milestone status format in $issue_file"
    ERRORS=$((ERRORS + 1))
  fi

  if [[ "$OVERALL_VALID_COUNT" -eq 1 ]]; then
    OVERALL_STATUS_LINE="$(printf '%s\n' "$OVERALL_VALID" | head -n 1)"
    OVERALL_STATUS="${OVERALL_STATUS_LINE#*:}"
    OVERALL_STATUS="${OVERALL_STATUS#- Overall status: }"
    OVERALL_STATUS="$(printf '%s' "$OVERALL_STATUS" | sed 's/^[[:space:]]*//')"

    if [[ "$OVERALL_STATUS" == "NOT DONE" ]]; then
      NOT_DONE_COUNT=$((NOT_DONE_COUNT + 1))
    elif [[ "$OVERALL_STATUS" =~ ^DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]; then
      DONE_COUNT=$((DONE_COUNT + 1))
      validate_commit "${BASH_REMATCH[1]}"
    fi
  fi

  while IFS= read -r status_line; do
    [[ -z "$status_line" ]] && continue
    status_text="${status_line#*:}"
    status_text="${status_text#- Status: }"
    status_text="$(printf '%s' "$status_text" | sed 's/^[[:space:]]*//')"
    if [[ "$status_text" =~ ^DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]; then
      validate_commit "${BASH_REMATCH[1]}"
    fi
  done <<<"$MILESTONE_VALID"
done <<<"$ISSUE_FILES"

if [[ "$ERRORS" -ne 0 ]]; then
  echo "executable issue status checks failed with $ERRORS error(s)"
  exit 1
fi

echo "executable issue status checks passed ($ISSUE_FILE_COUNT files: $DONE_COUNT done, $NOT_DONE_COUNT not done)"
