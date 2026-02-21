#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_sierra_primary_closure.sh"
TMP_DIR="$(mktemp -d -t leancairo_sierra_primary_closure_negative.XXXXXX)"
TMP_ISSUE="$TMP_DIR/05-track-a-lean-to-sierra-functions.issue.md"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cp "$ROOT_DIR/roadmap/executable-issues/05-track-a-lean-to-sierra-functions.issue.md" "$TMP_ISSUE"

python3 - "$TMP_ISSUE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()

header_re = re.compile(r"^### A8 Full non-Starknet function-family closure$")
status_re = re.compile(r"^- Status: (NOT DONE|DONE - [0-9a-f]{7,40})$")

for idx, line in enumerate(lines):
    if not header_re.match(line.strip()):
        continue
    status_idx = idx + 1
    if status_idx >= len(lines) or not status_re.match(lines[status_idx].strip()):
        raise SystemExit("failed to locate A8 status line in temporary issue file")
    lines[status_idx] = "- Status: NOT DONE"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    raise SystemExit(0)

raise SystemExit("missing A8 milestone header in temporary issue file")
PY

if "$CHECKER" --track-issue "$TMP_ISSUE" >/dev/null 2>&1; then
  echo "expected primary closure gate to fail when A8 status is forced to NOT DONE"
  exit 1
fi

echo "primary closure negative gate passed"
