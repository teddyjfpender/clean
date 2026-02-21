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

REQUIRED_DIFFERENTIAL_KEYS = (
    "kind",
    "vector_profiles",
    "replay_command",
    "lean_test_file",
    "backend_module",
    "backend_contract",
)

ALLOWED_DIFFERENTIAL_KINDS = {"none", "composite"}
ALLOWED_VECTOR_PROFILES = {"normal", "boundary", "failure"}

REQUIRED_BENCHMARK_KEYS = (
    "kind",
    "family",
    "runner_script",
    "min_sierra_improvement_pct",
    "min_l2_improvement_pct",
)
ALLOWED_BENCHMARK_KINDS = {"none", "gas_script"}

REQUIRED_COVERAGE_KEYS = (
    "complexity_tier",
    "family_tags",
    "capability_ids",
)
ALLOWED_COMPLEXITY_TIERS = {"medium", "high"}
ALLOWED_COVERAGE_FAMILIES = {
    "integer",
    "fixed_point",
    "control_flow",
    "aggregate",
    "crypto",
    "circuit",
    "scalar",
}


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


def normalize_optional_string(value: object, ctx: str) -> str:
    if value is None:
        return ""
    if not isinstance(value, str):
        raise ValueError(f"{ctx}: expected string or null")
    stripped = value.strip()
    if not stripped:
        raise ValueError(f"{ctx}: empty string is not allowed; use null instead")
    return stripped


def normalize_optional_float(value: object, ctx: str) -> float | None:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    raise ValueError(f"{ctx}: expected number or null")


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

        for key in ("id", "module", "lean_sources", "mirrors", "differential", "benchmark", "coverage"):
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

        differential = entry["differential"]
        if not isinstance(differential, dict):
            raise ValueError(f"{ctx}.differential: expected object")
        for key in REQUIRED_DIFFERENTIAL_KEYS:
            if key not in differential:
                raise ValueError(f"{ctx}.differential: missing key '{key}'")

        differential_kind = str(differential["kind"]).strip()
        if differential_kind not in ALLOWED_DIFFERENTIAL_KINDS:
            raise ValueError(
                f"{ctx}.differential.kind: invalid value '{differential_kind}', expected one of {sorted(ALLOWED_DIFFERENTIAL_KINDS)}"
            )

        vector_profiles_raw = differential["vector_profiles"]
        if not isinstance(vector_profiles_raw, list):
            raise ValueError(f"{ctx}.differential.vector_profiles: expected list")
        vector_profiles = []
        for profile_idx, profile in enumerate(vector_profiles_raw):
            if not isinstance(profile, str) or not profile.strip():
                raise ValueError(
                    f"{ctx}.differential.vector_profiles[{profile_idx}]: expected non-empty string"
                )
            profile_norm = profile.strip()
            if profile_norm not in ALLOWED_VECTOR_PROFILES:
                raise ValueError(
                    f"{ctx}.differential.vector_profiles[{profile_idx}]: invalid value '{profile_norm}'"
                )
            vector_profiles.append(profile_norm)
        if len(vector_profiles) != len(set(vector_profiles)):
            raise ValueError(f"{ctx}.differential.vector_profiles: entries must be unique")

        replay_command = normalize_optional_string(
            differential["replay_command"], f"{ctx}.differential.replay_command"
        )
        lean_test_file = normalize_optional_rel_path(
            differential["lean_test_file"], f"{ctx}.differential.lean_test_file"
        )
        backend_module = normalize_optional_string(
            differential["backend_module"], f"{ctx}.differential.backend_module"
        )
        backend_contract = normalize_optional_string(
            differential["backend_contract"], f"{ctx}.differential.backend_contract"
        )

        if differential_kind == "none":
            if vector_profiles:
                raise ValueError(
                    f"{ctx}.differential: kind 'none' requires empty vector_profiles"
                )
            if replay_command or lean_test_file or backend_module or backend_contract:
                raise ValueError(
                    f"{ctx}.differential: kind 'none' requires replay/lean/backend fields to be null"
                )
        elif differential_kind == "composite":
            required_profiles = {"normal", "boundary", "failure"}
            if not required_profiles.issubset(set(vector_profiles)):
                raise ValueError(
                    f"{ctx}.differential: kind 'composite' requires vector_profiles to include normal,boundary,failure"
                )
            if not replay_command:
                raise ValueError(
                    f"{ctx}.differential: kind 'composite' requires replay_command"
                )
            if not lean_test_file:
                raise ValueError(
                    f"{ctx}.differential: kind 'composite' requires lean_test_file"
                )
            if not lean_test_file.startswith("tests/lean/"):
                raise ValueError(
                    f"{ctx}.differential.lean_test_file must be under tests/lean/: {lean_test_file}"
                )
            if not backend_module:
                raise ValueError(
                    f"{ctx}.differential: kind 'composite' requires backend_module"
                )
            if not backend_contract:
                raise ValueError(
                    f"{ctx}.differential: kind 'composite' requires backend_contract"
                )

        benchmark = entry["benchmark"]
        if not isinstance(benchmark, dict):
            raise ValueError(f"{ctx}.benchmark: expected object")
        for key in REQUIRED_BENCHMARK_KEYS:
            if key not in benchmark:
                raise ValueError(f"{ctx}.benchmark: missing key '{key}'")

        benchmark_kind = str(benchmark["kind"]).strip()
        if benchmark_kind not in ALLOWED_BENCHMARK_KINDS:
            raise ValueError(
                f"{ctx}.benchmark.kind: invalid value '{benchmark_kind}', expected one of {sorted(ALLOWED_BENCHMARK_KINDS)}"
            )

        benchmark_family = normalize_optional_string(benchmark["family"], f"{ctx}.benchmark.family")
        benchmark_runner = normalize_optional_rel_path(
            benchmark["runner_script"], f"{ctx}.benchmark.runner_script"
        )
        min_sierra_improvement = normalize_optional_float(
            benchmark["min_sierra_improvement_pct"],
            f"{ctx}.benchmark.min_sierra_improvement_pct",
        )
        min_l2_improvement = normalize_optional_float(
            benchmark["min_l2_improvement_pct"],
            f"{ctx}.benchmark.min_l2_improvement_pct",
        )

        if benchmark_kind == "none":
            if benchmark_family or benchmark_runner or min_sierra_improvement is not None or min_l2_improvement is not None:
                raise ValueError(
                    f"{ctx}.benchmark: kind 'none' requires family/runner/threshold fields to be null"
                )
        elif benchmark_kind == "gas_script":
            if not benchmark_family:
                raise ValueError(f"{ctx}.benchmark: kind 'gas_script' requires family")
            if not benchmark_runner:
                raise ValueError(f"{ctx}.benchmark: kind 'gas_script' requires runner_script")
            if not benchmark_runner.startswith("examples/Benchmark/"):
                raise ValueError(
                    f"{ctx}.benchmark.runner_script must be under examples/Benchmark/: {benchmark_runner}"
                )
            if min_sierra_improvement is None or min_l2_improvement is None:
                raise ValueError(
                    f"{ctx}.benchmark: kind 'gas_script' requires min_sierra_improvement_pct and min_l2_improvement_pct"
                )

        coverage = entry["coverage"]
        if not isinstance(coverage, dict):
            raise ValueError(f"{ctx}.coverage: expected object")
        for key in REQUIRED_COVERAGE_KEYS:
            if key not in coverage:
                raise ValueError(f"{ctx}.coverage: missing key '{key}'")

        complexity_tier = str(coverage["complexity_tier"]).strip()
        if complexity_tier not in ALLOWED_COMPLEXITY_TIERS:
            raise ValueError(
                f"{ctx}.coverage.complexity_tier: invalid value '{complexity_tier}', expected one of {sorted(ALLOWED_COMPLEXITY_TIERS)}"
            )

        family_tags = coverage["family_tags"]
        if not isinstance(family_tags, list) or not family_tags:
            raise ValueError(f"{ctx}.coverage.family_tags: expected non-empty list")
        normalized_tags = []
        for family_idx, family in enumerate(family_tags):
            if not isinstance(family, str) or not family.strip():
                raise ValueError(f"{ctx}.coverage.family_tags[{family_idx}]: expected non-empty string")
            normalized = family.strip()
            if normalized not in ALLOWED_COVERAGE_FAMILIES:
                raise ValueError(
                    f"{ctx}.coverage.family_tags[{family_idx}]: invalid family '{normalized}'"
                )
            normalized_tags.append(normalized)
        if len(normalized_tags) != len(set(normalized_tags)):
            raise ValueError(f"{ctx}.coverage.family_tags: entries must be unique")

        capability_ids = coverage["capability_ids"]
        if not isinstance(capability_ids, list) or not capability_ids:
            raise ValueError(f"{ctx}.coverage.capability_ids: expected non-empty list")
        normalized_cap_ids = []
        for cap_idx, cap_id in enumerate(capability_ids):
            if not isinstance(cap_id, str) or not cap_id.strip():
                raise ValueError(f"{ctx}.coverage.capability_ids[{cap_idx}]: expected non-empty string")
            normalized_cap = cap_id.strip()
            if not normalized_cap.startswith("cap."):
                raise ValueError(
                    f"{ctx}.coverage.capability_ids[{cap_idx}]: capability id must start with 'cap.' ({normalized_cap})"
                )
            normalized_cap_ids.append(normalized_cap)
        if len(normalized_cap_ids) != len(set(normalized_cap_ids)):
            raise ValueError(f"{ctx}.coverage.capability_ids: entries must be unique")

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
