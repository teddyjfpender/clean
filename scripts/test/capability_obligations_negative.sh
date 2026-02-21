#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT_DIR/roadmap/capabilities/registry.json"
BASE="$ROOT_DIR/roadmap/capabilities/obligations.json"
VALIDATOR="$ROOT_DIR/scripts/roadmap/validate_capability_obligations.py"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Case 1: remove an implemented capability obligation entry.
MISSING_FILE="$TMP_DIR/obligations-missing.json"
python3 - "$BASE" "$MISSING_FILE" <<'PY'
import json
import sys
src, out = sys.argv[1], sys.argv[2]
payload = json.loads(open(src, encoding="utf-8").read())
obls = payload.get("obligations", [])
payload["obligations"] = [
    row
    for row in obls
    if isinstance(row, dict) and row.get("capability_id") != "cap.integer.u128.add.wrapping"
]
with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write("\n")
PY

if python3 "$VALIDATOR" --registry "$REGISTRY" --obligations "$MISSING_FILE" >"$TMP_DIR/missing.log" 2>&1; then
  echo "expected validator failure for missing implemented capability obligations"
  exit 1
fi
if ! rg -q "missing obligation entries for implemented capabilities" "$TMP_DIR/missing.log"; then
  echo "missing-entry diagnostic was not reported"
  cat "$TMP_DIR/missing.log"
  exit 1
fi

# Case 2: inject invalid test reference path.
BAD_PATH_FILE="$TMP_DIR/obligations-bad-path.json"
python3 - "$BASE" "$BAD_PATH_FILE" <<'PY'
import json
import sys
src, out = sys.argv[1], sys.argv[2]
payload = json.loads(open(src, encoding="utf-8").read())
for row in payload.get("obligations", []):
    if isinstance(row, dict) and row.get("capability_id") == "cap.scalar.felt252.add":
        row["test_refs"] = ["scripts/test/does_not_exist.sh"]
        break
with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write("\n")
PY

if python3 "$VALIDATOR" --registry "$REGISTRY" --obligations "$BAD_PATH_FILE" >"$TMP_DIR/badpath.log" 2>&1; then
  echo "expected validator failure for invalid test reference path"
  exit 1
fi
if ! rg -q "referenced file does not exist" "$TMP_DIR/badpath.log"; then
  echo "invalid-path diagnostic was not reported"
  cat "$TMP_DIR/badpath.log"
  exit 1
fi

echo "capability obligations negative checks passed"
