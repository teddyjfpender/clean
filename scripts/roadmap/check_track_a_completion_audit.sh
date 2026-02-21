#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GEN_SCRIPT="$ROOT_DIR/scripts/roadmap/generate_track_a_completion_audit.py"
MATRIX_REL="roadmap/reports/completion-matrix.json"
AUDIT_JSON_REL="roadmap/reports/track-a-completion-audit.json"
AUDIT_MD_REL="roadmap/reports/track-a-completion-audit.md"

TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
TMP_NEG="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B" "$TMP_NEG"' EXIT

python3 "$GEN_SCRIPT" --matrix "$MATRIX_REL" --out-dir "$TMP_A"
python3 "$GEN_SCRIPT" --matrix "$MATRIX_REL" --out-dir "$TMP_B"

if ! diff -u "$TMP_A/track-a-completion-audit.json" "$TMP_B/track-a-completion-audit.json" >/dev/null; then
  echo "non-deterministic Track-A audit JSON output"
  exit 1
fi
if ! diff -u "$TMP_A/track-a-completion-audit.md" "$TMP_B/track-a-completion-audit.md" >/dev/null; then
  echo "non-deterministic Track-A audit Markdown output"
  exit 1
fi

python3 - "$TMP_A/track-a-completion-audit.json" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("result") != "PASS":
    raise SystemExit(f"track-a completion audit failed: {payload.get('result')}")
print("track-a completion audit baseline passed")
PY

for dim in track_a_family_closure track_a_proof_closure track_a_benchmark_closure; do
  python3 - "$ROOT_DIR/$MATRIX_REL" "$TMP_NEG/$dim-matrix.json" "$dim" <<'PY'
import json
import sys
from pathlib import Path
src = Path(sys.argv[1])
out = Path(sys.argv[2])
dim = sys.argv[3]
payload = json.loads(src.read_text(encoding="utf-8"))
for row in payload.get("rows", []):
    if row.get("dimension_id") == dim:
        row["status"] = "not_ready"
        row["diagnostics"] = [f"injected negative status for {dim}"]
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

  python3 "$GEN_SCRIPT" --matrix "$TMP_NEG/$dim-matrix.json" --out-dir "$TMP_NEG/$dim"
  python3 - "$TMP_NEG/$dim/track-a-completion-audit.json" "$dim" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
dim = sys.argv[2]
if payload.get("result") != "FAIL":
    raise SystemExit(f"expected FAIL result for {dim} negative case")
if not any(dim in diag for diag in payload.get("diagnostics", [])):
    raise SystemExit(f"expected diagnostics to mention {dim}")
print(f"track-a negative case passed for {dim}")
PY
done

python3 "$GEN_SCRIPT" --matrix "$MATRIX_REL" --out-dir "$TMP_A"

if [[ ! -f "$ROOT_DIR/$AUDIT_JSON_REL" || ! -f "$ROOT_DIR/$AUDIT_MD_REL" ]]; then
  echo "missing committed Track-A audit artifacts"
  exit 1
fi

if ! diff -u "$ROOT_DIR/$AUDIT_JSON_REL" "$TMP_A/track-a-completion-audit.json" >/dev/null; then
  echo "Track-A audit JSON is stale: $AUDIT_JSON_REL"
  exit 1
fi
if ! diff -u "$ROOT_DIR/$AUDIT_MD_REL" "$TMP_A/track-a-completion-audit.md" >/dev/null; then
  echo "Track-A audit Markdown is stale: $AUDIT_MD_REL"
  exit 1
fi

echo "Track-A completion audit checks passed"
