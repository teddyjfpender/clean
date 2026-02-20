#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/generated_contract"

rm -rf "$OUT_DIR"

"$ROOT_DIR/scripts/workflow/generate-from-lean.sh" \
  --module MyLeanContract \
  --out "$OUT_DIR" \
  --emit-casm false

"$ROOT_DIR/scripts/workflow/build-generated-contract.sh" "$OUT_DIR"

index_file="$(find "$OUT_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
python3 "$ROOT_DIR/scripts/utils/find_contract_artifact.py" \
  --index "$index_file" \
  --contract-name HelloContract
