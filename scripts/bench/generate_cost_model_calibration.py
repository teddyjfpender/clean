#!/usr/bin/env python3
"""Generate versioned cost-model calibration artifacts from benchmark summary."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate cost-model calibration artifacts")
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

    case_rows: List[Dict[str, object]] = []
    abs_pct_errors: List[float] = []

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
        baseline = metrics.get("baseline_sierra_gas")
        measured = metrics.get("generated_sierra_gas")
        if not isinstance(baseline, (int, float)) or not isinstance(measured, (int, float)):
            raise ValueError(f"{ctx}.metrics: baseline/generated_sierra_gas must be numeric")

        baseline_f = float(baseline)
        measured_f = float(measured)
        if baseline_f <= 0.0:
            raise ValueError(f"{ctx}.metrics.baseline_sierra_gas must be > 0")

        coefficient = round(measured_f / baseline_f, 6)
        predicted = baseline_f * coefficient
        abs_error = abs(predicted - measured_f)
        abs_error_pct = 0.0 if measured_f == 0.0 else (abs_error / measured_f) * 100.0
        abs_pct_errors.append(abs_error_pct)

        case_rows.append(
            {
                "id": case_id,
                "family": family,
                "baseline_sierra_gas": baseline_f,
                "measured_sierra_gas": measured_f,
                "coefficient": coefficient,
                "predicted_sierra_gas": predicted,
                "abs_error": abs_error,
                "abs_error_pct": abs_error_pct,
            }
        )

    case_rows = sorted(case_rows, key=lambda row: str(row["id"]))
    case_count = len(case_rows)
    mean_abs_pct_error = 0.0 if case_count == 0 else sum(abs_pct_errors) / case_count
    max_abs_pct_error = max(abs_pct_errors, default=0.0)

    payload = {
        "version": 1,
        "model": {
            "name": "ratio_by_case_v1",
            "description": "Per-case baseline-to-generated ratio bootstrap calibration.",
        },
        "summary_source": str(summary_path),
        "case_count": case_count,
        "metrics": {
            "mean_abs_pct_error": mean_abs_pct_error,
            "max_abs_pct_error": max_abs_pct_error,
        },
        "cases": case_rows,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    lines: List[str] = []
    lines.append("# Cost Model Calibration")
    lines.append("")
    lines.append(f"- Summary source: `{summary_path}`")
    lines.append(f"- Model: `{payload['model']['name']}`")
    lines.append(f"- Case count: `{case_count}`")
    lines.append(f"- Mean absolute pct error: `{mean_abs_pct_error}`")
    lines.append(f"- Max absolute pct error: `{max_abs_pct_error}`")
    lines.append("")
    lines.append("| Case | Family | Coefficient | Measured Sierra Gas | Predicted Sierra Gas | Abs Error % |")
    lines.append("| --- | --- | ---: | ---: | ---: | ---: |")
    for row in case_rows:
        lines.append(
            f"| `{row['id']}` | `{row['family']}` | `{row['coefficient']}` | `{row['measured_sierra_gas']}` | `{row['predicted_sierra_gas']}` | `{row['abs_error_pct']}` |"
        )
    lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
