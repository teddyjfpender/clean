#!/usr/bin/env python3
"""Generate deterministic profile artifacts from manifest benchmark summary."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List

REQUIRED_METRICS = (
    "baseline_sierra_gas",
    "generated_sierra_gas",
    "baseline_l2_gas",
    "generated_l2_gas",
    "sierra_improvement_pct",
    "l2_improvement_pct",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate profile artifacts from benchmark summary")
    parser.add_argument("--summary", required=True)
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--out-md", required=True)
    return parser.parse_args()


def load_summary(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level must be object")
    cases = payload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError(f"{path}: cases must be non-empty list")
    return payload


def main() -> int:
    args = parse_args()
    summary_path = Path(args.summary).resolve()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()

    summary = load_summary(summary_path)
    raw_cases = summary.get("cases", [])

    rows: List[Dict[str, object]] = []
    for idx, case in enumerate(raw_cases):
        ctx = f"{summary_path}: cases[{idx}]"
        if not isinstance(case, dict):
            raise ValueError(f"{ctx}: expected object")

        case_id = str(case.get("id", "")).strip()
        family = str(case.get("family", "")).strip()
        if not case_id:
            raise ValueError(f"{ctx}.id: expected non-empty string")
        if not family:
            raise ValueError(f"{ctx}.family: expected non-empty string")

        metrics = case.get("metrics")
        if not isinstance(metrics, dict):
            raise ValueError(f"{ctx}.metrics: expected object")

        metric_values: Dict[str, float] = {}
        for key in REQUIRED_METRICS:
            if key not in metrics:
                raise ValueError(f"{ctx}.metrics: missing key '{key}'")
            value = metrics[key]
            if not isinstance(value, (int, float)):
                raise ValueError(f"{ctx}.metrics.{key}: expected numeric value")
            metric_values[key] = float(value)

        generated = metric_values["generated_sierra_gas"]
        baseline = metric_values["baseline_sierra_gas"]
        hotspot_ratio = 0.0
        if baseline > 0.0:
            hotspot_ratio = generated / baseline

        rows.append(
            {
                "id": case_id,
                "family": family,
                "baseline_sierra_gas": baseline,
                "generated_sierra_gas": generated,
                "delta_sierra_gas": baseline - generated,
                "sierra_improvement_pct": metric_values["sierra_improvement_pct"],
                "l2_improvement_pct": metric_values["l2_improvement_pct"],
                "hotspot_ratio": hotspot_ratio,
            }
        )

    rows = sorted(rows, key=lambda row: (-float(row["generated_sierra_gas"]), str(row["id"])))

    families: Dict[str, Dict[str, float]] = {}
    for row in rows:
        family = str(row["family"])
        bucket = families.setdefault(
            family,
            {
                "case_count": 0.0,
                "generated_sierra_total": 0.0,
                "avg_hotspot_ratio": 0.0,
            },
        )
        bucket["case_count"] += 1.0
        bucket["generated_sierra_total"] += float(row["generated_sierra_gas"])
        bucket["avg_hotspot_ratio"] += float(row["hotspot_ratio"])

    family_rows: List[Dict[str, object]] = []
    for family, bucket in sorted(families.items()):
        count = int(bucket["case_count"])
        avg_ratio = 0.0 if count == 0 else bucket["avg_hotspot_ratio"] / count
        family_rows.append(
            {
                "family": family,
                "case_count": count,
                "generated_sierra_total": bucket["generated_sierra_total"],
                "avg_hotspot_ratio": round(avg_ratio, 6),
            }
        )

    payload = {
        "version": 1,
        "summary_source": str(summary_path),
        "profile_case_count": len(rows),
        "hotspots": rows,
        "families": family_rows,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines: List[str] = []
    lines.append("# Benchmark Profile Artifacts")
    lines.append("")
    lines.append(f"- Source summary: `{summary_path}`")
    lines.append(f"- Profile cases: `{len(rows)}`")
    lines.append("")
    lines.append("## Hotspot Ranking")
    lines.append("")
    lines.append("| Case | Family | Generated Sierra Gas | Baseline Sierra Gas | Delta | Sierra improvement % | Hotspot ratio |")
    lines.append("| --- | --- | ---: | ---: | ---: | ---: | ---: |")
    for row in rows:
        lines.append(
            f"| `{row['id']}` | `{row['family']}` | `{row['generated_sierra_gas']}` | `{row['baseline_sierra_gas']}` | `{row['delta_sierra_gas']}` | `{row['sierra_improvement_pct']}` | `{row['hotspot_ratio']}` |"
        )
    lines.append("")
    lines.append("## Family Hotspot Summary")
    lines.append("")
    lines.append("| Family | Cases | Generated Sierra Total | Avg hotspot ratio |")
    lines.append("| --- | ---: | ---: | ---: |")
    for row in family_rows:
        lines.append(
            f"| `{row['family']}` | `{row['case_count']}` | `{row['generated_sierra_total']}` | `{row['avg_hotspot_ratio']}` |"
        )
    lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
