#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_aggregate_collection_e2e"
PROGRAM_JSON="$OUT_DIR/generated/sierra/program.sierra.json"
CASM_OUT="$OUT_DIR/generated/sierra/program.casm"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

(
  cd "$ROOT_DIR"
  lake exe leancairo-sierra-gen --module MyLeanSierraAggregateCollection --out "$OUT_DIR/generated" --optimize true
)

python3 - "$PROGRAM_JSON" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    program = json.load(f)

required_debug_names = {
    "Tuple2",
    "AggPair",
    "AggChoice",
    "Array<felt252>",
    "Span<felt252>",
    "Nullable<felt252>",
    "Box<felt252>",
}
required_generic_ids = {"Struct", "Enum", "Array", "Span", "Nullable", "Box"}

decls = program.get("type_declarations", [])
debug_names = {decl.get("id", {}).get("debug_name", "") for decl in decls}
generic_ids = {decl.get("long_id", {}).get("generic_id", "") for decl in decls}

missing_debug_names = sorted(required_debug_names - debug_names)
missing_generic_ids = sorted(required_generic_ids - generic_ids)
if missing_debug_names:
    raise SystemExit(f"missing expected aggregate/collection type declarations: {missing_debug_names}")
if missing_generic_ids:
    raise SystemExit(f"missing expected aggregate/collection generic type ids: {missing_generic_ids}")
PY

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  validate --input "$PROGRAM_JSON" >/dev/null

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  compile --input "$PROGRAM_JSON" --out-casm "$CASM_OUT" >/dev/null

test -s "$CASM_OUT"

echo "sierra aggregate/collection e2e (validate + compile) passed"
