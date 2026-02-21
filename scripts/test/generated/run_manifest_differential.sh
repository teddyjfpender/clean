#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export PATH="$HOME/.elan/bin:$PATH"

run_case() {
  local case_id="$1"
  local lean_test_file="$2"
  local backend_module="$3"
  local backend_contract="$4"
  local replay_command="$5"

  echo "running manifest differential case '$case_id'"
  if ! (
    cd "$ROOT_DIR"
    lake build LeanCairo.Compiler.Semantics.Eval
    lake env lean "$lean_test_file"
  ); then
    echo "manifest differential mismatch in evaluator lane for '$case_id'"
    echo "replay: $replay_command"
    exit 1
  fi

  if ! "$ROOT_DIR/scripts/test/run_backend_parity_case.sh" "$backend_module" "$backend_contract" "manifest differential $case_id"; then
    echo "manifest differential mismatch in backend parity lane for '$case_id'"
    echo "replay: $replay_command"
    exit 1
  fi
}

run_case "scalar_core" "tests/lean/sierra_scalar_differential.lean" "MyLeanSierraScalar" "SierraScalarContract" "lake env lean tests/lean/sierra_scalar_differential.lean && scripts/test/run_backend_parity_case.sh MyLeanSierraScalar SierraScalarContract scalar_core"
run_case "u128_range_checked" "tests/lean/sierra_u128_wrapping_differential.lean" "MyLeanSierraU128RangeChecked" "SierraU128RangeCheckedContract" "lake env lean tests/lean/sierra_u128_wrapping_differential.lean && scripts/test/run_backend_parity_case.sh MyLeanSierraU128RangeChecked SierraU128RangeCheckedContract u128_range_checked"

echo "manifest differential checks passed"
