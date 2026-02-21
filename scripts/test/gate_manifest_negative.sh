#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/config/gate-manifest.json"
VALIDATOR="$ROOT_DIR/scripts/roadmap/validate_gate_manifest_workflows.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 - "$ROOT_DIR/scripts/workflow/run-sierra-checks.sh" "$TMP_DIR/run-sierra-checks.sh" <<'PY'
from pathlib import Path
import sys
src = Path(sys.argv[1])
out = Path(sys.argv[2])
needle = '"$ROOT_DIR/scripts/roadmap/check_issue_statuses.sh"\n'
text = src.read_text(encoding='utf-8')
out.write_text(text.replace(needle, ''), encoding='utf-8')
PY

python3 - "$ROOT_DIR/scripts/workflow/run-mvp-checks.sh" "$TMP_DIR/run-mvp-checks.sh" <<'PY'
from pathlib import Path
import sys
src = Path(sys.argv[1])
out = Path(sys.argv[2])
needle = '"$ROOT_DIR/scripts/roadmap/check_issue_statuses.sh"\n'
text = src.read_text(encoding='utf-8')
out.write_text(text.replace(needle, ''), encoding='utf-8')
PY

cp "$ROOT_DIR/scripts/workflow/run-release-candidate-checks.sh" "$TMP_DIR/run-release-candidate-checks.sh"

if python3 "$VALIDATOR" \
  --manifest "$MANIFEST" \
  --workflow "$TMP_DIR/run-sierra-checks.sh" \
  --workflow "$TMP_DIR/run-mvp-checks.sh" \
  --workflow "$TMP_DIR/run-release-candidate-checks.sh" >"$TMP_DIR/negative.log" 2>&1; then
  echo "expected gate manifest validator to fail when required gate is removed"
  exit 1
fi

if ! rg -q "mandatory gate is not referenced by any workflow" "$TMP_DIR/negative.log"; then
  echo "gate manifest validator failed, but expected drift diagnostic was not reported"
  cat "$TMP_DIR/negative.log"
  exit 1
fi

echo "gate manifest negative checks passed"
