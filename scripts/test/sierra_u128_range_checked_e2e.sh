#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_u128_range_checked_e2e"
PROGRAM_JSON="$OUT_DIR/generated/sierra/program.sierra.json"
CASM_OUT="$OUT_DIR/generated/sierra/program.casm"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

(
  cd "$ROOT_DIR"
  lake exe leancairo-sierra-gen --module MyLeanSierraU128RangeChecked --out "$OUT_DIR/generated" --optimize true
)

python3 - "$PROGRAM_JSON" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    program = json.load(f)

for fn in program["funcs"]:
    name = fn["id"]["debug_name"]
    if name in {"addU128Wrapping", "subU128Wrapping", "mulU128Wrapping"}:
        params = fn["signature"]["param_types"]
        rets = fn["signature"]["ret_types"]
        if len(params) != 3 or params[0]["debug_name"] != "RangeCheck":
            raise SystemExit(f"missing explicit RangeCheck param in function '{name}'")
        if len(rets) != 2 or rets[0]["debug_name"] != "RangeCheck" or rets[1]["debug_name"] != "u128":
            raise SystemExit(f"missing explicit RangeCheck return lane in function '{name}'")
PY

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  validate --input "$PROGRAM_JSON" >/dev/null

cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
  compile --input "$PROGRAM_JSON" --out-casm "$CASM_OUT" >/dev/null

test -s "$CASM_OUT"

echo "sierra u128 range-checked e2e (validate + compile) passed"
