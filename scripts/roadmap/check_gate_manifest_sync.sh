#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/gate-manifest.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$ROOT_DIR/scripts/roadmap/generate_gate_manifest.py" \
  --obligations "roadmap/capabilities/obligations.json" \
  --out "$TMP_DIR/gate-manifest.json"

diff -u "$ROOT_DIR/$MANIFEST_REL" "$TMP_DIR/gate-manifest.json" >/dev/null

echo "gate manifest sync checks passed"
