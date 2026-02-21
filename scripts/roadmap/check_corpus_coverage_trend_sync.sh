#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COVERAGE_REL="generated/examples/corpus-coverage-report.json"
BASELINE_REL="roadmap/capabilities/corpus-coverage-trend-baseline.json"
OUT_JSON_REL="generated/examples/corpus-coverage-trend.json"
OUT_MD_REL="generated/examples/corpus-coverage-trend.md"

(
  cd "$ROOT_DIR"
  python3 scripts/examples/generate_corpus_coverage_trend.py \
    --coverage "$COVERAGE_REL" \
    --baseline "$BASELINE_REL" \
    --out-json "$OUT_JSON_REL" \
    --out-md "$OUT_MD_REL"
  git diff --exit-code "$OUT_JSON_REL" "$OUT_MD_REL"
)

echo "corpus coverage trend sync checks passed"
