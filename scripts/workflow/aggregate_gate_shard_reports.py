#!/usr/bin/env python3
"""Aggregate sharded gate reports deterministically."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Aggregate gate shard reports")
    parser.add_argument("--out", required=True)
    parser.add_argument("reports", nargs="+")
    return parser.parse_args()


def load_report(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level must be object")
    return payload


def main() -> int:
    args = parse_args()
    out_path = Path(args.out).resolve()

    reports: List[Dict[str, object]] = []
    for report_arg in args.reports:
        path = Path(report_arg).resolve()
        report = load_report(path)
        report["__path"] = str(path)
        reports.append(report)

    normalized_reports = sorted(reports, key=lambda row: int(row.get("shard_index", 0)))
    merged_results: List[Dict[str, object]] = []
    for report in normalized_reports:
        rows = report.get("results", [])
        if not isinstance(rows, list):
            raise ValueError(f"{report['__path']}: results must be list")
        for row in rows:
            if not isinstance(row, dict):
                continue
            gate = str(row.get("gate", "")).strip()
            status = str(row.get("status", "")).strip()
            if not gate or not status:
                continue
            merged_results.append({"gate": gate, "status": status})

    merged_results = sorted(merged_results, key=lambda row: row["gate"])
    failures = [row for row in merged_results if row["status"] == "fail"]

    payload = {
        "version": 1,
        "report_count": len(normalized_reports),
        "gate_count": len(merged_results),
        "failure_count": len(failures),
        "result": "PASS" if not failures else "FAIL",
        "shards": [
            {
                "path": report["__path"],
                "shard_index": int(report.get("shard_index", 0)),
                "shard_count": int(report.get("shard_count", 0)),
                "mode": str(report.get("mode", "")),
                "gate_count": int(report.get("gate_count", 0)),
            }
            for report in normalized_reports
        ],
        "results": merged_results,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
