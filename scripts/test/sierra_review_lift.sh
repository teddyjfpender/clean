#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_review_lift"
PROGRAM_JSON="$OUT_DIR/generated/sierra/program.sierra.json"
REVIEW_OUT="$OUT_DIR/generated/review/program.review.cairo"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

(
  cd "$ROOT_DIR"
  lake exe leancairo-sierra-gen --module MyLeanSierraSubset --out "$OUT_DIR/generated" --optimize true
)

python3 "$ROOT_DIR/scripts/sierra/render_review_lift.py" \
  --input "$PROGRAM_JSON" \
  --out "$REVIEW_OUT"

if [[ ! -s "$REVIEW_OUT" ]]; then
  echo "review-lift output missing or empty: $REVIEW_OUT"
  exit 1
fi

if ! rg -q 'sierra_stmt:[0-9]+' "$REVIEW_OUT"; then
  echo "review-lift output missing statement anchors"
  exit 1
fi

if ! rg -q '^fn identityFelt\(\)' "$REVIEW_OUT"; then
  echo "review-lift output missing expected function block"
  exit 1
fi

"$ROOT_DIR/scripts/roadmap/check_review_lift_isolation.sh"

echo "sierra review-lift checks passed"
