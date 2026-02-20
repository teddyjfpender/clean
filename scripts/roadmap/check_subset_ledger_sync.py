#!/usr/bin/env python3
"""Check direct Sierra subset ledger synchronization and closure metrics."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LEDGER_PATH = ROOT / "roadmap" / "12-direct-sierra-subset-coverage-ledger.md"
TRACK_A_ISSUE_PATH = ROOT / "roadmap" / "executable-issues" / "05-track-a-lean-to-sierra-functions.issue.md"
COVERAGE_MATRIX_PATH = ROOT / "roadmap" / "inventory" / "sierra-coverage-matrix.json"

# Only map milestones with explicit one-to-one correspondence.
SYNC_MILESTONE_PAIRS = {
    "S0": "A0",
    "S1": "A1",
    "S2": "A2",
    "S7": "A8",
}

METRIC_KEYS = [
    "pinned_surface_commit",
    "target_non_starknet_extension_modules",
    "implemented_non_starknet_extension_modules",
    "fail_fast_non_starknet_extension_modules",
    "unresolved_non_starknet_extension_modules",
    "implemented_non_starknet_closure_ratio",
    "bounded_non_starknet_closure_ratio",
    "done_subset_milestones",
    "total_subset_milestones",
    "subset_milestone_progress_ratio",
]


def parse_milestone_statuses(path: Path, prefix: str) -> dict[str, str]:
    header_re = re.compile(rf"^### {re.escape(prefix)}(\d+)\b")
    status_re = re.compile(r"^- Status: (NOT DONE|DONE - [0-9a-f]{7,40})$")

    statuses: dict[str, str] = {}
    current: str | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        header_match = header_re.match(line)
        if header_match:
            current = f"{prefix}{header_match.group(1)}"
            continue
        status_match = status_re.match(line)
        if status_match and current is not None and current not in statuses:
            statuses[current] = status_match.group(1)
            current = None
    return statuses


def parse_metric_values(ledger_text: str) -> dict[str, str]:
    metric_re = re.compile(r"^- `([a-z0-9_]+)`: `([^`]+)`$")
    values: dict[str, str] = {}
    for raw_line in ledger_text.splitlines():
        line = raw_line.strip()
        metric_match = metric_re.match(line)
        if metric_match:
            key = metric_match.group(1)
            value = metric_match.group(2)
            values[key] = value
    return values


def is_done(status: str) -> bool:
    return status.startswith("DONE - ")


def main() -> int:
    errors: list[str] = []

    if not LEDGER_PATH.exists():
        errors.append(f"missing ledger file: {LEDGER_PATH}")
    if not TRACK_A_ISSUE_PATH.exists():
        errors.append(f"missing Track-A issue file: {TRACK_A_ISSUE_PATH}")
    if not COVERAGE_MATRIX_PATH.exists():
        errors.append(f"missing coverage matrix: {COVERAGE_MATRIX_PATH}")
    if errors:
        for err in errors:
            print(err)
        print(f"subset ledger sync checks failed with {len(errors)} error(s)")
        return 1

    ledger_text = LEDGER_PATH.read_text(encoding="utf-8")
    if "roadmap/inventory/sierra-coverage-matrix.json" not in ledger_text:
        errors.append(
            "closure metric section must reference roadmap/inventory/sierra-coverage-matrix.json"
        )

    s_statuses = parse_milestone_statuses(LEDGER_PATH, "S")
    a_statuses = parse_milestone_statuses(TRACK_A_ISSUE_PATH, "A")

    for s_key, a_key in SYNC_MILESTONE_PAIRS.items():
        s_status = s_statuses.get(s_key)
        a_status = a_statuses.get(a_key)
        if s_status is None:
            errors.append(f"missing subset milestone status for {s_key} in {LEDGER_PATH}")
            continue
        if a_status is None:
            errors.append(f"missing Track-A milestone status for {a_key} in {TRACK_A_ISSUE_PATH}")
            continue
        if is_done(s_status) != is_done(a_status):
            errors.append(
                f"status drift: {s_key}={s_status} is not synchronized with {a_key}={a_status}"
            )

    metric_values = parse_metric_values(ledger_text)
    for key in METRIC_KEYS:
        if key not in metric_values:
            errors.append(f"missing closure metric key `{key}` in ledger")

    coverage = json.loads(COVERAGE_MATRIX_PATH.read_text(encoding="utf-8"))
    modules = coverage.get("extension_modules", [])
    non_starknet_modules = [
        m for m in modules if isinstance(m, dict) and not str(m.get("module_id", "")).startswith("starknet/")
    ]
    module_counts = Counter(str(m.get("status", "")) for m in non_starknet_modules)

    subset_keys = [f"S{idx}" for idx in range(8)]
    done_subset = sum(1 for key in subset_keys if is_done(s_statuses.get(key, "NOT DONE")))
    total_subset = len(subset_keys)

    target_non_starknet = len(non_starknet_modules)
    implemented_non_starknet = module_counts.get("implemented", 0)
    fail_fast_non_starknet = module_counts.get("fail_fast", 0)
    unresolved_non_starknet = module_counts.get("unresolved", 0)

    expected_metrics = {
        "pinned_surface_commit": str(coverage.get("pinned_commit", "")),
        "target_non_starknet_extension_modules": str(target_non_starknet),
        "implemented_non_starknet_extension_modules": str(implemented_non_starknet),
        "fail_fast_non_starknet_extension_modules": str(fail_fast_non_starknet),
        "unresolved_non_starknet_extension_modules": str(unresolved_non_starknet),
        "implemented_non_starknet_closure_ratio": (
            f"{implemented_non_starknet / target_non_starknet:.6f}" if target_non_starknet else "0.000000"
        ),
        "bounded_non_starknet_closure_ratio": (
            f"{(implemented_non_starknet + fail_fast_non_starknet) / target_non_starknet:.6f}"
            if target_non_starknet
            else "0.000000"
        ),
        "done_subset_milestones": str(done_subset),
        "total_subset_milestones": str(total_subset),
        "subset_milestone_progress_ratio": (
            f"{done_subset / total_subset:.6f}" if total_subset else "0.000000"
        ),
    }

    for key, expected in expected_metrics.items():
        observed = metric_values.get(key)
        if observed is None:
            continue
        if observed != expected:
            errors.append(
                f"closure metric mismatch for `{key}`: expected `{expected}`, observed `{observed}`"
            )

    if errors:
        for err in errors:
            print(err)
        print(f"subset ledger sync checks failed with {len(errors)} error(s)")
        return 1

    print("subset ledger sync checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
