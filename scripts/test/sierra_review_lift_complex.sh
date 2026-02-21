#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_review_lift_complex"
export PATH="$HOME/.elan/bin:$PATH"

run_case() {
  local module_name="$1"
  local case_id="$2"
  local expected_fn="$3"
  local case_dir="$OUT_DIR/$case_id"
  local program_json="$case_dir/generated/sierra/program.sierra.json"
  local review_out="$case_dir/generated/review/program.review.cairo"

  rm -rf "$case_dir"
  mkdir -p "$case_dir"

  (
    cd "$ROOT_DIR"
    lake exe leancairo-sierra-gen --module "$module_name" --out "$case_dir/generated" --optimize true
  )

  python3 "$ROOT_DIR/scripts/sierra/render_review_lift.py" \
    --input "$program_json" \
    --out "$review_out"

  if [[ ! -s "$review_out" ]]; then
    echo "review-lift output missing or empty: $review_out"
    exit 1
  fi

  if ! rg -q 'sierra_stmt:[0-9]+' "$review_out"; then
    echo "review-lift output missing statement anchors for $case_id"
    exit 1
  fi

  if ! rg -q "^fn ${expected_fn}\\(\\)" "$review_out"; then
    echo "review-lift output missing expected function '${expected_fn}' for $case_id"
    exit 1
  fi
}

run_case "circuit_gate_felt.Example" "circuit_gate_felt" "gateConstraint"
run_case "crypto_round_felt.Example" "crypto_round_felt" "cryptoRound"

"$ROOT_DIR/scripts/roadmap/check_review_lift_isolation.sh"

echo "sierra review-lift complex corpus checks passed"
