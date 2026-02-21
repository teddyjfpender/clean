#!/usr/bin/env python3
"""Generate deterministic program-completion certificate from completion matrix and audits."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]

MANDATORY_DIMENSIONS = [
    "track_a_benchmark_closure",
    "track_a_family_closure",
    "track_a_optimization_closure",
    "track_a_proof_closure",
    "track_b_divergence_contract_closure",
    "track_b_parity_closure",
    "track_b_purity_closure",
    "track_b_reviewability_closure",
    "program_p0_issue_closure",
    "program_release_evidence_closure",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate program-completion certificate artifacts")
    parser.add_argument("--matrix", default="roadmap/reports/completion-matrix.json", help="Completion matrix JSON")
    parser.add_argument(
        "--track-a-audit",
        default="roadmap/reports/track-a-completion-audit.json",
        help="Track-A audit JSON",
    )
    parser.add_argument(
        "--track-b-audit",
        default="roadmap/reports/track-b-completion-audit.json",
        help="Track-B audit JSON",
    )
    parser.add_argument(
        "--release-go-no-go",
        default="roadmap/reports/release-go-no-go-report.json",
        help="Release go/no-go JSON",
    )
    parser.add_argument("--out-dir", default="roadmap/reports", help="Output directory for certificate")
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
        "# Program Completion Certificate",
        "",
        f"- Result: `{payload['result']}`",
        f"- Pinned commit: `{payload['pinned_commit']}`",
        f"- Matrix: `{payload['matrix']}`",
        f"- Track-A audit: `{payload['track_a_audit']}`",
        f"- Track-B audit: `{payload['track_b_audit']}`",
        f"- Release go/no-go: `{payload['release_go_no_go']}`",
        "",
        "## Closure Summary",
        "",
        f"- Mandatory dimensions ready: `{payload['ready_dimensions']}` / `{payload['target_dimensions']}`",
        f"- Track-A audit result: `{payload['track_a_result']}`",
        f"- Track-B audit result: `{payload['track_b_result']}`",
        f"- Release go/no-go result: `{payload['release_result']}`",
        "",
        "## Mandatory Dimensions",
        "",
        "| Dimension | Status |",
        "| --- | --- |",
    ]

    for dim in MANDATORY_DIMENSIONS:
        lines.append(f"| `{dim}` | `{payload['dimension_statuses'].get(dim, 'missing')}` |")

    lines.extend(["", "## Blocking Reasons", ""])
    reasons = payload.get("blocking_reasons", [])
    if reasons:
        for reason in reasons:
            lines.append(f"- {reason}")
    else:
        lines.append("- none")

    lines.extend(["", "## Evidence Links", ""])
    for link in payload.get("evidence_links", []):
        lines.append(f"- `{link}`")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    matrix_path = (ROOT / args.matrix).resolve()
    track_a_path = (ROOT / args.track_a_audit).resolve()
    track_b_path = (ROOT / args.track_b_audit).resolve()
    release_path = (ROOT / args.release_go_no_go).resolve()
    out_dir = (ROOT / args.out_dir).resolve()

    matrix = load_json(matrix_path)
    track_a = load_json(track_a_path)
    track_b = load_json(track_b_path)
    release = load_json(release_path)

    rows = matrix.get("rows", [])
    if not isinstance(rows, list):
        raise ValueError(f"{matrix_path}: rows must be a list")

    statuses: Dict[str, str] = {}
    by_dim: Dict[str, Dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        dim = row.get("dimension_id")
        if isinstance(dim, str):
            by_dim[dim] = row
            status = row.get("status")
            statuses[dim] = status if isinstance(status, str) else "missing"

    blocking_reasons: List[str] = []
    for dim in MANDATORY_DIMENSIONS:
        status = statuses.get(dim, "missing")
        if status != "ready":
            blocking_reasons.append(f"mandatory dimension not ready: {dim}={status}")

    track_a_result = str(track_a.get("result", ""))
    track_b_result = str(track_b.get("result", ""))
    release_result = str(release.get("result", ""))

    if track_a_result != "PASS":
        blocking_reasons.append(f"track-a audit result is {track_a_result}")
    if track_b_result != "PASS":
        blocking_reasons.append(f"track-b audit result is {track_b_result}")
    if release_result != "PASS":
        blocking_reasons.append(f"release go/no-go result is {release_result}")

    ready_dimensions = sum(1 for dim in MANDATORY_DIMENSIONS if statuses.get(dim) == "ready")
    result = "PASS" if not blocking_reasons else "BLOCKED"

    evidence_links = sorted(
        {
            rel(matrix_path),
            rel(track_a_path),
            rel(track_b_path),
            rel(release_path),
            "roadmap/reports/release-compatibility-report.md",
            "roadmap/reports/release-proof-report.md",
            "roadmap/reports/release-benchmark-report.md",
            "roadmap/reports/release-capability-closure-report.md",
            "scripts/roadmap/check_completion_matrix.sh",
            "scripts/roadmap/check_track_a_completion_audit.sh",
            "scripts/roadmap/check_track_b_completion_audit.sh",
            "scripts/roadmap/check_release_reports_freshness.sh",
        }
    )

    payload = {
        "version": 1,
        "matrix": rel(matrix_path),
        "track_a_audit": rel(track_a_path),
        "track_b_audit": rel(track_b_path),
        "release_go_no_go": rel(release_path),
        "pinned_commit": matrix.get("pinned_commit", ""),
        "mandatory_dimensions": MANDATORY_DIMENSIONS,
        "dimension_statuses": {dim: statuses.get(dim, "missing") for dim in MANDATORY_DIMENSIONS},
        "ready_dimensions": ready_dimensions,
        "target_dimensions": len(MANDATORY_DIMENSIONS),
        "track_a_result": track_a_result,
        "track_b_result": track_b_result,
        "release_result": release_result,
        "result": result,
        "blocking_reasons": blocking_reasons,
        "evidence_links": evidence_links,
        "closure_summary": {
            "track_a": {
                "ready": sum(1 for dim in MANDATORY_DIMENSIONS if dim.startswith("track_a_") and statuses.get(dim) == "ready"),
                "target": sum(1 for dim in MANDATORY_DIMENSIONS if dim.startswith("track_a_")),
            },
            "track_b": {
                "ready": sum(1 for dim in MANDATORY_DIMENSIONS if dim.startswith("track_b_") and statuses.get(dim) == "ready"),
                "target": sum(1 for dim in MANDATORY_DIMENSIONS if dim.startswith("track_b_")),
            },
            "program": {
                "ready": sum(1 for dim in MANDATORY_DIMENSIONS if dim.startswith("program_") and statuses.get(dim) == "ready"),
                "target": sum(1 for dim in MANDATORY_DIMENSIONS if dim.startswith("program_")),
            },
        },
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    out_json = out_dir / "program-completion-certificate.json"
    out_md = out_dir / "program-completion-certificate.md"

    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(render_md(payload), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
