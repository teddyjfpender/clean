#!/usr/bin/env python3
"""Render Sierra family coverage report with explicit evidence references."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MATRIX_PATH = ROOT / "roadmap" / "inventory" / "sierra-coverage-matrix.json"
DEFAULT_OUT_JSON = ROOT / "roadmap" / "inventory" / "sierra-family-coverage-report.json"
DEFAULT_OUT_MD = ROOT / "roadmap" / "inventory" / "sierra-family-coverage-report.md"

EVIDENCE_BY_STATUS: dict[str, list[str]] = {
    "implemented": [
        "src/LeanCairo/Backend/Sierra/Emit/SubsetProgram.lean",
        "scripts/test/sierra_e2e.sh",
        "scripts/test/sierra_scalar_e2e.sh",
    ],
    "fail_fast": [
        "scripts/test/sierra_failfast_unsupported.sh",
        "scripts/roadmap/check_failfast_policy_lock.sh",
    ],
    "unresolved": [
        "roadmap/05-track-a-lean-to-sierra-functions.md",
    ],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-json", default=str(DEFAULT_OUT_JSON), help="Output JSON report path.")
    parser.add_argument("--out-md", default=str(DEFAULT_OUT_MD), help="Output markdown report path.")
    return parser.parse_args()


def module_entries(matrix_payload: dict) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    for raw_entry in matrix_payload.get("extension_modules", []):
        if not isinstance(raw_entry, dict):
            continue
        module_id = raw_entry.get("module_id")
        path = raw_entry.get("path")
        status = raw_entry.get("status")
        if not isinstance(module_id, str) or not isinstance(path, str) or not isinstance(status, str):
            continue
        evidence = EVIDENCE_BY_STATUS.get(status, ["roadmap/05-track-a-lean-to-sierra-functions.md"])
        entries.append(
            {
                "module_id": module_id,
                "path": path,
                "status": status,
                "evidence_refs": evidence,
            }
        )
    return entries


def render_markdown(pinned_commit: str, entries: list[dict[str, object]]) -> str:
    counts = Counter(str(entry["status"]) for entry in entries)
    lines = [
        "# Sierra Family Coverage Report (Pinned)",
        "",
        f"- Commit: `{pinned_commit}`",
        f"- Source matrix: `{MATRIX_PATH.relative_to(ROOT)}`",
        f"- Extension modules: `{len(entries)}`",
        f"- `implemented`: `{counts.get('implemented', 0)}`",
        f"- `fail_fast`: `{counts.get('fail_fast', 0)}`",
        f"- `unresolved`: `{counts.get('unresolved', 0)}`",
        "",
        "## Family Status and Evidence",
        "",
        "| Module | Status | Source file | Evidence refs |",
        "| --- | --- | --- | --- |",
    ]
    for entry in entries:
        evidence_refs = ", ".join(f"`{ref}`" for ref in entry["evidence_refs"])
        lines.append(
            f"| `{entry['module_id']}` | `{entry['status']}` | `{entry['path']}` | {evidence_refs} |"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_md.parent.mkdir(parents=True, exist_ok=True)

    matrix_payload = json.loads(MATRIX_PATH.read_text(encoding="utf-8"))
    pinned_commit = str(matrix_payload.get("pinned_commit", ""))
    entries = module_entries(matrix_payload)
    counts = Counter(str(entry["status"]) for entry in entries)

    report_json = {
        "pinned_commit": pinned_commit,
        "input_matrix": str(MATRIX_PATH.relative_to(ROOT)),
        "counts": counts,
        "entries": entries,
    }
    out_json.write_text(json.dumps(report_json, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(render_markdown(pinned_commit, entries), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
