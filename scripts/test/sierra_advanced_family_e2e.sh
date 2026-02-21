#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_advanced_family_e2e"
export PATH="$HOME/.elan/bin:$PATH"

run_case() {
  local module_name="$1"
  local case_id="$2"
  local case_dir="$OUT_DIR/$case_id"
  local program_json="$case_dir/generated/sierra/program.sierra.json"
  local casm_out="$case_dir/generated/sierra/program.casm"

  rm -rf "$case_dir"
  mkdir -p "$case_dir"

  (
    cd "$ROOT_DIR"
    lake exe leancairo-sierra-gen --module "$module_name" --out "$case_dir/generated" --optimize true
  )

  cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
    validate --input "$program_json" >/dev/null

  cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
    compile --input "$program_json" --out-casm "$casm_out" >/dev/null

  test -s "$casm_out"
}

run_case "circuit_gate_felt.Example" "circuit_gate_felt"
run_case "crypto_round_felt.Example" "crypto_round_felt"

echo "sierra advanced-family e2e (validate + compile) passed"
