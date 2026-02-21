#!/usr/bin/env python3
"""Enforce cost-model calibration policy thresholds."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check cost-model calibration thresholds")
    parser.add_argument("--calibration", required=True)
    parser.add_argument("--thresholds", required=True)
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level must be object")
    return payload


def main() -> int:
    args = parse_args()
    calibration_path = Path(args.calibration).resolve()
    thresholds_path = Path(args.thresholds).resolve()

    calibration = load_json(calibration_path)
    thresholds = load_json(thresholds_path)

    if calibration.get("version") != 1:
        raise SystemExit(f"{calibration_path}: version must be 1")
    if thresholds.get("version") != 1:
        raise SystemExit(f"{thresholds_path}: version must be 1")

    case_count = int(calibration.get("case_count", 0))
    metrics = calibration.get("metrics", {})
    if not isinstance(metrics, dict):
        raise SystemExit(f"{calibration_path}: metrics must be object")

    mean_abs_pct_error = float(metrics.get("mean_abs_pct_error", 0.0))
    max_abs_pct_error = float(metrics.get("max_abs_pct_error", 0.0))

    global_thresholds = thresholds.get("global", {})
    if not isinstance(global_thresholds, dict):
        raise SystemExit(f"{thresholds_path}: global thresholds must be object")

    min_case_count = int(global_thresholds.get("min_case_count", 0))
    max_mean_abs_pct_error = float(global_thresholds.get("max_mean_abs_pct_error", 100.0))
    max_max_abs_pct_error = float(global_thresholds.get("max_max_abs_pct_error", 100.0))

    errors = []
    if case_count < min_case_count:
        errors.append(
            f"case_count below threshold: current={case_count} min_required={min_case_count}"
        )
    if mean_abs_pct_error > max_mean_abs_pct_error:
        errors.append(
            "mean_abs_pct_error above threshold: "
            f"current={mean_abs_pct_error} max_allowed={max_mean_abs_pct_error}"
        )
    if max_abs_pct_error > max_max_abs_pct_error:
        errors.append(
            "max_abs_pct_error above threshold: "
            f"current={max_abs_pct_error} max_allowed={max_max_abs_pct_error}"
        )

    if errors:
        for error in errors:
            print(error)
        print(f"cost model calibration threshold checks failed with {len(errors)} error(s)")
        return 1

    print(
        "cost model calibration threshold checks passed "
        f"(case_count={case_count}, mean_abs_pct_error={mean_abs_pct_error}, max_abs_pct_error={max_abs_pct_error})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
