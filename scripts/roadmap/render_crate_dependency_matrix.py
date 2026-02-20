#!/usr/bin/env python3
"""Render dependency classification for focused Cairo crates."""

from __future__ import annotations

import argparse
import re
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PINNED_COMMIT_FILE = ROOT / "config" / "cairo_pinned_commit.txt"
CRATE_INVENTORY_PATH = ROOT / "roadmap" / "inventory" / "compiler-crates-inventory.md"
TOOLCHAIN_CARGO_PATH = ROOT / "tools" / "sierra_toolchain" / "Cargo.toml"
DEFAULT_OUT_PATH = ROOT / "roadmap" / "inventory" / "compiler-crates-dependency-matrix.md"

FOCUS_CRATES: list[str] = [
    "cairo-lang-compiler",
    "cairo-lang-parser",
    "cairo-lang-syntax",
    "cairo-lang-defs",
    "cairo-lang-semantic",
    "cairo-lang-lowering",
    "cairo-lang-sierra-generator",
    "cairo-lang-sierra",
    "cairo-lang-sierra-gas",
    "cairo-lang-sierra-ap-change",
    "cairo-lang-sierra-type-size",
    "cairo-lang-sierra-to-casm",
    "cairo-lang-casm",
    "cairo-lang-runner",
    "cairo-lang-starknet",
    "cairo-lang-test-plugin",
    "cairo-lang-utils",
    "cairo-lang-filesystem",
    "cairo-lang-diagnostics",
]

ROLE_BY_CRATE: dict[str, str] = {
    "cairo-lang-sierra": "authoritative semantic reference",
    "cairo-lang-sierra-type-size": "implementation reference",
    "cairo-lang-sierra-to-casm": "implementation reference",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out",
        default=str(DEFAULT_OUT_PATH),
        help="Output markdown path for dependency matrix.",
    )
    return parser.parse_args()


def load_pinned_commit() -> str:
    value = PINNED_COMMIT_FILE.read_text(encoding="utf-8").strip()
    if not value:
        raise ValueError(f"pinned commit file is empty: {PINNED_COMMIT_FILE}")
    return value


def parse_file_counts(inventory_path: Path) -> dict[str, int]:
    counts: dict[str, int] = {}
    pattern = re.compile(r"^- `([^`]+)`: `([0-9]+)` files$")
    for raw_line in inventory_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        match = pattern.match(line)
        if match is None:
            continue
        counts[match.group(1)] = int(match.group(2))
    return counts


def parse_required_crates(cargo_path: Path) -> set[str]:
    payload = tomllib.loads(cargo_path.read_text(encoding="utf-8"))
    dependencies = payload.get("dependencies", {})
    if not isinstance(dependencies, dict):
        raise ValueError(f"expected [dependencies] table in {cargo_path}")

    required: set[str] = set()
    for dep_name, dep_spec in dependencies.items():
        crate_name = dep_name
        if isinstance(dep_spec, dict):
            package_name = dep_spec.get("package")
            if isinstance(package_name, str) and package_name:
                crate_name = package_name
        if crate_name.startswith("cairo-lang-"):
            required.add(crate_name)
    return required


def render_matrix(
    pinned_commit: str,
    file_counts: dict[str, int],
    required_crates: set[str],
) -> str:
    missing = [name for name in FOCUS_CRATES if name not in file_counts]
    if missing:
        raise ValueError(
            "compiler crates inventory is missing focused crate counts: "
            + ", ".join(missing)
        )

    rows: list[str] = []
    for crate in FOCUS_CRATES:
        requirement = "required" if crate in required_crates else "optional"
        role = ROLE_BY_CRATE.get(crate, "optional context")
        rows.append(
            f"| `{crate}` | `{file_counts[crate]}` | `{requirement}` | {role} |"
        )

    required_count = sum(1 for crate in FOCUS_CRATES if crate in required_crates)
    optional_count = len(FOCUS_CRATES) - required_count

    lines = [
        "# Compiler Crate Dependency Matrix (Pinned)",
        "",
        f"- Commit: `{pinned_commit}`",
        f"- Source inventory: `{CRATE_INVENTORY_PATH.relative_to(ROOT)}`",
        f"- Tooling manifest: `{TOOLCHAIN_CARGO_PATH.relative_to(ROOT)}`",
        f"- Required focused crates: `{required_count}`",
        f"- Optional focused crates: `{optional_count}`",
        "",
        "## Classification Rules",
        "",
        "1. A focused crate is `required` iff it is a direct `cairo-lang-*` dependency in `tools/sierra_toolchain/Cargo.toml`.",
        "2. All other focused crates are `optional` context references for roadmap alignment.",
        "",
        "## Matrix",
        "",
        "| Crate | File count | Requirement | Role |",
        "| --- | ---: | --- | --- |",
        *rows,
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    out_path = Path(args.out).resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)

    pinned_commit = load_pinned_commit()
    file_counts = parse_file_counts(CRATE_INVENTORY_PATH)
    required_crates = parse_required_crates(TOOLCHAIN_CARGO_PATH)
    markdown = render_matrix(pinned_commit, file_counts, required_crates)
    out_path.write_text(markdown, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
