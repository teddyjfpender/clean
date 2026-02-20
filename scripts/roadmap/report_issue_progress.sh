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

track_for_issue() {
  local issue_file="$1"
  local rel_path="${issue_file#"$ROOT_DIR/"}"
  local base_name
  base_name="$(basename "$issue_file")"
  if [[ "$rel_path" == roadmap/executable-issues/inventory/* ]]; then
    echo "inventory"
  elif [[ "$base_name" == 05-* ]]; then
    echo "track-a"
  elif [[ "$base_name" == 06-* ]]; then
    echo "track-b"
  elif [[ "$base_name" == 07-* ]]; then
    echo "optimize"
  elif [[ "$base_name" == 08-* ]]; then
    echo "quality"
  elif [[ "$base_name" == 09-* || "$base_name" == 10-* || "$base_name" == "README.issue.md" ]]; then
    echo "governance"
  else
    echo "core"
  fi
}

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

TRACKS=(core track-a track-b optimize quality governance inventory)

track_key() {
  local track="$1"
  printf '%s' "${track//-/_}"
}

init_counter() {
  local prefix="$1"
  local track="$2"
  local key
  key="$(track_key "$track")"
  eval "${prefix}_${key}=0"
}

inc_counter() {
  local prefix="$1"
  local track="$2"
  local key
  key="$(track_key "$track")"
  eval "${prefix}_${key}=\$(( ${prefix}_${key} + 1 ))"
}

get_counter() {
  local prefix="$1"
  local track="$2"
  local key
  key="$(track_key "$track")"
  eval "printf '%s' \"\${${prefix}_${key}}\""
}

for track in "${TRACKS[@]}"; do
  init_counter "TRACK_ISSUE_DONE" "$track"
  init_counter "TRACK_ISSUE_NOT_DONE" "$track"
  init_counter "TRACK_ISSUE_INVALID" "$track"
  init_counter "TRACK_MILESTONE_DONE" "$track"
  init_counter "TRACK_MILESTONE_NOT_DONE" "$track"
  init_counter "TRACK_MILESTONE_INVALID" "$track"
done

while IFS= read -r issue_file; do
  [[ -z "$issue_file" ]] && continue
  track="$(track_for_issue "$issue_file")"
  status="$(extract_overall_status "$issue_file")"
  if [[ "$status" == "NOT DONE" ]]; then
    NOT_DONE_COUNT=$((NOT_DONE_COUNT + 1))
    inc_counter "TRACK_ISSUE_NOT_DONE" "$track"
  elif [[ "$status" =~ ^DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]; then
    DONE_COUNT=$((DONE_COUNT + 1))
    inc_counter "TRACK_ISSUE_DONE" "$track"
  else
    INVALID_COUNT=$((INVALID_COUNT + 1))
    inc_counter "TRACK_ISSUE_INVALID" "$track"
  fi

  while IFS= read -r milestone_line; do
    [[ -z "$milestone_line" ]] && continue
    milestone_status="${milestone_line#*- Status: }"
    milestone_status="$(printf '%s' "$milestone_status" | sed 's/^[[:space:]]*//')"
    if [[ "$milestone_status" == "NOT DONE" ]]; then
      MILESTONE_NOT_DONE=$((MILESTONE_NOT_DONE + 1))
      inc_counter "TRACK_MILESTONE_NOT_DONE" "$track"
    elif [[ "$milestone_status" =~ ^DONE[[:space:]]-[[:space:]]([0-9a-f]{7,40})$ ]]; then
      MILESTONE_DONE=$((MILESTONE_DONE + 1))
      inc_counter "TRACK_MILESTONE_DONE" "$track"
    else
      MILESTONE_INVALID=$((MILESTONE_INVALID + 1))
      inc_counter "TRACK_MILESTONE_INVALID" "$track"
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
printf '%s\n' "## Track Totals"
printf '%s\n' ""
printf '%s\n' "| Track | Issues done | Issues not done | Issues invalid | Milestones done | Milestones not done | Milestones invalid |"
printf '%s\n' "| --- | --- | --- | --- | --- | --- | --- |"
for track in "${TRACKS[@]}"; do
  issue_done="$(get_counter "TRACK_ISSUE_DONE" "$track")"
  issue_not_done="$(get_counter "TRACK_ISSUE_NOT_DONE" "$track")"
  issue_invalid="$(get_counter "TRACK_ISSUE_INVALID" "$track")"
  milestone_done="$(get_counter "TRACK_MILESTONE_DONE" "$track")"
  milestone_not_done="$(get_counter "TRACK_MILESTONE_NOT_DONE" "$track")"
  milestone_invalid="$(get_counter "TRACK_MILESTONE_INVALID" "$track")"
  printf -- "| %s | %s | %s | %s | %s | %s | %s |\n" \
    "$track" \
    "$issue_done" \
    "$issue_not_done" \
    "$issue_invalid" \
    "$milestone_done" \
    "$milestone_not_done" \
    "$milestone_invalid"
done
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
