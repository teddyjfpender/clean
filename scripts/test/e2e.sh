#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/e2e/generated_contract"

rm -rf "$OUT_DIR"
mkdir -p "$ROOT_DIR/.artifacts/e2e"

cd "$ROOT_DIR"
lake exe leancairo-gen --module MyLeanContract --out "$OUT_DIR" --emit-casm false

(
  cd "$OUT_DIR"
  scarb build
)

"$ROOT_DIR/scripts/test/abi_surface.sh" \
  "$OUT_DIR" \
  "$ROOT_DIR/tests/fixtures/hello_expected_abi.json" \
  "HelloContract"

index_file="$(find "$OUT_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
python3 "$OUT_DIR/scripts/find_contract_artifact.py" --index "$index_file" --contract HelloContract >/dev/null

echo "end-to-end Lean -> Cairo -> Scarb checks passed"
