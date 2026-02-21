#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_scalar_e2e"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

run_case() {
  local module_name="$1"
  local case_name="$2"
  local case_dir="$OUT_DIR/$case_name"
  local program_json="$case_dir/generated/sierra/program.sierra.json"
  local casm_out="$case_dir/generated/sierra/program.casm"

  (
    cd "$ROOT_DIR"
    lake exe leancairo-sierra-gen --module "$module_name" --out "$case_dir/generated" --optimize true
  )

  cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
    validate --input "$program_json" >/dev/null

  cargo run --manifest-path "$ROOT_DIR/tools/sierra_toolchain/Cargo.toml" -- \
    compile --input "$program_json" --out-casm "$casm_out" >/dev/null

  test -s "$casm_out"
}

run_case "MyLeanSierraScalar" "scalar_core"
run_case "MyLeanSierraIntSignatures" "integer_signatures"

python3 - <<'PY' "$OUT_DIR/integer_signatures/generated/sierra/program.sierra.json"
import json
import sys

path = sys.argv[1]
required = {"i8", "i16", "i32", "i64", "i128", "u8", "u16", "u32", "u64"}

with open(path, "r", encoding="utf-8") as f:
    program = json.load(f)

decls = program.get("type_declarations", [])
present = set()
for entry in decls:
    if isinstance(entry, dict):
        ident = entry.get("id")
        if isinstance(ident, dict):
            debug_name = ident.get("debug_name")
            if isinstance(debug_name, str):
                present.add(debug_name)

missing = sorted(required - present)
if missing:
    raise SystemExit(f"missing integer type declarations: {missing}")
PY

echo "sierra scalar e2e (validate + compile) passed"
