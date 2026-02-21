#!/usr/bin/env python3
"""Generate deterministic corelib parity trend report from current parity + baseline minima."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate corelib parity trend report")
    parser.add_argument("--parity", required=True, help="Path to corelib parity report JSON")
    parser.add_argument("--baseline", required=True, help="Path to corelib parity trend baseline JSON")
    parser.add_argument("--out-json", required=True, help="Output JSON path")
    parser.add_argument("--out-md", required=True, help="Output Markdown path")
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level JSON must be object")
    return payload


def main() -> int:
    args = parse_args()
    parity_path = Path(args.parity).resolve()
    baseline_path = Path(args.baseline).resolve()
    out_json_path = Path(args.out_json).resolve()
    out_md_path = Path(args.out_md).resolve()

    parity = load_json(parity_path)
    baseline = load_json(baseline_path)

    counts = parity.get("counts")
    if not isinstance(counts, dict):
        raise ValueError(f"{parity_path}: missing object field 'counts'")

    entries = parity.get("entries")
    if not isinstance(entries, list):
        raise ValueError(f"{parity_path}: missing list field 'entries'")

    minimums = baseline.get("minimums")
    if not isinstance(minimums, dict):
        raise ValueError(f"{baseline_path}: missing object field 'minimums'")

    supported_count = int(counts.get("supported", 0))
    partial_count = int(counts.get("partial", 0))
    excluded_count = int(counts.get("excluded", 0))
    total_count = len(entries)

    bounded_count = supported_count + partial_count
    bounded_ratio = 0.0 if total_count == 0 else round(bounded_count / total_count, 6)

    checks = [
        {
            "metric": "supported_count",
            "current": supported_count,
            "minimum": int(minimums.get("supported_count", 0)),
        },
        {
            "metric": "bounded_count",
            "current": bounded_count,
            "minimum": int(minimums.get("bounded_count", 0)),
        },
        {
            "metric": "bounded_ratio",
            "current": bounded_ratio,
            "minimum": float(minimums.get("bounded_ratio", 0.0)),
        },
    ]

    for check in checks:
        check["pass"] = bool(float(check["current"]) >= float(check["minimum"]))

    result = "PASS" if all(bool(check["pass"]) for check in checks) else "FAIL"
    payload = {
        "version": 1,
        "inputs": {
            "parity_report": str(parity_path),
            "baseline": str(baseline_path),
        },
        "pinned_commit": str(parity.get("pinned_commit", "")),
        "counts": {
            "supported": supported_count,
            "partial": partial_count,
            "excluded": excluded_count,
            "total": total_count,
            "bounded": bounded_count,
            "bounded_ratio": bounded_ratio,
        },
        "checks": checks,
        "result": result,
    }

    out_json_path.parent.mkdir(parents=True, exist_ok=True)
    out_json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines: List[str] = []
    lines.append("# Corelib Parity Trend Report")
    lines.append("")
    lines.append(f"- Parity source: `{parity_path}`")
    lines.append(f"- Baseline source: `{baseline_path}`")
    lines.append(f"- Pinned commit: `{payload['pinned_commit']}`")
    lines.append(f"- Result: `{result}`")
    lines.append("")
    lines.append("| Metric | Current | Minimum | Pass |")
    lines.append("| --- | ---: | ---: | --- |")
    for check in checks:
        pass_text = "true" if bool(check["pass"]) else "false"
        lines.append(
            f"| `{check['metric']}` | `{check['current']}` | `{check['minimum']}` | `{pass_text}` |"
        )
    lines.append("")
    lines.append("## Counts")
    lines.append("")
    lines.append(f"- Supported: `{supported_count}`")
    lines.append(f"- Partial: `{partial_count}`")
    lines.append(f"- Excluded: `{excluded_count}`")
    lines.append(f"- Total: `{total_count}`")
    lines.append(f"- Bounded (supported + partial): `{bounded_count}`")
    lines.append(f"- Bounded ratio: `{bounded_ratio}`")
    lines.append("")

    out_md_path.parent.mkdir(parents=True, exist_ok=True)
    out_md_path.write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote: {out_json_path}")
    print(f"wrote: {out_md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
