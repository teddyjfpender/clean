#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )/../.." && pwd)"
MANIFEST_REL="config/baselines-manifest.json"
TMP_A="$(mktemp -t baseline_sync_a.XXXXXX.log)"
TMP_B="$(mktemp -t baseline_sync_b.XXXXXX.log)"
trap 'rm -f "$TMP_A" "$TMP_B"' EXIT

"$ROOT_DIR/scripts/examples/sync_baselines.sh" --manifest "$MANIFEST_REL" >"$TMP_A"
"$ROOT_DIR/scripts/examples/sync_baselines.sh" --manifest "$MANIFEST_REL" >"$TMP_B"

diff -u "$TMP_A" "$TMP_B" >/dev/null

echo "baseline sync reproducibility checks passed"
