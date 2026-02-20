#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
  echo "usage: $0 <generated-project-dir> [contract-name]" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GENERATED_DIR="$(cd "$1" && pwd)"
CONTRACT_NAME="${2:-HelloContract}"

(
  cd "$GENERATED_DIR"
  scarb build
)

index_file="$(find "$GENERATED_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
if [[ -z "$index_file" ]]; then
  echo "failed to find starknet artifacts index in $GENERATED_DIR/target/dev" >&2
  exit 1
fi

metrics_path="$GENERATED_DIR/target/dev/${CONTRACT_NAME}_optimization_metrics.json"
python3 "$ROOT_DIR/scripts/bench/compute_sierra_cost.py" \
  --index "$index_file" \
  --contract-name "$CONTRACT_NAME" >"$metrics_path"

expanded_path="$GENERATED_DIR/target/dev/expanded.cairo"
(
  cd "$GENERATED_DIR"
  scarb expand --emit stdout --target-kind starknet-contract >"$expanded_path"
)

echo "review bundle generated:"
echo "  metrics: $metrics_path"
echo "  expanded cairo: $expanded_path"
echo "  generated cairo: $GENERATED_DIR/src/lib.cairo"

optimized_artifacts_dir="$GENERATED_DIR/target/dev/optimized_artifacts"
python3 "$ROOT_DIR/scripts/bench/optimize_artifacts.py" \
  --index "$index_file" \
  --contract-name "$CONTRACT_NAME" \
  --out-dir "$optimized_artifacts_dir" \
  --passes strip_sierra_debug_info >/dev/null

echo "  optimized artifacts index: $optimized_artifacts_dir/optimized.starknet_artifacts.json"
echo "  optimization report: $optimized_artifacts_dir/artifact_optimization_report.json"
