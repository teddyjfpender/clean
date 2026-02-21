#!/usr/bin/env python3
"""Validate executable-issue milestone dependency DAG and completion ordering."""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Set, Tuple


MILESTONE_HEADER_RE = re.compile(r"^###\s+([A-Za-z0-9-]+)\b")
MILESTONE_STATUS_RE = re.compile(r"^\s*-\s+Status:\s+(NOT DONE|DONE - [0-9a-f]{7,40})\s*$")


# Additional cross-issue dependency edges (child depends on parent).
EXPLICIT_DEPS: Dict[str, List[str]] = {
    "M-02-1": ["M-01-3", "M-00-3"],
    "M-03-1": ["M-02-3"],
    "M-04-1": ["M-03-3"],
    "A0": ["M-01-3"],
    "A1": ["M-04-3", "E2"],
    "A2": ["E3"],
    "A3": ["E4"],
    "B0": ["M-04-3"],
    "O1": ["A1"],
    "A8": ["E5"],
    "Q1": ["A1", "B0", "O1"],
    "R1": ["Q3"],
    "X1": ["M-00-3"],
    "E1": ["M-04-1"],
    "SXP-1": ["A2", "B2", "O2"],
    "CFB-1": ["SXP-2"],
    "LPA-1": ["SXP-3", "CFB-2", "Q3"],
    "CREG-1": ["SXP-1"],
    "TYC-1": ["CREG-2", "E3"],
    "EFF-1": ["TYC-2"],
    "SCL-1": ["CREG-3", "EFF-2", "A2"],
    "CPL-1": ["CREG-3", "TYC-4", "B2"],
    "COR-1": ["CFB-1", "CREG-2"],
    "BEN-1": ["CFB-3", "COR-2"],
    "OPTX-1": ["O2", "EFF-4", "BEN-2"],
    "CIX-1": ["LPA-2", "BEN-4", "COR-5"],
    "AUD-1": ["CIX-4", "LPA-4", "SCL-5", "CPL-4", "OPTX-5"],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check milestone DAG validity and dependency-aware completion statuses.",
    )
    parser.add_argument(
        "--validate-dag",
        action="store_true",
        help="only validate DAG structure (node existence + acyclic), skip status checks",
    )
    parser.add_argument(
        "--extra-edge",
        action="append",
        default=[],
        metavar="CHILD:PARENT",
        help="add dependency edge (child depends on parent), useful for negative tests",
    )
    return parser.parse_args()


def parse_milestones(issue_paths: List[Path]) -> Tuple[Dict[str, str], Dict[str, List[str]]]:
    milestone_status: Dict[str, str] = {}
    issue_to_milestones: Dict[str, List[str]] = {}

    for issue_path in issue_paths:
        current_id: str | None = None
        milestones_for_issue: List[str] = []
        for raw_line in issue_path.read_text(encoding="utf-8").splitlines():
            header_match = MILESTONE_HEADER_RE.match(raw_line)
            if header_match:
                current_id = header_match.group(1)
                if current_id in milestone_status:
                    raise ValueError(
                        f"duplicate milestone id '{current_id}' found in {issue_path}"
                    )
                milestones_for_issue.append(current_id)
                continue

            status_match = MILESTONE_STATUS_RE.match(raw_line)
            if status_match and current_id is not None:
                milestone_status[current_id] = status_match.group(1)

        issue_to_milestones[str(issue_path)] = milestones_for_issue

    return milestone_status, issue_to_milestones


def build_dependencies(
    issue_to_milestones: Dict[str, List[str]],
    extra_edges: List[str],
) -> Dict[str, Set[str]]:
    deps: Dict[str, Set[str]] = defaultdict(set)

    # Sequential dependency inside each issue file.
    for milestones in issue_to_milestones.values():
        for idx in range(1, len(milestones)):
            deps[milestones[idx]].add(milestones[idx - 1])

    # Explicit cross-issue dependencies.
    for child, parents in EXPLICIT_DEPS.items():
        for parent in parents:
            deps[child].add(parent)

    for edge in extra_edges:
        if ":" not in edge:
            raise ValueError(f"invalid --extra-edge '{edge}' (expected CHILD:PARENT)")
        child, parent = edge.split(":", 1)
        child = child.strip()
        parent = parent.strip()
        if not child or not parent:
            raise ValueError(f"invalid --extra-edge '{edge}' (empty child or parent)")
        deps[child].add(parent)

    return deps


def validate_node_existence(
    milestone_status: Dict[str, str],
    deps: Dict[str, Set[str]],
) -> List[str]:
    errors: List[str] = []
    known = set(milestone_status.keys())
    for child, parents in sorted(deps.items()):
        if child not in known:
            errors.append(f"dependency graph references unknown child milestone '{child}'")
        for parent in sorted(parents):
            if parent not in known:
                errors.append(
                    f"dependency graph references unknown parent milestone '{parent}' (child '{child}')"
                )
    return errors


def validate_acyclic(deps: Dict[str, Set[str]]) -> List[str]:
    errors: List[str] = []
    state: Dict[str, int] = {}  # 0=unvisited, 1=visiting, 2=done
    stack: List[str] = []

    def dfs(node: str) -> None:
        node_state = state.get(node, 0)
        if node_state == 1:
            cycle_start = stack.index(node) if node in stack else 0
            cycle = stack[cycle_start:] + [node]
            errors.append("dependency cycle detected: " + " -> ".join(cycle))
            return
        if node_state == 2:
            return

        state[node] = 1
        stack.append(node)
        for parent in sorted(deps.get(node, set())):
            dfs(parent)
        stack.pop()
        state[node] = 2

    all_nodes = set(deps.keys())
    for parents in deps.values():
        all_nodes.update(parents)
    for node in sorted(all_nodes):
        if state.get(node, 0) == 0:
            dfs(node)

    return errors


def is_done(status: str) -> bool:
    return bool(re.match(r"^DONE - [0-9a-f]{7,40}$", status))


def validate_status_dependencies(
    milestone_status: Dict[str, str],
    deps: Dict[str, Set[str]],
) -> List[str]:
    errors: List[str] = []
    for milestone, status in sorted(milestone_status.items()):
        if not is_done(status):
            continue
        for parent in sorted(deps.get(milestone, set())):
            parent_status = milestone_status.get(parent, "NOT DONE")
            if not is_done(parent_status):
                errors.append(
                    f"dependency violation: milestone '{milestone}' is done but dependency '{parent}' is {parent_status}"
                )
    return errors


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    issue_dir = root / "roadmap" / "executable-issues"
    issue_paths = sorted(issue_dir.rglob("*.issue.md"))
    if not issue_paths:
        print(f"no issue files found under {issue_dir}")
        return 1

    try:
        milestone_status, issue_to_milestones = parse_milestones(issue_paths)
        deps = build_dependencies(issue_to_milestones, args.extra_edge)
    except ValueError as exc:
        print(str(exc))
        return 1

    errors: List[str] = []
    errors.extend(validate_node_existence(milestone_status, deps))
    errors.extend(validate_acyclic(deps))

    if not args.validate_dag:
        errors.extend(validate_status_dependencies(milestone_status, deps))

    if errors:
        for error in errors:
            print(error)
        print(f"milestone dependency checks failed with {len(errors)} error(s)")
        return 1

    mode = "dag-only" if args.validate_dag else "dag+status"
    print(f"milestone dependency checks passed ({mode}, {len(milestone_status)} milestones)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
