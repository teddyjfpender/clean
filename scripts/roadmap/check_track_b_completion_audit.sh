#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GEN_SCRIPT="$ROOT_DIR/scripts/roadmap/generate_track_b_completion_audit.py"
MATRIX_REL="roadmap/reports/completion-matrix.json"
REGISTRY_REL="roadmap/capabilities/registry.json"
AUDIT_JSON_REL="roadmap/reports/track-b-completion-audit.json"
AUDIT_MD_REL="roadmap/reports/track-b-completion-audit.md"

TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
TMP_NEG="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B" "$TMP_NEG"' EXIT

python3 "$GEN_SCRIPT" --matrix "$MATRIX_REL" --capability-registry "$REGISTRY_REL" --out-dir "$TMP_A"
python3 "$GEN_SCRIPT" --matrix "$MATRIX_REL" --capability-registry "$REGISTRY_REL" --out-dir "$TMP_B"

if ! diff -u "$TMP_A/track-b-completion-audit.json" "$TMP_B/track-b-completion-audit.json" >/dev/null; then
  echo "non-deterministic Track-B audit JSON output"
  exit 1
fi
if ! diff -u "$TMP_A/track-b-completion-audit.md" "$TMP_B/track-b-completion-audit.md" >/dev/null; then
  echo "non-deterministic Track-B audit Markdown output"
  exit 1
fi

python3 - "$TMP_A/track-b-completion-audit.json" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("result") != "PASS":
    raise SystemExit(f"track-b completion audit failed: {payload.get('result')}")
print("track-b completion audit baseline passed")
PY

# Negative case: force parity dimension to not_ready.
python3 - "$ROOT_DIR/$MATRIX_REL" "$TMP_NEG/matrix-parity-negative.json" <<'PY'
import json
import sys
from pathlib import Path
src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
for row in payload.get("rows", []):
    if row.get("dimension_id") == "track_b_parity_closure":
        row["status"] = "not_ready"
        row["diagnostics"] = ["injected parity closure failure"]
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

python3 "$GEN_SCRIPT" --matrix "$TMP_NEG/matrix-parity-negative.json" --capability-registry "$REGISTRY_REL" --out-dir "$TMP_NEG/parity"
python3 - "$TMP_NEG/parity/track-b-completion-audit.json" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("result") != "FAIL":
    raise SystemExit("expected FAIL for parity negative case")
if not any("track_b_parity_closure" in diag for diag in payload.get("diagnostics", [])):
    raise SystemExit("expected diagnostics to mention track_b_parity_closure")
print("track-b parity negative case passed")
PY

# Negative case: remove divergence constraints and require failure.
python3 - "$ROOT_DIR/$REGISTRY_REL" "$TMP_NEG/registry-divergence-negative.json" <<'PY'
import json
import sys
from pathlib import Path
src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
for cap in payload.get("capabilities", []):
    if not isinstance(cap, dict):
        continue
    state = cap.get("support_state", {})
    if not isinstance(state, dict):
        continue
    if state.get("sierra") != state.get("cairo"):
        cap["divergence_constraints"] = []
        break
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

python3 "$GEN_SCRIPT" --matrix "$MATRIX_REL" --capability-registry "$TMP_NEG/registry-divergence-negative.json" --out-dir "$TMP_NEG/divergence"
python3 - "$TMP_NEG/divergence/track-b-completion-audit.json" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("result") != "FAIL":
    raise SystemExit("expected FAIL for undocumented divergence negative case")
if not payload.get("undocumented_divergence"):
    raise SystemExit("expected undocumented_divergence to be non-empty")
print("track-b undocumented divergence negative case passed")
PY

python3 "$GEN_SCRIPT" --matrix "$MATRIX_REL" --capability-registry "$REGISTRY_REL" --out-dir "$TMP_A"

if [[ ! -f "$ROOT_DIR/$AUDIT_JSON_REL" || ! -f "$ROOT_DIR/$AUDIT_MD_REL" ]]; then
  echo "missing committed Track-B audit artifacts"
  exit 1
fi

if ! diff -u "$ROOT_DIR/$AUDIT_JSON_REL" "$TMP_A/track-b-completion-audit.json" >/dev/null; then
  echo "Track-B audit JSON is stale: $AUDIT_JSON_REL"
  exit 1
fi
if ! diff -u "$ROOT_DIR/$AUDIT_MD_REL" "$TMP_A/track-b-completion-audit.md" >/dev/null; then
  echo "Track-B audit Markdown is stale: $AUDIT_MD_REL"
  exit 1
fi

echo "Track-B completion audit checks passed"
