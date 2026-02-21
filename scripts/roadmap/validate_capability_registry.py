#!/usr/bin/env python3
"""Validate capability registry schema and optional transition legality."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

ALLOWED_FAMILY_GROUPS = {
    "scalar",
    "integer",
    "field",
    "aggregate",
    "collection",
    "control",
    "resource",
    "crypto",
    "circuit",
    "runtime",
}

ALLOWED_STATES = {"planned", "fail_fast", "implemented"}
ALLOWED_SEMANTIC = {"pure", "effectful", "partial"}
ALLOWED_PROOF_STATUS = {"planned", "partial", "complete"}
STATE_TRANSITIONS = {
    "planned": {"planned", "fail_fast", "implemented"},
    "fail_fast": {"fail_fast", "implemented"},
    "implemented": {"implemented"},
}
RE_CAP_ID = re.compile(r"^cap\.[a-z0-9_.-]+$")


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON in {path}: {exc}") from exc


def require_keys(obj: Dict[str, object], keys: List[str], ctx: str, errors: List[str]) -> None:
    for key in keys:
        if key not in obj:
            errors.append(f"{ctx}: missing key '{key}'")


def as_list_of_strings(value: object, ctx: str, errors: List[str], allow_empty: bool = False) -> List[str]:
    if not isinstance(value, list):
        errors.append(f"{ctx}: expected list")
        return []
    out: List[str] = []
    for idx, item in enumerate(value):
        if not isinstance(item, str) or not item.strip():
            errors.append(f"{ctx}[{idx}]: expected non-empty string")
            continue
        out.append(item)
    if not allow_empty and not out:
        errors.append(f"{ctx}: list must be non-empty")
    if len(out) != len(set(out)):
        errors.append(f"{ctx}: list entries must be unique")
    return out


def validate_support_state(value: object, ctx: str, errors: List[str]) -> Tuple[str, str, str]:
    if not isinstance(value, dict):
        errors.append(f"{ctx}: expected object")
        return ("", "", "")
    require_keys(value, ["sierra", "cairo", "overall"], ctx, errors)
    sierra = value.get("sierra", "")
    cairo = value.get("cairo", "")
    overall = value.get("overall", "")

    for key, state in (("sierra", sierra), ("cairo", cairo), ("overall", overall)):
        if state not in ALLOWED_STATES:
            errors.append(f"{ctx}.{key}: invalid state '{state}'")

    if overall == "implemented" and (sierra != "implemented" or cairo != "implemented"):
        errors.append(
            f"{ctx}: overall=implemented requires sierra=implemented and cairo=implemented"
        )
    if overall == "planned" and sierra == "implemented" and cairo == "implemented":
        errors.append(f"{ctx}: overall=planned is inconsistent with both backends implemented")

    return str(sierra), str(cairo), str(overall)


def validate_registry(payload: object, path: Path) -> Tuple[List[str], Dict[str, Dict[str, str]]]:
    errors: List[str] = []
    states_by_capability: Dict[str, Dict[str, str]] = {}

    if not isinstance(payload, dict):
        return ([f"{path}: top-level must be object"], states_by_capability)

    require_keys(payload, ["version", "capabilities"], str(path), errors)

    version = payload.get("version")
    if version != 1:
        errors.append(f"{path}: version must be 1")

    capabilities = payload.get("capabilities")
    if not isinstance(capabilities, list) or not capabilities:
        errors.append(f"{path}: capabilities must be a non-empty list")
        return errors, states_by_capability

    seen_ids = set()
    ordered_ids: List[str] = []

    for idx, cap in enumerate(capabilities):
        ctx = f"{path}: capabilities[{idx}]"
        if not isinstance(cap, dict):
            errors.append(f"{ctx}: expected object")
            continue

        require_keys(
            cap,
            [
                "capability_id",
                "family_group",
                "mir_nodes",
                "sierra_targets",
                "cairo_targets",
                "resource_requirements",
                "semantic_class",
                "support_state",
                "proof_class",
                "proof_status",
                "test_class",
                "benchmark_class",
            ],
            ctx,
            errors,
        )

        cap_id = cap.get("capability_id", "")
        if not isinstance(cap_id, str) or not RE_CAP_ID.match(cap_id):
            errors.append(f"{ctx}.capability_id: invalid capability id '{cap_id}'")
            cap_id = ""
        elif cap_id in seen_ids:
            errors.append(f"{ctx}.capability_id: duplicate capability id '{cap_id}'")
        else:
            seen_ids.add(cap_id)
            ordered_ids.append(cap_id)

        family = cap.get("family_group")
        if family not in ALLOWED_FAMILY_GROUPS:
            errors.append(f"{ctx}.family_group: invalid value '{family}'")

        as_list_of_strings(cap.get("mir_nodes"), f"{ctx}.mir_nodes", errors, allow_empty=False)

        sierra_targets = cap.get("sierra_targets")
        if not isinstance(sierra_targets, dict):
            errors.append(f"{ctx}.sierra_targets: expected object")
        else:
            require_keys(sierra_targets, ["generic_type_ids", "generic_libfunc_ids"], f"{ctx}.sierra_targets", errors)
            as_list_of_strings(
                sierra_targets.get("generic_type_ids"),
                f"{ctx}.sierra_targets.generic_type_ids",
                errors,
                allow_empty=True,
            )
            as_list_of_strings(
                sierra_targets.get("generic_libfunc_ids"),
                f"{ctx}.sierra_targets.generic_libfunc_ids",
                errors,
                allow_empty=True,
            )

        cairo_targets = cap.get("cairo_targets")
        if not isinstance(cairo_targets, dict):
            errors.append(f"{ctx}.cairo_targets: expected object")
        else:
            require_keys(cairo_targets, ["forms"], f"{ctx}.cairo_targets", errors)
            as_list_of_strings(cairo_targets.get("forms"), f"{ctx}.cairo_targets.forms", errors, allow_empty=False)

        as_list_of_strings(cap.get("resource_requirements"), f"{ctx}.resource_requirements", errors, allow_empty=True)

        semantic_class = cap.get("semantic_class")
        if semantic_class not in ALLOWED_SEMANTIC:
            errors.append(f"{ctx}.semantic_class: invalid value '{semantic_class}'")

        sierra_state, cairo_state, overall_state = validate_support_state(cap.get("support_state"), f"{ctx}.support_state", errors)

        divergence_constraints = cap.get("divergence_constraints", [])
        if sierra_state != cairo_state:
            constraints = as_list_of_strings(
                divergence_constraints,
                f"{ctx}.divergence_constraints",
                errors,
                allow_empty=False,
            )
            if not constraints:
                errors.append(
                    f"{ctx}: divergent backend states require non-empty divergence_constraints"
                )
        else:
            if divergence_constraints not in ([], None):
                if not isinstance(divergence_constraints, list):
                    errors.append(f"{ctx}.divergence_constraints: expected list when present")
                else:
                    _ = as_list_of_strings(
                        divergence_constraints,
                        f"{ctx}.divergence_constraints",
                        errors,
                        allow_empty=True,
                    )

        proof_class = cap.get("proof_class")
        if not isinstance(proof_class, str) or not proof_class.strip():
            errors.append(f"{ctx}.proof_class: expected non-empty string")

        proof_status = cap.get("proof_status")
        if proof_status not in ALLOWED_PROOF_STATUS:
            errors.append(f"{ctx}.proof_status: invalid value '{proof_status}'")

        test_class = cap.get("test_class")
        if not isinstance(test_class, str) or not test_class.strip():
            errors.append(f"{ctx}.test_class: expected non-empty string")

        benchmark_class = cap.get("benchmark_class")
        if not isinstance(benchmark_class, str) or not benchmark_class.strip():
            errors.append(f"{ctx}.benchmark_class: expected non-empty string")

        if cap_id:
            states_by_capability[cap_id] = {
                "sierra": sierra_state,
                "cairo": cairo_state,
                "overall": overall_state,
            }

    if ordered_ids != sorted(ordered_ids):
        errors.append(f"{path}: capabilities must be sorted by capability_id")

    return errors, states_by_capability


def validate_transitions(
    old_states: Dict[str, Dict[str, str]],
    new_states: Dict[str, Dict[str, str]],
) -> List[str]:
    errors: List[str] = []

    removed = sorted(set(old_states.keys()) - set(new_states.keys()))
    if removed:
        errors.append(f"transition: capabilities removed without migration policy: {', '.join(removed)}")

    for cap_id in sorted(set(old_states.keys()) & set(new_states.keys())):
        for channel in ("sierra", "cairo", "overall"):
            old_state = old_states[cap_id][channel]
            new_state = new_states[cap_id][channel]
            allowed = STATE_TRANSITIONS.get(old_state, set())
            if new_state not in allowed:
                errors.append(
                    f"transition: illegal state change for {cap_id}.{channel}: {old_state} -> {new_state}"
                )

    return errors


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate capability registry")
    parser.add_argument("--registry", required=True, help="Path to registry.json")
    parser.add_argument(
        "--previous",
        default=None,
        help="Optional previous registry path to validate state transitions",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    registry_path = Path(args.registry)
    if not registry_path.exists():
        print(f"missing registry file: {registry_path}")
        return 1

    payload = load_json(registry_path)
    errors, states = validate_registry(payload, registry_path)

    if args.previous is not None:
        previous_path = Path(args.previous)
        if not previous_path.exists():
            errors.append(f"missing previous registry file: {previous_path}")
        else:
            previous_payload = load_json(previous_path)
            previous_errors, previous_states = validate_registry(previous_payload, previous_path)
            errors.extend(previous_errors)
            if not previous_errors:
                errors.extend(validate_transitions(previous_states, states))

    if errors:
        for err in errors:
            print(err)
        print(f"capability registry validation failed with {len(errors)} error(s)")
        return 1

    print("capability registry validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
