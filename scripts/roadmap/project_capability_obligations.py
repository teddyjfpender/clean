#!/usr/bin/env python3
"""Project capability obligations into deterministic report artifacts."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Project capability obligation reports")
    parser.add_argument("--registry", required=True)
    parser.add_argument("--obligations", required=True)
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--out-md", required=True)
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level JSON must be object")
    return payload


def run_validator(root: Path, registry: Path, obligations: Path) -> None:
    validator = root / "scripts" / "roadmap" / "validate_capability_obligations.py"
    subprocess.run(
        [
            "python3",
            str(validator),
            "--registry",
            str(registry),
            "--obligations",
            str(obligations),
        ],
        check=True,
        cwd=root,
    )


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]

    registry = Path(args.registry).resolve()
    obligations = Path(args.obligations).resolve()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()

    run_validator(root, registry, obligations)

    registry_payload = load_json(registry)
    obligations_payload = load_json(obligations)

    registry_caps = registry_payload.get("capabilities", [])
    obligations_rows = obligations_payload.get("obligations", [])
    if not isinstance(registry_caps, list) or not isinstance(obligations_rows, list):
        raise SystemExit("invalid registry/obligations payload")

    obligations_by_id = {
        str(row.get("capability_id", "")): row
        for row in obligations_rows
        if isinstance(row, dict)
    }

    rows: List[Dict[str, object]] = []
    implemented_missing: List[str] = []

    for cap in sorted(
        [cap for cap in registry_caps if isinstance(cap, dict)],
        key=lambda item: str(item.get("capability_id", "")),
    ):
        cap_id = str(cap.get("capability_id", "")).strip()
        if not cap_id:
            continue
        family = str(cap.get("family_group", "")).strip()
        support = cap.get("support_state", {})
        overall = str(support.get("overall", "")).strip()

        obligation = obligations_by_id.get(cap_id)
        has_obligation = isinstance(obligation, dict)
        required_states: List[str] = []
        proof_count = 0
        test_count = 0
        benchmark_count = 0

        if has_obligation:
            required_states_raw = obligation.get("required_for_states", [])
            proof_refs_raw = obligation.get("proof_refs", [])
            test_refs_raw = obligation.get("test_refs", [])
            benchmark_refs_raw = obligation.get("benchmark_refs", [])

            if isinstance(required_states_raw, list):
                required_states = sorted(
                    str(state).strip()
                    for state in required_states_raw
                    if isinstance(state, str) and state.strip()
                )
            if isinstance(proof_refs_raw, list):
                proof_count = len([ref for ref in proof_refs_raw if isinstance(ref, str) and ref.strip()])
            if isinstance(test_refs_raw, list):
                test_count = len([ref for ref in test_refs_raw if isinstance(ref, str) and ref.strip()])
            if isinstance(benchmark_refs_raw, list):
                benchmark_count = len([ref for ref in benchmark_refs_raw if isinstance(ref, str) and ref.strip()])

        satisfies_state = overall in required_states if has_obligation else False
        if overall == "implemented" and not satisfies_state:
            implemented_missing.append(cap_id)

        rows.append(
            {
                "capability_id": cap_id,
                "family_group": family,
                "overall_support_state": overall,
                "has_obligation_entry": has_obligation,
                "required_for_states": required_states,
                "satisfies_current_state": satisfies_state,
                "proof_ref_count": proof_count,
                "test_ref_count": test_count,
                "benchmark_ref_count": benchmark_count,
            }
        )

    implemented_total = len([row for row in rows if row["overall_support_state"] == "implemented"])
    implemented_satisfied = len(
        [
            row
            for row in rows
            if row["overall_support_state"] == "implemented" and row["satisfies_current_state"]
        ]
    )

    payload = {
        "version": 1,
        "registry": str(registry.relative_to(root)),
        "obligations": str(obligations.relative_to(root)),
        "total_capabilities": len(rows),
        "obligation_entry_count": len(obligations_by_id),
        "implemented_capability_count": implemented_total,
        "implemented_with_satisfied_obligations": implemented_satisfied,
        "implemented_missing_obligations": sorted(implemented_missing),
        "rows": rows,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines: List[str] = []
    lines.append("# Capability Obligation Report")
    lines.append("")
    lines.append(f"- Registry: `{payload['registry']}`")
    lines.append(f"- Obligations: `{payload['obligations']}`")
    lines.append(f"- Total capabilities: `{payload['total_capabilities']}`")
    lines.append(f"- Obligation entries: `{payload['obligation_entry_count']}`")
    lines.append(
        "- Implemented obligation closure: "
        f"`{implemented_satisfied}/{implemented_total}`"
    )
    lines.append("")

    lines.append("## Capability Matrix")
    lines.append("")
    lines.append(
        "| Capability ID | Family | Overall state | Has obligation | Required states | "
        "Satisfies current state | Proof refs | Test refs | Benchmark refs |"
    )
    lines.append("| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: |")
    for row in rows:
        required_states = row["required_for_states"]
        required_text = ", ".join(required_states) if required_states else "none"
        has_text = "true" if row["has_obligation_entry"] else "false"
        sat_text = "true" if row["satisfies_current_state"] else "false"
        lines.append(
            f"| `{row['capability_id']}` | `{row['family_group']}` | `{row['overall_support_state']}` "
            f"| `{has_text}` | `{required_text}` | `{sat_text}` "
            f"| `{row['proof_ref_count']}` | `{row['test_ref_count']}` | `{row['benchmark_ref_count']}` |"
        )
    lines.append("")

    lines.append("## Implemented Missing Obligations")
    lines.append("")
    missing = payload["implemented_missing_obligations"]
    if missing:
        for cap_id in missing:
            lines.append(f"- `{cap_id}`")
    else:
        lines.append("- none")
    lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
