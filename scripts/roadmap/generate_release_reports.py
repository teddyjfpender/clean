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
BENCHMARK_DOC = ROOT / "docs" / "fixed-point" / "benchmark-results.md"
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
    rows = parse_benchmark_rows()
    improvements = []
    for row in rows:
        raw = row["improvement"].rstrip("%")
        try:
            improvements.append((float(raw), row["kernel"]))
        except ValueError:
            continue
    best = max(improvements, default=(0.0, "n/a"))

    lines = [
        "# Release Benchmark Report",
        "",
        f"- Commit: `{pinned_commit}`",
        f"- Benchmark source: `{BENCHMARK_DOC.relative_to(ROOT)}`",
        f"- Kernel rows parsed: `{len(rows)}`",
        f"- Best measured improvement: `{best[0]:.2f}%` (`{best[1]}`)",
        "",
        "## Kernel Summary",
        "",
        "| Kernel | Hand Steps | Optimized Steps | Delta | Improvement | Speedup |",
        "| --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in rows:
        lines.append(
            f"| `{row['kernel']}` | `{row['hand_steps']}` | `{row['optimized_steps']}` | `{row['delta']}` | `{row['improvement']}` | `{row['speedup']}` |"
        )
    lines.append("")
    (out_dir / "release-benchmark-report.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    pinned_commit = load_commit()

    render_compatibility_report(out_dir, pinned_commit)
    render_proof_report(out_dir, pinned_commit)
    render_benchmark_report(out_dir, pinned_commit)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
