#!/usr/bin/env python3
"""Generate deterministic corpus coverage report mapping kernels to capability IDs."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Dict, List


REQUIRED_FAMILIES = [
    "integer",
    "fixed_point",
    "control_flow",
    "aggregate",
    "crypto",
    "circuit",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate corpus coverage report")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--registry", required=True)
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--out-md", required=True)
    return parser.parse_args()


def validate_manifest(root: Path, manifest: Path) -> None:
    validator = root / "scripts" / "examples" / "validate_examples_manifest.py"
    subprocess.run(
        ["python3", str(validator), "--manifest", str(manifest)],
        check=True,
        cwd=root,
    )


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    manifest = Path(args.manifest).resolve()
    registry = Path(args.registry).resolve()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()

    validate_manifest(root, manifest)

    manifest_payload = json.loads(manifest.read_text(encoding="utf-8"))
    registry_payload = json.loads(registry.read_text(encoding="utf-8"))

    capabilities = registry_payload.get("capabilities", [])
    capability_ids = set()
    implemented_capability_ids = set()
    if isinstance(capabilities, list):
        for cap in capabilities:
            if isinstance(cap, dict):
                cap_id = cap.get("capability_id")
                if isinstance(cap_id, str) and cap_id:
                    capability_ids.add(cap_id)
                    support = cap.get("support_state", {})
                    if isinstance(support, dict) and support.get("overall") == "implemented":
                        implemented_capability_ids.add(cap_id)

    examples = manifest_payload.get("examples", [])
    if not isinstance(examples, list) or not examples:
        raise SystemExit(f"invalid manifest examples list: {manifest}")

    kernel_rows: List[Dict[str, object]] = []
    family_counts: Dict[str, Dict[str, int]] = {}
    covered_capability_ids = set()

    for entry in examples:
        if not isinstance(entry, dict):
            continue
        example_id = str(entry.get("id", "")).strip()
        coverage = entry.get("coverage", {})
        if not example_id or not isinstance(coverage, dict):
            continue

        tier = str(coverage.get("complexity_tier", "")).strip()
        family_tags = coverage.get("family_tags", [])
        cap_ids = coverage.get("capability_ids", [])
        if not isinstance(family_tags, list) or not isinstance(cap_ids, list):
            raise SystemExit(f"invalid coverage entry for {example_id}")

        normalized_families = sorted(str(tag).strip() for tag in family_tags if isinstance(tag, str) and tag.strip())
        normalized_caps = sorted(str(cap).strip() for cap in cap_ids if isinstance(cap, str) and cap.strip())

        unknown_caps = sorted(cap for cap in normalized_caps if cap not in capability_ids)
        if unknown_caps:
            raise SystemExit(
                f"manifest coverage for '{example_id}' references unknown capability ids: {', '.join(unknown_caps)}"
            )

        for family in normalized_families:
            stats = family_counts.setdefault(family, {"medium": 0, "high": 0, "total": 0})
            stats["total"] += 1
            if tier == "medium":
                stats["medium"] += 1
            elif tier == "high":
                stats["high"] += 1

        for cap_id in normalized_caps:
            covered_capability_ids.add(cap_id)

        kernel_rows.append(
            {
                "id": example_id,
                "complexity_tier": tier,
                "family_tags": normalized_families,
                "capability_ids": normalized_caps,
            }
        )

    kernel_rows = sorted(kernel_rows, key=lambda row: str(row["id"]))

    required_status = []
    missing_required = []
    for family in REQUIRED_FAMILIES:
        stats = family_counts.get(family, {"medium": 0, "high": 0, "total": 0})
        satisfied = (stats["medium"] + stats["high"]) > 0
        if not satisfied:
            missing_required.append(family)
        required_status.append(
            {
                "family": family,
                "required": True,
                "satisfied": satisfied,
                "medium_count": stats["medium"],
                "high_count": stats["high"],
                "total_count": stats["total"],
            }
        )

    if missing_required:
        raise SystemExit(
            "missing required corpus families for medium/high kernels: "
            + ", ".join(sorted(missing_required))
        )

    missing_implemented_capabilities = sorted(
        cap for cap in implemented_capability_ids if cap not in covered_capability_ids
    )
    if missing_implemented_capabilities:
        raise SystemExit(
            "missing implemented capability coverage in corpus manifest: "
            + ", ".join(missing_implemented_capabilities)
        )

    implemented_total = len(implemented_capability_ids)
    implemented_covered = len(implemented_capability_ids.intersection(covered_capability_ids))
    implemented_coverage_ratio = 0.0 if implemented_total == 0 else round(implemented_covered / implemented_total, 6)

    payload = {
        "version": 1,
        "manifest": str(manifest.relative_to(root)),
        "registry": str(registry.relative_to(root)),
        "kernel_count": len(kernel_rows),
        "kernels": kernel_rows,
        "family_coverage": sorted(
            [
                {
                    "family": family,
                    "medium_count": stats["medium"],
                    "high_count": stats["high"],
                    "total_count": stats["total"],
                }
                for family, stats in family_counts.items()
            ],
            key=lambda row: str(row["family"]),
        ),
        "required_family_status": required_status,
        "implemented_capability_total": implemented_total,
        "implemented_capability_covered": implemented_covered,
        "implemented_capability_coverage_ratio": implemented_coverage_ratio,
        "implemented_capability_missing": missing_implemented_capabilities,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines: List[str] = []
    lines.append("# Corpus Coverage Report")
    lines.append("")
    lines.append(f"- Manifest: `{payload['manifest']}`")
    lines.append(f"- Capability registry: `{payload['registry']}`")
    lines.append(f"- Kernels: `{payload['kernel_count']}`")
    lines.append("")
    lines.append("## Kernel Mapping")
    lines.append("")
    lines.append("| Kernel | Complexity | Families | Capability IDs |")
    lines.append("| --- | --- | --- | --- |")
    for row in kernel_rows:
        lines.append(
            f"| `{row['id']}` | `{row['complexity_tier']}` | `{', '.join(row['family_tags'])}` | `{', '.join(row['capability_ids'])}` |"
        )
    lines.append("")
    lines.append("## Implemented Capability Coverage")
    lines.append("")
    lines.append(f"- Implemented capabilities in registry: `{implemented_total}`")
    lines.append(f"- Implemented capabilities covered by corpus: `{implemented_covered}`")
    lines.append(f"- Coverage ratio: `{implemented_coverage_ratio}`")
    missing = payload["implemented_capability_missing"]
    if missing:
        lines.append(f"- Missing: `{', '.join(missing)}`")
    else:
        lines.append("- Missing: `none`")
    lines.append("")
    lines.append("## Required Family Coverage")
    lines.append("")
    lines.append("| Family | Satisfied | Medium | High | Total |")
    lines.append("| --- | --- | ---: | ---: | ---: |")
    for row in required_status:
        satisfied_text = "true" if row["satisfied"] else "false"
        lines.append(
            f"| `{row['family']}` | `{satisfied_text}` | `{row['medium_count']}` | `{row['high_count']}` | `{row['total_count']}` |"
        )
    lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
