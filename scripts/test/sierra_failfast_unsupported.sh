#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_failfast"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

check_fail() {
  local module="$1"
  local expected_message="$2"
  local case_name="$3"
  local log_file="$OUT_DIR/${case_name}.log"

  if lake exe leancairo-sierra-gen --module "$module" --out "$OUT_DIR/$case_name" --optimize true >"$log_file" 2>&1; then
    echo "expected $case_name to fail, but command succeeded"
    cat "$log_file"
    exit 1
  fi

  if ! rg -q --fixed-strings "$expected_message" "$log_file"; then
    echo "missing expected fail-fast message for $case_name"
    echo "expected: $expected_message"
    cat "$log_file"
    exit 1
  fi
}

check_fail \
  MyLeanSierraSubsetUnsupportedU128Arith \
  "ltU128 lowering is not yet implemented" \
  "u128_arith"

check_fail \
  MyLeanSierraSubsetUnsupportedU256Sig \
  "unsupported parameter type 'u256'" \
  "u256_signature"

echo "sierra fail-fast unsupported checks passed"
