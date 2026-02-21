#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/generate_lowering_scaffolds.py" \
  --registry "$ROOT_DIR/roadmap/capabilities/registry.json" \
  --out-sierra "$TMP_A/sierra.lean" \
  --out-cairo "$TMP_A/cairo.lean"

python3 "$ROOT_DIR/scripts/roadmap/generate_lowering_scaffolds.py" \
  --registry "$ROOT_DIR/roadmap/capabilities/registry.json" \
  --out-sierra "$TMP_B/sierra.lean" \
  --out-cairo "$TMP_B/cairo.lean"

diff -u "$TMP_A/sierra.lean" "$TMP_B/sierra.lean" >/dev/null
diff -u "$TMP_A/cairo.lean" "$TMP_B/cairo.lean" >/dev/null

echo "lowering scaffold reproducibility checks passed"
