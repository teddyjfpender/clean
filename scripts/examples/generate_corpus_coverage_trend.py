#!/usr/bin/env python3
"""Generate deterministic corpus coverage trend report from current coverage + baseline minima."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate corpus coverage trend report")
    parser.add_argument("--coverage", required=True)
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--out-md", required=True)
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level must be object")
    return payload


def main() -> int:
    args = parse_args()
    coverage_path = Path(args.coverage).resolve()
    baseline_path = Path(args.baseline).resolve()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()

    coverage = load_json(coverage_path)
    baseline = load_json(baseline_path)

    minimums = baseline.get("minimums")
    if not isinstance(minimums, dict):
        raise ValueError(f"{baseline_path}: minimums must be object")

    kernel_count = int(coverage.get("kernel_count", 0))
    family_coverage = coverage.get("family_coverage", [])
    if not isinstance(family_coverage, list):
        raise ValueError(f"{coverage_path}: family_coverage must be list")
    family_count = len(family_coverage)

    implemented_ratio = float(coverage.get("implemented_capability_coverage_ratio", 0.0))

    min_kernel_count = int(minimums.get("kernel_count", 0))
    min_family_count = int(minimums.get("family_count", 0))
    min_implemented_ratio = float(minimums.get("implemented_capability_coverage_ratio", 0.0))

    checks = [
        {
            "metric": "kernel_count",
            "current": kernel_count,
            "minimum": min_kernel_count,
            "pass": kernel_count >= min_kernel_count,
        },
        {
            "metric": "family_count",
            "current": family_count,
            "minimum": min_family_count,
            "pass": family_count >= min_family_count,
        },
        {
            "metric": "implemented_capability_coverage_ratio",
            "current": implemented_ratio,
            "minimum": min_implemented_ratio,
            "pass": implemented_ratio >= min_implemented_ratio,
        },
    ]

    failures = [check for check in checks if not check["pass"]]
    payload = {
        "version": 1,
        "coverage_source": str(coverage_path),
        "baseline_source": str(baseline_path),
        "result": "PASS" if not failures else "FAIL",
        "checks": checks,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines: List[str] = []
    lines.append("# Corpus Coverage Trend Report")
    lines.append("")
    lines.append(f"- Coverage source: `{coverage_path}`")
    lines.append(f"- Baseline source: `{baseline_path}`")
    lines.append(f"- Result: `{payload['result']}`")
    lines.append("")
    lines.append("| Metric | Current | Minimum | Pass |")
    lines.append("| --- | ---: | ---: | --- |")
    for check in checks:
        pass_text = "true" if check["pass"] else "false"
        lines.append(
            f"| `{check['metric']}` | `{check['current']}` | `{check['minimum']}` | `{pass_text}` |"
        )
    lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
