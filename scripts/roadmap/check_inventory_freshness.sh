#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INVENTORY_DIR="$ROOT_DIR/roadmap/inventory"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/generate_inventory_docs.py" --out-dir "$TMP_DIR"

ERRORS=0
for file_name in corelib-src-inventory.md sierra-extensions-inventory.md compiler-crates-inventory.md; do
  src_file="$INVENTORY_DIR/$file_name"
  gen_file="$TMP_DIR/$file_name"

  if [[ ! -f "$src_file" ]]; then
    echo "missing committed inventory file: $src_file"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  if [[ ! -f "$gen_file" ]]; then
    echo "missing generated inventory file: $gen_file"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if ! diff -u "$src_file" "$gen_file" >/dev/null; then
    echo "inventory mismatch: $file_name"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ "$ERRORS" -ne 0 ]]; then
  echo "inventory freshness check failed with $ERRORS mismatch(es)"
  exit 1
fi

echo "inventory freshness check passed"
