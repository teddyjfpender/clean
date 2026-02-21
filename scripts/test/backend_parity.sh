#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/.elan/bin:$PATH"

HARNESS="$ROOT_DIR/scripts/test/generated/run_manifest_differential.sh"
if [[ ! -f "$HARNESS" ]]; then
  echo "missing generated differential harness: $HARNESS"
  echo "run: python3 scripts/examples/generate_differential_harness.py --manifest config/examples-manifest.json --out-script scripts/test/generated/run_manifest_differential.sh --out-json generated/examples/differential-harness.json"
  exit 1
fi

"$HARNESS"

echo "backend parity checks passed"
