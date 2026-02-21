#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/generate_lowering_scaffolds.py" \
  --registry "$ROOT_DIR/roadmap/capabilities/registry.json" \
  --out-sierra "$TMP_DIR/sierra.lean" \
  --out-cairo "$TMP_DIR/cairo.lean"

cp "$TMP_DIR/sierra.lean" "$TMP_DIR/sierra-edited.lean"
printf '\n-- manual edit (should be rejected by sync checks)\n' >> "$TMP_DIR/sierra-edited.lean"

if diff -u "$TMP_DIR/sierra.lean" "$TMP_DIR/sierra-edited.lean" >/dev/null; then
  echo "expected manual edit to diverge from generated lowering scaffold"
  exit 1
fi

echo "lowering scaffold sync negative checks passed"
