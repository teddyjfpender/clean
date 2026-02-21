#!/usr/bin/env python3
"""Resolve Starknet contract artifact paths from Scarb artifacts index."""

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--index', required=True, help='Path to *.starknet_artifacts.json')
    parser.add_argument('--contract', default=None, help='Contract name in artifacts index')
    args = parser.parse_args()

    index_path = Path(args.index)
    data = json.loads(index_path.read_text())
    contracts = data.get('contracts', [])
    if not contracts:
        raise SystemExit('No contracts found in artifacts index')

    selected = None
    if args.contract is None:
        selected = contracts[0]
    else:
        for contract in contracts:
            if contract.get('contract_name') == args.contract:
                selected = contract
                break
    if selected is None:
        raise SystemExit(f"Contract not found: {args.contract}")

    artifacts = selected.get('artifacts', {})
    base = index_path.parent
    sierra = artifacts.get('sierra')
    casm = artifacts.get('casm')

    if sierra:
        print(str((base / sierra).resolve()))
    if casm:
        print(str((base / casm).resolve()))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
