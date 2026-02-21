#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$BENCH_DIR/../../.." && pwd)"

GENERATED_SRC="$ROOT_DIR/examples/Cairo/karatsuba_u128/src/lib.cairo"
BASELINE_KARATSUBA_SRC="$ROOT_DIR/examples/Cairo-Baseline/karatsuba_u128/src/karatsuba.cairo"
BASELINE_CONST_POW_SRC="$ROOT_DIR/examples/Cairo-Baseline/karatsuba_u128/src/const_pow.cairo"

GENERATED_DST="$BENCH_DIR/src/generated_function.cairo"
BASELINE_KARATSUBA_DST="$BENCH_DIR/src/baseline_karatsuba.cairo"
BASELINE_CONST_POW_DST="$BENCH_DIR/src/baseline_const_pow.cairo"
BASELINE_FUNCTION_DST="$BENCH_DIR/src/baseline_function.cairo"

for p in "$GENERATED_SRC" "$BASELINE_KARATSUBA_SRC" "$BASELINE_CONST_POW_SRC"; do
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

fn_match = re.search(r"fn\s+karatsuba_combine\s*\((?P<params>.*?)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)\s*\{", impl_block, re.S)
if not fn_match:
    fail("failed to locate function karatsuba_combine in generated impl")
fn_open = fn_match.end() - 1
fn_close = find_matching_brace(impl_block, fn_open)
fn_source = impl_block[fn_match.start():fn_close + 1]

brace_index = fn_source.find("{")
signature = fn_source[:brace_index].strip()
body = fn_source[brace_index:]
sig_match = re.match(r"fn\s+karatsuba_combine\s*\((?P<params>.*)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)", signature, re.S)
if not sig_match:
    fail("failed to parse function signature")
params_text = sig_match.group("params")
ret_ty = sig_match.group("ret")

parts = [p.strip() for p in params_text.split(",") if p.strip()]
filtered = [p for p in parts if not re.fullmatch(r"self\s*:\s*@ContractState", " ".join(p.split()))]
rendered_params = ", ".join(filtered)

out = (
    "// Synced from examples/Cairo/karatsuba_u128/src/lib.cairo\n"
    "// Extracted function: karatsuba_combine (self removed)\n\n"
    f"pub fn karatsuba_combine_generated({rendered_params}) -> {ret_ty} {body}\n"
)
out_path.write_text(out, encoding="utf-8")
PY

python3 - "$BASELINE_KARATSUBA_SRC" "$BASELINE_KARATSUBA_DST" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1]).read_text(encoding="utf-8")
# Keep Alexandria source but patch import/module path and div_half_ceil termination.
src = src.replace("super::const_pow", "super::baseline_const_pow")
src = src.replace("(num + 1) % 2", "(num + 1) / 2")
Path(sys.argv[2]).write_text(src, encoding="utf-8")
PY

cp "$BASELINE_CONST_POW_SRC" "$BASELINE_CONST_POW_DST"

cat > "$BASELINE_FUNCTION_DST" <<'EOF2'
// Synced wrapper for Alexandria baseline karatsuba.
use super::baseline_karatsuba::multiply;

pub fn karatsuba_baseline(x: u128, y: u128) -> u128 {
    multiply(x, y)
}
EOF2

echo "synced: $GENERATED_DST"
echo "synced: $BASELINE_KARATSUBA_DST"
echo "synced: $BASELINE_CONST_POW_DST"
echo "synced: $BASELINE_FUNCTION_DST"
