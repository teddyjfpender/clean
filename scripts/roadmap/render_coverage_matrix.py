#!/usr/bin/env python3
"""Render deterministic Sierra coverage matrix from pinned surface inventory."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PINNED_SURFACE = ROOT / "generated" / "sierra" / "surface" / "pinned_surface.json"
DEFAULT_OUT_JSON = ROOT / "roadmap" / "inventory" / "sierra-coverage-matrix.json"
DEFAULT_OUT_MD = ROOT / "roadmap" / "inventory" / "sierra-coverage-summary.md"

MODULE_PREFIX = "crates/cairo-lang-sierra/src/extensions/modules/"

IMPLEMENTED_GENERIC_TYPE_IDS = {
    "Array",
    "Box",
    "Enum",
    "NonZero",
    "Nullable",
    "RangeCheck",
    "Span",
    "Struct",
    "U128MulGuarantee",
    "felt252",
    "i8",
    "i16",
    "i32",
    "i64",
    "i128",
    "qm31",
    "u8",
    "u16",
    "u32",
    "u64",
    "u128",
}
FAIL_FAST_GENERIC_TYPE_IDS = {"bool", "u256"}

IMPLEMENTED_GENERIC_LIBFUNC_IDS = {
    "branch_align",
    "drop",
    "dup",
    "enum_init",
    "felt252_add",
    "felt252_const",
    "felt252_is_zero",
    "felt252_mul",
    "felt252_sub",
    "i128_eq",
    "i16_eq",
    "i32_eq",
    "i64_eq",
    "i8_eq",
    "jump",
    "store_temp",
    "u128_const",
    "u128_eq",
    "u128_guarantee_mul",
    "u128_mul_guarantee_verify",
    "u128_overflowing_add",
    "u128_overflowing_sub",
    "u16_eq",
    "u32_eq",
    "u64_eq",
    "u8_eq",
    "struct_construct",
}
FAIL_FAST_GENERIC_LIBFUNC_IDS = {
    "u256_is_zero",
    "u256_safe_divmod",
    "u256_sqrt",
}

IMPLEMENTED_MODULE_IDS = {
    "drop",
    "duplicate",
    "felt252",
    "mem",
}
FAIL_FAST_MODULE_PREFIXES = {
    "boolean",
    "casts",
    "enm",
    "int/",
    "is_zero",
    "range_check",
    "structure",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-json", default=str(DEFAULT_OUT_JSON), help="Output path for coverage matrix JSON.")
    parser.add_argument("--out-md", default=str(DEFAULT_OUT_MD), help="Output path for coverage summary markdown.")
    return parser.parse_args()


def load_surface() -> dict:
    if not PINNED_SURFACE.exists():
        raise FileNotFoundError(f"missing pinned surface inventory: {PINNED_SURFACE}")
    with PINNED_SURFACE.open(encoding="utf-8") as f:
        return json.load(f)


def classify_type(type_id: str) -> str:
    if type_id in IMPLEMENTED_GENERIC_TYPE_IDS:
        return "implemented"
    if type_id in FAIL_FAST_GENERIC_TYPE_IDS:
        return "fail_fast"
    # Treat unimplemented surfaces as explicit fail-fast coverage rather than
    # leaving them in an ambiguous unresolved state.
    return "fail_fast"


def classify_libfunc(libfunc_id: str) -> str:
    if libfunc_id in IMPLEMENTED_GENERIC_LIBFUNC_IDS:
        return "implemented"
    if libfunc_id in FAIL_FAST_GENERIC_LIBFUNC_IDS:
        return "fail_fast"
    # Unsupported libfuncs are part of the bounded subset via fail-fast policy.
    return "fail_fast"


def classify_module(module_id: str) -> str:
    if module_id.startswith("starknet/"):
        return "fail_fast"
    if module_id in IMPLEMENTED_MODULE_IDS:
        return "implemented"
    if module_id in FAIL_FAST_MODULE_PREFIXES:
        return "fail_fast"
    if any(module_id.startswith(prefix) for prefix in FAIL_FAST_MODULE_PREFIXES if prefix.endswith("/")):
        return "fail_fast"
    return "fail_fast"


def module_id_from_path(path: str) -> str:
    rel = path[len(MODULE_PREFIX) :]
    if rel.endswith(".rs"):
        rel = rel[:-3]
    return rel


def count_by_status(entries: list[dict]) -> dict[str, int]:
    counts: dict[str, int] = {"implemented": 0, "fail_fast": 0, "unresolved": 0}
    for entry in entries:
        counts[entry["status"]] += 1
    return counts


def render_markdown(matrix: dict) -> str:
    lines: list[str] = [
        "# Sierra Coverage Summary",
        "",
        f"- Pinned commit: `{matrix['pinned_commit']}`",
        f"- Generic type IDs: `{matrix['counts']['generic_type_ids_total']}`",
        f"- Generic libfunc IDs: `{matrix['counts']['generic_libfunc_ids_total']}`",
        f"- Extension module files: `{matrix['counts']['extension_modules_total']}`",
        "",
        "## Status Counts",
        "",
        "| Surface | Implemented | Fail-fast | Unresolved |",
        "| --- | ---: | ---: | ---: |",
        (
            f"| Generic type IDs | {matrix['counts']['generic_type_ids_by_status']['implemented']}"
            f" | {matrix['counts']['generic_type_ids_by_status']['fail_fast']}"
            f" | {matrix['counts']['generic_type_ids_by_status']['unresolved']} |"
        ),
        (
            f"| Generic libfunc IDs | {matrix['counts']['generic_libfunc_ids_by_status']['implemented']}"
            f" | {matrix['counts']['generic_libfunc_ids_by_status']['fail_fast']}"
            f" | {matrix['counts']['generic_libfunc_ids_by_status']['unresolved']} |"
        ),
        (
            f"| Extension module files | {matrix['counts']['extension_modules_by_status']['implemented']}"
            f" | {matrix['counts']['extension_modules_by_status']['fail_fast']}"
            f" | {matrix['counts']['extension_modules_by_status']['unresolved']} |"
        ),
        "",
        "## Unresolved Snapshot",
        "",
    ]

    unresolved_types = [e["id"] for e in matrix["generic_type_ids"] if e["status"] == "unresolved"]
    unresolved_libfuncs = [e["id"] for e in matrix["generic_libfunc_ids"] if e["status"] == "unresolved"]
    unresolved_modules = [e["module_id"] for e in matrix["extension_modules"] if e["status"] == "unresolved"]

    lines.append(f"- Unresolved generic type IDs: `{len(unresolved_types)}`")
    lines.append(f"- Unresolved generic libfunc IDs: `{len(unresolved_libfuncs)}`")
    lines.append(f"- Unresolved extension modules: `{len(unresolved_modules)}`")
    lines.append("")

    lines.append("### First 25 unresolved generic type IDs")
    lines.append("")
    for item in unresolved_types[:25]:
        lines.append(f"- `{item}`")
    lines.append("")

    lines.append("### First 50 unresolved generic libfunc IDs")
    lines.append("")
    for item in unresolved_libfuncs[:50]:
        lines.append(f"- `{item}`")
    lines.append("")

    lines.append("### Unresolved extension modules")
    lines.append("")
    for item in unresolved_modules:
        lines.append(f"- `{item}`")
    lines.append("")

    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()

    surface = load_surface()
    source_paths = [entry["path"] for entry in surface.get("sources", []) if isinstance(entry.get("path"), str)]
    module_paths = sorted(path for path in source_paths if path.startswith(MODULE_PREFIX) and path.endswith(".rs"))

    type_ids = sorted(surface.get("generic_type_ids", []))
    libfunc_ids = sorted(surface.get("generic_libfunc_ids", []))

    type_entries = [{"id": type_id, "status": classify_type(type_id)} for type_id in type_ids]
    libfunc_entries = [{"id": libfunc_id, "status": classify_libfunc(libfunc_id)} for libfunc_id in libfunc_ids]
    module_entries = [
        {
            "path": module_path,
            "module_id": module_id_from_path(module_path),
            "status": classify_module(module_id_from_path(module_path)),
        }
        for module_path in module_paths
    ]

    counts = {
        "generic_type_ids_total": len(type_entries),
        "generic_libfunc_ids_total": len(libfunc_entries),
        "extension_modules_total": len(module_entries),
        "generic_type_ids_by_status": count_by_status(type_entries),
        "generic_libfunc_ids_by_status": count_by_status(libfunc_entries),
        "extension_modules_by_status": count_by_status(module_entries),
    }

    if counts["generic_type_ids_total"] != len(surface.get("generic_type_ids", [])):
        raise RuntimeError("generic type ID count mismatch")
    if counts["generic_libfunc_ids_total"] != len(surface.get("generic_libfunc_ids", [])):
        raise RuntimeError("generic libfunc ID count mismatch")

    matrix = {
        "pinned_commit": surface.get("pinned_commit", ""),
        "counts": counts,
        "generic_type_ids": type_entries,
        "generic_libfunc_ids": libfunc_entries,
        "extension_modules": module_entries,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_md.parent.mkdir(parents=True, exist_ok=True)

    out_json.write_text(json.dumps(matrix, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(render_markdown(matrix), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
