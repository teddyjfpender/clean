#!/usr/bin/env python3
"""Deterministic structural Sierra JSON canonicalization pass."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Canonicalize Sierra program structure")
    parser.add_argument("--input", required=True, help="Input Sierra JSON path")
    parser.add_argument("--out", required=True, help="Output Sierra JSON path")
    return parser.parse_args()


def require_keys(payload: dict[str, Any]) -> None:
    required = ["version", "type_declarations", "libfunc_declarations", "statements", "funcs"]
    for key in required:
        if key not in payload:
            raise ValueError(f"missing required Sierra key '{key}'")
    if not isinstance(payload["type_declarations"], list):
        raise ValueError("type_declarations must be a list")
    if not isinstance(payload["libfunc_declarations"], list):
        raise ValueError("libfunc_declarations must be a list")
    if not isinstance(payload["statements"], list):
        raise ValueError("statements must be a list")
    if not isinstance(payload["funcs"], list):
        raise ValueError("funcs must be a list")


def read_decl_sort_key(entry: Any) -> tuple[str, str]:
    if not isinstance(entry, dict):
        return ("", json.dumps(entry, sort_keys=True))
    ident = entry.get("id")
    if not isinstance(ident, dict):
        return ("", json.dumps(entry, sort_keys=True))
    debug_name = ident.get("debug_name")
    if not isinstance(debug_name, str):
        debug_name = ""
    raw_id = ident.get("id")
    if isinstance(raw_id, int):
        id_key = f"{raw_id:020d}"
    else:
        id_key = json.dumps(raw_id, sort_keys=True)
    return (debug_name, id_key)


def canonicalize(payload: dict[str, Any]) -> dict[str, Any]:
    require_keys(payload)
    out = dict(payload)
    out["type_declarations"] = sorted(payload["type_declarations"], key=read_decl_sort_key)
    out["libfunc_declarations"] = sorted(payload["libfunc_declarations"], key=read_decl_sort_key)
    return out


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).resolve()
    output_path = Path(args.out).resolve()

    payload = json.loads(input_path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise SystemExit("input Sierra payload must be a JSON object")

    optimized = canonicalize(payload)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(optimized, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
