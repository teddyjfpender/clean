#!/usr/bin/env python3
"""Compute simple contract cost metrics from Scarb Starknet artifacts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--index", required=True, help="Path to *.starknet_artifacts.json")
    parser.add_argument(
        "--contract-name",
        default=None,
        help="Optional contract_name selector. Defaults to first contract if omitted.",
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def select_contract(index_payload: dict[str, Any], contract_name: str | None) -> dict[str, Any]:
    contracts = index_payload.get("contracts", [])
    if not contracts:
        raise ValueError("artifacts index has no contracts")

    if contract_name is None:
        return contracts[0]

    for contract in contracts:
        if contract.get("contract_name") == contract_name:
            return contract

    raise ValueError(f"contract_name not found in artifacts index: {contract_name}")


def abi_function_count(contract_class_payload: dict[str, Any]) -> int:
    abi = contract_class_payload.get("abi", [])
    count = 0
    for entry in abi:
        if entry.get("type") != "interface":
            continue
        for item in entry.get("items", []):
            if item.get("type") == "function":
                count += 1
    return count


def main() -> int:
    args = parse_args()
    index_path = Path(args.index)
    index_payload = load_json(index_path)

    selected = select_contract(index_payload, args.contract_name)
    contract_name = selected.get("contract_name")
    artifacts = selected.get("artifacts", {})
    sierra_rel = artifacts.get("sierra")
    casm_rel = artifacts.get("casm")
    if not sierra_rel:
        raise ValueError("selected contract has no Sierra artifact")

    contract_path = (index_path.parent / sierra_rel).resolve()
    contract_class = load_json(contract_path)

    sierra_program = contract_class.get("sierra_program", [])
    entry_points = contract_class.get("entry_points_by_type", {})

    metrics = {
        "contract_name": contract_name,
        "contract_class": str(contract_path),
        "sierra_program_len": len(sierra_program),
        "entry_points_external": len(entry_points.get("EXTERNAL", [])),
        "entry_points_constructor": len(entry_points.get("CONSTRUCTOR", [])),
        "entry_points_l1_handler": len(entry_points.get("L1_HANDLER", [])),
        "abi_function_count": abi_function_count(contract_class),
    }

    if casm_rel:
        casm_path = (index_path.parent / casm_rel).resolve()
        casm_class = load_json(casm_path)
        metrics["casm_contract_class"] = str(casm_path)
        metrics["casm_bytecode_len"] = len(casm_class.get("bytecode", []))
        metrics["casm_hint_count"] = len(casm_class.get("hints", []))
        # Prefer CASM bytecode length when available; use Sierra length as fallback tie-breaker.
        metrics["score"] = metrics["casm_bytecode_len"] * 10_000 + metrics["sierra_program_len"]
    else:
        # Fallback for Sierra-only builds.
        metrics["casm_contract_class"] = None
        metrics["casm_bytecode_len"] = None
        metrics["casm_hint_count"] = None
        metrics["score"] = metrics["sierra_program_len"]

    print(json.dumps(metrics, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
