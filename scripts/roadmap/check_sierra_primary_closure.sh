#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MATRIX_FILE="$ROOT_DIR/roadmap/inventory/sierra-coverage-matrix.json"
TRACK_A_ISSUE="$ROOT_DIR/roadmap/executable-issues/05-track-a-lean-to-sierra-functions.issue.md"

if [[ ! -f "$MATRIX_FILE" ]]; then
  echo "missing Sierra coverage matrix: $MATRIX_FILE"
  exit 1
fi

if [[ ! -f "$TRACK_A_ISSUE" ]]; then
  echo "missing Track-A executable issue file: $TRACK_A_ISSUE"
  exit 1
fi

UNRESOLVED_NON_STARKNET="$(
python3 - <<'PY' "$MATRIX_FILE"
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
bad = []
for entry in payload.get("extension_modules", []):
    module_id = entry.get("module_id")
    status = entry.get("status")
    if not isinstance(module_id, str) or not isinstance(status, str):
        continue
    if module_id.startswith("starknet/"):
        continue
    if status != "implemented":
        bad.append(f"{module_id}:{status}")

print("\n".join(bad))
PY
)"

if [[ -n "$UNRESOLVED_NON_STARKNET" ]]; then
  echo "primary closure blocked: non-Starknet modules not fully implemented"
  echo "$UNRESOLVED_NON_STARKNET" | head -n 20
  exit 1
fi

A8_STATUS_LINE="$(grep -E '^### A8 Full non-Starknet function-family closure$' -n "$TRACK_A_ISSUE" | cut -d: -f1 | head -n 1 || true)"
if [[ -z "$A8_STATUS_LINE" ]]; then
  echo "missing A8 milestone header in $TRACK_A_ISSUE"
  exit 1
fi

A8_STATUS="$(sed -n "$((A8_STATUS_LINE + 1))p" "$TRACK_A_ISSUE")"
if ! grep -Eq '^- Status: DONE - [0-9a-f]{7,40}$' <<<"$A8_STATUS"; then
  echo "primary closure blocked: A8 is not DONE in $TRACK_A_ISSUE"
  exit 1
fi

echo "primary closure check passed"
