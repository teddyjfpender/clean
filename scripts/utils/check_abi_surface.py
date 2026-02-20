#!/usr/bin/env python3
"""Validate contract ABI surface against expected function signatures."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

TYPE_ALIASES = {
    "felt252": "core::felt252",
    "u128": "core::integer::u128",
    "u256": "core::integer::u256",
    "bool": "core::bool",
}


def canonical_type(type_name: str) -> str:
    return TYPE_ALIASES.get(type_name, type_name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--index", required=True, help="Path to *.starknet_artifacts.json")
    parser.add_argument("--expect", required=True, help="Path to expected ABI JSON")
    parser.add_argument(
        "--contract-name",
        default=None,
        help="Optional contract_name selector; defaults to expect.contract_name",
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def select_contract(index_payload: dict[str, Any], contract_name: str | None) -> dict[str, Any]:
    contracts = index_payload.get("contracts", [])
    if not contracts:
        raise ValueError("artifacts index contains no contracts")
    if contract_name is None:
        if len(contracts) == 1:
            return contracts[0]
        raise ValueError("multiple contracts in artifacts index; pass --contract-name")
    for contract in contracts:
        if contract.get("contract_name") == contract_name:
            return contract
    raise ValueError(f"contract_name not found in artifacts index: {contract_name}")


def extract_interface_functions(contract_class_payload: dict[str, Any]) -> list[dict[str, Any]]:
    abi = contract_class_payload.get("abi", [])
    functions: list[dict[str, Any]] = []
    for entry in abi:
        if entry.get("type") != "interface":
            continue
        for item in entry.get("items", []):
            if item.get("type") == "function":
                functions.append(item)
    return functions


def check_function(
    expected_fn: dict[str, Any],
    actual_fn: dict[str, Any],
    errors: list[str],
) -> None:
    expected_mutability = expected_fn.get("state_mutability", "view")
    actual_mutability = actual_fn.get("state_mutability")
    if expected_mutability != actual_mutability:
        errors.append(
            f"function '{expected_fn['name']}' mutability mismatch: expected {expected_mutability}, got {actual_mutability}"
        )

    expected_inputs = expected_fn.get("inputs", [])
    actual_inputs = actual_fn.get("inputs", [])
    if len(expected_inputs) != len(actual_inputs):
        errors.append(
            f"function '{expected_fn['name']}' input arity mismatch: expected {len(expected_inputs)}, got {len(actual_inputs)}"
        )
    else:
        for index, (expected_arg, actual_arg) in enumerate(zip(expected_inputs, actual_inputs)):
            expected_name = expected_arg.get("name")
            actual_name = actual_arg.get("name")
            if expected_name is not None and expected_name != actual_name:
                errors.append(
                    f"function '{expected_fn['name']}' input[{index}] name mismatch: expected {expected_name}, got {actual_name}"
                )
            expected_type = canonical_type(expected_arg["type"])
            actual_type = actual_arg.get("type")
            if expected_type != actual_type:
                errors.append(
                    f"function '{expected_fn['name']}' input[{index}] type mismatch: expected {expected_type}, got {actual_type}"
                )

    expected_outputs = expected_fn.get("outputs", [])
    actual_outputs = actual_fn.get("outputs", [])
    if len(expected_outputs) != len(actual_outputs):
        errors.append(
            f"function '{expected_fn['name']}' output arity mismatch: expected {len(expected_outputs)}, got {len(actual_outputs)}"
        )
    else:
        for index, (expected_output, actual_output) in enumerate(
            zip(expected_outputs, actual_outputs)
        ):
            expected_type = canonical_type(expected_output["type"])
            actual_type = actual_output.get("type")
            if expected_type != actual_type:
                errors.append(
                    f"function '{expected_fn['name']}' output[{index}] type mismatch: expected {expected_type}, got {actual_type}"
                )


def validate_abi(
    expected_payload: dict[str, Any],
    actual_functions: list[dict[str, Any]],
) -> list[str]:
    errors: list[str] = []
    expected_functions = expected_payload.get("functions", [])

    actual_by_name = {fn.get("name"): fn for fn in actual_functions}
    expected_names = {fn["name"] for fn in expected_functions}
    actual_names = set(actual_by_name.keys())

    missing = sorted(expected_names - actual_names)
    extra = sorted(name for name in (actual_names - expected_names) if name is not None)

    for name in missing:
        errors.append(f"missing ABI function: {name}")
    for name in extra:
        errors.append(f"unexpected ABI function: {name}")

    for expected_fn in expected_functions:
        name = expected_fn["name"]
        actual_fn = actual_by_name.get(name)
        if actual_fn is None:
            continue
        check_function(expected_fn, actual_fn, errors)

    return errors


def main() -> int:
    args = parse_args()
    index_path = Path(args.index)
    expected_path = Path(args.expect)

    index_payload = load_json(index_path)
    expected_payload = load_json(expected_path)

    selected_contract_name = args.contract_name or expected_payload.get("contract_name")
    contract_entry = select_contract(index_payload, selected_contract_name)

    sierra_rel = contract_entry.get("artifacts", {}).get("sierra")
    if not sierra_rel:
        raise ValueError("selected contract has no Sierra artifact path")

    contract_class_path = (index_path.parent / sierra_rel).resolve()
    contract_class_payload = load_json(contract_class_path)
    actual_functions = extract_interface_functions(contract_class_payload)

    errors = validate_abi(expected_payload, actual_functions)
    if errors:
        print("ABI validation failed:")
        for err in errors:
            print(f"- {err}")
        return 1

    print(
        f"ABI validation passed for {selected_contract_name} using {contract_class_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
