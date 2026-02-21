#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$BENCH_DIR/../../.." && pwd)"

GENERATED_SRC="$ROOT_DIR/examples/Cairo/fast_power_u128/src/lib.cairo"
BASELINE_SRC="$ROOT_DIR/examples/Cairo-Baseline/fast_power_u128/src/lib.cairo"
BASELINE_FAST_POWER_SRC="$ROOT_DIR/examples/Cairo-Baseline/fast_power_u128/src/fast_power.cairo"

GENERATED_DST="$BENCH_DIR/src/generated_function.cairo"
BASELINE_DST="$BENCH_DIR/src/baseline_function.cairo"
BASELINE_FAST_POWER_DST="$BENCH_DIR/src/fast_power.cairo"

if [[ ! -f "$GENERATED_SRC" ]]; then
  echo "error: generated source not found: $GENERATED_SRC" >&2
  exit 1
fi
if [[ ! -f "$BASELINE_SRC" ]]; then
  echo "error: baseline source not found: $BASELINE_SRC" >&2
  exit 1
fi
if [[ ! -f "$BASELINE_FAST_POWER_SRC" ]]; then
  echo "error: baseline fast_power source not found: $BASELINE_FAST_POWER_SRC" >&2
  exit 1
fi

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

fn_match = re.search(r"fn\s+pow13_u128\s*\((?P<params>.*?)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)\s*\{", impl_block, re.S)
if not fn_match:
    fail("failed to locate function pow13_u128 in generated impl")
fn_open = fn_match.end() - 1
fn_close = find_matching_brace(impl_block, fn_open)
fn_source = impl_block[fn_match.start():fn_close + 1]

brace_index = fn_source.find("{")
signature = fn_source[:brace_index].strip()
body = fn_source[brace_index:]
sig_match = re.match(r"fn\s+pow13_u128\s*\((?P<params>.*)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)", signature, re.S)
if not sig_match:
    fail("failed to parse function signature")
params_text = sig_match.group("params")
ret_ty = sig_match.group("ret")

parts = [p.strip() for p in params_text.split(",") if p.strip()]
filtered = [p for p in parts if not re.fullmatch(r"self\s*:\s*@ContractState", " ".join(p.split()))]
rendered_params = ", ".join(filtered)

out = (
    "// Synced from examples/Cairo/fast_power_u128/src/lib.cairo\n"
    "// Extracted function: pow13_u128 (self removed)\n\n"
    f"pub fn pow13_generated({rendered_params}) -> {ret_ty} {body}\n"
)
out_path.write_text(out, encoding="utf-8")
PY

cat > "$BASELINE_DST" <<'EOF2'
// Synced from examples/Cairo-Baseline/fast_power_u128/src/lib.cairo
use super::fast_power::fast_power;

pub fn pow13_baseline(x: u128) -> u128 {
    fast_power(x, 13_u128)
}
EOF2

cp "$BASELINE_FAST_POWER_SRC" "$BASELINE_FAST_POWER_DST"

echo "synced: $GENERATED_DST"
echo "synced: $BASELINE_DST"
echo "synced: $BASELINE_FAST_POWER_DST"
