#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

python3 "$ROOT_DIR/scripts/examples/generate_corpus_coverage_report.py" \
  --manifest "$ROOT_DIR/config/examples-manifest.json" \
  --registry "$ROOT_DIR/roadmap/capabilities/registry.json" \
  --out-json "$TMP_A/corpus-coverage-report.json" \
  --out-md "$TMP_A/corpus-coverage-report.md"

python3 "$ROOT_DIR/scripts/examples/generate_corpus_coverage_report.py" \
  --manifest "$ROOT_DIR/config/examples-manifest.json" \
  --registry "$ROOT_DIR/roadmap/capabilities/registry.json" \
  --out-json "$TMP_B/corpus-coverage-report.json" \
  --out-md "$TMP_B/corpus-coverage-report.md"

diff -u "$TMP_A/corpus-coverage-report.json" "$TMP_B/corpus-coverage-report.json" >/dev/null
diff -u "$TMP_A/corpus-coverage-report.md" "$TMP_B/corpus-coverage-report.md" >/dev/null

echo "corpus coverage reproducibility checks passed"
