#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_NAME="${1:-MyLeanContract}"
CONTRACT_NAME="${2:-HelloContract}"
OUT_BASE="$ROOT_DIR/.artifacts/bench/tune_inlining"
STRATEGIES=("${3:-default}" "avoid" "8" "16" "32")

export PATH="$HOME/.elan/bin:$PATH"
rm -rf "$OUT_BASE"
mkdir -p "$OUT_BASE"

best_strategy=""
best_score=""

printf "%-12s %-10s %-10s %-10s\n" "strategy" "score" "sierra" "casm"

for strategy in "${STRATEGIES[@]}"; do
  strategy_safe="$(printf '%s' "$strategy" | tr -c 'a-zA-Z0-9' '_')"
  out_dir="$OUT_BASE/$strategy_safe"
  mkdir -p "$out_dir"

  (
    cd "$ROOT_DIR"
    lake exe leancairo-gen \
      --module "$MODULE_NAME" \
      --out "$out_dir" \
      --emit-casm true \
      --optimize true \
      --inlining-strategy "$strategy"
  )

  (
    cd "$out_dir"
    scarb build
  )

  index_file="$(find "$out_dir/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
  metrics="$(python3 "$ROOT_DIR/scripts/bench/compute_sierra_cost.py" --index "$index_file" --contract-name "$CONTRACT_NAME")"
  score="$(printf '%s' "$metrics" | python3 -c 'import json,sys; print(json.load(sys.stdin)["score"])')"
  sierra_len="$(printf '%s' "$metrics" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sierra_program_len"])')"
  casm_len="$(printf '%s' "$metrics" | python3 -c 'import json,sys; print(json.load(sys.stdin)["casm_bytecode_len"])')"

  printf "%-12s %-10s %-10s %-10s\n" "$strategy" "$score" "$sierra_len" "$casm_len"

  if [[ -z "$best_strategy" ]] || (( score < best_score )); then
    best_strategy="$strategy"
    best_score="$score"
  fi
done

echo
echo "best inlining strategy: $best_strategy (score=$best_score)"
