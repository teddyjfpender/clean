#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/generated/examples/benchmark-harness.json"
OUT_JSON="$ROOT_DIR/generated/examples/benchmark-summary.json"
OUT_MD="$ROOT_DIR/generated/examples/benchmark-summary.md"
LOGS_DIR="$ROOT_DIR/.artifacts/manifest_benchmark"

python3 "$ROOT_DIR/scripts/bench/run_manifest_benchmark_suite.py" \
  --config "$CONFIG_FILE" \
  --out-json "$OUT_JSON" \
  --out-md "$OUT_MD" \
  --logs-dir "$LOGS_DIR"

python3 "$ROOT_DIR/scripts/bench/check_manifest_benchmark_thresholds.py" \
  --config "$CONFIG_FILE" \
  --summary "$OUT_JSON"

echo "manifest benchmark harness checks passed"
