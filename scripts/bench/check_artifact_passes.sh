#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_NAME="${1:-MyLeanContract}"
CONTRACT_NAME="${2:-HelloContract}"
OUT_BASE="$ROOT_DIR/.artifacts/bench/artifact_passes"
SOURCE_DIR="$OUT_BASE/source"
OPT_DIR="$OUT_BASE/optimized"

rm -rf "$OUT_BASE"
mkdir -p "$OUT_BASE"

cd "$ROOT_DIR"
export PATH="$HOME/.elan/bin:$PATH"

lake exe leancairo-gen \
  --module "$MODULE_NAME" \
  --out "$SOURCE_DIR" \
  --emit-casm true \
  --optimize true \
  --inlining-strategy default

(
  cd "$SOURCE_DIR"
  scarb build
)

source_index="$(find "$SOURCE_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
if [[ -z "$source_index" ]]; then
  echo "failed to find source artifacts index" >&2
  exit 1
fi

python3 "$ROOT_DIR/scripts/bench/optimize_artifacts.py" \
  --index "$source_index" \
  --contract-name "$CONTRACT_NAME" \
  --out-dir "$OPT_DIR" \
  --passes strip_sierra_debug_info >/tmp/leancairo_artifact_opt_report.json

optimized_index="$OPT_DIR/optimized.starknet_artifacts.json"
source_metrics="$(python3 "$ROOT_DIR/scripts/bench/compute_sierra_cost.py" --index "$source_index" --contract-name "$CONTRACT_NAME")"
optimized_metrics="$(python3 "$ROOT_DIR/scripts/bench/compute_sierra_cost.py" --index "$optimized_index" --contract-name "$CONTRACT_NAME")"

source_score="$(printf '%s' "$source_metrics" | python3 -c 'import json,sys; print(json.load(sys.stdin)["score"])')"
optimized_score="$(printf '%s' "$optimized_metrics" | python3 -c 'import json,sys; print(json.load(sys.stdin)["score"])')"

if (( optimized_score != source_score )); then
  echo "artifact pass semantics regression: score changed from $source_score to $optimized_score" >&2
  exit 1
fi

source_size="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["source_metrics"]["file_size_bytes"])' "$OPT_DIR/artifact_optimization_report.json")"
optimized_size="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["optimized_metrics"]["file_size_bytes"])' "$OPT_DIR/artifact_optimization_report.json")"

echo "artifact pass verification passed: score preserved ($source_score), size ${source_size}B -> ${optimized_size}B"
