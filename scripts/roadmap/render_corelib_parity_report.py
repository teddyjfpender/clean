#!/usr/bin/env python3
"""Render deterministic corelib parity classification from pinned inventories."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PINNED_COMMIT_FILE = ROOT / "config" / "cairo_pinned_commit.txt"
CORELIB_INVENTORY_PATH = ROOT / "roadmap" / "inventory" / "corelib-src-inventory.md"
SIERRA_COVERAGE_MATRIX_PATH = ROOT / "roadmap" / "inventory" / "sierra-coverage-matrix.json"
DEFAULT_OUT_JSON = ROOT / "roadmap" / "inventory" / "corelib-parity-report.json"
DEFAULT_OUT_MD = ROOT / "roadmap" / "inventory" / "corelib-parity-report.md"

SUPPORTED = "supported"
PARTIAL = "partial"
EXCLUDED = "excluded"
ALLOWED_STATUSES = {SUPPORTED, PARTIAL, EXCLUDED}

EXCLUDED_PREFIXES: tuple[str, ...] = (
    "corelib/src/starknet/",
    "corelib/src/test/",
    "corelib/src/prelude/",
)

# Narrow deterministic mapping from corelib entry points to Sierra extension modules.
CORELIB_TO_SIERRA_MODULE: dict[str, str] = {
    "corelib/src/felt_252.cairo": "felt252",
    "corelib/src/integer.cairo": "int/mod",
    "corelib/src/boolean.cairo": "boolean",
    "corelib/src/array.cairo": "array",
    "corelib/src/nullable.cairo": "nullable",
    "corelib/src/dict.cairo": "felt252_dict",
    "corelib/src/box.cairo": "boxing",
    "corelib/src/bytes_31.cairo": "bytes31",
    "corelib/src/qm31.cairo": "qm31",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-json", default=str(DEFAULT_OUT_JSON), help="Output JSON report path.")
    parser.add_argument("--out-md", default=str(DEFAULT_OUT_MD), help="Output markdown report path.")
    return parser.parse_args()


def load_pinned_commit() -> str:
    value = PINNED_COMMIT_FILE.read_text(encoding="utf-8").strip()
    if not value:
        raise ValueError(f"pinned commit file is empty: {PINNED_COMMIT_FILE}")
    return value


def parse_corelib_files(inventory_path: Path) -> list[str]:
    corelib_files: list[str] = []
    for raw_line in inventory_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line.startswith("- `") or not line.endswith("`"):
            continue
        value = line[3:-1]
        if value.startswith("corelib/src/") and value.endswith(".cairo"):
            corelib_files.append(value)
    return sorted(set(corelib_files))


def load_module_statuses(matrix_path: Path) -> dict[str, str]:
    payload = json.loads(matrix_path.read_text(encoding="utf-8"))
    module_statuses: dict[str, str] = {}
    for entry in payload.get("extension_modules", []):
        if not isinstance(entry, dict):
            continue
        module_id = entry.get("module_id")
        status = entry.get("status")
        if isinstance(module_id, str) and isinstance(status, str):
            module_statuses[module_id] = status
    return module_statuses


def classify_corelib_file(path: str, module_statuses: dict[str, str]) -> dict[str, str]:
    for prefix in EXCLUDED_PREFIXES:
        if path.startswith(prefix):
            return {
                "path": path,
                "status": EXCLUDED,
                "module_id": "",
                "reason": f"excluded by scope prefix '{prefix}'",
            }

    module_id = CORELIB_TO_SIERRA_MODULE.get(path)
    if module_id is None:
        return {
            "path": path,
            "status": EXCLUDED,
            "module_id": "",
            "reason": "no direct Sierra module mapping in current parity rules",
        }

    module_status = module_statuses.get(module_id, "unresolved")
    if module_status == "implemented":
        status = SUPPORTED
        reason = "mapped Sierra module is implemented in current direct backend lane"
    elif module_status == "fail_fast":
        status = PARTIAL
        reason = "mapped Sierra module is fail-fast bounded in current direct backend lane"
    else:
        status = EXCLUDED
        reason = f"mapped Sierra module status is '{module_status}' (not yet in supported/partial lane)"

    return {"path": path, "status": status, "module_id": module_id, "reason": reason}


def render_markdown(
    pinned_commit: str, inventory_path: Path, matrix_path: Path, entries: list[dict[str, str]]
) -> str:
    counts = Counter(entry["status"] for entry in entries)
    lines = [
        "# Corelib Parity Report (Pinned)",
        "",
        f"- Commit: `{pinned_commit}`",
        f"- Source inventory: `{inventory_path.relative_to(ROOT)}`",
        f"- Coverage matrix input: `{matrix_path.relative_to(ROOT)}`",
        f"- Total corelib files classified: `{len(entries)}`",
        f"- `{SUPPORTED}`: `{counts.get(SUPPORTED, 0)}`",
        f"- `{PARTIAL}`: `{counts.get(PARTIAL, 0)}`",
        f"- `{EXCLUDED}`: `{counts.get(EXCLUDED, 0)}`",
        "",
        "## Classification Rules",
        "",
        "1. Files under Starknet/test/prelude prefixes are classified as `excluded` for current function-first scope.",
        "2. Mapped files are classified from Sierra extension module status:",
        "   - `implemented` -> `supported`",
        "   - `fail_fast` -> `partial`",
        "   - any other status -> `excluded`",
        "3. Files without a direct mapping rule are `excluded` until explicit mapping is added.",
        "",
        "## File Classification",
        "",
        "| Corelib file | Status | Sierra module | Reason |",
        "| --- | --- | --- | --- |",
    ]
    for entry in entries:
        module = f"`{entry['module_id']}`" if entry["module_id"] else "`-`"
        lines.append(
            f"| `{entry['path']}` | `{entry['status']}` | {module} | {entry['reason']} |"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    out_json = Path(args.out_json).resolve()
    out_md = Path(args.out_md).resolve()
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_md.parent.mkdir(parents=True, exist_ok=True)

    pinned_commit = load_pinned_commit()
    corelib_files = parse_corelib_files(CORELIB_INVENTORY_PATH)
    module_statuses = load_module_statuses(SIERRA_COVERAGE_MATRIX_PATH)

    entries = [classify_corelib_file(path, module_statuses) for path in corelib_files]
    for entry in entries:
        status = entry["status"]
        if status not in ALLOWED_STATUSES:
            raise ValueError(f"invalid parity status '{status}' for {entry['path']}")

    report_json = {
        "pinned_commit": pinned_commit,
        "inputs": {
            "corelib_inventory": str(CORELIB_INVENTORY_PATH.relative_to(ROOT)),
            "sierra_coverage_matrix": str(SIERRA_COVERAGE_MATRIX_PATH.relative_to(ROOT)),
        },
        "counts": Counter(entry["status"] for entry in entries),
        "entries": entries,
    }
    out_json.write_text(json.dumps(report_json, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(
        render_markdown(pinned_commit, CORELIB_INVENTORY_PATH, SIERRA_COVERAGE_MATRIX_PATH, entries),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
