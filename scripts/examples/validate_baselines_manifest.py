#!/usr/bin/env python3
"""Validate pinned baseline provenance manifest."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Set

COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate baselines manifest")
    parser.add_argument("--manifest", required=True)
    parser.add_argument(
        "--examples-manifest",
        default="config/examples-manifest.json",
        help="Examples manifest for baseline mirror cross-check",
    )
    parser.add_argument("--emit-tsv", action="store_true")
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level must be object")
    return payload


def normalize_rel_path(value: object, ctx: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{ctx}: expected non-empty string")
    path = Path(value.strip())
    if path.is_absolute():
        raise ValueError(f"{ctx}: path must be relative")
    if ".." in path.parts:
        raise ValueError(f"{ctx}: path must not contain '..'")
    return str(path)


def load_expected_baselines(examples_manifest_path: Path) -> Dict[str, str]:
    payload = load_json(examples_manifest_path)
    examples = payload.get("examples")
    if not isinstance(examples, list):
        raise ValueError(f"{examples_manifest_path}: examples must be list")

    out: Dict[str, str] = {}
    for idx, entry in enumerate(examples):
        ctx = f"{examples_manifest_path}: examples[{idx}]"
        if not isinstance(entry, dict):
            raise ValueError(f"{ctx}: expected object")
        ex_id = entry.get("id")
        mirrors = entry.get("mirrors")
        if not isinstance(ex_id, str) or not ex_id.strip():
            raise ValueError(f"{ctx}: missing non-empty id")
        if not isinstance(mirrors, dict):
            raise ValueError(f"{ctx}: missing mirrors object")
        baseline_dir = mirrors.get("baseline_dir")
        if baseline_dir is None:
            continue
        baseline_dir = normalize_rel_path(baseline_dir, f"{ctx}.mirrors.baseline_dir")
        out[ex_id.strip()] = baseline_dir
    return out


def validate_manifest(root: Path, manifest_path: Path, expected_baselines: Dict[str, str]) -> List[Dict[str, str]]:
    payload = load_json(manifest_path)
    if payload.get("version") != 1:
        raise ValueError(f"{manifest_path}: version must be 1")
    rows = payload.get("baselines")
    if not isinstance(rows, list) or not rows:
        raise ValueError(f"{manifest_path}: baselines must be a non-empty list")

    seen_ids: Set[str] = set()
    seen_dirs: Set[str] = set()
    out_rows: List[Dict[str, str]] = []

    for idx, row in enumerate(rows):
        ctx = f"{manifest_path}: baselines[{idx}]"
        if not isinstance(row, dict):
            raise ValueError(f"{ctx}: expected object")

        required = {
            "id",
            "baseline_dir",
            "source_repo",
            "source_commit",
            "source_paths",
            "sync_script",
            "patch_script",
            "patch_justification",
            "provenance_doc",
        }
        missing = sorted(required.difference(row.keys()))
        if missing:
            raise ValueError(f"{ctx}: missing keys: {', '.join(missing)}")

        baseline_id = str(row["id"]).strip()
        if not baseline_id:
            raise ValueError(f"{ctx}.id: expected non-empty string")
        if baseline_id in seen_ids:
            raise ValueError(f"{ctx}: duplicate id '{baseline_id}'")
        seen_ids.add(baseline_id)

        baseline_dir = normalize_rel_path(row["baseline_dir"], f"{ctx}.baseline_dir")
        if not baseline_dir.startswith("examples/Cairo-Baseline/"):
            raise ValueError(f"{ctx}.baseline_dir must be under examples/Cairo-Baseline/: {baseline_dir}")
        if baseline_dir in seen_dirs:
            raise ValueError(f"{ctx}: duplicate baseline_dir '{baseline_dir}'")
        seen_dirs.add(baseline_dir)
        if not (root / baseline_dir).is_dir():
            raise ValueError(f"{ctx}.baseline_dir does not exist: {baseline_dir}")

        source_repo = str(row["source_repo"]).strip()
        if not source_repo or "/" not in source_repo:
            raise ValueError(f"{ctx}.source_repo: expected owner/repo")

        source_commit = str(row["source_commit"]).strip()
        if not COMMIT_RE.match(source_commit):
            raise ValueError(f"{ctx}.source_commit: expected 40-char lowercase hex")

        source_paths = row["source_paths"]
        if not isinstance(source_paths, list) or not source_paths:
            raise ValueError(f"{ctx}.source_paths: expected non-empty list")
        normalized_source_paths: List[str] = []
        for path_idx, source_path in enumerate(source_paths):
            rel = normalize_rel_path(source_path, f"{ctx}.source_paths[{path_idx}]")
            normalized_source_paths.append(rel)
        if len(normalized_source_paths) != len(set(normalized_source_paths)):
            raise ValueError(f"{ctx}.source_paths: duplicate entries are not allowed")

        sync_script = normalize_rel_path(row["sync_script"], f"{ctx}.sync_script")
        patch_script = normalize_rel_path(row["patch_script"], f"{ctx}.patch_script")
        provenance_doc = normalize_rel_path(row["provenance_doc"], f"{ctx}.provenance_doc")

        for script_path, key in ((sync_script, "sync_script"), (patch_script, "patch_script")):
            resolved = root / script_path
            if not resolved.is_file():
                raise ValueError(f"{ctx}.{key}: file does not exist: {script_path}")

        provenance_path = root / provenance_doc
        if not provenance_path.is_file():
            raise ValueError(f"{ctx}.provenance_doc: file does not exist: {provenance_doc}")

        patch_justification = str(row["patch_justification"]).strip()
        if len(patch_justification) < 20:
            raise ValueError(f"{ctx}.patch_justification: must be at least 20 chars")

        provenance_text = provenance_path.read_text(encoding="utf-8")
        if source_commit not in provenance_text:
            raise ValueError(
                f"{ctx}.provenance_doc must include source_commit {source_commit}: {provenance_doc}"
            )

        expected_dir = expected_baselines.get(baseline_id)
        if expected_dir is None:
            raise ValueError(
                f"{ctx}: baseline id '{baseline_id}' is not present in examples manifest baseline mirrors"
            )
        if expected_dir != baseline_dir:
            raise ValueError(
                f"{ctx}: baseline_dir mismatch with examples manifest for '{baseline_id}': {baseline_dir} != {expected_dir}"
            )

        out_rows.append(
            {
                "id": baseline_id,
                "baseline_dir": baseline_dir,
                "source_repo": source_repo,
                "source_commit": source_commit,
                "sync_script": sync_script,
                "patch_script": patch_script,
                "provenance_doc": provenance_doc,
            }
        )

    missing_ids = sorted(set(expected_baselines.keys()).difference(seen_ids))
    if missing_ids:
        raise ValueError(
            "manifest missing baseline entries required by examples manifest: " + ", ".join(missing_ids)
        )

    return sorted(out_rows, key=lambda row: row["id"])


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    manifest_path = Path(args.manifest).resolve()
    examples_manifest_path = (root / args.examples_manifest).resolve()

    expected_baselines = load_expected_baselines(examples_manifest_path)
    rows = validate_manifest(root, manifest_path, expected_baselines)

    if args.emit_tsv:
        for row in rows:
            print(
                "\t".join(
                    [
                        row["id"],
                        row["baseline_dir"],
                        row["source_repo"],
                        row["source_commit"],
                        row["sync_script"],
                        row["patch_script"],
                        row["provenance_doc"],
                    ]
                )
            )
    else:
        print(f"baseline manifest validation passed ({len(rows)} baselines)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
