#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$ROOT_DIR/.artifacts/sierra_surface_codegen"
OUT_JSON="$TMP_DIR/pinned_surface.json"
OUT_LEAN="$TMP_DIR/Surface.lean"

mkdir -p "$TMP_DIR"

python3 "$ROOT_DIR/scripts/sierra/generate_surface_bindings.py" \
  --out-json "$OUT_JSON" \
  --out-lean "$OUT_LEAN"

diff -u "$ROOT_DIR/generated/sierra/surface/pinned_surface.json" "$OUT_JSON"
diff -u "$ROOT_DIR/src/LeanCairo/Backend/Sierra/Generated/Surface.lean" "$OUT_LEAN"

echo "sierra surface codegen snapshot check passed"
