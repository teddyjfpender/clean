#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_milestone_dependencies.py"
LOG_FILE="$(mktemp -t leancairo_milestone_deps_negative.XXXXXX.log)"
ISSUE25_FILE="$ROOT_DIR/roadmap/executable-issues/25-full-function-compiler-completion-matrix.issue.md"
ISSUE25_BACKUP="$(mktemp -t leancairo_issue25_backup.XXXXXX.md)"

cleanup() {
  rm -f "$LOG_FILE"
  if [[ -f "$ISSUE25_BACKUP" ]]; then
    cp "$ISSUE25_BACKUP" "$ISSUE25_FILE"
    rm -f "$ISSUE25_BACKUP"
  fi
}
trap cleanup EXIT

if "$CHECKER" --validate-dag --extra-edge "M-01-1:M-01-3" >"$LOG_FILE" 2>&1; then
  echo "expected milestone checker to fail when cycle is introduced"
  exit 1
fi

if ! grep -q "cycle" "$LOG_FILE"; then
  echo "cycle injection failed without cycle diagnostic"
  cat "$LOG_FILE"
  exit 1
fi

if [[ ! -f "$ISSUE25_FILE" ]]; then
  echo "missing issue file for status-order negative test: $ISSUE25_FILE"
  exit 1
fi

cp "$ISSUE25_FILE" "$ISSUE25_BACKUP"

python3 - <<'PY' "$ISSUE25_FILE"
import re
import sys
from pathlib import Path

issue_path = Path(sys.argv[1])
lines = issue_path.read_text(encoding="utf-8").splitlines()

target_header = "### AUD-1 Completion matrix schema and data sources"
header_idx = None
for idx, line in enumerate(lines):
    if line.strip() == target_header:
        header_idx = idx
        break

if header_idx is None:
    raise SystemExit(f"missing milestone header for negative test: {target_header}")

for idx in range(header_idx + 1, len(lines)):
    line = lines[idx].strip()
    if line.startswith("### "):
        break
    if re.match(r"^- Status: DONE - [0-9a-f]{7,40}$", line):
        lines[idx] = "- Status: NOT DONE"
        issue_path.write_text("\\n".join(lines) + "\\n", encoding="utf-8")
        raise SystemExit(0)

raise SystemExit("failed to find DONE status line under AUD-1 milestone")
PY

if "$CHECKER" >"$LOG_FILE" 2>&1; then
  echo "expected milestone checker to fail when AUD-1 is forced to NOT DONE"
  exit 1
fi

if ! grep -Eq "dependency violation|dependency graph references unknown (child|parent) milestone" "$LOG_FILE"; then
  echo "status-order mutation failed without dependency/graph diagnostic"
  cat "$LOG_FILE"
  exit 1
fi

echo "milestone dependency negative regression passed"
