#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

OUT_JSON="$ROOT_DIR/roadmap/reports/optimization-closure-report.json"
OUT_MD="$ROOT_DIR/roadmap/reports/optimization-closure-report.md"

python3 "$ROOT_DIR/scripts/roadmap/generate_optimization_closure_report.py" \
  --issue "$ROOT_DIR/roadmap/executable-issues/23-verified-optimizing-compiler-escalation-plan.issue.md" \
  --out-json "$TMP_DIR/optimization-closure-report.json" \
  --out-md "$TMP_DIR/optimization-closure-report.md"

ERRORS=0
for file_name in optimization-closure-report.json optimization-closure-report.md; do
  if [[ ! -f "$ROOT_DIR/roadmap/reports/$file_name" ]]; then
    echo "missing committed optimization closure artifact: roadmap/reports/$file_name"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  if ! diff -u "$ROOT_DIR/roadmap/reports/$file_name" "$TMP_DIR/$file_name" >/dev/null; then
    echo "optimization closure report mismatch: $file_name"
    ERRORS=$((ERRORS + 1))
  fi
done

python3 - "$OUT_JSON" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
if payload.get("result") != "PASS":
    raise SystemExit(f"optimization closure report result is not PASS: {payload.get('result')}")
if int(payload.get("done_count", 0)) != int(payload.get("target_count", 0)):
    raise SystemExit("optimization closure report does not show full milestone completion")
if payload.get("missing_artifacts"):
    raise SystemExit("optimization closure report has missing artifacts")
PY

if [[ "$ERRORS" -ne 0 ]]; then
  echo "optimization closure report checks failed with $ERRORS mismatch(es)"
  exit 1
fi

echo "optimization closure report checks passed"
