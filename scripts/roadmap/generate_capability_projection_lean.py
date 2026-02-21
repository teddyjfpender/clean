#!/usr/bin/env python3
"""Generate Lean capability projection constants from capability registry."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List, Set

TY_MAP: Dict[str, str] = {
    "felt252": ".felt252",
    "u128": ".u128",
    "u256": ".u256",
    "bool": ".bool",
    "i8": ".i8",
    "i16": ".i16",
    "i32": ".i32",
    "i64": ".i64",
    "i128": ".i128",
    "u8": ".u8",
    "u16": ".u16",
    "u32": ".u32",
    "u64": ".u64",
    "qm31": ".qm31",
}

SIGNATURE_TYPE_IDS: Set[str] = set(TY_MAP.keys())


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Lean capability projection")
    parser.add_argument("--registry", required=True)
    parser.add_argument("--out", required=True)
    return parser.parse_args()


def format_string_list(name: str, values: List[str]) -> str:
    lines = [f"def {name} : List String :=", "["]
    for value in values:
        lines.append(f'  "{value}",')
    lines.append("]")
    return "\n".join(lines)


def format_ty_list(name: str, values: List[str]) -> str:
    lines = [f"def {name} : List Ty :=", "["]
    for value in values:
        lines.append(f"  {value},")
    lines.append("]")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    registry = Path(args.registry)
    out = Path(args.out)

    payload = json.loads(registry.read_text(encoding="utf-8"))
    capabilities = payload.get("capabilities", [])
    if not isinstance(capabilities, list):
        raise SystemExit(f"invalid capabilities list: {registry}")

    sierra_implemented = []
    sierra_fail_fast = []
    signature_tys = set()

    for cap in capabilities:
        if not isinstance(cap, dict):
            continue
        cap_id = str(cap.get("capability_id", ""))
        support = cap.get("support_state", {})
        if not isinstance(support, dict):
            continue

        sierra_state = str(support.get("sierra", ""))
        if sierra_state == "implemented":
            if cap_id:
                sierra_implemented.append(cap_id)
            targets = cap.get("sierra_targets", {})
            if isinstance(targets, dict):
                type_ids = targets.get("generic_type_ids", [])
                if isinstance(type_ids, list):
                    for type_id in type_ids:
                        type_id_str = str(type_id)
                        if type_id_str in SIGNATURE_TYPE_IDS:
                            signature_tys.add(TY_MAP[type_id_str])
        elif sierra_state == "fail_fast":
            if cap_id:
                sierra_fail_fast.append(cap_id)

    sierra_implemented = sorted(set(sierra_implemented))
    sierra_fail_fast = sorted(set(sierra_fail_fast))
    signature_ty_list = sorted(signature_tys)

    content = "\n\n".join(
        [
            "import LeanCairo.Core.Domain.Ty",
            "namespace LeanCairo.Backend.Sierra.Generated",
            "open LeanCairo.Core.Domain",
            format_string_list("sierraImplementedCapabilityIds", sierra_implemented),
            format_string_list("sierraFailFastCapabilityIds", sierra_fail_fast),
            format_ty_list("sierraSupportedSignatureTys", signature_ty_list),
            "def isSierraCapabilityImplemented (capabilityId : String) : Bool :=\n  sierraImplementedCapabilityIds.contains capabilityId",
            "def isSierraSignatureTySupported (ty : Ty) : Bool :=\n  sierraSupportedSignatureTys.contains ty",
            "end LeanCairo.Backend.Sierra.Generated",
        ]
    )

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content + "\n", encoding="utf-8")
    print(f"wrote: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
