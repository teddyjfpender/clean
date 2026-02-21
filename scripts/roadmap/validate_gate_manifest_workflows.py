#!/usr/bin/env python3
"""Validate generated quality-gate manifest against workflow scripts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List, Set


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate gate manifest workflow coverage")
    parser.add_argument("--manifest", required=True)
    parser.add_argument(
        "--workflow",
        action="append",
        default=[],
        help="Override workflow path(s). If omitted, use manifest workflows.",
    )
    return parser.parse_args()


def load_manifest(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level must be object")
    if payload.get("version") != 1:
        raise ValueError(f"{path}: version must be 1")
    return payload


def normalize_list(payload: Dict[str, object], key: str, ctx: str) -> List[str]:
    raw = payload.get(key)
    if not isinstance(raw, list) or not raw:
        raise ValueError(f"{ctx}: '{key}' must be a non-empty list")
    out: List[str] = []
    for idx, item in enumerate(raw):
        if not isinstance(item, str) or not item.strip():
            raise ValueError(f"{ctx}: {key}[{idx}] must be non-empty string")
        out.append(item.strip())
    if len(out) != len(set(out)):
        raise ValueError(f"{ctx}: '{key}' must be unique")
    return out


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    manifest_path = Path(args.manifest).resolve()
    payload = load_manifest(manifest_path)

    mandatory_gates = normalize_list(payload, "mandatory_gates", str(manifest_path))
    workflows_from_manifest = normalize_list(payload, "workflows", str(manifest_path))

    workflow_paths: List[Path] = []
    if args.workflow:
        for item in args.workflow:
            workflow_paths.append(Path(item).resolve())
    else:
        for rel in workflows_from_manifest:
            workflow_paths.append((root / rel).resolve())

    errors: List[str] = []

    for gate in mandatory_gates:
        gate_path = (root / gate).resolve()
        if not gate_path.exists():
            errors.append(f"missing mandatory gate artifact: {gate}")

    workflow_texts: Dict[Path, str] = {}
    for workflow in workflow_paths:
        if not workflow.exists():
            errors.append(f"missing workflow script: {workflow}")
            continue
        workflow_texts[workflow] = workflow.read_text(encoding="utf-8")

    for gate in mandatory_gates:
        found = False
        for workflow, text in workflow_texts.items():
            if gate in text:
                found = True
                break
        if not found:
            errors.append(f"mandatory gate is not referenced by any workflow: {gate}")

    if errors:
        for err in errors:
            print(err)
        print(f"gate manifest workflow validation failed with {len(errors)} error(s)")
        return 1

    print(
        "gate manifest workflow validation passed "
        f"({len(mandatory_gates)} gates, {len(workflow_paths)} workflows)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
