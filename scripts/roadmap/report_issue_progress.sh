#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ISSUE_DIR="$ROOT_DIR/roadmap/executable-issues"

if [[ ! -d "$ISSUE_DIR" ]]; then
  echo "missing executable issues directory: $ISSUE_DIR"
  exit 1
fi

ISSUE_FILES="$(find "$ISSUE_DIR" -type f -name '*.issue.md' | sort)"
ISSUE_FILE_COUNT="$(printf '%s\n' "$ISSUE_FILES" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$ISSUE_FILE_COUNT" == "0" ]]; then
  echo "no issue files found"
  exit 1
fi

extract_overall_status() {
  local issue_file="$1"
  local line
  line="$(grep -E '^[[:space:]]*-[[:space:]]+Overall status:[[:space:]]+(NOT DONE|DONE - [0-9a-f]{7,40})$' "$issue_file" | head -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo "INVALID"
    return
  fi
  line="${line#*- Overall status: }"
  echo "$line"
}

DONE_COUNT=0
NOT_DONE_COUNT=0
INVALID_COUNT=0
MILESTONE_DONE=0
MILESTONE_NOT_DONE=0
MILESTONE_INVALID=0

while IFS= read -r issue_file; do
  [[ -z "$issue_file" ]] && continue
  status="$(extract_overall_status "$issue_file")"
  if [[ "$status" == "NOT DONE" ]]; then
    NOT_DONE_COUNT=$((NOT_DONE_COUNT + 1))
  elif [[ "$status" =~ ^DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]; then
    DONE_COUNT=$((DONE_COUNT + 1))
  else
    INVALID_COUNT=$((INVALID_COUNT + 1))
  fi

  while IFS= read -r milestone_line; do
    [[ -z "$milestone_line" ]] && continue
    milestone_status="${milestone_line#*- Status: }"
    milestone_status="$(printf '%s' "$milestone_status" | sed 's/^[[:space:]]*//')"
    if [[ "$milestone_status" == "NOT DONE" ]]; then
      MILESTONE_NOT_DONE=$((MILESTONE_NOT_DONE + 1))
    elif [[ "$milestone_status" =~ ^DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]; then
      MILESTONE_DONE=$((MILESTONE_DONE + 1))
    else
      MILESTONE_INVALID=$((MILESTONE_INVALID + 1))
    fi
  done < <(grep -E '^[[:space:]]*-[[:space:]]+Status:' "$issue_file" || true)
done <<<"$ISSUE_FILES"

HEAD_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"

printf '%s\n' "# Executable Issue Progress Report"
printf '%s\n' ""
printf -- "- Repository commit: %s\n" "$HEAD_COMMIT"
printf -- "- Issue files: %s\n" "$ISSUE_FILE_COUNT"
printf -- "- Overall statuses: %s done, %s not done, %s invalid\n" "$DONE_COUNT" "$NOT_DONE_COUNT" "$INVALID_COUNT"
printf -- "- Milestone statuses: %s done, %s not done, %s invalid\n" "$MILESTONE_DONE" "$MILESTONE_NOT_DONE" "$MILESTONE_INVALID"
printf '%s\n' ""
printf '%s\n' "## Issue Statuses"
printf '%s\n' ""
printf '%s\n' "| Issue file | Overall status |"
printf '%s\n' "| --- | --- |"

while IFS= read -r issue_file; do
  [[ -z "$issue_file" ]] && continue
  rel_path="${issue_file#"$ROOT_DIR/"}"
  status="$(extract_overall_status "$issue_file")"
  printf -- "| %s | %s |\n" "$rel_path" "$status"
done <<<"$ISSUE_FILES"
