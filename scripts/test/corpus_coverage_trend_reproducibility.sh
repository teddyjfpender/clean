#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COVERAGE_REL="generated/examples/corpus-coverage-report.json"
BASELINE_REL="roadmap/capabilities/corpus-coverage-trend-baseline.json"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

(
  cd "$ROOT_DIR"
  python3 scripts/examples/generate_corpus_coverage_trend.py \
    --coverage "$COVERAGE_REL" \
    --baseline "$BASELINE_REL" \
    --out-json "$TMP_A/trend.json" \
    --out-md "$TMP_A/trend.md"
  python3 scripts/examples/generate_corpus_coverage_trend.py \
    --coverage "$COVERAGE_REL" \
    --baseline "$BASELINE_REL" \
    --out-json "$TMP_B/trend.json" \
    --out-md "$TMP_B/trend.md"
)

diff -u "$TMP_A/trend.json" "$TMP_B/trend.json" >/dev/null
diff -u "$TMP_A/trend.md" "$TMP_B/trend.md" >/dev/null

echo "corpus coverage trend reproducibility checks passed"
