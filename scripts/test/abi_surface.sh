#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
  echo "usage: $0 <generated-project-dir> <expected-abi-json> [contract-name]" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GENERATED_DIR="$1"
EXPECTED_ABI="$2"
CONTRACT_NAME="${3:-}"

index_file="$(find "$GENERATED_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
if [[ -z "$index_file" ]]; then
  echo "could not locate *.starknet_artifacts.json under $GENERATED_DIR/target/dev" >&2
  exit 1
fi

if [[ -n "$CONTRACT_NAME" ]]; then
  python3 "$ROOT_DIR/scripts/utils/check_abi_surface.py" \
    --index "$index_file" \
    --expect "$EXPECTED_ABI" \
    --contract-name "$CONTRACT_NAME"
else
  python3 "$ROOT_DIR/scripts/utils/check_abi_surface.py" \
    --index "$index_file" \
    --expect "$EXPECTED_ABI"
fi
