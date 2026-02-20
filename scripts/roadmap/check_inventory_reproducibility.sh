#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GEN_SCRIPT="$ROOT_DIR/scripts/roadmap/generate_inventory_docs.py"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

python3 "$GEN_SCRIPT" --out-dir "$TMP_A"
python3 "$GEN_SCRIPT" --out-dir "$TMP_B"

ERRORS=0
for file_name in corelib-src-inventory.md sierra-extensions-inventory.md compiler-crates-inventory.md; do
  if ! diff -u "$TMP_A/$file_name" "$TMP_B/$file_name" >/dev/null; then
    echo "non-deterministic inventory output for $file_name"
    ERRORS=$((ERRORS + 1))
  fi
done

if python3 "$GEN_SCRIPT" --out-dir "$TMP_A" --pinned-surface "$TMP_A/does-not-exist.json" >/dev/null 2>&1; then
  echo "expected generator to fail when pinned surface prerequisite is missing"
  ERRORS=$((ERRORS + 1))
fi

if [[ "$ERRORS" -ne 0 ]]; then
  echo "inventory reproducibility checks failed with $ERRORS error(s)"
  exit 1
fi

echo "inventory reproducibility checks passed"
