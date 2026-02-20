#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/roadmap/inventory"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/render_coverage_matrix.py" \
  --out-json "$TMP_DIR/sierra-coverage-matrix.json" \
  --out-md "$TMP_DIR/sierra-coverage-summary.md"

ERRORS=0
for file_name in sierra-coverage-matrix.json sierra-coverage-summary.md; do
  src_file="$OUT_DIR/$file_name"
  gen_file="$TMP_DIR/$file_name"

  if [[ ! -f "$src_file" ]]; then
    echo "missing committed coverage artifact: $src_file"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if ! diff -u "$src_file" "$gen_file" >/dev/null; then
    echo "coverage artifact mismatch: $file_name"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ "$ERRORS" -ne 0 ]]; then
  echo "coverage matrix freshness check failed with $ERRORS mismatch(es)"
  exit 1
fi

echo "coverage matrix freshness check passed"
