#!/usr/bin/env python3
"""Validate MIR family contract coverage against IR, evaluator, and optimizer."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Set

NODE_STATES = {"implemented", "fail_fast", "planned"}
FAMILY_GROUPS = {"scalar", "integer", "control", "binding", "storage"}
EFFECT_INVARIANTS = {"pure", "resource-threaded"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate MIR family contract")
    parser.add_argument("--contract", required=True)
    parser.add_argument("--ir-expr", required=True)
    parser.add_argument("--eval", required=True)
    parser.add_argument("--optimize", required=True)
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"contract must be a JSON object: {path}")
    return payload


def extract_ir_expr_constructors(path: Path) -> List[str]:
    text = path.read_text(encoding="utf-8")
    start = text.find("inductive IRExpr")
    if start < 0:
        raise ValueError(f"failed to locate 'inductive IRExpr' in {path}")
    end = text.find("deriving Repr, DecidableEq", start)
    if end < 0:
        raise ValueError(f"failed to locate IRExpr deriving clause in {path}")
    block = text[start:end]
    ctors: List[str] = []
    for raw_line in block.splitlines():
        m = re.match(r"\s*\|\s*([A-Za-z0-9_]+)\b", raw_line)
        if m:
            ctors.append(m.group(1))
    if not ctors:
        raise ValueError(f"no IRExpr constructors parsed from {path}")
    return ctors


def extract_def_block(text: str, marker: str) -> str:
    start = text.find(marker)
    if start < 0:
        raise ValueError(f"failed to locate definition marker: {marker}")
    tail = text[start:]
    m = re.search(r"\n\ndef\s+[A-Za-z0-9_]+", tail)
    return tail if m is None else tail[: m.start()]


def extract_case_constructors(block: str) -> Set[str]:
    constructors: Set[str] = set()
    for raw_line in block.splitlines():
        m_direct = re.match(r"\s*\|\s*\.([A-Za-z0-9_]+)\b", raw_line)
        if m_direct:
            constructors.add(m_direct.group(1))
            continue
        m_qualified = re.match(r"\s*\|\s*@IRExpr\.([A-Za-z0-9_]+)\b", raw_line)
        if m_qualified:
            constructors.add(m_qualified.group(1))
    return constructors


def validate_nodes(contract_path: Path, payload: Dict[str, object], ir_constructors: List[str]) -> List[str]:
    errors: List[str] = []
    nodes = payload.get("nodes")
    if not isinstance(nodes, list) or not nodes:
        return [f"contract nodes must be a non-empty list: {contract_path}"]

    seen: Set[str] = set()
    contract_constructors: List[str] = []
    for idx, node in enumerate(nodes):
        context = f"{contract_path} nodes[{idx}]"
        if not isinstance(node, dict):
            errors.append(f"invalid node object: {context}")
            continue

        ctor = node.get("constructor")
        family = node.get("family_group")
        state = node.get("support_state")
        type_inv = node.get("type_invariant")
        effect_inv = node.get("effect_invariant")

        if not isinstance(ctor, str) or not ctor:
            errors.append(f"missing constructor: {context}")
            continue
        contract_constructors.append(ctor)
        if ctor in seen:
            errors.append(f"duplicate constructor entry: {ctor}")
        seen.add(ctor)

        if not isinstance(family, str) or family not in FAMILY_GROUPS:
            errors.append(f"invalid family_group for {ctor}: {family}")
        if not isinstance(state, str) or state not in NODE_STATES:
            errors.append(f"invalid support_state for {ctor}: {state}")
        if not isinstance(type_inv, str) or not type_inv.strip():
            errors.append(f"missing type_invariant for {ctor}")
        if not isinstance(effect_inv, str) or effect_inv not in EFFECT_INVARIANTS:
            errors.append(f"invalid effect_invariant for {ctor}: {effect_inv}")

    ir_set = set(ir_constructors)
    contract_set = set(contract_constructors)
    missing = sorted(ir_set - contract_set)
    extra = sorted(contract_set - ir_set)
    if missing:
        errors.append(f"contract missing IRExpr constructors: {', '.join(missing)}")
    if extra:
        errors.append(f"contract has unknown constructors: {', '.join(extra)}")
    return errors


def validate_case_coverage(
    nodes: List[Dict[str, object]],
    eval_expr_cases: Set[str],
    eval_expr_strict_cases: Set[str],
    optimize_cases: Set[str],
) -> List[str]:
    errors: List[str] = []
    for node in nodes:
        ctor = str(node.get("constructor", ""))
        if not ctor:
            continue
        state = str(node.get("support_state", ""))
        if state != "implemented":
            continue
        if ctor not in eval_expr_cases:
            errors.append(f"evalExpr missing implemented constructor case: {ctor}")
        if ctor not in eval_expr_strict_cases:
            errors.append(f"evalExprStrict missing implemented constructor case: {ctor}")
        if ctor not in optimize_cases:
            errors.append(f"optimizeExpr missing implemented constructor case: {ctor}")
    return errors


def validate_no_wildcard_fallback(block: str, label: str) -> List[str]:
    if re.search(r"\|\s*_\s*=>", block):
        return [f"wildcard fallback is forbidden in {label}"]
    return []


def validate_fail_fast_contracts(root: Path, payload: Dict[str, object]) -> List[str]:
    errors: List[str] = []
    entries = payload.get("fail_fast_contracts")
    if not isinstance(entries, list) or not entries:
        return [f"missing fail_fast_contracts list: {root}"]

    seen_ids: Set[str] = set()
    for idx, entry in enumerate(entries):
        context = f"fail_fast_contracts[{idx}]"
        if not isinstance(entry, dict):
            errors.append(f"invalid fail-fast contract object: {context}")
            continue
        contract_id = entry.get("id")
        script = entry.get("test_script")
        evidence_file = entry.get("evidence_file")
        expected = entry.get("expected_substring")

        if not isinstance(contract_id, str) or not contract_id.strip():
            errors.append(f"missing id: {context}")
        elif contract_id in seen_ids:
            errors.append(f"duplicate fail-fast contract id: {contract_id}")
        else:
            seen_ids.add(contract_id)

        if not isinstance(script, str) or not script.strip():
            errors.append(f"missing test_script: {context}")
        else:
            script_path = root / script
            if not script_path.is_file():
                errors.append(f"missing test_script path: {script}")

        if not isinstance(evidence_file, str) or not evidence_file.strip():
            errors.append(f"missing evidence_file: {context}")
            continue
        evidence_path = root / evidence_file
        if not evidence_path.is_file():
            errors.append(f"missing evidence_file path: {evidence_file}")
            continue

        if not isinstance(expected, str) or not expected.strip():
            errors.append(f"missing expected_substring: {context}")
            continue

        evidence_text = evidence_path.read_text(encoding="utf-8")
        if expected not in evidence_text:
            errors.append(
                f"expected_substring not found in evidence file ({context}): {expected}"
            )

    return errors


def main() -> int:
    args = parse_args()
    contract_path = Path(args.contract)
    ir_expr_path = Path(args.ir_expr)
    eval_path = Path(args.eval)
    optimize_path = Path(args.optimize)

    payload = load_json(contract_path)
    root = contract_path.resolve().parents[2]

    errors: List[str] = []
    version = payload.get("version")
    if version != 1:
        errors.append(f"unsupported contract version (expected 1): {version}")

    try:
        ir_constructors = extract_ir_expr_constructors(ir_expr_path)
    except ValueError as exc:
        errors.append(str(exc))
        ir_constructors = []

    if ir_constructors:
        errors.extend(validate_nodes(contract_path, payload, ir_constructors))

    eval_text = eval_path.read_text(encoding="utf-8")
    optimize_text = optimize_path.read_text(encoding="utf-8")
    try:
        eval_expr_block = extract_def_block(eval_text, "def evalExpr (ctx : EvalContext)")
        eval_expr_strict_block = extract_def_block(eval_text, "def evalExprStrict (ctx : EvalContext)")
        optimize_expr_block = extract_def_block(optimize_text, "def optimizeExpr : IRExpr ty -> IRExpr ty")
    except ValueError as exc:
        errors.append(str(exc))
        eval_expr_block = ""
        eval_expr_strict_block = ""
        optimize_expr_block = ""

    if eval_expr_block and eval_expr_strict_block and optimize_expr_block:
        eval_expr_cases = extract_case_constructors(eval_expr_block)
        eval_expr_strict_cases = extract_case_constructors(eval_expr_strict_block)
        optimize_cases = extract_case_constructors(optimize_expr_block)

        nodes = payload.get("nodes", [])
        if isinstance(nodes, list):
            errors.extend(
                validate_case_coverage(
                    [n for n in nodes if isinstance(n, dict)],
                    eval_expr_cases,
                    eval_expr_strict_cases,
                    optimize_cases,
                )
            )

        errors.extend(validate_no_wildcard_fallback(eval_expr_block, "evalExpr"))
        errors.extend(validate_no_wildcard_fallback(eval_expr_strict_block, "evalExprStrict"))
        errors.extend(validate_no_wildcard_fallback(optimize_expr_block, "optimizeExpr"))

    errors.extend(validate_fail_fast_contracts(root, payload))

    if errors:
        for error in errors:
            print(error)
        print(f"MIR family contract validation failed with {len(errors)} error(s)")
        return 1

    print(
        "MIR family contract validation passed "
        f"({len(payload.get('nodes', []))} nodes, {len(payload.get('fail_fast_contracts', []))} fail-fast contracts)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
