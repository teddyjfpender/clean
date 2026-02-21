#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_SRC="$ROOT_DIR/config/examples-manifest.json"
REGISTRY="$ROOT_DIR/roadmap/capabilities/registry.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BROKEN_MANIFEST="$TMP_DIR/examples-manifest-corpus-broken.json"
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

for entry in examples:
    coverage = entry.get("coverage", {})
    if not isinstance(coverage, dict):
        continue
    tags = coverage.get("family_tags", [])
    if not isinstance(tags, list):
        continue
    if "circuit" in tags:
        coverage["family_tags"] = [tag for tag in tags if tag != "circuit"]
        break

out.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/examples/generate_corpus_coverage_report.py" \
  --manifest "$BROKEN_MANIFEST" \
  --registry "$REGISTRY" \
  --out-json "$TMP_DIR/out.json" \
  --out-md "$TMP_DIR/out.md" >/dev/null 2>&1; then
  echo "expected corpus coverage report generation to fail when required family is missing"
  exit 1
fi

BROKEN_IMPLEMENTED_MANIFEST="$TMP_DIR/examples-manifest-implemented-broken.json"
python3 - "$MANIFEST_SRC" "$BROKEN_IMPLEMENTED_MANIFEST" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
payload = json.loads(src.read_text(encoding="utf-8"))
examples = payload.get("examples", [])
if not isinstance(examples, list) or not examples:
    raise SystemExit("expected non-empty examples list")

for entry in examples:
    if entry.get("id") != "crypto_round_felt":
        continue
    coverage = entry.get("coverage", {})
    if not isinstance(coverage, dict):
        continue
    caps = coverage.get("capability_ids", [])
    if not isinstance(caps, list):
        continue
    coverage["capability_ids"] = [cap for cap in caps if cap != "cap.scalar.felt252.sub"]
    break

out.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/examples/generate_corpus_coverage_report.py" \
  --manifest "$BROKEN_IMPLEMENTED_MANIFEST" \
  --registry "$REGISTRY" \
  --out-json "$TMP_DIR/out2.json" \
  --out-md "$TMP_DIR/out2.md" >/dev/null 2>&1; then
  echo "expected corpus coverage report generation to fail when implemented capability coverage is missing"
  exit 1
fi

echo "corpus coverage negative checks passed"
