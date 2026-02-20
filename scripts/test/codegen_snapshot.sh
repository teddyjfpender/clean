#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/codegen_snapshot"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$ROOT_DIR/.artifacts"

cd "$ROOT_DIR"
lake exe leancairo-gen --module Examples.Hello --out "$OUT_DIR" --emit-casm false

diff -u "$ROOT_DIR/tests/golden/hello/lib.cairo" "$OUT_DIR/src/lib.cairo"

echo "codegen snapshot passed"
