#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG="$ROOT_DIR/roadmap/reports/rgr-deliverables.json"
VALIDATOR="$ROOT_DIR/scripts/roadmap/validate_rgr_deliverables.py"
LOG_FILE="$(mktemp -t rgr_deliverables_negative.XXXXXX.log)"
TMP_FILE="$(mktemp -t rgr_deliverables_negative.XXXXXX.json)"
trap 'rm -f "$LOG_FILE" "$TMP_FILE"' EXIT

if [[ ! -f "$CATALOG" ]]; then
  echo "missing catalog: $CATALOG"
  exit 1
fi

# Case 1: missing gate command path must fail.
python3 - <<'PY' "$CATALOG" "$TMP_FILE"
import json
import sys
from pathlib import Path
src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
payload["deliverables"][0]["phase_gates"]["green"] = ["scripts/roadmap/does_not_exist.sh"]
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if python3 "$VALIDATOR" --catalog "$TMP_FILE" >"$LOG_FILE" 2>&1; then
  echo "expected validator to fail when gate path is missing"
  exit 1
fi
if ! rg -q "command path not found" "$LOG_FILE"; then
  echo "missing diagnostic for invalid gate path"
  cat "$LOG_FILE"
  exit 1
fi

# Case 2: illegal DONE transition (not ready + no evidence) must fail.
python3 - <<'PY' "$CATALOG" "$TMP_FILE"
import json
import sys
from pathlib import Path
src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
for item in payload.get("deliverables", []):
    if item.get("computed_ready") is False:
        item["status"] = "DONE - deadbeef"
        item["evidence_tests"] = []
        item["evidence_proofs"] = []
        break
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if python3 "$VALIDATOR" --catalog "$TMP_FILE" >"$LOG_FILE" 2>&1; then
  echo "expected validator to fail on illegal DONE transition"
  exit 1
fi
if ! rg -q "DONE requires" "$LOG_FILE"; then
  echo "missing DONE-transition diagnostic"
  cat "$LOG_FILE"
  exit 1
fi

echo "RGR deliverables negative checks passed"
