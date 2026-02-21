#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/generate_gate_manifest.py" \
  --obligations "roadmap/capabilities/obligations.json" \
  --out "$TMP_A/gate-manifest.json"
python3 "$ROOT_DIR/scripts/roadmap/generate_gate_manifest.py" \
  --obligations "roadmap/capabilities/obligations.json" \
  --out "$TMP_B/gate-manifest.json"

diff -u "$TMP_A/gate-manifest.json" "$TMP_B/gate-manifest.json" >/dev/null

echo "gate manifest reproducibility checks passed"
