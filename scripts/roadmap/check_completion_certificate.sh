#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GEN_SCRIPT="$ROOT_DIR/scripts/roadmap/generate_completion_certificate.py"
MATRIX_REL="roadmap/reports/completion-matrix.json"
TRACK_A_REL="roadmap/reports/track-a-completion-audit.json"
TRACK_B_REL="roadmap/reports/track-b-completion-audit.json"
RELEASE_REL="roadmap/reports/release-go-no-go-report.json"
ISSUE25_REL="roadmap/executable-issues/25-full-function-compiler-completion-matrix.issue.md"
CERT_JSON_REL="roadmap/reports/program-completion-certificate.json"
CERT_MD_REL="roadmap/reports/program-completion-certificate.md"

TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
TMP_NEG="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B" "$TMP_NEG"' EXIT

python3 "$GEN_SCRIPT" \
  --matrix "$MATRIX_REL" \
  --track-a-audit "$TRACK_A_REL" \
  --track-b-audit "$TRACK_B_REL" \
  --release-go-no-go "$RELEASE_REL" \
  --out-dir "$TMP_A"
python3 "$GEN_SCRIPT" \
  --matrix "$MATRIX_REL" \
  --track-a-audit "$TRACK_A_REL" \
  --track-b-audit "$TRACK_B_REL" \
  --release-go-no-go "$RELEASE_REL" \
  --out-dir "$TMP_B"

if ! diff -u "$TMP_A/program-completion-certificate.json" "$TMP_B/program-completion-certificate.json" >/dev/null; then
  echo "non-deterministic program completion certificate JSON output"
  exit 1
fi
if ! diff -u "$TMP_A/program-completion-certificate.md" "$TMP_B/program-completion-certificate.md" >/dev/null; then
  echo "non-deterministic program completion certificate Markdown output"
  exit 1
fi

if ! rg -q '^## Closure Summary$' "$TMP_A/program-completion-certificate.md"; then
  echo "certificate markdown missing closure summary section"
  exit 1
fi
if ! rg -q '^## Evidence Links$' "$TMP_A/program-completion-certificate.md"; then
  echo "certificate markdown missing evidence links section"
  exit 1
fi

ISSUE_STATUS="$(rg -n '^- Overall status: (NOT DONE|DONE - [0-9a-f]{7,40})$' "$ROOT_DIR/$ISSUE25_REL" | sed -E 's/^[0-9]+:- Overall status: //')"
python3 - "$TMP_A/program-completion-certificate.json" "$ISSUE_STATUS" <<'PY'
import json
import re
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
issue_status = sys.argv[2].strip()
result = payload.get("result")
if re.match(r"^DONE - [0-9a-f]{7,40}$", issue_status):
    if result != "PASS":
        raise SystemExit(f"certificate must be PASS when issue25 is DONE; got {result}")
else:
    if result != "BLOCKED":
        raise SystemExit(f"certificate must be BLOCKED when issue25 is NOT DONE; got {result}")
print(f"certificate gating check passed (issue25={issue_status}, result={result})")
PY

# Negative case: mandatory dimension not ready must force BLOCKED.
python3 - "$ROOT_DIR/$MATRIX_REL" "$TMP_NEG/matrix-negative.json" <<'PY'
import json
import sys
from pathlib import Path
src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
for row in payload.get("rows", []):
    if row.get("dimension_id") == "track_a_family_closure":
        row["status"] = "not_ready"
        row["diagnostics"] = ["injected certificate negative case"]
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

python3 "$GEN_SCRIPT" \
  --matrix "$TMP_NEG/matrix-negative.json" \
  --track-a-audit "$TRACK_A_REL" \
  --track-b-audit "$TRACK_B_REL" \
  --release-go-no-go "$RELEASE_REL" \
  --out-dir "$TMP_NEG"
python3 - "$TMP_NEG/program-completion-certificate.json" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("result") != "BLOCKED":
    raise SystemExit("expected BLOCKED result for negative mandatory-dimension case")
if not any("track_a_family_closure" in reason for reason in payload.get("blocking_reasons", [])):
    raise SystemExit("expected blocking reason to mention track_a_family_closure")
print("certificate negative mandatory-dimension case passed")
PY

python3 "$GEN_SCRIPT" \
  --matrix "$MATRIX_REL" \
  --track-a-audit "$TRACK_A_REL" \
  --track-b-audit "$TRACK_B_REL" \
  --release-go-no-go "$RELEASE_REL" \
  --out-dir "$TMP_A"

if [[ ! -f "$ROOT_DIR/$CERT_JSON_REL" || ! -f "$ROOT_DIR/$CERT_MD_REL" ]]; then
  echo "missing committed certificate artifacts"
  exit 1
fi

if ! diff -u "$ROOT_DIR/$CERT_JSON_REL" "$TMP_A/program-completion-certificate.json" >/dev/null; then
  echo "program completion certificate JSON is stale: $CERT_JSON_REL"
  exit 1
fi
if ! diff -u "$ROOT_DIR/$CERT_MD_REL" "$TMP_A/program-completion-certificate.md" >/dev/null; then
  echo "program completion certificate Markdown is stale: $CERT_MD_REL"
  exit 1
fi

echo "program completion certificate checks passed"
