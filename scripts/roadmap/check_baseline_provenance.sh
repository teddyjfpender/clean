#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/baselines-manifest.json"

python3 "$ROOT_DIR/scripts/examples/validate_baselines_manifest.py" \
  --manifest "$ROOT_DIR/$MANIFEST_REL" \
  --examples-manifest "config/examples-manifest.json"

"$ROOT_DIR/scripts/examples/sync_baselines.sh" --manifest "$MANIFEST_REL" >/dev/null

echo "baseline provenance checks passed"
