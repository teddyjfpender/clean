#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/examples-manifest.json"
OUT_CONFIG_REL="generated/examples/benchmark-harness.json"
OUT_SCRIPT_REL="scripts/bench/generated/run_manifest_benchmarks.sh"

(
  cd "$ROOT_DIR"
  python3 scripts/examples/generate_benchmark_harness.py \
    --manifest "$MANIFEST_REL" \
    --out-config "$OUT_CONFIG_REL" \
    --out-script "$OUT_SCRIPT_REL"
  git diff --exit-code "$OUT_CONFIG_REL" "$OUT_SCRIPT_REL"
)

echo "benchmark harness sync checks passed"
