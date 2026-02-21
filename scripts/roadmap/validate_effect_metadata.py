#!/usr/bin/env python3
"""Validate IR effect metadata schema and legality constraints."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

EXPECTED_NODES = [
    "addFelt252",
    "addU128",
    "addU256",
    "eq",
    "ite",
    "leU128",
    "leU256",
    "letE",
    "litBool",
    "litFelt252",
    "litU128",
    "litU256",
    "ltU128",
    "ltU256",
    "mulFelt252",
    "mulU128",
    "mulU256",
    "storageRead",
    "subFelt252",
    "subU128",
    "subU256",
    "var",
]
ALLOWED_CLASSES = {"pure", "effectful", "partial"}
ALLOWED_FAILURE = {"none", "panic_or_error"}
ALLOWED_RESOURCES = {"gas", "range_check", "segment_arena", "panic_channel"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate effect metadata JSON")
    parser.add_argument("--metadata", required=True, help="Path to config/effect-metadata.json")
    return parser.parse_args()


def error(msg: str) -> None:
    raise ValueError(msg)


def main() -> int:
    args = parse_args()
    metadata_path = Path(args.metadata).resolve()
    payload = json.loads(metadata_path.read_text(encoding="utf-8"))

    if not isinstance(payload, dict):
        error("top-level payload must be an object")
    if payload.get("version") != 1:
        error("metadata version must be 1")

    rows = payload.get("nodes")
    if not isinstance(rows, list) or not rows:
        error("nodes must be a non-empty list")

    names: list[str] = []
    for idx, row in enumerate(rows):
        if not isinstance(row, dict):
            error(f"nodes[{idx}] must be an object")
        node = row.get("node")
        effect_class = row.get("effect_class")
        failure_channel = row.get("failure_channel")
        resources = row.get("resource_writes")
        if not isinstance(node, str) or not node:
            error(f"nodes[{idx}].node must be a non-empty string")
        if not isinstance(effect_class, str) or effect_class not in ALLOWED_CLASSES:
            error(f"nodes[{idx}] '{node}': invalid effect_class '{effect_class}'")
        if not isinstance(failure_channel, str) or failure_channel not in ALLOWED_FAILURE:
            error(f"nodes[{idx}] '{node}': invalid failure_channel '{failure_channel}'")
        if not isinstance(resources, list):
            error(f"nodes[{idx}] '{node}': resource_writes must be a list")
        if len(resources) != len(set(resources)):
            error(f"nodes[{idx}] '{node}': duplicate resource_writes entries")
        for resource in resources:
            if not isinstance(resource, str) or resource not in ALLOWED_RESOURCES:
                error(f"nodes[{idx}] '{node}': invalid resource '{resource}'")

        # Illegal class combinations.
        if effect_class == "pure":
            if resources:
                error(f"nodes[{idx}] '{node}': pure nodes cannot declare resource writes")
            if failure_channel != "none":
                error(f"nodes[{idx}] '{node}': pure nodes cannot declare failure channels")
        if effect_class == "partial" and failure_channel == "none":
            error(f"nodes[{idx}] '{node}': partial nodes must declare panic_or_error failure channel")

        names.append(node)

    if names != sorted(names):
        error("nodes must be sorted lexicographically by node name")
    if len(names) != len(set(names)):
        error("node names must be unique")

    expected = sorted(EXPECTED_NODES)
    missing = sorted(set(expected) - set(names))
    extra = sorted(set(names) - set(expected))
    if missing:
        error(f"missing node metadata entries: {', '.join(missing)}")
    if extra:
        error(f"unexpected node metadata entries: {', '.join(extra)}")

    print(f"effect metadata validation passed ({len(names)} nodes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
