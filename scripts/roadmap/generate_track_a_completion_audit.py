#!/usr/bin/env python3
"""Generate deterministic Track-A completion audit from completion matrix."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]

REQUIRED_DIMENSIONS = [
    "track_a_benchmark_closure",
    "track_a_family_closure",
    "track_a_optimization_closure",
    "track_a_proof_closure",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Track-A completion audit artifacts")
    parser.add_argument(
        "--matrix",
        default="roadmap/reports/completion-matrix.json",
        help="Completion matrix JSON path",
    )
    parser.add_argument(
        "--out-dir",
        default="roadmap/reports",
        help="Output directory for audit artifacts",
    )
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise ValueError(f"missing required file: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return payload


def rel(path: Path) -> str:
    resolved = path.resolve()
    try:
        return str(resolved.relative_to(ROOT))
    except ValueError:
        return str(resolved)


def render_md(payload: Dict[str, Any]) -> str:
    lines: List[str] = [
        "# Track-A Completion Audit",
        "",
        f"- Matrix: `{payload['matrix']}`",
        f"- Pinned commit: `{payload['pinned_commit']}`",
        f"- Result: `{payload['result']}`",
        "",
        "## Predicate Status",
        "",
        "| Predicate | Status |",
        "| --- | --- |",
    ]

    for dim in REQUIRED_DIMENSIONS:
        lines.append(f"| `{dim}` | `{payload['statuses'].get(dim, 'missing')}` |")

    lines.extend(["", "## Diagnostics", ""])
    diagnostics = payload.get("diagnostics", [])
    if diagnostics:
        for item in diagnostics:
            lines.append(f"- {item}")
    else:
        lines.append("- none")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    matrix_path = (ROOT / args.matrix).resolve()
    out_dir = (ROOT / args.out_dir).resolve()

    matrix = load_json(matrix_path)
    rows = matrix.get("rows", [])
    if not isinstance(rows, list):
        raise ValueError(f"{matrix_path}: rows must be a list")

    by_dim: Dict[str, Dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        dim = row.get("dimension_id")
        if isinstance(dim, str):
            by_dim[dim] = row

    statuses: Dict[str, str] = {}
    diagnostics: List[str] = []
    for dim in REQUIRED_DIMENSIONS:
        row = by_dim.get(dim)
        if row is None:
            statuses[dim] = "missing"
            diagnostics.append(f"missing matrix dimension: {dim}")
            continue
        status = row.get("status")
        if not isinstance(status, str):
            status = "missing"
        statuses[dim] = status
        if status != "ready":
            diagnostics.append(f"{dim} is {status}")
            for diag in row.get("diagnostics", []):
                if isinstance(diag, str):
                    diagnostics.append(f"{dim}: {diag}")

    result = "PASS" if not diagnostics else "FAIL"
    payload = {
        "version": 1,
        "matrix": rel(matrix_path),
        "pinned_commit": matrix.get("pinned_commit", ""),
        "required_dimensions": REQUIRED_DIMENSIONS,
        "statuses": statuses,
        "diagnostics": diagnostics,
        "result": result,
        "ready_dimensions": sum(1 for dim in REQUIRED_DIMENSIONS if statuses.get(dim) == "ready"),
        "target_dimensions": len(REQUIRED_DIMENSIONS),
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    out_json = out_dir / "track-a-completion-audit.json"
    out_md = out_dir / "track-a-completion-audit.md"
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(render_md(payload), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
