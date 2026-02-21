#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

"$ROOT_DIR/scripts/roadmap/check_issue_evidence.sh"
python3 "$ROOT_DIR/scripts/roadmap/generate_release_reports.py" --out-dir "$TMP_DIR"

REPORT_JSON="$TMP_DIR/release-go-no-go-report.json"
REPORT_MD="$TMP_DIR/release-go-no-go-report.md"

python3 - "$REPORT_JSON" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
result = payload.get("result")
if result != "PASS":
    raise SystemExit(f"release go/no-go failed: result={result}")
print("release go/no-go thresholds passed")
PY

if ! rg -q "^## Capability Closure$" "$REPORT_MD"; then
  echo "missing capability closure section in release go/no-go report"
  exit 1
fi
if ! rg -q "^## Proof Closure$" "$REPORT_MD"; then
  echo "missing proof closure section in release go/no-go report"
  exit 1
fi
if ! rg -q "^## Benchmark Closure$" "$REPORT_MD"; then
  echo "missing benchmark closure section in release go/no-go report"
  exit 1
fi

echo "release go/no-go checks passed"
