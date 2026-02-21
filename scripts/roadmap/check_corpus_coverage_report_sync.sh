#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/examples-manifest.json"
REGISTRY_REL="roadmap/capabilities/registry.json"
OUT_JSON_REL="generated/examples/corpus-coverage-report.json"
OUT_MD_REL="generated/examples/corpus-coverage-report.md"

(
  cd "$ROOT_DIR"
  python3 scripts/examples/generate_corpus_coverage_report.py \
    --manifest "$MANIFEST_REL" \
    --registry "$REGISTRY_REL" \
    --out-json "$OUT_JSON_REL" \
    --out-md "$OUT_MD_REL"
  git diff --exit-code "$OUT_JSON_REL" "$OUT_MD_REL"
)

echo "corpus coverage report sync checks passed"
