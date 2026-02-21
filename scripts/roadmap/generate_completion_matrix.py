#!/usr/bin/env python3
"""Generate deterministic full-program completion matrix artifacts."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[2]

DONE_STATUS_RE = re.compile(r"^DONE - [0-9a-f]{7,40}$")
OVERALL_STATUS_RE = re.compile(r"^- Overall status: (NOT DONE|DONE - [0-9a-f]{7,40})$")
MILESTONE_HEADER_RE = re.compile(r"^### ([A-Za-z0-9-]+)\b")
MILESTONE_STATUS_RE = re.compile(r"^- Status: (NOT DONE|DONE - [0-9a-f]{7,40})$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate completion matrix artifacts")
    parser.add_argument("--schema", default="config/completion-matrix-schema.json", help="Matrix schema path")
    parser.add_argument("--pinned-commit", default="config/cairo_pinned_commit.txt", help="Pinned commit path")
    parser.add_argument(
        "--sierra-matrix",
        default="roadmap/inventory/sierra-coverage-matrix.json",
        help="Sierra coverage matrix JSON",
    )
    parser.add_argument(
        "--release-go-no-go",
        default="roadmap/reports/release-go-no-go-report.json",
        help="Release go/no-go report JSON",
    )
    parser.add_argument(
        "--optimization-closure",
        default="roadmap/reports/optimization-closure-report.json",
        help="Optimization closure report JSON",
    )
    parser.add_argument(
        "--corelib-parity-trend",
        default="roadmap/inventory/corelib-parity-trend.json",
        help="Corelib parity trend report JSON",
    )
    parser.add_argument(
        "--capability-registry",
        default="roadmap/capabilities/registry.json",
        help="Capability registry JSON",
    )
    parser.add_argument(
        "--track-a-issue",
        default="roadmap/executable-issues/05-track-a-lean-to-sierra-functions.issue.md",
        help="Track-A issue markdown",
    )
    parser.add_argument(
        "--track-b-issue",
        default="roadmap/executable-issues/20-track-b-cairo-parity-and-reviewability-plan.issue.md",
        help="Track-B issue markdown",
    )
    parser.add_argument(
        "--issues-dir",
        default="roadmap/executable-issues",
        help="Executable issues directory",
    )
    parser.add_argument(
        "--out-dir",
        default="roadmap/reports",
        help="Output directory for completion matrix artifacts",
    )
    return parser.parse_args()


def require_path(path: Path, label: str) -> None:
    if not path.exists():
        raise ValueError(f"missing required data source ({label}): {path}")


def load_json(path: Path, label: str) -> Any:
    require_path(path, label)
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON in {label}: {path}: {exc}") from exc


def load_text(path: Path, label: str) -> str:
    require_path(path, label)
    return path.read_text(encoding="utf-8")


def parse_issue_statuses(issue_path: Path) -> Tuple[str, Dict[str, str]]:
    text = load_text(issue_path, "issue")
    overall = "NOT DONE"
    milestones: Dict[str, str] = {}

    current_milestone: str | None = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        overall_match = OVERALL_STATUS_RE.match(line)
        if overall_match:
            overall = overall_match.group(1)

        header_match = MILESTONE_HEADER_RE.match(line)
        if header_match:
            current_milestone = header_match.group(1)
            continue

        status_match = MILESTONE_STATUS_RE.match(line)
        if status_match and current_milestone is not None:
            milestones[current_milestone] = status_match.group(1)

    return overall, milestones


def is_done(status: str) -> bool:
    return bool(DONE_STATUS_RE.match(status))


def relative(path: Path) -> str:
    return str(path.resolve().relative_to(ROOT))


def classify_status(checks: List[bool]) -> str:
    if checks and all(checks):
        return "ready"
    if checks and any(checks):
        return "conditionally_ready"
    return "not_ready"


def build_rows(
    sierra_matrix: Dict[str, Any],
    go_no_go: Dict[str, Any],
    optimization: Dict[str, Any],
    parity_trend: Dict[str, Any],
    registry: Dict[str, Any],
    track_a_milestones: Dict[str, str],
    track_b_milestones: Dict[str, str],
    issues_dir: Path,
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []

    extension_modules = sierra_matrix.get("extension_modules", [])
    bad_non_starknet: List[str] = []
    if isinstance(extension_modules, list):
        for entry in extension_modules:
            if not isinstance(entry, dict):
                continue
            module_id = entry.get("module_id")
            status = entry.get("status")
            if not isinstance(module_id, str) or not isinstance(status, str):
                continue
            if module_id.startswith("starknet/"):
                continue
            if status not in {"implemented", "fail_fast"}:
                bad_non_starknet.append(f"{module_id}:{status}")

    family_ready = len(bad_non_starknet) == 0
    rows.append(
        {
            "dimension_id": "track_a_family_closure",
            "target_scope": "lean->sierra->casm",
            "required_metrics": [
                f"non_starknet_non_closed_modules={len(bad_non_starknet)}",
            ],
            "required_artifacts": [
                "roadmap/inventory/sierra-coverage-matrix.json",
                "roadmap/inventory/sierra-family-coverage-report.json",
            ],
            "blocking_gates": [
                "scripts/roadmap/check_sierra_primary_closure.sh",
                "scripts/roadmap/check_sierra_coverage_report_freshness.sh",
            ],
            "status": "ready" if family_ready else "not_ready",
            "diagnostics": bad_non_starknet[:10],
            "evidence_refs": [
                "scripts/roadmap/check_sierra_primary_closure.sh",
                "roadmap/inventory/sierra-coverage-matrix.json",
            ],
        }
    )

    proof = go_no_go.get("proof", {}) if isinstance(go_no_go, dict) else {}
    proof_pass = bool(proof.get("pass") is True)
    rows.append(
        {
            "dimension_id": "track_a_proof_closure",
            "target_scope": "lean->sierra->casm",
            "required_metrics": [
                f"proof_pass={proof_pass}",
                f"missing_required_theorems={int(proof.get('missing_required_theorems', 0))}",
                f"placeholder_count={int(proof.get('placeholder_count', 0))}",
            ],
            "required_artifacts": [
                "roadmap/reports/release-proof-report.md",
                "roadmap/reports/release-go-no-go-report.json",
            ],
            "blocking_gates": [
                "scripts/roadmap/check_proof_obligations.sh",
                "scripts/roadmap/check_release_go_no_go.sh",
            ],
            "status": "ready" if proof_pass else "not_ready",
            "diagnostics": [] if proof_pass else ["release go/no-go proof section failed"],
            "evidence_refs": [
                "roadmap/reports/release-go-no-go-report.json",
                "scripts/roadmap/check_release_go_no_go.sh",
            ],
        }
    )

    benchmark = go_no_go.get("benchmark", {}) if isinstance(go_no_go, dict) else {}
    benchmark_pass = bool(benchmark.get("pass") is True)
    rows.append(
        {
            "dimension_id": "track_a_benchmark_closure",
            "target_scope": "lean->sierra->casm",
            "required_metrics": [
                f"benchmark_pass={benchmark_pass}",
                f"case_count={int(benchmark.get('case_count', 0))}",
                f"hotspot_sierra_improvement_pct={float(benchmark.get('hotspot_sierra_improvement_pct', 0.0))}",
            ],
            "required_artifacts": [
                "generated/examples/benchmark-summary.json",
                "roadmap/reports/release-benchmark-report.md",
            ],
            "blocking_gates": [
                "scripts/bench/check_optimizer_non_regression.sh",
                "scripts/bench/check_optimizer_family_thresholds.sh",
            ],
            "status": "ready" if benchmark_pass else "not_ready",
            "diagnostics": [] if benchmark_pass else ["release go/no-go benchmark section failed"],
            "evidence_refs": [
                "roadmap/reports/release-go-no-go-report.json",
                "roadmap/reports/release-benchmark-report.md",
            ],
        }
    )

    opt_result = str(optimization.get("result", ""))
    opt_done = int(optimization.get("done_count", 0))
    opt_target = int(optimization.get("target_count", 0))
    opt_ready = opt_result == "PASS" and opt_done >= opt_target
    rows.append(
        {
            "dimension_id": "track_a_optimization_closure",
            "target_scope": "lean->sierra->casm",
            "required_metrics": [
                f"optimization_result={opt_result}",
                f"optimization_done_count={opt_done}",
                f"optimization_target_count={opt_target}",
            ],
            "required_artifacts": [
                "roadmap/reports/optimization-closure-report.json",
                "roadmap/reports/optimization-closure-report.md",
            ],
            "blocking_gates": [
                "scripts/roadmap/check_optimization_closure_report.sh",
                "scripts/roadmap/check_release_go_no_go.sh",
            ],
            "status": "ready" if opt_ready else "not_ready",
            "diagnostics": [] if opt_ready else ["optimization closure report is not PASS"],
            "evidence_refs": [
                "roadmap/reports/optimization-closure-report.json",
                "scripts/roadmap/check_optimization_closure_report.sh",
            ],
        }
    )

    parity_result = str(parity_trend.get("result", ""))
    parity_ready = parity_result == "PASS"
    rows.append(
        {
            "dimension_id": "track_b_parity_closure",
            "target_scope": "lean->cairo",
            "required_metrics": [
                f"parity_result={parity_result}",
                f"supported={int(parity_trend.get('counts', {}).get('supported', 0))}",
                f"bounded={int(parity_trend.get('counts', {}).get('bounded', 0))}",
            ],
            "required_artifacts": [
                "roadmap/inventory/corelib-parity-report.json",
                "roadmap/inventory/corelib-parity-trend.json",
            ],
            "blocking_gates": [
                "scripts/roadmap/check_corelib_parity_freshness.sh",
                "scripts/roadmap/check_corelib_parity_trend.sh",
            ],
            "status": "ready" if parity_ready else "not_ready",
            "diagnostics": [] if parity_ready else ["corelib parity trend result is not PASS"],
            "evidence_refs": [
                "roadmap/inventory/corelib-parity-trend.json",
                "scripts/roadmap/check_corelib_parity_trend.sh",
            ],
        }
    )

    reviewability_done = is_done(track_b_milestones.get("CPL-4", "NOT DONE"))
    determinism_done = is_done(track_b_milestones.get("CPL-3", "NOT DONE"))
    reviewability_status = classify_status([reviewability_done, determinism_done])
    reviewability_diag: List[str] = []
    if not reviewability_done:
        reviewability_diag.append("CPL-4 milestone is not DONE")
    if not determinism_done:
        reviewability_diag.append("CPL-3 milestone is not DONE")
    rows.append(
        {
            "dimension_id": "track_b_reviewability_closure",
            "target_scope": "lean->cairo",
            "required_metrics": [
                f"CPL-3={track_b_milestones.get('CPL-3', 'NOT FOUND')}",
                f"CPL-4={track_b_milestones.get('CPL-4', 'NOT FOUND')}",
            ],
            "required_artifacts": [
                "scripts/sierra/render_review_lift.py",
                "scripts/test/sierra_review_lift_complex.sh",
            ],
            "blocking_gates": [
                "scripts/test/sierra_review_lift.sh",
                "scripts/test/sierra_review_lift_complex.sh",
            ],
            "status": reviewability_status,
            "diagnostics": reviewability_diag,
            "evidence_refs": [
                "roadmap/executable-issues/20-track-b-cairo-parity-and-reviewability-plan.issue.md",
                "scripts/test/sierra_review_lift_complex.sh",
            ],
        }
    )

    divergence_missing: List[str] = []
    capabilities = registry.get("capabilities", [])
    if isinstance(capabilities, list):
        for cap in capabilities:
            if not isinstance(cap, dict):
                continue
            cap_id = str(cap.get("capability_id", ""))
            state = cap.get("support_state", {})
            if not isinstance(state, dict):
                continue
            sierra_state = state.get("sierra")
            cairo_state = state.get("cairo")
            if sierra_state == cairo_state:
                continue
            constraints = cap.get("divergence_constraints", [])
            if not isinstance(constraints, list) or len([x for x in constraints if isinstance(x, str) and x.strip()]) == 0:
                divergence_missing.append(cap_id)

    divergence_ready = len(divergence_missing) == 0
    rows.append(
        {
            "dimension_id": "track_b_divergence_contract_closure",
            "target_scope": "lean->cairo",
            "required_metrics": [
                f"missing_divergence_contracts={len(divergence_missing)}",
            ],
            "required_artifacts": [
                "roadmap/capabilities/registry.json",
                "roadmap/inventory/capability-coverage-report.json",
            ],
            "blocking_gates": [
                "scripts/roadmap/check_capability_registry.sh",
                "scripts/roadmap/check_capability_obligations.sh",
            ],
            "status": "ready" if divergence_ready else "not_ready",
            "diagnostics": divergence_missing[:20],
            "evidence_refs": [
                "roadmap/capabilities/registry.json",
                "scripts/roadmap/check_capability_registry.sh",
            ],
        }
    )

    purity_done = is_done(track_b_milestones.get("CPL-1", "NOT DONE"))
    purity_diag = [] if purity_done else ["CPL-1 milestone is not DONE"]
    rows.append(
        {
            "dimension_id": "track_b_purity_closure",
            "target_scope": "lean->cairo",
            "required_metrics": [
                f"CPL-1={track_b_milestones.get('CPL-1', 'NOT FOUND')}",
            ],
            "required_artifacts": [
                "scripts/test/sierra_primary_without_cairo.sh",
                "scripts/test/sierra_primary_cairo_coupling_guard.sh",
            ],
            "blocking_gates": [
                "scripts/test/sierra_primary_without_cairo.sh",
                "scripts/test/sierra_primary_cairo_coupling_guard.sh",
            ],
            "status": "ready" if purity_done else "not_ready",
            "diagnostics": purity_diag,
            "evidence_refs": [
                "roadmap/executable-issues/20-track-b-cairo-parity-and-reviewability-plan.issue.md",
                "scripts/test/sierra_primary_without_cairo.sh",
            ],
        }
    )

    p0_pending: List[str] = []
    for issue_path in sorted(issues_dir.glob("*.issue.md")):
        text = issue_path.read_text(encoding="utf-8")
        priority_p0 = any(line.strip() == "- Priority: P0" for line in text.splitlines())
        if not priority_p0:
            continue
        overall_status = "NOT DONE"
        for line in text.splitlines():
            match = OVERALL_STATUS_RE.match(line.strip())
            if match:
                overall_status = match.group(1)
                break
        if not is_done(overall_status):
            p0_pending.append(issue_path.name)

    p0_ready = len(p0_pending) == 0
    rows.append(
        {
            "dimension_id": "program_p0_issue_closure",
            "target_scope": "program",
            "required_metrics": [
                f"pending_p0_issues={len(p0_pending)}",
            ],
            "required_artifacts": [
                "roadmap/executable-issues",
            ],
            "blocking_gates": [
                "scripts/roadmap/check_issue_statuses.sh",
                "scripts/roadmap/check_issue_dependencies.sh",
                "scripts/roadmap/check_milestone_dependencies.py",
            ],
            "status": "ready" if p0_ready else "not_ready",
            "diagnostics": p0_pending,
            "evidence_refs": [
                "scripts/roadmap/check_issue_statuses.sh",
                "scripts/roadmap/check_issue_dependencies.sh",
            ],
        }
    )

    required_reports = [
        "roadmap/reports/release-compatibility-report.md",
        "roadmap/reports/release-proof-report.md",
        "roadmap/reports/release-benchmark-report.md",
        "roadmap/reports/release-capability-closure-report.md",
        "roadmap/reports/release-go-no-go-report.json",
        "roadmap/reports/release-go-no-go-report.md",
    ]
    missing_reports = [path for path in required_reports if not (ROOT / path).exists()]
    report_ready = len(missing_reports) == 0
    rows.append(
        {
            "dimension_id": "program_release_evidence_closure",
            "target_scope": "program",
            "required_metrics": [
                f"missing_required_reports={len(missing_reports)}",
            ],
            "required_artifacts": required_reports,
            "blocking_gates": [
                "scripts/roadmap/check_release_reports_freshness.sh",
                "scripts/roadmap/check_release_go_no_go.sh",
            ],
            "status": "ready" if report_ready else "not_ready",
            "diagnostics": missing_reports,
            "evidence_refs": [
                "scripts/roadmap/check_release_reports_freshness.sh",
                "roadmap/reports/release-go-no-go-report.json",
            ],
        }
    )

    rows.sort(key=lambda row: row["dimension_id"])
    return rows


def render_markdown(matrix_payload: Dict[str, Any]) -> str:
    lines: List[str] = [
        "# Completion Matrix",
        "",
        f"- Pinned commit: `{matrix_payload['pinned_commit']}`",
        f"- Schema: `{matrix_payload['schema']}`",
        "",
        "## Data Sources",
        "",
    ]

    for key, value in sorted(matrix_payload["data_sources"].items()):
        lines.append(f"- `{key}`: `{value}`")

    lines.extend(
        [
            "",
            "## Dimensions",
            "",
            "| Dimension | Scope | Status | Blocking gates |",
            "| --- | --- | --- | --- |",
        ]
    )

    for row in matrix_payload["rows"]:
        gates = ", ".join(f"`{gate}`" for gate in row["blocking_gates"]) if row["blocking_gates"] else "`none`"
        lines.append(
            f"| `{row['dimension_id']}` | `{row['target_scope']}` | `{row['status']}` | {gates} |"
        )

    lines.extend(["", "## Diagnostics", ""])
    for row in matrix_payload["rows"]:
        diag = row["diagnostics"]
        if not diag:
            continue
        lines.append(f"### `{row['dimension_id']}`")
        for item in diag:
            lines.append(f"- {item}")
        lines.append("")

    if lines[-1] != "":
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    args = parse_args()

    schema_path = (ROOT / args.schema).resolve()
    pinned_path = (ROOT / args.pinned_commit).resolve()
    sierra_path = (ROOT / args.sierra_matrix).resolve()
    go_no_go_path = (ROOT / args.release_go_no_go).resolve()
    optimization_path = (ROOT / args.optimization_closure).resolve()
    parity_trend_path = (ROOT / args.corelib_parity_trend).resolve()
    registry_path = (ROOT / args.capability_registry).resolve()
    track_a_issue_path = (ROOT / args.track_a_issue).resolve()
    track_b_issue_path = (ROOT / args.track_b_issue).resolve()
    issues_dir = (ROOT / args.issues_dir).resolve()
    out_dir = (ROOT / args.out_dir).resolve()

    require_path(schema_path, "schema")
    pinned_commit = load_text(pinned_path, "pinned_commit").strip()
    if not pinned_commit:
        raise ValueError(f"empty pinned commit file: {pinned_path}")

    sierra_matrix = load_json(sierra_path, "sierra_matrix")
    go_no_go = load_json(go_no_go_path, "release_go_no_go")
    optimization = load_json(optimization_path, "optimization_closure")
    parity_trend = load_json(parity_trend_path, "corelib_parity_trend")
    registry = load_json(registry_path, "capability_registry")

    require_path(issues_dir, "issues_dir")
    if not issues_dir.is_dir():
        raise ValueError(f"issues_dir is not a directory: {issues_dir}")

    _, track_a_milestones = parse_issue_statuses(track_a_issue_path)
    _, track_b_milestones = parse_issue_statuses(track_b_issue_path)

    rows = build_rows(
        sierra_matrix=sierra_matrix,
        go_no_go=go_no_go,
        optimization=optimization,
        parity_trend=parity_trend,
        registry=registry,
        track_a_milestones=track_a_milestones,
        track_b_milestones=track_b_milestones,
        issues_dir=issues_dir,
    )

    matrix_payload = {
        "version": 1,
        "schema_version": 1,
        "schema": relative(schema_path),
        "pinned_commit": pinned_commit,
        "data_sources": {
            "capability_registry": relative(registry_path),
            "corelib_parity_trend": relative(parity_trend_path),
            "optimization_closure": relative(optimization_path),
            "release_go_no_go": relative(go_no_go_path),
            "sierra_matrix": relative(sierra_path),
            "track_a_issue": relative(track_a_issue_path),
            "track_b_issue": relative(track_b_issue_path),
        },
        "rows": rows,
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    out_json = out_dir / "completion-matrix.json"
    out_md = out_dir / "completion-matrix.md"

    out_json.write_text(json.dumps(matrix_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(render_markdown(matrix_payload), encoding="utf-8")

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
