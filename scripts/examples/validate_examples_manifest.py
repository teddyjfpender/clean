#!/usr/bin/env python3
"""Validate examples manifest schema and emit deterministic rows."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List, Tuple


REQUIRED_MIRROR_KEYS = (
    "lean_dir",
    "sierra_dir",
    "cairo_dir",
    "baseline_dir",
    "benchmark_dir",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate examples manifest")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--emit-tsv", action="store_true")
    return parser.parse_args()


def normalize_rel_path(value: str, ctx: str) -> str:
    path = Path(value)
    if path.is_absolute():
        raise ValueError(f"{ctx}: path must be relative, got absolute '{value}'")
    parts = list(path.parts)
    if any(part == ".." for part in parts):
        raise ValueError(f"{ctx}: path must not contain '..': '{value}'")
    normalized = str(path).strip()
    if not normalized:
        raise ValueError(f"{ctx}: path must be non-empty")
    return normalized


def normalize_optional_rel_path(value: object, ctx: str) -> str:
    if value is None:
        return ""
    if not isinstance(value, str):
        raise ValueError(f"{ctx}: expected string or null")
    stripped = value.strip()
    if not stripped:
        raise ValueError(f"{ctx}: empty string is not allowed; use null for no mirror")
    return normalize_rel_path(stripped, ctx)


def validate_manifest(manifest_path: Path) -> List[Tuple[str, str, str, str, str, str, str, List[str]]]:
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{manifest_path}: top-level must be object")

    version = payload.get("version")
    if version != 2:
        raise ValueError(f"{manifest_path}: version must be 2")

    examples = payload.get("examples")
    if not isinstance(examples, list) or not examples:
        raise ValueError(f"{manifest_path}: examples must be a non-empty list")

    rows: List[Tuple[str, str, str, str, str, str, str, List[str]]] = []
    seen_ids = set()
    mirror_paths_seen = set()

    for idx, entry in enumerate(examples):
        ctx = f"{manifest_path}: examples[{idx}]"
        if not isinstance(entry, dict):
            raise ValueError(f"{ctx}: expected object")

        for key in ("id", "module", "lean_sources", "mirrors"):
            if key not in entry:
                raise ValueError(f"{ctx}: missing key '{key}'")

        example_id = str(entry["id"]).strip()
        module_name = str(entry["module"]).strip()
        if not example_id:
            raise ValueError(f"{ctx}: id must be non-empty")
        if not module_name:
            raise ValueError(f"{ctx}: module must be non-empty")
        if example_id in seen_ids:
            raise ValueError(f"{ctx}: duplicate id '{example_id}'")
        seen_ids.add(example_id)

        lean_sources_raw = entry["lean_sources"]
        if not isinstance(lean_sources_raw, list) or not lean_sources_raw:
            raise ValueError(f"{ctx}: lean_sources must be a non-empty list")
        lean_sources: List[str] = []
        for source_idx, source in enumerate(lean_sources_raw):
            if not isinstance(source, str) or not source.strip():
                raise ValueError(f"{ctx}: lean_sources[{source_idx}] must be non-empty string")
            lean_sources.append(normalize_rel_path(source.strip(), f"{ctx}.lean_sources[{source_idx}]"))
        if len(set(lean_sources)) != len(lean_sources):
            raise ValueError(f"{ctx}: lean_sources must be unique")

        mirrors = entry["mirrors"]
        if not isinstance(mirrors, dict):
            raise ValueError(f"{ctx}.mirrors: expected object")
        for key in REQUIRED_MIRROR_KEYS:
            if key not in mirrors:
                raise ValueError(f"{ctx}.mirrors: missing key '{key}'")

        lean_dir = normalize_rel_path(str(mirrors["lean_dir"]).strip(), f"{ctx}.mirrors.lean_dir")
        sierra_dir = normalize_rel_path(str(mirrors["sierra_dir"]).strip(), f"{ctx}.mirrors.sierra_dir")
        cairo_dir = normalize_rel_path(str(mirrors["cairo_dir"]).strip(), f"{ctx}.mirrors.cairo_dir")
        baseline_dir = normalize_optional_rel_path(mirrors["baseline_dir"], f"{ctx}.mirrors.baseline_dir")
        benchmark_dir = normalize_optional_rel_path(mirrors["benchmark_dir"], f"{ctx}.mirrors.benchmark_dir")

        if not lean_dir.startswith("examples/Lean/"):
            raise ValueError(f"{ctx}.mirrors.lean_dir must be under examples/Lean/: {lean_dir}")
        if not sierra_dir.startswith("examples/Sierra/"):
            raise ValueError(f"{ctx}.mirrors.sierra_dir must be under examples/Sierra/: {sierra_dir}")
        if not cairo_dir.startswith("examples/Cairo/"):
            raise ValueError(f"{ctx}.mirrors.cairo_dir must be under examples/Cairo/: {cairo_dir}")
        if baseline_dir and not baseline_dir.startswith("examples/Cairo-Baseline/"):
            raise ValueError(
                f"{ctx}.mirrors.baseline_dir must be under examples/Cairo-Baseline/: {baseline_dir}"
            )
        if benchmark_dir and not benchmark_dir.startswith("examples/Benchmark/"):
            raise ValueError(
                f"{ctx}.mirrors.benchmark_dir must be under examples/Benchmark/: {benchmark_dir}"
            )

        for source in lean_sources:
            if not source.startswith(f"{lean_dir}/"):
                raise ValueError(
                    f"{ctx}: lean source '{source}' must live under declared lean_dir '{lean_dir}'"
                )

        for lane_name, lane_path in (
            ("lean_dir", lean_dir),
            ("sierra_dir", sierra_dir),
            ("cairo_dir", cairo_dir),
            ("baseline_dir", baseline_dir),
            ("benchmark_dir", benchmark_dir),
        ):
            if not lane_path:
                continue
            key = (lane_name, lane_path)
            if key in mirror_paths_seen:
                raise ValueError(f"{ctx}: duplicate mirror path '{lane_path}' for lane '{lane_name}'")
            mirror_paths_seen.add(key)

        rows.append(
            (
                example_id,
                module_name,
                lean_dir,
                sierra_dir,
                cairo_dir,
                baseline_dir,
                benchmark_dir,
                lean_sources,
            )
        )

    if [row[0] for row in rows] != sorted(row[0] for row in rows):
        raise ValueError(f"{manifest_path}: examples must be sorted by id for deterministic generation")

    return rows


def main() -> int:
    args = parse_args()
    manifest_path = Path(args.manifest)
    if not manifest_path.is_file():
        raise SystemExit(f"missing examples manifest: {manifest_path}")

    rows = validate_manifest(manifest_path)
    if args.emit_tsv:
        for row in rows:
            baseline_out = row[5] if row[5] else "-"
            benchmark_out = row[6] if row[6] else "-"
            print(
                "\t".join(
                    [
                        row[0],
                        row[1],
                        row[2],
                        row[3],
                        row[4],
                        baseline_out,
                        benchmark_out,
                        ",".join(row[7]),
                    ]
                )
            )
    else:
        print(f"examples manifest validation passed ({len(rows)} entries)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
