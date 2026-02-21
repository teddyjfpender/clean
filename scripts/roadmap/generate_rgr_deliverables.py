#!/usr/bin/env python3
"""Generate deterministic RED->GREEN->REFACTOR deliverable catalog."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]
STATUS_RE = re.compile(r"^(NOT DONE|DONE - [0-9a-f]{7,40})$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate RGR deliverable catalog")
    parser.add_argument(
        "--spec",
        default="config/rgr-deliverable-spec.json",
        help="RGR deliverable policy spec",
    )
    parser.add_argument(
        "--matrix",
        default="roadmap/inventory/sierra-coverage-matrix.json",
        help="Sierra coverage matrix source",
    )
    parser.add_argument(
        "--status-source",
        default="roadmap/reports/rgr-deliverables.json",
        help="Existing catalog used to preserve status/evidence fields",
    )
    parser.add_argument(
        "--pinned-commit",
        default="config/cairo_pinned_commit.txt",
        help="Pinned commit file",
    )
    parser.add_argument(
        "--out-json",
        default="roadmap/reports/rgr-deliverables.json",
        help="Output catalog JSON",
    )
    parser.add_argument(
        "--out-md",
        default="roadmap/reports/rgr-deliverables.md",
        help="Output catalog Markdown",
    )
    return parser.parse_args()


def load_json(path: Path, label: str) -> Dict[str, Any]:
    if not path.exists():
        raise ValueError(f"missing required {label}: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{label} must be a JSON object: {path}")
    return payload


def rel(path: Path) -> str:
    return str(path.resolve().relative_to(ROOT))


def load_status_source(path: Path) -> Dict[str, Dict[str, Any]]:
    if not path.exists():
        return {}
    payload = load_json(path, "status source")
    entries = payload.get("deliverables", [])
    if not isinstance(entries, list):
        return {}

    by_id: Dict[str, Dict[str, Any]] = {}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        entry_id = entry.get("id")
        status = entry.get("status")
        if not isinstance(entry_id, str) or not isinstance(status, str):
            continue
        if not STATUS_RE.match(status):
            continue
        by_id[entry_id] = {
            "status": status,
            "evidence_tests": entry.get("evidence_tests", []),
            "evidence_proofs": entry.get("evidence_proofs", []),
        }
    return by_id


def match_modules(match_spec: Dict[str, Any], modules: List[Dict[str, str]]) -> List[Dict[str, str]]:
    kind = match_spec.get("kind")
    if kind == "non_starknet_all":
        return [m for m in modules if not m["module_id"].startswith("starknet/")]
    if kind == "starknet_all":
        return [m for m in modules if m["module_id"].startswith("starknet/")]
    if kind == "module_ids":
        module_ids = match_spec.get("module_ids")
        if not isinstance(module_ids, list) or not module_ids:
            raise ValueError("module_ids matcher requires non-empty 'module_ids' list")
        wanted = [m for m in module_ids if isinstance(m, str) and m]
        if len(wanted) != len(module_ids):
            raise ValueError("module_ids matcher entries must be non-empty strings")

        module_map = {m["module_id"]: m for m in modules}
        missing = [mid for mid in wanted if mid not in module_map]
        if missing:
            raise ValueError(f"module_ids matcher references unknown module IDs: {missing}")
        return [module_map[mid] for mid in wanted]

    raise ValueError(f"unsupported matcher kind: {kind!r}")


def remaining_modules(target_policy: str, selected: List[Dict[str, str]]) -> List[str]:
    if target_policy == "implemented_only":
        return sorted([m["module_id"] for m in selected if m["status"] != "implemented"])
    if target_policy == "implemented_or_failfast":
        return sorted(
            [
                m["module_id"]
                for m in selected
                if m["status"] not in {"implemented", "fail_fast"}
            ]
        )
    raise ValueError(f"unsupported target_policy: {target_policy!r}")


def ensure_unique_ids(ids: List[str]) -> None:
    seen = set()
    dup = []
    for item in ids:
        if item in seen:
            dup.append(item)
        seen.add(item)
    if dup:
        raise ValueError(f"duplicate deliverable IDs in policy spec: {sorted(set(dup))}")


def ensure_phase_gates(phase_gates: Dict[str, Any], deliverable_id: str) -> Dict[str, List[str]]:
    out: Dict[str, List[str]] = {}
    for phase in ("red", "green", "refactor"):
        raw = phase_gates.get(phase)
        if not isinstance(raw, list) or not raw:
            raise ValueError(f"deliverable {deliverable_id}: phase '{phase}' requires non-empty gate list")
        gates: List[str] = []
        for gate in raw:
            if not isinstance(gate, str) or not gate.strip():
                raise ValueError(f"deliverable {deliverable_id}: invalid gate entry in phase '{phase}'")
            gates.append(gate.strip())
        out[phase] = gates
    return out


def render_md(payload: Dict[str, Any]) -> str:
    lines: List[str] = [
        "# RGR Deliverables",
        "",
        f"- Pinned commit: `{payload['pinned_commit']}`",
        f"- Spec: `{payload['sources']['spec']}`",
        f"- Matrix: `{payload['sources']['matrix']}`",
        "",
        "## Summary",
        "",
        f"- Deliverables: `{payload['summary']['deliverable_count']}`",
        f"- `NOT DONE`: `{payload['summary']['status_counts']['not_done']}`",
        f"- `DONE`: `{payload['summary']['status_counts']['done']}`",
        "",
        "## Catalog",
        "",
        "| ID | Priority | Policy | Modules | Remaining | Ready | Status |",
        "| --- | ---: | --- | ---: | ---: | --- | --- |",
    ]

    for item in payload["deliverables"]:
        lines.append(
            "| `{id}` | `{priority}` | `{policy}` | `{mods}` | `{remaining}` | `{ready}` | `{status}` |".format(
                id=item["id"],
                priority=item["priority"],
                policy=item["target_policy"],
                mods=item["module_count"],
                remaining=item["remaining_count"],
                ready="yes" if item["computed_ready"] else "no",
                status=item["status"],
            )
        )

    lines.extend(["", "## Deliverable Details", ""])
    for item in payload["deliverables"]:
        lines.append(f"### `{item['id']}` {item['title']}")
        lines.append(f"- Priority: `{item['priority']}`")
        lines.append(f"- Policy: `{item['target_policy']}`")
        lines.append(f"- Status: `{item['status']}`")
        lines.append(f"- Computed ready: `{item['computed_ready']}`")
        lines.append(f"- Module count: `{item['module_count']}`")
        lines.append(f"- Remaining count: `{item['remaining_count']}`")
        lines.append("- Gates:")
        lines.append(f"- RED: {', '.join(f'`{g}`' for g in item['phase_gates']['red'])}")
        lines.append(f"- GREEN: {', '.join(f'`{g}`' for g in item['phase_gates']['green'])}")
        lines.append(f"- REFACTOR: {', '.join(f'`{g}`' for g in item['phase_gates']['refactor'])}")
        if item["remaining_module_ids"]:
            lines.append("- Remaining modules:")
            for module_id in item["remaining_module_ids"]:
                lines.append(f"- `{module_id}`")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    spec_path = (ROOT / args.spec).resolve()
    matrix_path = (ROOT / args.matrix).resolve()
    status_source_path = (ROOT / args.status_source).resolve()
    pinned_path = (ROOT / args.pinned_commit).resolve()
    out_json_path = (ROOT / args.out_json).resolve()
    out_md_path = (ROOT / args.out_md).resolve()

    spec = load_json(spec_path, "RGR spec")
    matrix = load_json(matrix_path, "Sierra coverage matrix")

    pinned_commit = pinned_path.read_text(encoding="utf-8").strip()
    if not pinned_commit:
        raise ValueError(f"empty pinned commit file: {pinned_path}")

    deliverable_specs = spec.get("deliverables")
    if spec.get("version") != 1:
        raise ValueError("RGR spec version must be 1")
    if not isinstance(deliverable_specs, list) or not deliverable_specs:
        raise ValueError("RGR spec requires non-empty deliverables list")

    modules_raw = matrix.get("extension_modules")
    if not isinstance(modules_raw, list) or not modules_raw:
        raise ValueError("Sierra coverage matrix requires non-empty extension_modules list")

    modules: List[Dict[str, str]] = []
    for entry in modules_raw:
        if not isinstance(entry, dict):
            continue
        module_id = entry.get("module_id")
        status = entry.get("status")
        if not isinstance(module_id, str) or not isinstance(status, str):
            continue
        modules.append({"module_id": module_id, "status": status})

    status_source = load_status_source(status_source_path)

    ids = [d.get("id") for d in deliverable_specs if isinstance(d, dict)]
    if any(not isinstance(i, str) or not i for i in ids):
        raise ValueError("each deliverable in spec requires non-empty string id")
    ensure_unique_ids([i for i in ids if isinstance(i, str)])

    deliverables: List[Dict[str, Any]] = []
    for item in deliverable_specs:
        if not isinstance(item, dict):
            raise ValueError("deliverable entries must be objects")
        deliverable_id = item.get("id")
        if not isinstance(deliverable_id, str) or not deliverable_id:
            raise ValueError("deliverable id must be non-empty string")

        title = item.get("title")
        if not isinstance(title, str) or not title:
            raise ValueError(f"deliverable {deliverable_id}: missing title")

        priority = item.get("priority")
        if not isinstance(priority, int) or priority < 0:
            raise ValueError(f"deliverable {deliverable_id}: priority must be non-negative integer")

        target_policy = item.get("target_policy")
        if target_policy not in {"implemented_only", "implemented_or_failfast"}:
            raise ValueError(f"deliverable {deliverable_id}: unsupported target_policy {target_policy!r}")

        match_spec = item.get("match")
        if not isinstance(match_spec, dict):
            raise ValueError(f"deliverable {deliverable_id}: missing match object")

        phases = ensure_phase_gates(item.get("phase_gates", {}), deliverable_id)
        selected = match_modules(match_spec, modules)

        selected_ids = sorted([m["module_id"] for m in selected])
        status_counts = dict(sorted(Counter(m["status"] for m in selected).items()))
        remaining_ids = remaining_modules(target_policy, selected)
        computed_ready = len(remaining_ids) == 0

        prior = status_source.get(deliverable_id, {})
        status = prior.get("status", "NOT DONE")
        if not isinstance(status, str) or not STATUS_RE.match(status):
            status = "NOT DONE"

        evidence_tests = prior.get("evidence_tests", [])
        evidence_proofs = prior.get("evidence_proofs", [])
        if not isinstance(evidence_tests, list):
            evidence_tests = []
        if not isinstance(evidence_proofs, list):
            evidence_proofs = []

        deliverables.append(
            {
                "id": deliverable_id,
                "title": title,
                "priority": priority,
                "target_policy": target_policy,
                "status": status,
                "computed_ready": computed_ready,
                "module_count": len(selected_ids),
                "module_scope": selected_ids,
                "module_status_counts": status_counts,
                "remaining_count": len(remaining_ids),
                "remaining_module_ids": remaining_ids,
                "phase_gates": phases,
                "evidence_tests": evidence_tests,
                "evidence_proofs": evidence_proofs,
            }
        )

    deliverables.sort(key=lambda d: (d["priority"], d["id"]))

    status_counts = {"done": 0, "not_done": 0}
    for item in deliverables:
        if item["status"].startswith("DONE - "):
            status_counts["done"] += 1
        else:
            status_counts["not_done"] += 1

    payload = {
        "version": 1,
        "pinned_commit": pinned_commit,
        "sources": {
            "spec": rel(spec_path),
            "matrix": rel(matrix_path),
            "status_source": rel(status_source_path),
        },
        "summary": {
            "deliverable_count": len(deliverables),
            "status_counts": status_counts,
        },
        "deliverables": deliverables,
    }

    out_json_path.parent.mkdir(parents=True, exist_ok=True)
    out_json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md_path.parent.mkdir(parents=True, exist_ok=True)
    out_md_path.write_text(render_md(payload), encoding="utf-8")

    print(f"wrote: {out_json_path}")
    print(f"wrote: {out_md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
