#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_FILE="$ROOT_DIR/roadmap/inventory/compiler-crates-dependency-matrix.md"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/render_crate_dependency_matrix.py" --out "$TMP_FILE"

if [[ ! -f "$OUT_FILE" ]]; then
  echo "missing committed dependency matrix: $OUT_FILE"
  exit 1
fi

if ! diff -u "$OUT_FILE" "$TMP_FILE" >/dev/null; then
  echo "crate dependency matrix mismatch: compiler-crates-dependency-matrix.md"
  exit 1
fi

echo "crate dependency matrix freshness check passed"
