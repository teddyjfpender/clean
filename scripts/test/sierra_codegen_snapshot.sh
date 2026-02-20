#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_codegen_snapshot"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$ROOT_DIR/.artifacts"

cd "$ROOT_DIR"
lake exe leancairo-sierra-gen --module MyLeanSierraSubset --out "$OUT_DIR" --optimize true

diff -u \
  "$ROOT_DIR/tests/golden/sierra_subset/program.sierra.json" \
  "$OUT_DIR/sierra/program.sierra.json"

echo "sierra codegen snapshot test passed"
