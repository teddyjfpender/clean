#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/backend_parity"
export PATH="$HOME/.elan/bin:$PATH"

MODULE_NAME="${1:-}"
CONTRACT_NAME="${2:-}"
LABEL="${3:-backend parity}"

if [[ -z "$MODULE_NAME" || -z "$CONTRACT_NAME" ]]; then
  echo "usage: $0 <module-name> <contract-name> [label]"
  exit 1
fi

CASE_DIR="$OUT_DIR/$MODULE_NAME"
DIRECT_DIR="$CASE_DIR/direct_sierra"
CAIRO_DIR="$CASE_DIR/cairo"
DIRECT_PROGRAM="$DIRECT_DIR/sierra/program.sierra.json"

rm -rf "$CASE_DIR"
mkdir -p "$CASE_DIR"

(
  cd "$ROOT_DIR"
  lake exe leancairo-sierra-gen --module "$MODULE_NAME" --out "$DIRECT_DIR" --optimize true
  lake exe leancairo-gen --module "$MODULE_NAME" --out "$CAIRO_DIR" --emit-casm false --optimize true
)

(
  cd "$CAIRO_DIR"
  scarb build
)

INDEX_FILE="$(find "$CAIRO_DIR/target/dev" -maxdepth 1 -name '*.starknet_artifacts.json' | head -n 1)"
if [[ -z "$INDEX_FILE" ]]; then
  echo "backend parity: failed to locate artifacts index for module '$MODULE_NAME'"
  exit 1
fi

CONTRACT_CLASS="$(
  python3 "$ROOT_DIR/scripts/utils/find_contract_artifact.py" \
    --index "$INDEX_FILE" \
    --contract-name "$CONTRACT_NAME" | head -n 1
)"
if [[ -z "$CONTRACT_CLASS" || ! -f "$CONTRACT_CLASS" ]]; then
  echo "backend parity: failed to locate contract class for '$CONTRACT_NAME' in module '$MODULE_NAME'"
  exit 1
fi

if [[ ! -f "$DIRECT_PROGRAM" ]]; then
  echo "backend parity: missing direct Sierra program output for module '$MODULE_NAME' at $DIRECT_PROGRAM"
  exit 1
fi

python3 "$ROOT_DIR/scripts/utils/check_backend_parity.py" \
  --direct-sierra "$DIRECT_PROGRAM" \
  --contract-class "$CONTRACT_CLASS" \
  --label "$LABEL"
