#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/render_sierra_coverage_report.py" \
  --out-json "$TMP_DIR/sierra-family-coverage-report.json" \
  --out-md "$TMP_DIR/sierra-family-coverage-report.md"

ERRORS=0
for file_name in sierra-family-coverage-report.json sierra-family-coverage-report.md; do
  src_file="$ROOT_DIR/roadmap/inventory/$file_name"
  gen_file="$TMP_DIR/$file_name"
  if [[ ! -f "$src_file" ]]; then
    echo "missing committed Sierra coverage report artifact: $src_file"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  if ! diff -u "$src_file" "$gen_file" >/dev/null; then
    echo "Sierra coverage report mismatch: $file_name"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ "$ERRORS" -ne 0 ]]; then
  echo "Sierra coverage report freshness check failed with $ERRORS mismatch(es)"
  exit 1
fi

echo "Sierra coverage report freshness check passed"
