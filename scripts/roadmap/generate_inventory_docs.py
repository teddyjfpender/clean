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
DEFAULT_PINNED_SURFACE = ROOT / "generated" / "sierra" / "surface" / "pinned_surface.json"
DEFAULT_PINNED_COMMIT_FILE = ROOT / "config" / "cairo_pinned_commit.txt"
DEFAULT_TREE_CACHE = ROOT / "roadmap" / "inventory" / "pinned-tree-paths.json"


def load_pinned_commit(commit_file: Path) -> str:
    value = commit_file.read_text(encoding="utf-8").strip()
    if not value:
        raise ValueError(f"pinned commit file is empty: {commit_file}")
    return value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out-dir",
        default=str(INVENTORY_DIR),
        help="Output directory for generated inventory markdown files.",
    )
    parser.add_argument(
        "--pinned-surface",
        default=str(DEFAULT_PINNED_SURFACE),
        help="Path to pinned Sierra surface json.",
    )
    parser.add_argument(
        "--pinned-commit-file",
        default=str(DEFAULT_PINNED_COMMIT_FILE),
        help="Path to pinned Cairo commit file.",
    )
    parser.add_argument(
        "--tree-cache",
        default=str(DEFAULT_TREE_CACHE),
        help="Path to cached pinned Cairo tree paths json.",
    )
    parser.add_argument(
        "--refresh-tree-cache",
        action="store_true",
        help="Fetch tree paths from GitHub API and refresh cache before generation.",
    )
    return parser.parse_args()


def fetch_tree_paths_remote(pinned_commit: str) -> list[str]:
    tree_url = (
        "https://api.github.com/repos/starkware-libs/cairo/git/trees/"
        f"{pinned_commit}?recursive=1"
    )
    request = urllib.request.Request(
        tree_url,
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


def load_tree_paths_from_cache(cache_path: Path, pinned_commit: str) -> list[str]:
    if not cache_path.exists():
        raise FileNotFoundError(
            f"missing tree cache file: {cache_path} (run with --refresh-tree-cache to regenerate)"
        )
    payload = json.loads(cache_path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"invalid tree cache payload: {cache_path}")
    cache_commit = payload.get("pinned_commit")
    if cache_commit != pinned_commit:
        raise ValueError(
            f"tree cache commit mismatch: expected {pinned_commit}, got {cache_commit} in {cache_path}"
        )
    paths = payload.get("paths")
    if not isinstance(paths, list) or not all(isinstance(item, str) for item in paths):
        raise ValueError(f"invalid tree cache path list in {cache_path}")
    return sorted(paths)


def write_tree_cache(cache_path: Path, pinned_commit: str, paths: list[str]) -> None:
    payload = {"pinned_commit": pinned_commit, "paths": sorted(paths)}
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def write_corelib_inventory(paths: list[str], out_dir: Path, pinned_commit: str) -> None:
    core_files = [p for p in paths if p.startswith("corelib/src/") and p.endswith(".cairo")]
    by_dir = Counter("/".join(p.split("/")[:3]) for p in core_files)

    lines: list[str] = [
        "# Corelib Src Inventory (Pinned)",
        "",
        f"- Commit: `{pinned_commit}`",
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


def write_sierra_inventory(
    paths: list[str], out_dir: Path, pinned_commit: str, pinned_surface: Path
) -> None:
    sierra_rs = [p for p in paths if p.startswith("crates/cairo-lang-sierra/src/") and p.endswith(".rs")]
    extension_modules = [
        p for p in sierra_rs if p.startswith("crates/cairo-lang-sierra/src/extensions/modules/")
    ]

    if not pinned_surface.exists():
        raise FileNotFoundError(
            f"missing pinned surface file: {pinned_surface} (run Sierra surface generator first)"
        )
    surface = json.loads(pinned_surface.read_text(encoding="utf-8"))

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
        f"- Commit: `{pinned_commit}`",
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


def write_crates_inventory(paths: list[str], out_dir: Path, pinned_commit: str) -> None:
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
        f"- Commit: `{pinned_commit}`",
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
    pinned_surface = Path(args.pinned_surface).resolve()
    commit_file = Path(args.pinned_commit_file).resolve()
    tree_cache = Path(args.tree_cache).resolve()
    pinned_commit = load_pinned_commit(commit_file)
    out_dir.mkdir(parents=True, exist_ok=True)
    if args.refresh_tree_cache:
        paths = fetch_tree_paths_remote(pinned_commit)
        write_tree_cache(tree_cache, pinned_commit, paths)
    else:
        paths = load_tree_paths_from_cache(tree_cache, pinned_commit)
    write_corelib_inventory(paths, out_dir, pinned_commit)
    write_sierra_inventory(paths, out_dir, pinned_commit, pinned_surface)
    write_crates_inventory(paths, out_dir, pinned_commit)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
