#!/usr/bin/env python3
"""Build fixedpoint_bench Cairo source from Lean-generated baseline/optimized outputs.

Specification:
- Inputs:
  - --baseline-lib: path to Cairo file generated with --optimize false
  - --optimized-lib: path to Cairo file generated with --optimize true
  - --out: output path for packages/fixedpoint_bench/src/lib.cairo
- Outputs:
  - Writes deterministic standalone benchmark source that exposes executable entrypoints:
    bench_qmul_hand/opt, bench_qexp_hand/opt, bench_qlog_hand/opt,
    bench_qnewton_hand/opt, bench_fib_naive/fast.
- Invariants:
  - Hand/opt kernels are extracted from Lean IR generated contract functions.
  - Function signatures in output contain no ContractState self parameter.
  - Output is deterministic for identical inputs.
- Failure modes:
  - Missing input files, parse failures, or missing target functions => non-zero exit.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


KERNEL_FUNCTIONS = [
    "qmul_kernel",
    "qexp_taylor",
    "qlog1p_taylor",
    "qnewton_recip",
]


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
    fail("unbalanced braces while parsing function body")
    return -1


def split_params(params_text: str) -> list[str]:
    params: list[str] = []
    cur = []
    depth_round = depth_square = depth_curly = depth_angle = 0
    for ch in params_text:
        if ch == "(":
            depth_round += 1
        elif ch == ")":
            depth_round -= 1
        elif ch == "[":
            depth_square += 1
        elif ch == "]":
            depth_square -= 1
        elif ch == "{":
            depth_curly += 1
        elif ch == "}":
            depth_curly -= 1
        elif ch == "<":
            depth_angle += 1
        elif ch == ">":
            depth_angle -= 1

        if (
            ch == ","
            and depth_round == 0
            and depth_square == 0
            and depth_curly == 0
            and depth_angle == 0
        ):
            part = "".join(cur).strip()
            if part:
                params.append(part)
            cur = []
        else:
            cur.append(ch)

    tail = "".join(cur).strip()
    if tail:
        params.append(tail)
    return params


def extract_impl_block(source: str) -> str:
    pattern = re.compile(
        r"impl\s+[A-Za-z0-9_]+\s+of\s+super::[A-Za-z0-9_<>]+\s*\{",
        re.S,
    )
    match = pattern.search(source)
    if not match:
        fail("failed to locate contract impl block in generated Cairo source")

    brace_index = match.end() - 1
    close_index = find_matching_brace(source, brace_index)
    return source[match.start() : close_index + 1]


def extract_function_source(impl_block: str, function_name: str) -> str:
    pattern = re.compile(
        rf"fn\s+{re.escape(function_name)}\s*\((?P<params>.*?)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)\s*\{{",
        re.S,
    )
    match = pattern.search(impl_block)
    if not match:
        fail(f"failed to locate function with body: {function_name}")

    brace_index = match.end() - 1
    close_index = find_matching_brace(impl_block, brace_index)
    return impl_block[match.start() : close_index + 1]


def rewrite_as_standalone(function_source: str, new_name: str) -> str:
    brace_index = function_source.find("{")
    if brace_index < 0:
        fail(f"failed to parse function signature for {new_name}")

    signature = function_source[:brace_index].strip()
    body = function_source[brace_index:]

    sig_match = re.match(
        r"fn\s+(?P<name>[A-Za-z0-9_]+)\s*\((?P<params>.*)\)\s*->\s*(?P<ret>[A-Za-z0-9_]+)\s*$",
        signature,
        re.S,
    )
    if not sig_match:
        fail(f"failed to match function signature for {new_name}")

    params_text = sig_match.group("params")
    ret_ty = sig_match.group("ret")

    params = split_params(params_text)
    filtered_params = []
    for param in params:
        normalized = " ".join(param.split())
        if re.fullmatch(r"self\s*:\s*@ContractState", normalized):
            continue
        if re.fullmatch(r"ref\s+self\s*:\s*ContractState", normalized):
            continue
        filtered_params.append(param.strip())

    rendered_params = ", ".join(filtered_params)
    return f"fn {new_name}({rendered_params}) -> {ret_ty} {body}"


def render_output(hand_functions: dict[str, str], opt_functions: dict[str, str]) -> str:
    ordered_functions: list[str] = []
    for name in KERNEL_FUNCTIONS:
        ordered_functions.append(hand_functions[name])
        ordered_functions.append(opt_functions[name])

    kernels_block = "\n\n".join(ordered_functions)

    return (
        "// Generated by scripts/bench/generate_fixedpoint_bench.sh from Lean IR outputs.\n"
        "// Source module: MyLeanFixedPointBench (baseline --optimize false, optimized --optimize true).\n"
        "// Do not edit this file directly.\n"
        "use core::integer::u256;\n\n"
        f"{kernels_block}\n\n"
        "fn u256_from_u128(v: u128) -> u256 {\n"
        "    u256 { low: v, high: 0 }\n"
        "}\n\n"
        "fn fib_naive(n: u32) -> u128 {\n"
        "    if n <= 1 {\n"
        "        n.into()\n"
        "    } else {\n"
        "        fib_naive(n - 1) + fib_naive(n - 2)\n"
        "    }\n"
        "}\n\n"
        "fn fib_pair_fast(n: u32) -> (u128, u128) {\n"
        "    if n == 0 {\n"
        "        (0, 1)\n"
        "    } else {\n"
        "        let (a, b) = fib_pair_fast(n / 2);\n"
        "        let c = a * (2 * b - a);\n"
        "        let d = a * a + b * b;\n"
        "        if n % 2 == 0 {\n"
        "            (c, d)\n"
        "        } else {\n"
        "            (d, c + d)\n"
        "        }\n"
        "    }\n"
        "}\n\n"
        "fn fib_fast(n: u32) -> u128 {\n"
        "    let (f, _) = fib_pair_fast(n);\n"
        "    f\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qmul_hand() -> u256 {\n"
        "    qmul_kernel_hand(u256_from_u128(17), u256_from_u128(9), u256_from_u128(5))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qmul_opt() -> u256 {\n"
        "    qmul_kernel_opt(u256_from_u128(17), u256_from_u128(9), u256_from_u128(5))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qexp_hand() -> u256 {\n"
        "    qexp_taylor_hand(u256_from_u128(11))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qexp_opt() -> u256 {\n"
        "    qexp_taylor_opt(u256_from_u128(11))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qlog_hand() -> u256 {\n"
        "    qlog1p_taylor_hand(u256_from_u128(13))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qlog_opt() -> u256 {\n"
        "    qlog1p_taylor_opt(u256_from_u128(13))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qnewton_hand() -> u256 {\n"
        "    qnewton_recip_hand(u256_from_u128(3))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_qnewton_opt() -> u256 {\n"
        "    qnewton_recip_opt(u256_from_u128(3))\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_fib_naive() -> u128 {\n"
        "    fib_naive(22)\n"
        "}\n\n"
        "#[executable]\n"
        "fn bench_fib_fast() -> u128 {\n"
        "    fib_fast(22)\n"
        "}\n\n"
        "#[cfg(test)]\n"
        "mod tests {\n"
        "    use super::{\n"
        "        qmul_kernel_hand,\n"
        "        qmul_kernel_opt,\n"
        "        qexp_taylor_hand,\n"
        "        qexp_taylor_opt,\n"
        "        qlog1p_taylor_hand,\n"
        "        qlog1p_taylor_opt,\n"
        "        qnewton_recip_hand,\n"
        "        qnewton_recip_opt,\n"
        "        fib_naive,\n"
        "        fib_fast,\n"
        "        u256_from_u128,\n"
        "    };\n\n"
        "    #[test]\n"
        "    fn test_qmul_equivalence() {\n"
        "        let a = u256_from_u128(17);\n"
        "        let b = u256_from_u128(9);\n"
        "        let c = u256_from_u128(5);\n"
        "        assert_eq!(qmul_kernel_hand(a, b, c), qmul_kernel_opt(a, b, c));\n"
        "    }\n\n"
        "    #[test]\n"
        "    fn test_qexp_equivalence() {\n"
        "        let x = u256_from_u128(11);\n"
        "        assert_eq!(qexp_taylor_hand(x), qexp_taylor_opt(x));\n"
        "    }\n\n"
        "    #[test]\n"
        "    fn test_qlog_equivalence() {\n"
        "        let z = u256_from_u128(13);\n"
        "        assert_eq!(qlog1p_taylor_hand(z), qlog1p_taylor_opt(z));\n"
        "    }\n\n"
        "    #[test]\n"
        "    fn test_qnewton_equivalence() {\n"
        "        let x = u256_from_u128(3);\n"
        "        assert_eq!(qnewton_recip_hand(x), qnewton_recip_opt(x));\n"
        "    }\n\n"
        "    #[test]\n"
        "    fn test_fib_equivalence() {\n"
        "        assert_eq!(fib_naive(22), fib_fast(22));\n"
        "    }\n"
        "}\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline-lib", required=True)
    parser.add_argument("--optimized-lib", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    baseline_path = Path(args.baseline_lib)
    optimized_path = Path(args.optimized_lib)
    out_path = Path(args.out)

    if not baseline_path.is_file():
        fail(f"baseline file does not exist: {baseline_path}")
    if not optimized_path.is_file():
        fail(f"optimized file does not exist: {optimized_path}")

    baseline_source = baseline_path.read_text(encoding="utf-8")
    optimized_source = optimized_path.read_text(encoding="utf-8")
    baseline_impl = extract_impl_block(baseline_source)
    optimized_impl = extract_impl_block(optimized_source)

    hand_functions: dict[str, str] = {}
    opt_functions: dict[str, str] = {}

    for name in KERNEL_FUNCTIONS:
        hand_src = extract_function_source(baseline_impl, name)
        opt_src = extract_function_source(optimized_impl, name)
        hand_functions[name] = rewrite_as_standalone(hand_src, f"{name}_hand")
        opt_functions[name] = rewrite_as_standalone(opt_src, f"{name}_opt")

    rendered = render_output(hand_functions, opt_functions)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(rendered, encoding="utf-8")
    print(f"generated: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
