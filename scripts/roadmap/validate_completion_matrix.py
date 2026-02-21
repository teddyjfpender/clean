#!/usr/bin/env python3
"""Validate completion-matrix payload against repository schema."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


class ValidationError(Exception):
    pass


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValidationError(f"invalid JSON in {path}: {exc}") from exc


def require_keys(obj: Dict[str, Any], keys: List[str], ctx: str) -> List[str]:
    errors: List[str] = []
    for key in keys:
        if key not in obj:
            errors.append(f"{ctx}: missing key '{key}'")
    return errors


def validate_matrix(schema: Dict[str, Any], matrix: Dict[str, Any], matrix_path: Path) -> List[str]:
    errors: List[str] = []

    if not isinstance(schema, dict):
        return ["schema: expected object"]
    if schema.get("version") != 1:
        errors.append("schema: version must be 1")

    required_top = schema.get("required_top_level", [])
    required_rows = schema.get("required_row_fields", [])
    status_values = schema.get("status_values", [])

    if not isinstance(required_top, list) or not all(isinstance(v, str) for v in required_top):
        errors.append("schema.required_top_level must be a list of strings")
        required_top = []
    if not isinstance(required_rows, list) or not all(isinstance(v, str) for v in required_rows):
        errors.append("schema.required_row_fields must be a list of strings")
        required_rows = []
    if not isinstance(status_values, list) or not all(isinstance(v, str) for v in status_values):
        errors.append("schema.status_values must be a list of strings")
        status_values = []

    if not isinstance(matrix, dict):
        errors.append(f"{matrix_path}: top-level must be object")
        return errors

    errors.extend(require_keys(matrix, required_top, str(matrix_path)))

    if matrix.get("version") != 1:
        errors.append(f"{matrix_path}: version must be 1")

    schema_version = matrix.get("schema_version")
    if schema_version != 1:
        errors.append(f"{matrix_path}: schema_version must be 1")

    pinned_commit = matrix.get("pinned_commit")
    if not isinstance(pinned_commit, str) or not pinned_commit:
        errors.append(f"{matrix_path}: pinned_commit must be non-empty string")

    data_sources = matrix.get("data_sources")
    if not isinstance(data_sources, dict) or not data_sources:
        errors.append(f"{matrix_path}: data_sources must be a non-empty object")
    else:
        for key, value in sorted(data_sources.items()):
            if not isinstance(key, str) or not key:
                errors.append(f"{matrix_path}: data_sources keys must be non-empty strings")
            if not isinstance(value, str) or not value:
                errors.append(f"{matrix_path}: data_sources[{key!r}] must be non-empty string")

    rows = matrix.get("rows")
    if not isinstance(rows, list) or not rows:
        errors.append(f"{matrix_path}: rows must be a non-empty list")
        return errors

    seen_ids = set()
    for idx, row in enumerate(rows):
        ctx = f"{matrix_path}: rows[{idx}]"
        if not isinstance(row, dict):
            errors.append(f"{ctx}: expected object")
            continue
        errors.extend(require_keys(row, required_rows, ctx))

        dim_id = row.get("dimension_id")
        if not isinstance(dim_id, str) or not dim_id:
            errors.append(f"{ctx}.dimension_id: expected non-empty string")
        elif dim_id in seen_ids:
            errors.append(f"{ctx}.dimension_id: duplicate value '{dim_id}'")
        else:
            seen_ids.add(dim_id)

        target_scope = row.get("target_scope")
        if not isinstance(target_scope, str) or not target_scope:
            errors.append(f"{ctx}.target_scope: expected non-empty string")

        for list_field in ("required_metrics", "required_artifacts", "blocking_gates", "diagnostics", "evidence_refs"):
            value = row.get(list_field)
            if not isinstance(value, list):
                errors.append(f"{ctx}.{list_field}: expected list")
                continue
            for item_idx, item in enumerate(value):
                if not isinstance(item, str):
                    errors.append(f"{ctx}.{list_field}[{item_idx}]: expected string")

        status = row.get("status")
        if status not in status_values:
            errors.append(f"{ctx}.status: expected one of {status_values}, got {status!r}")

    sorted_ids = sorted(seen_ids)
    current_ids = [row.get("dimension_id") for row in rows if isinstance(row, dict)]
    if current_ids != sorted_ids:
        errors.append(f"{matrix_path}: rows must be sorted by dimension_id")

    return errors


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate completion matrix schema conformance")
    parser.add_argument("--schema", required=True, help="Path to completion matrix schema JSON")
    parser.add_argument("--matrix", required=True, help="Path to completion matrix JSON")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    schema_path = Path(args.schema)
    matrix_path = Path(args.matrix)

    if not schema_path.exists():
        print(f"missing schema file: {schema_path}")
        return 1
    if not matrix_path.exists():
        print(f"missing matrix file: {matrix_path}")
        return 1

    try:
        schema = load_json(schema_path)
        matrix = load_json(matrix_path)
        errors = validate_matrix(schema, matrix, matrix_path)
    except ValidationError as exc:
        print(str(exc))
        return 1

    if errors:
        for error in errors:
            print(error)
        print(f"completion matrix validation failed with {len(errors)} error(s)")
        return 1

    print("completion matrix validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
