#!/usr/bin/env python3
"""Check Lean->Sierra function signatures against Lean->Cairo ABI signatures."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


DIRECT_TO_ABI = {
    "felt252": "core::felt252",
    "u128": "core::integer::u128",
    "u256": "core::integer::u256",
    "bool": "core::bool",
    "core::bool": "core::bool",
    "i8": "core::integer::i8",
    "i16": "core::integer::i16",
    "i32": "core::integer::i32",
    "i64": "core::integer::i64",
    "i128": "core::integer::i128",
    "u8": "core::integer::u8",
    "u16": "core::integer::u16",
    "u32": "core::integer::u32",
    "u64": "core::integer::u64",
    "qm31": "core::qm31",
    "RangeCheck": "core::range_check::RangeCheck",
    "GasBuiltin": "core::gas::GasBuiltin",
    "SegmentArena": "core::segment_arena::SegmentArena",
    "PanicSignal": "core::panic::PanicSignal",
}

RESOURCE_TYPES = {
    "core::range_check::RangeCheck",
    "core::gas::GasBuiltin",
    "core::segment_arena::SegmentArena",
    "core::panic::PanicSignal",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--direct-sierra", required=True, help="Path to direct Sierra program json")
    parser.add_argument("--contract-class", required=True, help="Path to Cairo contract class json")
    parser.add_argument(
        "--label",
        default="backend parity",
        help="Friendly label used in diagnostics",
    )
    return parser.parse_args()


def to_snake_case(value: str) -> str:
    out: list[str] = []
    is_first = True
    previous_underscore = False
    for char in value:
        if char.isupper():
            if not is_first and not previous_underscore:
                out.append("_")
            out.append(char.lower())
            previous_underscore = False
        else:
            if char in "- .":
                mapped = "_"
            elif char.isalnum() or char == "_":
                mapped = char
            else:
                mapped = "_"
            out.append(mapped)
            previous_underscore = mapped == "_"
        is_first = False
    return "".join(out)


def canonicalize_type(debug_name: str) -> str:
    return DIRECT_TO_ABI.get(debug_name, debug_name)


def normalize_signature_types(types: list[str]) -> list[str]:
    canonical = [canonicalize_type(t) for t in types]
    return [t for t in canonical if t not in RESOURCE_TYPES]


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def collect_direct_signatures(payload: dict) -> dict[str, dict[str, list[str]]]:
    signatures: dict[str, dict[str, list[str]]] = {}
    funcs = payload.get("funcs", [])
    for func in funcs:
        func_id = func.get("id", {})
        debug_name = func_id.get("debug_name")
        if not isinstance(debug_name, str) or debug_name == "":
            raise ValueError("direct Sierra function id is missing debug_name")
        signature = func.get("signature", {})
        param_types = [
            entry.get("debug_name", "")
            for entry in signature.get("param_types", [])
            if isinstance(entry, dict)
        ]
        ret_types = [
            entry.get("debug_name", "")
            for entry in signature.get("ret_types", [])
            if isinstance(entry, dict)
        ]
        name = to_snake_case(debug_name)
        signatures[name] = {
            "params": normalize_signature_types(param_types),
            "outputs": normalize_signature_types(ret_types),
        }
    return signatures


def collect_abi_signatures(payload: dict) -> dict[str, dict[str, list[str]]]:
    signatures: dict[str, dict[str, list[str]]] = {}
    abi = payload.get("abi", [])
    for entry in abi:
        if entry.get("type") != "interface":
            continue
        for item in entry.get("items", []):
            if item.get("type") != "function":
                continue
            name = item.get("name")
            if not isinstance(name, str) or name == "":
                raise ValueError("ABI function missing name")
            params = [inp.get("type", "") for inp in item.get("inputs", [])]
            outputs = [out.get("type", "") for out in item.get("outputs", [])]
            signatures[name] = {"params": params, "outputs": outputs}
    return signatures


def render_sig(signature: dict[str, list[str]]) -> str:
    params = ", ".join(signature["params"])
    outputs = ", ".join(signature["outputs"])
    return f"({params}) -> ({outputs})"


def main() -> int:
    args = parse_args()
    direct_payload = load_json(Path(args.direct_sierra))
    contract_payload = load_json(Path(args.contract_class))

    direct_sigs = collect_direct_signatures(direct_payload)
    abi_sigs = collect_abi_signatures(contract_payload)

    errors: list[str] = []
    for fn_name, direct_sig in sorted(direct_sigs.items()):
        abi_sig = abi_sigs.get(fn_name)
        if abi_sig is None:
            errors.append(
                f"{args.label}: missing ABI function for direct function '{fn_name}'"
            )
            continue
        if abi_sig["params"] != direct_sig["params"] or abi_sig["outputs"] != direct_sig["outputs"]:
            errors.append(
                f"{args.label}: signature mismatch for '{fn_name}': "
                f"direct {render_sig(direct_sig)} vs cairo {render_sig(abi_sig)}"
            )

    extra = sorted(set(abi_sigs.keys()) - set(direct_sigs.keys()))
    for fn_name in extra:
        errors.append(f"{args.label}: extra Cairo ABI function not present in direct Sierra: '{fn_name}'")

    if errors:
        for err in errors:
            print(err)
        print(f"{args.label}: parity check failed with {len(errors)} error(s)")
        return 1

    print(
        f"{args.label}: parity check passed "
        f"({len(direct_sigs)} shared signatures)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
