#!/usr/bin/env python3
"""Render a review-only Sierra->Cairo-like listing with statement anchors."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Path to generated Sierra program json.")
    parser.add_argument("--out", required=True, help="Path to output review file.")
    return parser.parse_args()


def debug_name(obj: Any) -> str:
    if isinstance(obj, dict):
        value = obj.get("debug_name")
        if isinstance(value, str) and value:
            return value
    return "unknown"


def statement_label(stmt: dict[str, Any]) -> str:
    if "Invocation" in stmt:
        invocation = stmt["Invocation"]
        if isinstance(invocation, dict):
            libfunc = invocation.get("libfunc_id")
            return f"invoke {debug_name(libfunc)}"
        return "invoke <invalid>"
    if "Return" in stmt:
        return "return"
    return "statement"


def render_review(program: dict[str, Any], source_path: Path) -> str:
    funcs = program.get("funcs", [])
    statements = program.get("statements", [])
    if not isinstance(funcs, list) or not isinstance(statements, list):
        raise ValueError("invalid Sierra program format: funcs/statements must be lists")

    entry_pairs: list[tuple[int, str]] = []
    for fn in funcs:
        if not isinstance(fn, dict):
            continue
        fn_id = fn.get("id")
        fn_name = debug_name(fn_id)
        entry_point = fn.get("entry_point")
        if not isinstance(entry_point, int):
            continue
        entry_pairs.append((entry_point, fn_name))
    entry_pairs.sort(key=lambda item: item[0])

    lines: list[str] = [
        "// REVIEW-ONLY SIERRA LIFT",
        "// This output is non-authoritative and must never feed compilation.",
        f"// Source Sierra: {source_path}",
        "",
    ]

    for idx, (entry_point, fn_name) in enumerate(entry_pairs):
        next_entry = entry_pairs[idx + 1][0] if idx + 1 < len(entry_pairs) else len(statements)
        lines.append(f"fn {fn_name}() {{")
        for stmt_index in range(entry_point, min(next_entry, len(statements))):
            stmt = statements[stmt_index]
            if not isinstance(stmt, dict):
                continue
            label = statement_label(stmt)
            lines.append(f"    // sierra_stmt:{stmt_index}")
            lines.append(f"    {label};")
        lines.append("}")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).resolve()
    out_path = Path(args.out).resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.loads(input_path.read_text(encoding="utf-8"))
    rendered = render_review(payload, input_path)
    out_path.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
