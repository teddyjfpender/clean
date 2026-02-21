#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="$(mktemp -d)"
SNAP_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR" "$SNAP_DIR"' EXIT

OUT_CONFIG="$WORK_DIR/benchmark-harness.json"
OUT_SCRIPT="$WORK_DIR/run_manifest_benchmarks.sh"

python3 "$ROOT_DIR/scripts/examples/generate_benchmark_harness.py" \
  --manifest "$ROOT_DIR/config/examples-manifest.json" \
  --out-config "$OUT_CONFIG" \
  --out-script "$OUT_SCRIPT"

cp "$OUT_CONFIG" "$SNAP_DIR/benchmark-harness.json"
cp "$OUT_SCRIPT" "$SNAP_DIR/run_manifest_benchmarks.sh"

python3 "$ROOT_DIR/scripts/examples/generate_benchmark_harness.py" \
  --manifest "$ROOT_DIR/config/examples-manifest.json" \
  --out-config "$OUT_CONFIG" \
  --out-script "$OUT_SCRIPT"

diff -u "$SNAP_DIR/benchmark-harness.json" "$OUT_CONFIG" >/dev/null
diff -u "$SNAP_DIR/run_manifest_benchmarks.sh" "$OUT_SCRIPT" >/dev/null

echo "benchmark harness reproducibility checks passed"
