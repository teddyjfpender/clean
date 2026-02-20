#!/usr/bin/env python3
"""Generate pinned Cairo upstream inventory markdown docs under roadmap/inventory."""

from __future__ import annotations

import argparse
import json
import urllib.request
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INVENTORY_DIR = ROOT / "roadmap" / "inventory"
PINNED_SURFACE = ROOT / "generated" / "sierra" / "surface" / "pinned_surface.json"
PINNED_COMMIT_FILE = ROOT / "config" / "cairo_pinned_commit.txt"


def load_pinned_commit() -> str:
    value = PINNED_COMMIT_FILE.read_text(encoding="utf-8").strip()
    if not value:
        raise ValueError(f"pinned commit file is empty: {PINNED_COMMIT_FILE}")
    return value


PINNED_COMMIT = load_pinned_commit()
TREE_URL = (
    "https://api.github.com/repos/starkware-libs/cairo/git/trees/"
    f"{PINNED_COMMIT}?recursive=1"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out-dir",
        default=str(INVENTORY_DIR),
        help="Output directory for generated inventory markdown files.",
    )
    return parser.parse_args()


def fetch_tree_paths() -> list[str]:
    request = urllib.request.Request(
        TREE_URL,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "leancairo-roadmap-inventory-generator",
        },
    )
    with urllib.request.urlopen(request) as response:  # noqa: S310
        payload = json.load(response)
    return sorted(
        entry["path"]
        for entry in payload.get("tree", [])
        if entry.get("type") == "blob" and isinstance(entry.get("path"), str)
    )


def write_corelib_inventory(paths: list[str], out_dir: Path) -> None:
    core_files = [p for p in paths if p.startswith("corelib/src/") and p.endswith(".cairo")]
    by_dir = Counter("/".join(p.split("/")[:3]) for p in core_files)

    lines: list[str] = [
        "# Corelib Src Inventory (Pinned)",
        "",
        f"- Commit: `{PINNED_COMMIT}`",
        "- Source: `corelib/src`",
        f"- Cairo files: `{len(core_files)}`",
        "",
        "## Directory Summary",
        "",
    ]
    for key, value in sorted(by_dir.items()):
        lines.append(f"- `{key}`: `{value}`")

    lines.extend(["", "## Full File List", ""])
    lines.extend(f"- `{path}`" for path in core_files)
    lines.append("")

    (out_dir / "corelib-src-inventory.md").write_text("\n".join(lines), encoding="utf-8")


def write_sierra_inventory(paths: list[str], out_dir: Path) -> None:
    sierra_rs = [p for p in paths if p.startswith("crates/cairo-lang-sierra/src/") and p.endswith(".rs")]
    extension_modules = [
        p for p in sierra_rs if p.startswith("crates/cairo-lang-sierra/src/extensions/modules/")
    ]

    if not PINNED_SURFACE.exists():
        raise FileNotFoundError(
            f"missing pinned surface file: {PINNED_SURFACE} (run Sierra surface generator first)"
        )
    surface = json.loads(PINNED_SURFACE.read_text(encoding="utf-8"))

    core_files = [
        "crates/cairo-lang-sierra/src/program.rs",
        "crates/cairo-lang-sierra/src/program_registry.rs",
        "crates/cairo-lang-sierra/src/extensions/core.rs",
        "crates/cairo-lang-sierra/src/extensions/lib_func.rs",
        "crates/cairo-lang-sierra/src/extensions/types.rs",
        "crates/cairo-lang-sierra/src/ids.rs",
    ]

    lines: list[str] = [
        "# Sierra Extensions Inventory (Pinned)",
        "",
        f"- Commit: `{PINNED_COMMIT}`",
        "- Source: `crates/cairo-lang-sierra/src`",
        f"- Rust source files under `src`: `{len(sierra_rs)}`",
        f"- Extension module files: `{len(extension_modules)}`",
        f"- Extracted generic type IDs: `{len(surface['generic_type_ids'])}`",
        f"- Extracted generic libfunc IDs: `{len(surface['generic_libfunc_ids'])}`",
        "",
        "## Core Surface Files",
        "",
    ]
    lines.extend(f"- `{path}`" for path in core_files)
    lines.extend(["", "## Extension Module Files", ""])
    lines.extend(f"- `{path}`" for path in extension_modules)
    lines.append("")

    (out_dir / "sierra-extensions-inventory.md").write_text("\n".join(lines), encoding="utf-8")


def write_crates_inventory(paths: list[str], out_dir: Path) -> None:
    crate_paths = [p for p in paths if p.startswith("crates/")]
    crate_counts = Counter(p.split("/")[1] for p in crate_paths)

    focus_crates = [
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

    lines: list[str] = [
        "# Compiler Crates Focus Inventory (Pinned)",
        "",
        f"- Commit: `{PINNED_COMMIT}`",
        "- Source: `crates/`",
        f"- Total tracked crates in tree: `{len({p.split('/')[1] for p in crate_paths})}`",
        "",
        "## Focus Crate File Counts",
        "",
    ]
    for name in focus_crates:
        lines.append(f"- `{name}`: `{crate_counts.get(name, 0)}` files")
    lines.append("")

    (out_dir / "compiler-crates-inventory.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = fetch_tree_paths()
    write_corelib_inventory(paths, out_dir)
    write_sierra_inventory(paths, out_dir)
    write_crates_inventory(paths, out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
