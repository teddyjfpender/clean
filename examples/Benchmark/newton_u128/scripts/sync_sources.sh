#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$BENCH_DIR/../../.." && pwd)"

GENERATED_SRC="$ROOT_DIR/examples/Cairo/newton_u128/src/lib.cairo"
BASELINE_SRC="$ROOT_DIR/examples/Cairo-Baseline/newton_u128/src/lib.cairo"

GENERATED_DST="$BENCH_DIR/src/generated_contract.cairo"
BASELINE_DST="$BENCH_DIR/src/baseline_contract.cairo"

if [[ ! -f "$GENERATED_SRC" ]]; then
  echo "error: generated source not found: $GENERATED_SRC" >&2
  exit 1
fi
if [[ ! -f "$BASELINE_SRC" ]]; then
  echo "error: baseline source not found: $BASELINE_SRC" >&2
  exit 1
fi

cp "$GENERATED_SRC" "$GENERATED_DST"
cp "$BASELINE_SRC" "$BASELINE_DST"

echo "synced: $GENERATED_DST"
echo "synced: $BASELINE_DST"
