#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATOR="$ROOT_DIR/scripts/roadmap/validate_capability_registry.py"
REGISTRY="$ROOT_DIR/roadmap/capabilities/registry.json"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

DUP="$TMP_DIR/duplicate.json"
python3 - "$REGISTRY" "$DUP" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
p = json.loads(src.read_text(encoding="utf-8"))
if len(p["capabilities"]) < 2:
    raise SystemExit("expected at least 2 capabilities")
p["capabilities"][1]["capability_id"] = p["capabilities"][0]["capability_id"]
out.write_text(json.dumps(p, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if python3 "$VALIDATOR" --registry "$DUP" >/dev/null 2>&1; then
  echo "expected duplicate-id validation failure"
  exit 1
fi

PREV="$TMP_DIR/previous.json"
NEW="$TMP_DIR/new_illegal_transition.json"
cp "$REGISTRY" "$PREV"
python3 - "$REGISTRY" "$NEW" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
p = json.loads(src.read_text(encoding="utf-8"))
target = None
for cap in p["capabilities"]:
    if cap["support_state"]["overall"] == "implemented":
        target = cap
        break
if target is None:
    raise SystemExit("expected at least one implemented capability")
target["support_state"]["sierra"] = "planned"
target["support_state"]["cairo"] = "planned"
target["support_state"]["overall"] = "planned"
out.write_text(json.dumps(p, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if python3 "$VALIDATOR" --registry "$NEW" --previous "$PREV" >/dev/null 2>&1; then
  echo "expected illegal-transition validation failure"
  exit 1
fi

echo "capability registry negative tests passed"
