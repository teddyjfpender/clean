#!/usr/bin/env python3
"""Generate Lean/JSON Sierra surface bindings from pinned cairo-lang-sierra sources.

This script is intentionally deterministic:
- fixed upstream commit pin,
- sorted input file order,
- sorted output IDs,
- stable JSON encoding.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import urllib.request
from dataclasses import dataclass
from pathlib import Path


PINNED_COMMIT = "e56055c87a9db4e3dbb91c82ccb2ea751a8dc617"
GITHUB_API_TREE_URL = (
    "https://api.github.com/repos/starkware-libs/cairo/git/trees/"
    f"{PINNED_COMMIT}?recursive=1"
)
RAW_BASE_URL = (
    "https://raw.githubusercontent.com/starkware-libs/cairo/"
    f"{PINNED_COMMIT}"
)
MODULES_PREFIX = "crates/cairo-lang-sierra/src/extensions/modules/"

EXTRA_SOURCE_PATHS = [
    "crates/cairo-lang-sierra/src/extensions/core.rs",
    "crates/cairo-lang-sierra/src/extensions/lib_func.rs",
    "crates/cairo-lang-sierra/src/extensions/types.rs",
    "crates/cairo-lang-sierra/src/ids.rs",
]

TYPE_ID_PATTERN = re.compile(
    r'const\s+(?:ID|[A-Z0-9_]+):\s+GenericTypeId\s*=\s*GenericTypeId::new_inline\("([^"]+)"\);'
)
LIBFUNC_ID_PATTERN = re.compile(
    r'const\s+(?:STR_ID|[A-Z0-9_]+):\s*&\'static str\s*=\s*"([^"]+)";'
)


@dataclass(frozen=True)
class SourceFile:
    path: str
    contents: str

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.contents.encode("utf-8")).hexdigest()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-json", required=True, help="Path for generated JSON metadata.")
    parser.add_argument("--out-lean", required=True, help="Path for generated Lean bindings.")
    return parser.parse_args()


def fetch_text(url: str) -> str:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "leancairo-sierra-surface-generator",
        },
    )
    with urllib.request.urlopen(request) as response:  # noqa: S310
        return response.read().decode("utf-8")


def fetch_tree_paths() -> list[str]:
    payload = json.loads(fetch_text(GITHUB_API_TREE_URL))
    paths: list[str] = []
    for entry in payload.get("tree", []):
        path = entry.get("path")
        kind = entry.get("type")
        if not isinstance(path, str) or kind != "blob":
            continue
        if path.startswith(MODULES_PREFIX) and path.endswith(".rs"):
            paths.append(path)
    return sorted(paths)


def load_source_files() -> list[SourceFile]:
    module_paths = fetch_tree_paths()
    all_paths = sorted(set(module_paths + EXTRA_SOURCE_PATHS))
    result: list[SourceFile] = []
    for path in all_paths:
        contents = fetch_text(f"{RAW_BASE_URL}/{path}")
        result.append(SourceFile(path=path, contents=contents))
    return result


def extract_ids(source_files: list[SourceFile]) -> tuple[list[str], list[str]]:
    type_ids: set[str] = set()
    libfunc_ids: set[str] = set()
    for source in source_files:
        type_ids.update(TYPE_ID_PATTERN.findall(source.contents))
        libfunc_ids.update(LIBFUNC_ID_PATTERN.findall(source.contents))
    return sorted(type_ids), sorted(libfunc_ids)


def ensure_parent_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def write_json(path: Path, source_files: list[SourceFile], type_ids: list[str], libfunc_ids: list[str]) -> None:
    payload = {
        "pinned_commit": PINNED_COMMIT,
        "sources": [
            {"path": source.path, "sha256": source.sha256}
            for source in source_files
        ],
        "generic_type_ids": type_ids,
        "generic_libfunc_ids": libfunc_ids,
    }
    encoded = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    ensure_parent_dir(path)
    path.write_text(encoded, encoding="utf-8")


def escape_lean_string(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )


def render_lean_list(values: list[str]) -> str:
    if not values:
        return "[]"
    lines = ["["]
    for value in values:
        lines.append(f'  "{escape_lean_string(value)}",')
    lines.append("]")
    return "\n".join(lines)


def write_lean(path: Path, source_files: list[SourceFile], type_ids: list[str], libfunc_ids: list[str]) -> None:
    source_paths = [source.path for source in source_files]
    content = "\n".join(
        [
            "namespace LeanCairo.Backend.Sierra.Generated",
            "",
            f'def pinnedCommit : String := "{PINNED_COMMIT}"',
            "",
            "def sourcePaths : List String :=",
            render_lean_list(source_paths),
            "",
            "def genericTypeIds : List String :=",
            render_lean_list(type_ids),
            "",
            "def genericLibfuncIds : List String :=",
            render_lean_list(libfunc_ids),
            "",
            "end LeanCairo.Backend.Sierra.Generated",
            "",
        ]
    )
    ensure_parent_dir(path)
    path.write_text(content, encoding="utf-8")


def main() -> int:
    args = parse_args()
    out_json = Path(args.out_json)
    out_lean = Path(args.out_lean)

    source_files = load_source_files()
    type_ids, libfunc_ids = extract_ids(source_files)
    write_json(out_json, source_files, type_ids, libfunc_ids)
    write_lean(out_lean, source_files, type_ids, libfunc_ids)
    print(
        json.dumps(
            {
                "pinned_commit": PINNED_COMMIT,
                "source_files": len(source_files),
                "generic_type_ids": len(type_ids),
                "generic_libfunc_ids": len(libfunc_ids),
                "out_json": str(out_json),
                "out_lean": str(out_lean),
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
