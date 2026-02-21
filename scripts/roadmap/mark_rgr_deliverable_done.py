#!/usr/bin/env python3
"""Mark an RGR deliverable as DONE - <commit> after phase-gate completion."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Mark RGR deliverable done")
    parser.add_argument(
        "--catalog",
        default="roadmap/reports/rgr-deliverables.json",
        help="Path to rgr-deliverables.json",
    )
    parser.add_argument(
        "--deliverable",
        required=True,
        help="Deliverable ID to mark done",
    )
    parser.add_argument(
        "--commit",
        required=True,
        help="Commit hash to record in DONE status",
    )
    parser.add_argument(
        "--evidence-test",
        action="append",
        default=[],
        help="Evidence test command/path (repeatable)",
    )
    parser.add_argument(
        "--evidence-proof",
        action="append",
        default=[],
        help="Evidence proof path (repeatable)",
    )
    parser.add_argument(
        "--spec",
        default="config/rgr-deliverable-spec.json",
        help="RGR spec path used for regeneration",
    )
    parser.add_argument(
        "--matrix",
        default="roadmap/inventory/sierra-coverage-matrix.json",
        help="Sierra matrix path used for regeneration",
    )
    parser.add_argument(
        "--out-md",
        default="",
        help="Optional markdown output path; defaults to catalog sibling .md",
    )
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"catalog must be a JSON object: {path}")
    return payload


def git_commit_exists(commit_hash: str) -> bool:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "cat-file", "-e", f"{commit_hash}^{{commit}}"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def normalize_unique(values: List[str]) -> List[str]:
    out: List[str] = []
    seen = set()
    for value in values:
        trimmed = value.strip()
        if not trimmed or trimmed in seen:
            continue
        seen.add(trimmed)
        out.append(trimmed)
    return out


def main() -> int:
    args = parse_args()

    catalog_path = (ROOT / args.catalog).resolve()
    spec_path = (ROOT / args.spec).resolve()
    matrix_path = (ROOT / args.matrix).resolve()
    out_md_path = (ROOT / args.out_md).resolve() if args.out_md else catalog_path.with_suffix(".md")

    if not catalog_path.exists():
        raise ValueError(f"missing catalog: {catalog_path}")
    if not spec_path.exists():
        raise ValueError(f"missing spec: {spec_path}")
    if not matrix_path.exists():
        raise ValueError(f"missing matrix: {matrix_path}")

    if not git_commit_exists(args.commit):
        raise ValueError(f"commit does not exist: {args.commit}")

    payload = load_json(catalog_path)
    deliverables = payload.get("deliverables")
    if not isinstance(deliverables, list):
        raise ValueError("catalog missing deliverables list")

    target: Dict[str, Any] | None = None
    for item in deliverables:
        if isinstance(item, dict) and item.get("id") == args.deliverable:
            target = item
            break

    if target is None:
        raise ValueError(f"deliverable id not found: {args.deliverable}")

    status = target.get("status")
    if status != "NOT DONE":
        raise ValueError(
            f"deliverable {args.deliverable} must be NOT DONE before marking done (current: {status})"
        )

    if target.get("computed_ready") is not True:
        raise ValueError(f"deliverable {args.deliverable} is not computed-ready")

    phase_gates = target.get("phase_gates", {})
    default_tests: List[str] = []
    if isinstance(phase_gates, dict):
        for phase in ("red", "green", "refactor"):
            gates = phase_gates.get(phase, [])
            if isinstance(gates, list):
                for gate in gates:
                    if isinstance(gate, str) and gate.strip():
                        default_tests.append(gate.strip())

    evidence_tests = normalize_unique(args.evidence_test or default_tests)
    evidence_proofs = normalize_unique(
        args.evidence_proof
        or [
            str(spec_path.relative_to(ROOT)),
            str(matrix_path.relative_to(ROOT)),
            "scripts/roadmap/run_rgr_loop.sh",
            str(catalog_path.relative_to(ROOT)) if catalog_path.is_relative_to(ROOT) else str(catalog_path),
        ]
    )

    if not evidence_tests:
        raise ValueError("cannot mark done without evidence tests")
    if not evidence_proofs:
        raise ValueError("cannot mark done without evidence proofs")

    target["status"] = f"DONE - {args.commit}"
    target["evidence_tests"] = evidence_tests
    target["evidence_proofs"] = evidence_proofs

    catalog_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    subprocess.run(
        [
            "python3",
            str(ROOT / "scripts/roadmap/generate_rgr_deliverables.py"),
            "--spec",
            str(spec_path),
            "--matrix",
            str(matrix_path),
            "--status-source",
            str(catalog_path),
            "--out-json",
            str(catalog_path),
            "--out-md",
            str(out_md_path),
        ],
        check=True,
    )

    print(
        f"marked deliverable done: id={args.deliverable} status='DONE - {args.commit}' catalog={catalog_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
