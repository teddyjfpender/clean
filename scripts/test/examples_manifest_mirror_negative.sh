#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_SRC="$ROOT_DIR/config/examples-manifest.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BROKEN_MANIFEST="$TMP_DIR/examples-manifest-broken.json"
python3 - "$MANIFEST_SRC" "$BROKEN_MANIFEST" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
examples = payload.get("examples", [])
if not isinstance(examples, list) or not examples:
    raise SystemExit("expected non-empty examples list")

examples[0]["mirrors"]["sierra_dir"] = "examples/Sierra/nonexistent_mirror_path"
out.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")
PY

if "$ROOT_DIR/scripts/test/examples_structure.sh" "$BROKEN_MANIFEST" >/dev/null 2>&1; then
  echo "expected examples_structure check to fail on missing mirror path"
  exit 1
fi

echo "examples manifest mirror negative checks passed"
