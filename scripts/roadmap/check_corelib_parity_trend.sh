#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PARITY_REL="roadmap/inventory/corelib-parity-report.json"
BASELINE_REL="roadmap/capabilities/corelib-parity-trend-baseline.json"
OUT_JSON_REL="roadmap/inventory/corelib-parity-trend.json"

python3 "$ROOT_DIR/scripts/roadmap/generate_corelib_parity_trend.py" \
  --parity "$ROOT_DIR/$PARITY_REL" \
  --baseline "$ROOT_DIR/$BASELINE_REL" \
  --out-json "$TMP_DIR/corelib-parity-trend.json" \
  --out-md "$TMP_DIR/corelib-parity-trend.md"

ERRORS=0
for file_name in corelib-parity-trend.json corelib-parity-trend.md; do
  src_file="$ROOT_DIR/roadmap/inventory/$file_name"
  if [[ ! -f "$src_file" ]]; then
    echo "missing committed corelib parity trend artifact: $src_file"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  if ! diff -u "$src_file" "$TMP_DIR/$file_name" >/dev/null; then
    echo "corelib parity trend artifact mismatch: $file_name"
    ERRORS=$((ERRORS + 1))
  fi
done

python3 - "$ROOT_DIR/$OUT_JSON_REL" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
if payload.get("result") != "PASS":
    raise SystemExit(f"corelib parity trend result is not PASS: {payload.get('result')}")
PY

if [[ "$ERRORS" -ne 0 ]]; then
  echo "corelib parity trend checks failed with $ERRORS mismatch(es)"
  exit 1
fi

echo "corelib parity trend checks passed"
