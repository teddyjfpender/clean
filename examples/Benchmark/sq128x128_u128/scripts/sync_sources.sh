#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$BENCH_DIR/../../.." && pwd)"

GENERATED_SRC="$ROOT_DIR/examples/Cairo/sq128x128_u128/src/lib.cairo"
BASELINE_TYPES_SRC="$ROOT_DIR/examples/Cairo-Baseline/sq128x128_u128/src/types.cairo"
BASELINE_ARITH_SRC="$ROOT_DIR/examples/Cairo-Baseline/sq128x128_u128/src/arithmetic.cairo"

GENERATED_DST="$BENCH_DIR/src/generated_function.cairo"
BASELINE_TYPES_DST="$BENCH_DIR/src/baseline_types.cairo"
BASELINE_ARITH_DST="$BENCH_DIR/src/baseline_arithmetic.cairo"
BASELINE_FUNCTION_DST="$BENCH_DIR/src/baseline_function.cairo"

for p in "$GENERATED_SRC" "$BASELINE_TYPES_SRC" "$BASELINE_ARITH_SRC"; do
  if [[ ! -f "$p" ]]; then
    echo "error: missing source: $p" >&2
    exit 1
  fi
done

python3 - "$GENERATED_SRC" "$GENERATED_DST" <<'PY'
import re
import sys
from pathlib import Path

src_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
source = src_path.read_text(encoding="utf-8")

def fail(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(1)

def find_matching_brace(text: str, open_index: int) -> int:
    depth = 0
    for idx in range(open_index, len(text)):
        ch = text[idx]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return idx
    fail("unbalanced braces")
    return -1

impl_match = re.search(r"impl\s+[A-Za-z0-9_]+\s+of\s+super::[A-Za-z0-9_<>]+\s*\{", source, re.S)
if not impl_match:
    fail("failed to locate impl block in generated Cairo source")
impl_open = impl_match.end() - 1
impl_close = find_matching_brace(source, impl_open)
impl_block = source[impl_match.start():impl_close + 1]

fn_match = re.search(r"fn\s+sq128x128_affine_kernel\s*\((?P<params>.*?)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)\s*\{", impl_block, re.S)
if not fn_match:
    fail("failed to locate function sq128x128_affine_kernel in generated impl")
fn_open = fn_match.end() - 1
fn_close = find_matching_brace(impl_block, fn_open)
fn_source = impl_block[fn_match.start():fn_close + 1]

brace_index = fn_source.find("{")
signature = fn_source[:brace_index].strip()
body = fn_source[brace_index:]
sig_match = re.match(r"fn\s+sq128x128_affine_kernel\s*\((?P<params>.*)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)", signature, re.S)
if not sig_match:
    fail("failed to parse function signature")
params_text = sig_match.group("params")
ret_ty = sig_match.group("ret")

parts = [p.strip() for p in params_text.split(",") if p.strip()]
filtered = [p for p in parts if not re.fullmatch(r"self\s*:\s*@ContractState", " ".join(p.split()))]
rendered_params = ", ".join(filtered)

out = (
    "// Synced from examples/Cairo/sq128x128_u128/src/lib.cairo\n"
    "// Extracted function: sq128x128_affine_kernel (self removed)\n\n"
    f"pub fn sq128x128_affine_kernel_generated({rendered_params}) -> {ret_ty} {body}\n"
)
out_path.write_text(out, encoding="utf-8")
PY

cp "$BASELINE_TYPES_SRC" "$BASELINE_TYPES_DST"
python3 - "$BASELINE_ARITH_SRC" "$BASELINE_ARITH_DST" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1]).read_text(encoding="utf-8")
src = src.replace("super::types", "super::baseline_types")
Path(sys.argv[2]).write_text(src, encoding="utf-8")
PY

cat > "$BASELINE_FUNCTION_DST" <<'EOF2'
// Wrapper to keep benchmark call-sites stable.
use super::baseline_arithmetic::sq128x128_affine_kernel_baseline;

pub fn sq128x128_affine_kernel_baseline_fn(
    a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128
) -> u128 {
    sq128x128_affine_kernel_baseline(a_raw, b_raw, c_raw, d_raw, e_raw)
}
EOF2

echo "synced: $GENERATED_DST"
echo "synced: $BASELINE_TYPES_DST"
echo "synced: $BASELINE_ARITH_DST"
echo "synced: $BASELINE_FUNCTION_DST"
