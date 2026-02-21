#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BASE="$ROOT_DIR/config/effect-metadata.json"

MISSING_NODE="$TMP_DIR/missing-node.json"
python3 - "$BASE" "$MISSING_NODE" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
payload["nodes"] = [row for row in payload.get("nodes", []) if row.get("node") != "addU128"]
dst.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if "$ROOT_DIR/scripts/roadmap/check_effect_metadata.sh" --metadata "$MISSING_NODE" >/dev/null 2>&1; then
  echo "expected effect metadata check to fail when required node metadata is missing"
  exit 1
fi

ILLEGAL_COMBO="$TMP_DIR/illegal-combo.json"
python3 - "$BASE" "$ILLEGAL_COMBO" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
for row in payload.get("nodes", []):
    if row.get("node") == "var":
        row["resource_writes"] = ["gas"]
        break
dst.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if "$ROOT_DIR/scripts/roadmap/check_effect_metadata.sh" --metadata "$ILLEGAL_COMBO" >/dev/null 2>&1; then
  echo "expected effect metadata check to fail on illegal pure/resource combination"
  exit 1
fi

echo "effect metadata negative checks passed"
