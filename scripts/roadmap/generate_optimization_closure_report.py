#!/usr/bin/env python3
"""Generate optimization closure report from executable issue status + artifacts."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ISSUE_PATH_DEFAULT = ROOT / "roadmap" / "executable-issues" / "23-verified-optimizing-compiler-escalation-plan.issue.md"
OUT_JSON_DEFAULT = ROOT / "roadmap" / "reports" / "optimization-closure-report.json"
OUT_MD_DEFAULT = ROOT / "roadmap" / "reports" / "optimization-closure-report.md"
MILESTONES = ["OPTX-1", "OPTX-2", "OPTX-3", "OPTX-4"]
REQUIRED_ARTIFACTS = [
    "src/LeanCairo/Compiler/Optimize/Pass.lean",
    "src/LeanCairo/Compiler/Optimize/Pipeline.lean",
    "src/LeanCairo/Compiler/Proof/OptimizeSound.lean",
    "src/LeanCairo/Compiler/Proof/CSELetNormSound.lean",
    "scripts/bench/check_optimizer_non_regression.sh",
    "scripts/bench/check_optimizer_family_thresholds.sh",
    "generated/examples/cost-model-calibration.json",
    "generated/examples/cost-model-calibration.md",
    "roadmap/reports/release-go-no-go-report.json",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate optimization closure report")
    parser.add_argument("--issue", default=str(ISSUE_PATH_DEFAULT), help="Issue markdown path")
    parser.add_argument("--out-json", default=str(OUT_JSON_DEFAULT), help="Output JSON report path")
    parser.add_argument("--out-md", default=str(OUT_MD_DEFAULT), help="Output markdown report path")
    return parser.parse_args()


def parse_statuses(issue_path: Path) -> dict[str, str]:
    statuses: dict[str, str] = {}
    current: str | None = None
    for line in issue_path.read_text(encoding="utf-8").splitlines():
        header = re.match(r"^###\s+([A-Za-z0-9-]+)\b", line)
        if header:
            current = header.group(1)
            continue
        status = re.match(r"^- Status: (NOT DONE|DONE - [0-9a-f]{7,40})$", line)
        if status and current is not None:
            statuses[current] = status.group(1)
    return statuses


def is_done(status: str) -> bool:
    return status.startswith("DONE - ")


def render_markdown(report: dict[str, object], issue_path: Path) -> str:
    lines = [
        "# Optimization Closure Report",
        "",
        f"- Source issue: `{issue_path.relative_to(ROOT)}`",
        f"- Result: `{report['result']}`",
        f"- Completed milestones: `{report['done_count']}` / `{report['target_count']}`",
        "",
        "## Milestone Status",
        "",
        "| Milestone | Status |",
        "| --- | --- |",
    ]
    statuses = report.get("milestone_statuses", {})
    if isinstance(statuses, dict):
        for milestone in MILESTONES:
            lines.append(f"| `{milestone}` | `{statuses.get(milestone, 'NOT DONE')}` |")

    lines.extend(["", "## Required Artifacts", ""])
    missing = report.get("missing_artifacts", [])
    if isinstance(missing, list) and missing:
        lines.append("- Missing:")
        for rel in missing:
            lines.append(f"  - `{rel}`")
    else:
        lines.append("- Missing: none")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    issue_path = Path(args.issue).resolve()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()

    statuses = parse_statuses(issue_path)
    done_count = sum(1 for milestone in MILESTONES if is_done(statuses.get(milestone, "NOT DONE")))
    missing_artifacts = [rel for rel in REQUIRED_ARTIFACTS if not (ROOT / rel).exists()]
    result = "PASS" if done_count == len(MILESTONES) and not missing_artifacts else "FAIL"

    report = {
        "version": 1,
        "issue": str(issue_path.relative_to(ROOT)),
        "result": result,
        "done_count": done_count,
        "target_count": len(MILESTONES),
        "milestone_statuses": {milestone: statuses.get(milestone, "NOT DONE") for milestone in MILESTONES},
        "required_artifacts": REQUIRED_ARTIFACTS,
        "missing_artifacts": missing_artifacts,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(render_markdown(report, issue_path), encoding="utf-8")
    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
