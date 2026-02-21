#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/gate-manifest.json"
MANIFEST_PATH="$ROOT_DIR/$MANIFEST_REL"

VALIDATE=0
if [[ "${1:-}" == "--validate-workflows" ]]; then
  VALIDATE=1
fi

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "missing gate manifest: $MANIFEST_REL"
  exit 1
fi

MANDATORY_GATES=()
while IFS= read -r gate; do
  if [[ -n "$gate" ]]; then
    MANDATORY_GATES+=("$gate")
  fi
done < <(python3 - "$MANIFEST_PATH" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
payload = json.loads(manifest_path.read_text(encoding="utf-8"))
gates = payload.get("mandatory_gates", [])
if not isinstance(gates, list):
    raise SystemExit(1)
for gate in gates:
    if isinstance(gate, str) and gate.strip():
        print(gate.strip())
PY
)

if [[ "${#MANDATORY_GATES[@]}" -eq 0 ]]; then
  echo "gate manifest contains no mandatory gates: $MANIFEST_REL"
  exit 1
fi

echo "quality gate inventory (${#MANDATORY_GATES[@]} total):"
for gate in "${MANDATORY_GATES[@]}"; do
  echo "- $gate"
done

if [[ "$VALIDATE" -ne 1 ]]; then
  exit 0
fi

python3 "$ROOT_DIR/scripts/roadmap/validate_gate_manifest_workflows.py" \
  --manifest "$MANIFEST_PATH"
