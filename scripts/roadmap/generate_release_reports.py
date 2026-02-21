#!/usr/bin/env python3
"""Generate deterministic release reports from versioned source artifacts."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR_DEFAULT = ROOT / "roadmap" / "reports"
PIN_FILE = ROOT / "config" / "cairo_pinned_commit.txt"
SIERRA_REPORT = ROOT / "roadmap" / "inventory" / "sierra-family-coverage-report.json"
CORELIB_REPORT = ROOT / "roadmap" / "inventory" / "corelib-parity-report.json"
CAPABILITY_REPORT = ROOT / "roadmap" / "inventory" / "capability-coverage-report.json"
CAPABILITY_SLO_BASELINE = ROOT / "roadmap" / "capabilities" / "capability-closure-slo-baseline.json"
BENCHMARK_DOC = ROOT / "docs" / "fixed-point" / "benchmark-results.md"
MANIFEST_BENCHMARK_SUMMARY = ROOT / "generated" / "examples" / "benchmark-summary.json"
PROOF_CHECK_SCRIPT = ROOT / "scripts" / "roadmap" / "check_proof_obligations.sh"
PROOF_DIR = ROOT / "src" / "LeanCairo" / "Compiler" / "Proof"
SEM_DIR = ROOT / "src" / "LeanCairo" / "Compiler" / "Semantics"
OPT_DIR = ROOT / "src" / "LeanCairo" / "Compiler" / "Optimize"
PROOF_DEBT_FILE = ROOT / "roadmap" / "proof-debt.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", default=str(OUT_DIR_DEFAULT), help="Output directory for release reports.")
    return parser.parse_args()


def load_commit() -> str:
    value = PIN_FILE.read_text(encoding="utf-8").strip()
    if not value:
        raise ValueError(f"empty commit pin file: {PIN_FILE}")
    return value


def count_theorem_occurrences(theorem: str) -> int:
    pattern = re.compile(rf"theorem\s+{re.escape(theorem)}\b")
    count = 0
    for directory in (PROOF_DIR, SEM_DIR, OPT_DIR):
        for path in sorted(directory.rglob("*.lean")):
            text = path.read_text(encoding="utf-8")
            count += len(pattern.findall(text))
    return count


def parse_required_theorems() -> list[str]:
    text = PROOF_CHECK_SCRIPT.read_text(encoding="utf-8")
    block_match = re.search(r"REQUIRED_THEOREMS=\(\n(.*?)\n\)", text, flags=re.S)
    if block_match is None:
        raise ValueError(f"failed to parse REQUIRED_THEOREMS from {PROOF_CHECK_SCRIPT}")
    block = block_match.group(1)
    theorem_names = re.findall(r'"([^"]+)"', block)
    if not theorem_names:
        raise ValueError("no required theorems parsed from proof check script")
    return theorem_names


def count_placeholders() -> int:
    pattern = re.compile(r"\bsorry\b|\badmit\b")
    count = 0
    for directory in (PROOF_DIR, SEM_DIR):
        for path in sorted(directory.rglob("*.lean")):
            count += len(pattern.findall(path.read_text(encoding="utf-8")))
    return count


def load_proof_debt() -> dict:
    if not PROOF_DEBT_FILE.exists():
        return {"entries": []}
    payload = json.loads(PROOF_DEBT_FILE.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        return {"entries": []}
    entries = payload.get("entries")
    if not isinstance(entries, list):
        entries = []
    return {"entries": entries}


def parse_benchmark_rows() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    pattern = re.compile(
        r"^\| `([^`]+)` \| ([0-9]+) \| ([0-9]+) \| ([0-9]+) \| ([0-9.]+%) \| ([0-9.]+x) \|$"
    )
    for line in BENCHMARK_DOC.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line.strip())
        if match is None:
            continue
        rows.append(
            {
                "kernel": match.group(1),
                "hand_steps": match.group(2),
                "optimized_steps": match.group(3),
                "delta": match.group(4),
                "improvement": match.group(5),
                "speedup": match.group(6),
            }
        )
    return rows


def render_compatibility_report(out_dir: Path, pinned_commit: str) -> None:
    sierra = json.loads(SIERRA_REPORT.read_text(encoding="utf-8"))
    corelib = json.loads(CORELIB_REPORT.read_text(encoding="utf-8"))
    sierra_counts = sierra.get("counts", {})
    corelib_counts = corelib.get("counts", {})

    lines = [
        "# Release Compatibility Report",
        "",
        f"- Commit: `{pinned_commit}`",
        f"- Sierra family source: `{SIERRA_REPORT.relative_to(ROOT)}`",
        f"- Corelib parity source: `{CORELIB_REPORT.relative_to(ROOT)}`",
        "",
        "## Sierra Family Coverage",
        "",
        f"- `implemented`: `{sierra_counts.get('implemented', 0)}`",
        f"- `fail_fast`: `{sierra_counts.get('fail_fast', 0)}`",
        f"- `unresolved`: `{sierra_counts.get('unresolved', 0)}`",
        "",
        "## Corelib Parity Coverage",
        "",
        f"- `supported`: `{corelib_counts.get('supported', 0)}`",
        f"- `partial`: `{corelib_counts.get('partial', 0)}`",
        f"- `excluded`: `{corelib_counts.get('excluded', 0)}`",
        "",
    ]
    (out_dir / "release-compatibility-report.md").write_text("\n".join(lines), encoding="utf-8")


def render_proof_report(out_dir: Path, pinned_commit: str) -> None:
    theorem_names = parse_required_theorems()
    theorem_results = [
        (name, count_theorem_occurrences(name)) for name in theorem_names
    ]
    missing = [name for name, count in theorem_results if count == 0]
    placeholder_count = count_placeholders()
    debt = load_proof_debt()["entries"]
    open_high = [
        entry
        for entry in debt
        if isinstance(entry, dict)
        and entry.get("status") == "open"
        and entry.get("severity") == "high"
    ]

    lines = [
        "# Release Proof Report",
        "",
        f"- Commit: `{pinned_commit}`",
        f"- Required theorem source: `{PROOF_CHECK_SCRIPT.relative_to(ROOT)}`",
        f"- Required theorem count: `{len(theorem_names)}`",
        f"- Missing required theorems: `{len(missing)}`",
        f"- Placeholder count (`sorry`/`admit`): `{placeholder_count}`",
        f"- Open high-severity proof debt items: `{len(open_high)}`",
        "",
        "## Required Theorem Presence",
        "",
        "| Theorem | Occurrences |",
        "| --- | ---: |",
    ]
    for name, count in theorem_results:
        lines.append(f"| `{name}` | `{count}` |")
    lines.extend(["", "## Open High-Severity Proof Debt", ""])
    if open_high:
        for entry in open_high:
            lines.append(f"- `{entry.get('id', 'unknown')}`: {entry.get('summary', '')}")
    else:
        lines.append("- none")
    lines.append("")

    (out_dir / "release-proof-report.md").write_text("\n".join(lines), encoding="utf-8")


def render_benchmark_report(out_dir: Path, pinned_commit: str) -> None:
    lines = [
        "# Release Benchmark Report",
        "",
        f"- Commit: `{pinned_commit}`",
    ]

    if MANIFEST_BENCHMARK_SUMMARY.exists():
        payload = json.loads(MANIFEST_BENCHMARK_SUMMARY.read_text(encoding="utf-8"))
        cases = payload.get("cases", [])
        families = payload.get("families", [])
        if not isinstance(cases, list):
            cases = []
        if not isinstance(families, list):
            families = []

        best_case = ("n/a", 0.0)
        worst_case = ("n/a", 0.0)
        if cases:
            ordered = sorted(
                [
                    (
                        str(case.get("id", "")),
                        float(case.get("metrics", {}).get("sierra_improvement_pct", 0.0)),
                        float(case.get("metrics", {}).get("l2_improvement_pct", 0.0)),
                    )
                    for case in cases
                    if isinstance(case, dict)
                ],
                key=lambda item: item[1],
            )
            if ordered:
                worst_case = (ordered[0][0], ordered[0][1])
                best_case = (ordered[-1][0], ordered[-1][1])

        lines.extend(
            [
                f"- Benchmark source: `{MANIFEST_BENCHMARK_SUMMARY.relative_to(ROOT)}`",
                f"- Cases parsed: `{len(cases)}`",
                f"- Best Sierra improvement: `{best_case[1]:.2f}%` (`{best_case[0]}`)",
                f"- Hotspot (lowest Sierra improvement): `{worst_case[1]:.2f}%` (`{worst_case[0]}`)",
                "",
                "## Family Summary",
                "",
                "| Family | Cases | Avg Sierra improvement % | Avg L2 improvement % |",
                "| --- | ---: | ---: | ---: |",
            ]
        )
        for family in families:
            if not isinstance(family, dict):
                continue
            lines.append(
                f"| `{family.get('family', '')}` | `{family.get('case_count', 0)}` | `{float(family.get('avg_sierra_improvement_pct', 0.0))}` | `{float(family.get('avg_l2_improvement_pct', 0.0))}` |"
            )

        lines.extend(["", "## Case Summary", "", "| Case | Sierra improvement % | L2 improvement % |", "| --- | ---: | ---: |"])
        for case in sorted(
            [c for c in cases if isinstance(c, dict)],
            key=lambda item: str(item.get("id", "")),
        ):
            metrics = case.get("metrics", {})
            lines.append(
                f"| `{case.get('id', '')}` | `{float(metrics.get('sierra_improvement_pct', 0.0))}` | `{float(metrics.get('l2_improvement_pct', 0.0))}` |"
            )
        lines.append("")
    else:
        rows = parse_benchmark_rows()
        improvements = []
        for row in rows:
            raw = row["improvement"].rstrip("%")
            try:
                improvements.append((float(raw), row["kernel"]))
            except ValueError:
                continue
        best = max(improvements, default=(0.0, "n/a"))

        lines.extend(
            [
                f"- Benchmark source: `{BENCHMARK_DOC.relative_to(ROOT)}`",
                f"- Kernel rows parsed: `{len(rows)}`",
                f"- Best measured improvement: `{best[0]:.2f}%` (`{best[1]}`)",
                "",
                "## Kernel Summary",
                "",
                "| Kernel | Hand Steps | Optimized Steps | Delta | Improvement | Speedup |",
                "| --- | ---: | ---: | ---: | ---: | ---: |",
            ]
        )
        for row in rows:
            lines.append(
                f"| `{row['kernel']}` | `{row['hand_steps']}` | `{row['optimized_steps']}` | `{row['delta']}` | `{row['improvement']}` | `{row['speedup']}` |"
            )
        lines.append("")

    (out_dir / "release-benchmark-report.md").write_text("\n".join(lines), encoding="utf-8")


def render_capability_closure_report(out_dir: Path, pinned_commit: str) -> None:
    capability = json.loads(CAPABILITY_REPORT.read_text(encoding="utf-8"))
    baseline = json.loads(CAPABILITY_SLO_BASELINE.read_text(encoding="utf-8"))

    overall = capability.get("overall_status_counts", {})
    sierra = capability.get("sierra_status_counts", {})
    cairo = capability.get("cairo_status_counts", {})
    closure = capability.get("closure_ratios", {})
    minimums = baseline.get("minimums", {})
    family_minimums = minimums.get("family_overall_implemented", {})

    violations: list[str] = []
    checks = [
        ("overall", int(overall.get("implemented", 0)), int(minimums.get("overall_implemented", 0))),
        ("sierra", int(sierra.get("implemented", 0)), int(minimums.get("sierra_implemented", 0))),
        ("cairo", int(cairo.get("implemented", 0)), int(minimums.get("cairo_implemented", 0))),
    ]
    for label, current, required in checks:
        if current < required:
            violations.append(f"{label}: current={current}, required_min={required}")

    families = capability.get("families", {})
    if isinstance(family_minimums, dict):
        for family, required in sorted(family_minimums.items()):
            entry = families.get(family, {})
            family_overall = entry.get("overall", {}) if isinstance(entry, dict) else {}
            current = int(family_overall.get("implemented", 0))
            if current < int(required):
                violations.append(
                    f"family {family}: current={current}, required_min={required}"
                )

    lines = [
        "# Release Capability Closure Report",
        "",
        f"- Commit: `{pinned_commit}`",
        f"- Capability source: `{CAPABILITY_REPORT.relative_to(ROOT)}`",
        f"- SLO baseline: `{CAPABILITY_SLO_BASELINE.relative_to(ROOT)}`",
        f"- Total capabilities: `{capability.get('total_capabilities', 0)}`",
        "",
        "## Closure Ratios",
        "",
        f"- `overall_implemented_ratio`: `{closure.get('overall_implemented_ratio', 0.0)}`",
        f"- `sierra_implemented_ratio`: `{closure.get('sierra_implemented_ratio', 0.0)}`",
        f"- `cairo_implemented_ratio`: `{closure.get('cairo_implemented_ratio', 0.0)}`",
        "",
        "## Monotonicity Against SLO Baseline",
        "",
    ]

    if violations:
        lines.append(f"- Result: `FAIL` (`{len(violations)}` violations)")
        for violation in violations:
            lines.append(f"- {violation}")
    else:
        lines.append("- Result: `PASS`")
    lines.append("")

    (out_dir / "release-capability-closure-report.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    pinned_commit = load_commit()

    render_compatibility_report(out_dir, pinned_commit)
    render_proof_report(out_dir, pinned_commit)
    render_benchmark_report(out_dir, pinned_commit)
    render_capability_closure_report(out_dir, pinned_commit)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
