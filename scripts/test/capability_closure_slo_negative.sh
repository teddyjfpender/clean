#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REPORT="$TMP_DIR/capability-coverage-report.json"
BASELINE="$ROOT_DIR/roadmap/capabilities/capability-closure-slo-baseline.json"

cp "$ROOT_DIR/roadmap/inventory/capability-coverage-report.json" "$REPORT"

python3 - "$REPORT" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
payload["overall_status_counts"]["implemented"] = 0
payload["sierra_status_counts"]["implemented"] = 0
payload["cairo_status_counts"]["implemented"] = 0
payload["families"]["integer"]["overall"]["implemented"] = 0
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if "$ROOT_DIR/scripts/roadmap/check_capability_closure_slo.sh" --report "$REPORT" --baseline "$BASELINE" >/dev/null 2>&1; then
  echo "expected capability closure SLO check to fail for regressed report"
  exit 1
fi

echo "capability closure SLO negative checks passed"
