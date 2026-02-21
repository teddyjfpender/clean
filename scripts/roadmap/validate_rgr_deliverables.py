#!/usr/bin/env python3
"""Validate RED->GREEN->REFACTOR deliverable catalog structure and legality."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]
STATUS_RE = re.compile(r"^(NOT DONE|DONE - ([0-9a-f]{7,40}))$")
ID_RE = re.compile(r"^d[0-9]{2}-[a-z0-9-]+$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate RGR deliverables catalog")
    parser.add_argument("--catalog", required=True, help="Path to rgr-deliverables.json")
    parser.add_argument(
        "--matrix",
        default="roadmap/inventory/sierra-coverage-matrix.json",
        help="Path to Sierra coverage matrix",
    )
    return parser.parse_args()


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON in {path}: {exc}") from exc


def git_commit_exists(commit_hash: str) -> bool:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "cat-file", "-e", f"{commit_hash}^{{commit}}"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def command_ref_exists(command: str) -> bool:
    first = command.strip().split()[0] if command.strip() else ""
    if not first:
        return False
    if first in {"python3", "bash", "sh"}:
        parts = command.strip().split()
        if len(parts) < 2:
            return False
        first = parts[1]
    if first.startswith("./"):
        first = first[2:]
    if "/" not in first:
        return True
    return (ROOT / first).exists()


def main() -> int:
    args = parse_args()
    catalog_path = Path(args.catalog)
    matrix_path = (ROOT / args.matrix).resolve()

    if not catalog_path.exists():
        print(f"missing catalog: {catalog_path}")
        return 1
    if not matrix_path.exists():
        print(f"missing matrix source: {matrix_path}")
        return 1

    payload = load_json(catalog_path)
    matrix = load_json(matrix_path)

    errors: List[str] = []

    if not isinstance(payload, dict):
        print(f"catalog top-level must be object: {catalog_path}")
        return 1

    if payload.get("version") != 1:
        errors.append("catalog version must be 1")

    deliverables = payload.get("deliverables")
    if not isinstance(deliverables, list) or not deliverables:
        errors.append("catalog requires non-empty deliverables list")
        deliverables = []

    matrix_modules = set()
    extension_modules = matrix.get("extension_modules", [])
    if isinstance(extension_modules, list):
        for entry in extension_modules:
            if isinstance(entry, dict) and isinstance(entry.get("module_id"), str):
                matrix_modules.add(entry["module_id"])

    seen_ids = set()
    prev_key = None

    for idx, item in enumerate(deliverables):
        ctx = f"deliverables[{idx}]"
        if not isinstance(item, dict):
            errors.append(f"{ctx}: must be object")
            continue

        for key in (
            "id",
            "title",
            "priority",
            "target_policy",
            "status",
            "computed_ready",
            "module_count",
            "module_scope",
            "remaining_count",
            "remaining_module_ids",
            "phase_gates",
            "evidence_tests",
            "evidence_proofs",
        ):
            if key not in item:
                errors.append(f"{ctx}: missing key '{key}'")

        item_id = item.get("id")
        if not isinstance(item_id, str) or not ID_RE.match(item_id):
            errors.append(f"{ctx}.id: invalid id '{item_id}'")
            continue
        if item_id in seen_ids:
            errors.append(f"{ctx}.id: duplicate id '{item_id}'")
        seen_ids.add(item_id)

        title = item.get("title")
        if not isinstance(title, str) or not title.strip():
            errors.append(f"{ctx}.title: expected non-empty string")

        priority = item.get("priority")
        if not isinstance(priority, int) or priority < 0:
            errors.append(f"{ctx}.priority: expected non-negative integer")

        sort_key = (priority if isinstance(priority, int) else 10**9, item_id)
        if prev_key is not None and sort_key < prev_key:
            errors.append("deliverables must be sorted by (priority, id)")
        prev_key = sort_key

        target_policy = item.get("target_policy")
        if target_policy not in {"implemented_only", "implemented_or_failfast"}:
            errors.append(f"{ctx}.target_policy: unsupported value '{target_policy}'")

        status = item.get("status")
        if not isinstance(status, str):
            errors.append(f"{ctx}.status: expected string")
            status = "NOT DONE"
        match = STATUS_RE.match(status)
        if match is None:
            errors.append(f"{ctx}.status: invalid status '{status}'")
            commit_hash = None
        else:
            commit_hash = match.group(2)

        computed_ready = item.get("computed_ready")
        if not isinstance(computed_ready, bool):
            errors.append(f"{ctx}.computed_ready: expected bool")
            computed_ready = False

        module_scope = item.get("module_scope")
        if not isinstance(module_scope, list) or not module_scope:
            errors.append(f"{ctx}.module_scope: expected non-empty list")
            module_scope = []
        else:
            for mod_idx, module_id in enumerate(module_scope):
                if not isinstance(module_id, str) or not module_id:
                    errors.append(f"{ctx}.module_scope[{mod_idx}]: expected non-empty string")
                    continue
                if module_id not in matrix_modules:
                    errors.append(f"{ctx}.module_scope[{mod_idx}]: unknown module id '{module_id}'")

        module_count = item.get("module_count")
        if not isinstance(module_count, int) or module_count != len(module_scope):
            errors.append(f"{ctx}.module_count must equal len(module_scope)")

        remaining_ids = item.get("remaining_module_ids")
        if not isinstance(remaining_ids, list):
            errors.append(f"{ctx}.remaining_module_ids: expected list")
            remaining_ids = []
        remaining_count = item.get("remaining_count")
        if not isinstance(remaining_count, int) or remaining_count != len(remaining_ids):
            errors.append(f"{ctx}.remaining_count must equal len(remaining_module_ids)")

        if computed_ready and remaining_ids:
            errors.append(f"{ctx}: computed_ready=true requires empty remaining_module_ids")

        phase_gates = item.get("phase_gates")
        if not isinstance(phase_gates, dict):
            errors.append(f"{ctx}.phase_gates: expected object")
            phase_gates = {}
        for phase in ("red", "green", "refactor"):
            gates = phase_gates.get(phase)
            if not isinstance(gates, list) or not gates:
                errors.append(f"{ctx}.phase_gates.{phase}: expected non-empty list")
                continue
            for gate_idx, gate in enumerate(gates):
                if not isinstance(gate, str) or not gate.strip():
                    errors.append(f"{ctx}.phase_gates.{phase}[{gate_idx}]: invalid gate command")
                    continue
                if not command_ref_exists(gate):
                    errors.append(f"{ctx}.phase_gates.{phase}[{gate_idx}]: command path not found '{gate}'")

        evidence_tests = item.get("evidence_tests")
        evidence_proofs = item.get("evidence_proofs")
        if not isinstance(evidence_tests, list):
            errors.append(f"{ctx}.evidence_tests: expected list")
            evidence_tests = []
        if not isinstance(evidence_proofs, list):
            errors.append(f"{ctx}.evidence_proofs: expected list")
            evidence_proofs = []

        if status.startswith("DONE - "):
            if commit_hash is None or not git_commit_exists(commit_hash):
                errors.append(f"{ctx}.status: commit does not exist '{commit_hash}'")
            if not computed_ready:
                errors.append(f"{ctx}.status: DONE requires computed_ready=true")
            if not evidence_tests:
                errors.append(f"{ctx}: DONE requires non-empty evidence_tests")
            if not evidence_proofs:
                errors.append(f"{ctx}: DONE requires non-empty evidence_proofs")

    if errors:
        for err in errors:
            print(err)
        print(f"RGR deliverables validation failed with {len(errors)} error(s)")
        return 1

    print("RGR deliverables validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
