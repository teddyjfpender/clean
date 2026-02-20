#!/usr/bin/env python3
"""Resolve Starknet contract artifact paths from a Scarb artifacts index file."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--index", required=True, help="Path to *.starknet_artifacts.json")
    parser.add_argument(
        "--contract-name",
        default=None,
        help="Optional contract_name selector from the artifacts index",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    index_path = Path(args.index)
    payload = json.loads(index_path.read_text())
    contracts = payload.get("contracts", [])
    if not contracts:
        raise SystemExit("No contracts found in artifacts index")

    selected = None
    if args.contract_name is None:
        selected = contracts[0]
    else:
        for contract in contracts:
            if contract.get("contract_name") == args.contract_name:
                selected = contract
                break
    if selected is None:
        raise SystemExit(f"Contract not found in artifacts index: {args.contract_name}")

    artifacts = selected.get("artifacts", {})
    sierra = artifacts.get("sierra")
    casm = artifacts.get("casm")

    if sierra:
        print(str((index_path.parent / sierra).resolve()))
    if casm:
        print(str((index_path.parent / casm).resolve()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
