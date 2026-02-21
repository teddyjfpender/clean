#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="$ROOT_DIR/scripts/roadmap/run_rgr_loop.sh"
CATALOG="$ROOT_DIR/roadmap/reports/rgr-deliverables.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Dry-run determinism check.
"$RUNNER" --deliverable d00-non-starknet-closure-guard --catalog roadmap/reports/rgr-deliverables.json --dry-run >"$TMP_DIR/run-a.log"
"$RUNNER" --deliverable d00-non-starknet-closure-guard --catalog roadmap/reports/rgr-deliverables.json --dry-run >"$TMP_DIR/run-b.log"

diff -u "$TMP_DIR/run-a.log" "$TMP_DIR/run-b.log" >/dev/null

# Full phase execution for bootstrap deliverable.
"$RUNNER" --deliverable d00-non-starknet-closure-guard --catalog roadmap/reports/rgr-deliverables.json

# Missing gate path should fail fast.
python3 - <<'PY' "$CATALOG" "$TMP_DIR/invalid-catalog.json"
import json
import sys
from pathlib import Path
src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
payload["deliverables"][0]["phase_gates"]["red"] = ["scripts/roadmap/does-not-exist.sh"]
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if "$RUNNER" --deliverable d00-non-starknet-closure-guard --catalog "$TMP_DIR/invalid-catalog.json" >"$TMP_DIR/invalid.log" 2>&1; then
  echo "expected loop runner to fail on missing gate path"
  exit 1
fi
if ! rg -q "command path not found|missing gate command path" "$TMP_DIR/invalid.log"; then
  echo "missing fail-fast diagnostic for missing gate path"
  cat "$TMP_DIR/invalid.log"
  exit 1
fi

echo "RGR loop smoke checks passed"
