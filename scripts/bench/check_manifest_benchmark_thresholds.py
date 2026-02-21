#!/usr/bin/env python3
"""Validate per-case and per-family benchmark thresholds for manifest benchmark suite."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check manifest benchmark thresholds")
    parser.add_argument("--config", required=True)
    parser.add_argument("--summary", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config_path = Path(args.config)
    summary_path = Path(args.summary)

    config = json.loads(config_path.read_text(encoding="utf-8"))
    summary = json.loads(summary_path.read_text(encoding="utf-8"))

    case_cfg: Dict[str, Dict[str, object]] = {}
    for case in config.get("cases", []):
        if not isinstance(case, dict):
            continue
        case_id = str(case.get("id", "")).strip()
        if not case_id:
            continue
        case_cfg[case_id] = case

    family_thresholds: Dict[str, Dict[str, float]] = {}
    for row in config.get("family_thresholds", []):
        if not isinstance(row, dict):
            continue
        family = str(row.get("family", "")).strip()
        if not family:
            continue
        family_thresholds[family] = {
            "min_sierra_improvement_pct": float(row.get("min_sierra_improvement_pct", 0.0)),
            "min_l2_improvement_pct": float(row.get("min_l2_improvement_pct", 0.0)),
        }

    errors: List[str] = []
    for row in summary.get("cases", []):
        if not isinstance(row, dict):
            continue
        case_id = str(row.get("id", "")).strip()
        metrics = row.get("metrics", {})
        if case_id not in case_cfg or not isinstance(metrics, dict):
            errors.append(f"summary case missing from config or invalid metrics: {case_id}")
            continue

        cfg = case_cfg[case_id]
        sierra_improvement = float(metrics.get("sierra_improvement_pct", 0.0))
        l2_improvement = float(metrics.get("l2_improvement_pct", 0.0))
        min_sierra = float(cfg.get("min_sierra_improvement_pct", 0.0))
        min_l2 = float(cfg.get("min_l2_improvement_pct", 0.0))
        if sierra_improvement < min_sierra:
            errors.append(
                f"case threshold violation ({case_id}): sierra_improvement_pct={sierra_improvement} < min={min_sierra}"
            )
        if l2_improvement < min_l2:
            errors.append(
                f"case threshold violation ({case_id}): l2_improvement_pct={l2_improvement} < min={min_l2}"
            )

    for family_row in summary.get("families", []):
        if not isinstance(family_row, dict):
            continue
        family = str(family_row.get("family", "")).strip()
        if family not in family_thresholds:
            continue
        avg_sierra = float(family_row.get("avg_sierra_improvement_pct", 0.0))
        avg_l2 = float(family_row.get("avg_l2_improvement_pct", 0.0))
        min_sierra = family_thresholds[family]["min_sierra_improvement_pct"]
        min_l2 = family_thresholds[family]["min_l2_improvement_pct"]
        if avg_sierra < min_sierra:
            errors.append(
                f"family threshold violation ({family}): avg_sierra_improvement_pct={avg_sierra} < min={min_sierra}"
            )
        if avg_l2 < min_l2:
            errors.append(
                f"family threshold violation ({family}): avg_l2_improvement_pct={avg_l2} < min={min_l2}"
            )

    if errors:
        for err in errors:
            print(err)
        print(f"manifest benchmark threshold checks failed with {len(errors)} error(s)")
        return 1

    print("manifest benchmark threshold checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
