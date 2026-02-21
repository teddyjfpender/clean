#!/usr/bin/env python3
"""Run manifest-driven benchmark cases and emit deterministic summary artifacts."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Dict, List


KEY_VALUE_RE = re.compile(r"^([a-zA-Z0-9_]+)\s*=\s*(.+)$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run manifest benchmark suite")
    parser.add_argument("--config", required=True)
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--out-md", required=True)
    parser.add_argument("--logs-dir", required=True)
    return parser.parse_args()


def parse_numeric(value: str) -> float:
    stripped = value.strip()
    if stripped.endswith("%"):
        stripped = stripped[:-1]
    return float(stripped)


def parse_metrics(output: str) -> Dict[str, float]:
    metrics: Dict[str, float] = {}
    for raw_line in output.splitlines():
        line = raw_line.strip()
        match = KEY_VALUE_RE.match(line)
        if not match:
            continue
        key = match.group(1)
        value = match.group(2).strip()
        try:
            metrics[key] = parse_numeric(value)
        except ValueError:
            continue
    return metrics


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    config_path = Path(args.config).resolve()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()
    logs_dir = Path(args.logs_dir).resolve()

    payload = json.loads(config_path.read_text(encoding="utf-8"))
    cases = payload.get("cases", [])
    if not isinstance(cases, list) or not cases:
        raise SystemExit(f"invalid benchmark harness config (no cases): {config_path}")

    logs_dir.mkdir(parents=True, exist_ok=True)

    summary_cases: List[Dict[str, object]] = []
    family_buckets: Dict[str, List[Dict[str, object]]] = {}

    for case in cases:
        if not isinstance(case, dict):
            raise SystemExit("invalid case entry in benchmark config")
        case_id = str(case.get("id", "")).strip()
        family = str(case.get("family", "")).strip()
        runner_script = str(case.get("runner_script", "")).strip()
        if not case_id or not family or not runner_script:
            raise SystemExit(f"invalid case fields in benchmark config: {case}")

        runner_abs = (root / runner_script).resolve()
        if not runner_abs.is_file():
            raise SystemExit(f"missing benchmark runner script for {case_id}: {runner_script}")

        proc = subprocess.run(
            [str(runner_abs)],
            cwd=root,
            text=True,
            capture_output=True,
        )
        combined_output = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")

        log_file = logs_dir / f"{case_id}.log"
        log_file.write_text(combined_output, encoding="utf-8")

        if proc.returncode != 0:
            print(combined_output)
            raise SystemExit(
                f"benchmark case failed: id={case_id} runner={runner_script} (see {log_file})"
            )

        metrics = parse_metrics(combined_output)
        required = (
            "baseline_sierra_gas",
            "generated_sierra_gas",
            "baseline_l2_gas",
            "generated_l2_gas",
            "sierra_improvement_pct",
            "l2_improvement_pct",
        )
        missing = [key for key in required if key not in metrics]
        if missing:
            raise SystemExit(
                f"benchmark case {case_id} missing required metrics: {', '.join(missing)}"
            )

        row = {
            "id": case_id,
            "family": family,
            "runner_script": runner_script,
            "log_file": str(log_file.relative_to(root)),
            "metrics": {
                "baseline_sierra_gas": metrics["baseline_sierra_gas"],
                "generated_sierra_gas": metrics["generated_sierra_gas"],
                "baseline_l2_gas": metrics["baseline_l2_gas"],
                "generated_l2_gas": metrics["generated_l2_gas"],
                "sierra_improvement_pct": metrics["sierra_improvement_pct"],
                "l2_improvement_pct": metrics["l2_improvement_pct"],
                "baseline_fn_avg_gas": metrics.get("baseline_fn_avg_gas", 0.0),
                "generated_fn_avg_gas": metrics.get("generated_fn_avg_gas", 0.0),
                "fn_improvement_pct": metrics.get("fn_improvement_pct", 0.0),
            },
        }
        summary_cases.append(row)
        family_buckets.setdefault(family, []).append(row)

    summary_cases = sorted(summary_cases, key=lambda item: str(item["id"]))

    family_summary: List[Dict[str, object]] = []
    for family in sorted(family_buckets.keys()):
        rows = family_buckets[family]
        avg_sierra = sum(float(row["metrics"]["sierra_improvement_pct"]) for row in rows) / len(rows)
        avg_l2 = sum(float(row["metrics"]["l2_improvement_pct"]) for row in rows) / len(rows)
        family_summary.append(
            {
                "family": family,
                "case_count": len(rows),
                "avg_sierra_improvement_pct": round(avg_sierra, 6),
                "avg_l2_improvement_pct": round(avg_l2, 6),
            }
        )

    summary = {
        "version": 1,
        "config": str(config_path.relative_to(root)),
        "case_count": len(summary_cases),
        "cases": summary_cases,
        "families": family_summary,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines: List[str] = []
    lines.append("# Manifest Benchmark Summary")
    lines.append("")
    lines.append(f"- Config: `{summary['config']}`")
    lines.append(f"- Cases: `{summary['case_count']}`")
    lines.append("")
    lines.append("## Case Metrics")
    lines.append("")
    lines.append("| Case | Family | Sierra improvement % | L2 improvement % | Log |")
    lines.append("| --- | --- | ---: | ---: | --- |")
    for row in summary_cases:
        metrics = row["metrics"]
        lines.append(
            f"| `{row['id']}` | `{row['family']}` | `{metrics['sierra_improvement_pct']}` | `{metrics['l2_improvement_pct']}` | `{row['log_file']}` |"
        )
    lines.append("")
    lines.append("## Family Aggregates")
    lines.append("")
    lines.append("| Family | Cases | Avg Sierra improvement % | Avg L2 improvement % |")
    lines.append("| --- | ---: | ---: | ---: |")
    for family_row in family_summary:
        lines.append(
            f"| `{family_row['family']}` | `{family_row['case_count']}` | `{family_row['avg_sierra_improvement_pct']}` | `{family_row['avg_l2_improvement_pct']}` |"
        )
    lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
