#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$BENCH_DIR/../../.." && pwd)"

GENERATED_SRC="$ROOT_DIR/examples/Cairo/sq128x128_u128/src/lib.cairo"
UPSTREAM_SRC_DIR="${SQ128_UPSTREAM_DIR:-$ROOT_DIR/examples/Cairo-Baseline/sq128x128_u128/.artifacts/upstream-sq128-main}"

GENERATED_DST="$BENCH_DIR/src/generated_function.cairo"
BASELINE_FUNCTION_DST="$BENCH_DIR/src/baseline_function.cairo"
UPSTREAM_DST_ROOT="$BENCH_DIR/src/upstream"
UPSTREAM_DST_SQ128="$UPSTREAM_DST_ROOT/sq128"

required_generated=(
  "$GENERATED_SRC"
)

required_upstream=(
  "$UPSTREAM_SRC_DIR/common.cairo"
  "$UPSTREAM_SRC_DIR/sq128.cairo"
  "$UPSTREAM_SRC_DIR/advanced.cairo"
  "$UPSTREAM_SRC_DIR/arithmetic.cairo"
  "$UPSTREAM_SRC_DIR/constructors.cairo"
  "$UPSTREAM_SRC_DIR/internal.cairo"
  "$UPSTREAM_SRC_DIR/traits.cairo"
  "$UPSTREAM_SRC_DIR/types.cairo"
)

for p in "${required_generated[@]}"; do
  if [[ ! -f "$p" ]]; then
    echo "error: missing generated source: $p" >&2
    exit 1
  fi
done

for p in "${required_upstream[@]}"; do
  if [[ ! -f "$p" ]]; then
    echo "error: missing upstream source: $p" >&2
    echo "hint: run examples/Cairo-Baseline/sq128x128_u128/scripts/pull_upstream_sq128.sh" >&2
    exit 1
  fi
done

mkdir -p "$UPSTREAM_DST_SQ128"

cp "$UPSTREAM_SRC_DIR/common.cairo" "$UPSTREAM_DST_ROOT/common.cairo"
cp "$UPSTREAM_SRC_DIR/sq128.cairo" "$UPSTREAM_DST_ROOT/sq128.cairo"
cp "$UPSTREAM_SRC_DIR/advanced.cairo" "$UPSTREAM_DST_SQ128/advanced.cairo"
cp "$UPSTREAM_SRC_DIR/arithmetic.cairo" "$UPSTREAM_DST_SQ128/arithmetic.cairo"
cp "$UPSTREAM_SRC_DIR/constructors.cairo" "$UPSTREAM_DST_SQ128/constructors.cairo"
cp "$UPSTREAM_SRC_DIR/internal.cairo" "$UPSTREAM_DST_SQ128/internal.cairo"
cp "$UPSTREAM_SRC_DIR/traits.cairo" "$UPSTREAM_DST_SQ128/traits.cairo"
cp "$UPSTREAM_SRC_DIR/types.cairo" "$UPSTREAM_DST_SQ128/types.cairo"

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

function_names = [
    "sq128x128_add_raw",
    "sq128x128_sub_raw",
    "sq128x128_mul_raw",
    "sq128x128_delta_raw",
    "sq128x128_affine_kernel",
    "sq128x128_add_raw_u8",
    "sq128x128_sub_raw_u8",
    "sq128x128_mul_raw_u8",
    "sq128x128_delta_raw_u8",
    "sq128x128_affine_kernel_u8",
    "sq128x128_add_raw_u16",
    "sq128x128_sub_raw_u16",
    "sq128x128_mul_raw_u16",
    "sq128x128_delta_raw_u16",
    "sq128x128_affine_kernel_u16",
    "sq128x128_add_raw_u32",
    "sq128x128_sub_raw_u32",
    "sq128x128_mul_raw_u32",
    "sq128x128_delta_raw_u32",
    "sq128x128_affine_kernel_u32",
    "sq128x128_add_raw_u64",
    "sq128x128_sub_raw_u64",
    "sq128x128_mul_raw_u64",
    "sq128x128_delta_raw_u64",
    "sq128x128_affine_kernel_u64",
]

chunks: list[str] = [
    "// Synced from examples/Cairo/sq128x128_u128/src/lib.cairo",
    "// Extracted generated functions with `self: @ContractState` removed.",
    "",
]

for fn_name in function_names:
    pattern = re.compile(
        rf"fn\s+{re.escape(fn_name)}\s*\((?P<params>.*?)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)\s*\{{",
        re.S,
    )
    fn_match = pattern.search(impl_block)
    if not fn_match:
        fail(f"failed to locate function {fn_name} in generated impl")

    fn_open = fn_match.end() - 1
    fn_close = find_matching_brace(impl_block, fn_open)
    fn_source = impl_block[fn_match.start():fn_close + 1]

    brace_index = fn_source.find("{")
    signature = fn_source[:brace_index].strip()
    body = fn_source[brace_index:]

    sig_match = re.match(
        rf"fn\s+{re.escape(fn_name)}\s*\((?P<params>.*)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)",
        signature,
        re.S,
    )
    if not sig_match:
        fail(f"failed to parse function signature for {fn_name}")

    params_text = sig_match.group("params")
    ret_ty = sig_match.group("ret")
    parts = [p.strip() for p in params_text.split(",") if p.strip()]
    filtered = [p for p in parts if not re.fullmatch(r"self\s*:\s*@ContractState", " ".join(p.split()))]
    rendered_params = ", ".join(filtered)

    chunks.append(f"pub fn {fn_name}_generated({rendered_params}) -> {ret_ty} {body}")
    chunks.append("")

out_path.write_text("\n".join(chunks).rstrip() + "\n", encoding="utf-8")
PY

cat > "$BASELINE_FUNCTION_DST" <<'EOF2'
// Wrappers over freshly pulled upstream SQ128 modules.

use super::upstream::sq128::{
    SQ128x128,
    U128IntoSQ128x128,
    add_unchecked,
    delta,
    mul_down_unchecked,
    sub_unchecked,
    to_raw,
};

const TWO_POW_64: u128 = 0x1_0000_0000_0000_0000_u128;
const TWO_POW_32: u64 = 0x1_0000_0000_u64;
const TWO_POW_16: u32 = 0x1_0000_u32;
const TWO_POW_8: u16 = 0x100_u16;

fn sq_to_u128_integer_unchecked(value: SQ128x128) -> u128 {
    let raw = to_raw(value);
    assert(raw.neg == false, 'sq_neg');
    assert(raw.limb0 == 0_u64, 'sq_frac0');
    assert(raw.limb1 == 0_u64, 'sq_frac1');
    raw.limb2.into() + raw.limb3.into() * TWO_POW_64
}

fn wrap_u64(value: u128) -> u64 {
    (value % TWO_POW_64).try_into().unwrap()
}

fn wrap_u32(value: u64) -> u32 {
    (value % TWO_POW_32).try_into().unwrap()
}

fn wrap_u16(value: u32) -> u16 {
    (value % TWO_POW_16).try_into().unwrap()
}

fn wrap_u8(value: u16) -> u8 {
    (value % TWO_POW_8).try_into().unwrap()
}

pub fn sq128x128_add_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(add_unchecked(a, b))
}

pub fn sq128x128_sub_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(sub_unchecked(a, b))
}

pub fn sq128x128_mul_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(mul_down_unchecked(a, b))
}

pub fn sq128x128_delta_raw_baseline_fn(a_raw: u128, b_raw: u128) -> u128 {
    let a: SQ128x128 = a_raw.into();
    let b: SQ128x128 = b_raw.into();
    sq_to_u128_integer_unchecked(delta(a, b))
}

pub fn sq128x128_affine_kernel_baseline_fn(
    a_raw: u128, b_raw: u128, c_raw: u128, d_raw: u128, e_raw: u128,
) -> u128 {
    let sum_ab = sq128x128_add_raw_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    wrap_u16(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    wrap_u16(a_raw.into() + TWO_POW_16 - b_raw.into())
}

pub fn sq128x128_mul_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    wrap_u16(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u16_baseline_fn(a_raw: u16, b_raw: u16) -> u16 {
    sq128x128_sub_raw_u16_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u16_baseline_fn(
    a_raw: u16, b_raw: u16, c_raw: u16, d_raw: u16, e_raw: u16,
) -> u16 {
    let sum_ab = sq128x128_add_raw_u16_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u16_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u16_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u16_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    wrap_u8(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    wrap_u8(a_raw.into() + TWO_POW_8 - b_raw.into())
}

pub fn sq128x128_mul_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    wrap_u8(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u8_baseline_fn(a_raw: u8, b_raw: u8) -> u8 {
    sq128x128_sub_raw_u8_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u8_baseline_fn(
    a_raw: u8, b_raw: u8, c_raw: u8, d_raw: u8, e_raw: u8,
) -> u8 {
    let sum_ab = sq128x128_add_raw_u8_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u8_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u8_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u8_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    wrap_u32(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    wrap_u32(a_raw.into() + TWO_POW_32 - b_raw.into())
}

pub fn sq128x128_mul_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    wrap_u32(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u32_baseline_fn(a_raw: u32, b_raw: u32) -> u32 {
    sq128x128_sub_raw_u32_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u32_baseline_fn(
    a_raw: u32, b_raw: u32, c_raw: u32, d_raw: u32, e_raw: u32,
) -> u32 {
    let sum_ab = sq128x128_add_raw_u32_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u32_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u32_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u32_baseline_fn(mul_term, e_raw)
}

pub fn sq128x128_add_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    wrap_u64(a_raw.into() + b_raw.into())
}

pub fn sq128x128_sub_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    wrap_u64(a_raw.into() + TWO_POW_64 - b_raw.into())
}

pub fn sq128x128_mul_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    wrap_u64(a_raw.into() * b_raw.into())
}

pub fn sq128x128_delta_raw_u64_baseline_fn(a_raw: u64, b_raw: u64) -> u64 {
    sq128x128_sub_raw_u64_baseline_fn(b_raw, a_raw)
}

pub fn sq128x128_affine_kernel_u64_baseline_fn(
    a_raw: u64, b_raw: u64, c_raw: u64, d_raw: u64, e_raw: u64,
) -> u64 {
    let sum_ab = sq128x128_add_raw_u64_baseline_fn(a_raw, b_raw);
    let delta_cd = sq128x128_sub_raw_u64_baseline_fn(c_raw, d_raw);
    let mul_term = sq128x128_mul_raw_u64_baseline_fn(sum_ab, delta_cd);
    sq128x128_add_raw_u64_baseline_fn(mul_term, e_raw)
}
EOF2

echo "synced: $GENERATED_DST"
echo "synced: $BASELINE_FUNCTION_DST"
echo "synced: $UPSTREAM_DST_ROOT/common.cairo"
echo "synced: $UPSTREAM_DST_ROOT/sq128.cairo"
echo "synced: $UPSTREAM_DST_SQ128/{advanced,arithmetic,constructors,internal,traits,types}.cairo"
