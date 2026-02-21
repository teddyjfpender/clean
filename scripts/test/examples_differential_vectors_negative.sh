#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_SRC="$ROOT_DIR/config/examples-manifest.json"
VALIDATOR="$ROOT_DIR/scripts/examples/validate_examples_manifest.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BROKEN_MANIFEST="$TMP_DIR/examples-manifest-vectors-broken.json"
python3 - "$MANIFEST_SRC" "$BROKEN_MANIFEST" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))

examples = payload.get("examples", [])
target = None
for entry in examples:
    diff = entry.get("differential", {})
    if isinstance(diff, dict) and diff.get("kind") == "composite":
        target = diff
        break
if target is None:
    raise SystemExit("expected at least one composite differential entry")

target["vector_profiles"] = ["normal", "boundary"]
out.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")
PY

if python3 "$VALIDATOR" --manifest "$BROKEN_MANIFEST" >/dev/null 2>&1; then
  echo "expected validator to reject composite differential without failure vectors"
  exit 1
fi

echo "examples differential vectors negative checks passed"
