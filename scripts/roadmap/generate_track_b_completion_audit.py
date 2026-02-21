#!/usr/bin/env python3
"""Generate deterministic Track-B completion audit from completion matrix and capability registry."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]

REQUIRED_DIMENSIONS = [
    "track_b_divergence_contract_closure",
    "track_b_parity_closure",
    "track_b_purity_closure",
    "track_b_reviewability_closure",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Track-B completion audit artifacts")
    parser.add_argument(
        "--matrix",
        default="roadmap/reports/completion-matrix.json",
        help="Completion matrix JSON path",
    )
    parser.add_argument(
        "--capability-registry",
        default="roadmap/capabilities/registry.json",
        help="Capability registry JSON path",
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
        "# Track-B Completion Audit",
        "",
        f"- Matrix: `{payload['matrix']}`",
        f"- Capability registry: `{payload['capability_registry']}`",
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

    lines.extend(["", "## Undocumented Divergence", ""])
    undocumented = payload.get("undocumented_divergence", [])
    if undocumented:
        for cap in undocumented:
            lines.append(f"- `{cap}`")
    else:
        lines.append("- none")

    lines.extend(["", "## Diagnostics", ""])
    diagnostics = payload.get("diagnostics", [])
    if diagnostics:
        for item in diagnostics:
            lines.append(f"- {item}")
    else:
        lines.append("- none")
    lines.append("")
    return "\n".join(lines)


def find_undocumented_divergence(registry: Dict[str, Any]) -> List[str]:
    undocumented: List[str] = []
    caps = registry.get("capabilities", [])
    if not isinstance(caps, list):
        return ["registry.capabilities is not a list"]

    for cap in caps:
        if not isinstance(cap, dict):
            continue
        cap_id = cap.get("capability_id", "unknown")
        support_state = cap.get("support_state", {})
        if not isinstance(support_state, dict):
            continue
        sierra_state = support_state.get("sierra")
        cairo_state = support_state.get("cairo")
        if sierra_state == cairo_state:
            continue
        constraints = cap.get("divergence_constraints", [])
        if not isinstance(constraints, list):
            undocumented.append(str(cap_id))
            continue
        has_non_empty = any(isinstance(item, str) and item.strip() for item in constraints)
        if not has_non_empty:
            undocumented.append(str(cap_id))

    return sorted(undocumented)


def main() -> int:
    args = parse_args()
    matrix_path = (ROOT / args.matrix).resolve()
    registry_path = (ROOT / args.capability_registry).resolve()
    out_dir = (ROOT / args.out_dir).resolve()

    matrix = load_json(matrix_path)
    registry = load_json(registry_path)

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

    undocumented = find_undocumented_divergence(registry)
    if undocumented:
        diagnostics.append("undocumented divergence contracts detected")
        for cap_id in undocumented:
            diagnostics.append(f"undocumented divergence: {cap_id}")

    result = "PASS" if not diagnostics else "FAIL"
    payload = {
        "version": 1,
        "matrix": rel(matrix_path),
        "capability_registry": rel(registry_path),
        "pinned_commit": matrix.get("pinned_commit", ""),
        "required_dimensions": REQUIRED_DIMENSIONS,
        "statuses": statuses,
        "undocumented_divergence": undocumented,
        "diagnostics": diagnostics,
        "result": result,
        "ready_dimensions": sum(1 for dim in REQUIRED_DIMENSIONS if statuses.get(dim) == "ready"),
        "target_dimensions": len(REQUIRED_DIMENSIONS),
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    out_json = out_dir / "track-b-completion-audit.json"
    out_md = out_dir / "track-b-completion-audit.md"
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(render_md(payload), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
