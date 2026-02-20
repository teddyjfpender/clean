#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/backend_parity"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

run_case() {
  local module_name="$1"
  local contract_name="$2"
  local label="$3"
  local case_dir="$OUT_DIR/$module_name"
  local direct_dir="$case_dir/direct_sierra"
  local cairo_dir="$case_dir/cairo"
  local direct_program="$direct_dir/sierra/program.sierra.json"

  mkdir -p "$case_dir"

  (
    cd "$ROOT_DIR"
    lake exe leancairo-sierra-gen --module "$module_name" --out "$direct_dir" --optimize true
    lake exe leancairo-gen --module "$module_name" --out "$cairo_dir" --emit-casm false --optimize true
  )

  (
    cd "$cairo_dir"
    scarb build
  )

  local index_file
  index_file="$(find "$cairo_dir/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
  if [[ -z "$index_file" ]]; then
    echo "backend parity: failed to locate artifacts index for module '$module_name'"
    exit 1
  fi

  local contract_class
  contract_class="$(
    python3 "$ROOT_DIR/scripts/utils/find_contract_artifact.py" \
      --index "$index_file" \
      --contract-name "$contract_name" | head -n 1
  )"
  if [[ -z "$contract_class" || ! -f "$contract_class" ]]; then
    echo "backend parity: failed to locate contract class for '$contract_name' in module '$module_name'"
    exit 1
  fi

  if [[ ! -f "$direct_program" ]]; then
    echo "backend parity: missing direct Sierra program output for module '$module_name' at $direct_program"
    exit 1
  fi

  python3 "$ROOT_DIR/scripts/utils/check_backend_parity.py" \
    --direct-sierra "$direct_program" \
    --contract-class "$contract_class" \
    --label "$label"
}

run_case "MyLeanSierraScalar" "SierraScalarContract" "backend parity scalar"
run_case "MyLeanSierraU128RangeChecked" "SierraU128RangeCheckedContract" "backend parity u128"

"$ROOT_DIR/scripts/test/sierra_differential.sh"
"$ROOT_DIR/scripts/test/sierra_u128_wrapping_differential.sh"

echo "backend parity checks passed"
