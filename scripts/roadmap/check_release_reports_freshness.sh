#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/roadmap/reports"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/generate_release_reports.py" --out-dir "$TMP_DIR"

ERRORS=0
for file_name in release-compatibility-report.md release-proof-report.md release-benchmark-report.md release-capability-closure-report.md release-go-no-go-report.md release-go-no-go-report.json; do
  src_file="$OUT_DIR/$file_name"
  gen_file="$TMP_DIR/$file_name"
  if [[ ! -f "$src_file" ]]; then
    echo "missing committed release report: $src_file"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  if ! diff -u "$src_file" "$gen_file" >/dev/null; then
    echo "release report mismatch: $file_name"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ "$ERRORS" -ne 0 ]]; then
  echo "release report freshness check failed with $ERRORS mismatch(es)"
  exit 1
fi

echo "release report freshness check passed"
