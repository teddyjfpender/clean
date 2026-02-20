#!/usr/bin/env python3
"""Apply validated optimization passes to Starknet contract artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
from copy import deepcopy
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--index", required=True, help="Path to *.starknet_artifacts.json")
    parser.add_argument("--contract-name", required=True, help="contract_name selector")
    parser.add_argument("--out-dir", required=True, help="Output directory for optimized artifacts")
    parser.add_argument(
        "--passes",
        default="strip_sierra_debug_info",
        help="Comma-separated pass names. Supported: strip_sierra_debug_info",
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def dump_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, sort_keys=True, separators=(",", ":")))


def select_contract(index_payload: dict[str, Any], contract_name: str) -> tuple[int, dict[str, Any]]:
    contracts = index_payload.get("contracts", [])
    for idx, contract in enumerate(contracts):
        if contract.get("contract_name") == contract_name:
            return idx, contract
    raise ValueError(f"contract_name not found in artifacts index: {contract_name}")


def sha256_json(value: Any) -> str:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def artifact_semantics_signature(
    sierra_class: dict[str, Any], casm_class: dict[str, Any] | None
) -> dict[str, str]:
    signature = {
        "sierra_program_hash": sha256_json(sierra_class.get("sierra_program", [])),
        "sierra_entry_points_hash": sha256_json(sierra_class.get("entry_points_by_type", {})),
        "sierra_abi_hash": sha256_json(sierra_class.get("abi", [])),
    }
    if casm_class is not None:
        signature["casm_bytecode_hash"] = sha256_json(casm_class.get("bytecode", []))
        signature["casm_entry_points_hash"] = sha256_json(casm_class.get("entry_points_by_type", {}))
    return signature


def apply_pass_strip_sierra_debug_info(
    sierra_class: dict[str, Any], casm_class: dict[str, Any] | None
) -> tuple[dict[str, Any], dict[str, Any] | None, dict[str, Any]]:
    changed = "sierra_program_debug_info" in sierra_class
    optimized = dict(sierra_class)
    optimized.pop("sierra_program_debug_info", None)
    report = {"pass": "strip_sierra_debug_info", "changed": changed}
    return optimized, casm_class, report


PASS_REGISTRY = {
    "strip_sierra_debug_info": apply_pass_strip_sierra_debug_info,
}


def apply_passes(
    sierra_class: dict[str, Any], casm_class: dict[str, Any] | None, passes: list[str]
) -> tuple[dict[str, Any], dict[str, Any] | None, list[dict[str, Any]]]:
    current_sierra = deepcopy(sierra_class)
    current_casm = deepcopy(casm_class) if casm_class is not None else None
    reports: list[dict[str, Any]] = []

    for pass_name in passes:
        fn = PASS_REGISTRY.get(pass_name)
        if fn is None:
            supported = ", ".join(sorted(PASS_REGISTRY))
            raise ValueError(f"unsupported pass '{pass_name}', supported passes: {supported}")
        current_sierra, current_casm, report = fn(current_sierra, current_casm)
        reports.append(report)

    return current_sierra, current_casm, reports


def build_metrics(
    sierra_class: dict[str, Any], casm_class: dict[str, Any] | None, path: Path
) -> dict[str, Any]:
    metrics = {
        "artifact_path": str(path),
        "file_size_bytes": path.stat().st_size,
        "sierra_program_len": len(sierra_class.get("sierra_program", [])),
        "entry_points_external": len(sierra_class.get("entry_points_by_type", {}).get("EXTERNAL", [])),
    }
    if casm_class is not None:
        metrics["casm_bytecode_len"] = len(casm_class.get("bytecode", []))
        metrics["casm_hints_count"] = len(casm_class.get("hints", []))
    else:
        metrics["casm_bytecode_len"] = None
        metrics["casm_hints_count"] = None
    return metrics


def main() -> int:
    args = parse_args()
    index_path = Path(args.index).resolve()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    passes = [p.strip() for p in args.passes.split(",") if p.strip()]
    if not passes:
        raise ValueError("no passes specified")

    index_payload = load_json(index_path)
    selected_index, selected_contract = select_contract(index_payload, args.contract_name)
    artifacts = selected_contract.get("artifacts", {})

    sierra_rel = artifacts.get("sierra")
    if not sierra_rel:
        raise ValueError("selected contract has no Sierra artifact")
    sierra_path = (index_path.parent / sierra_rel).resolve()
    sierra_class = load_json(sierra_path)

    casm_rel = artifacts.get("casm")
    casm_path = (index_path.parent / casm_rel).resolve() if casm_rel else None
    casm_class = load_json(casm_path) if casm_path else None

    before_sig = artifact_semantics_signature(sierra_class, casm_class)
    optimized_sierra, optimized_casm, pass_reports = apply_passes(sierra_class, casm_class, passes)
    after_sig = artifact_semantics_signature(optimized_sierra, optimized_casm)

    if before_sig != after_sig:
        raise ValueError(
            "semantic invariants violated by artifact pass pipeline: critical Sierra/CASM fields changed"
        )

    optimized_sierra_name = sierra_path.name.replace(".contract_class.json", ".optimized.contract_class.json")
    optimized_sierra_path = out_dir / optimized_sierra_name
    dump_json(optimized_sierra_path, optimized_sierra)

    optimized_casm_path = None
    optimized_casm_name = None
    if optimized_casm is not None and casm_path is not None:
        optimized_casm_name = casm_path.name.replace(
            ".compiled_contract_class.json", ".optimized.compiled_contract_class.json"
        )
        optimized_casm_path = out_dir / optimized_casm_name
        dump_json(optimized_casm_path, optimized_casm)

    optimized_index = deepcopy(index_payload)
    optimized_contract = deepcopy(optimized_index["contracts"][selected_index])
    optimized_contract["artifacts"] = dict(optimized_contract.get("artifacts", {}))
    optimized_contract["artifacts"]["sierra"] = optimized_sierra_name
    if optimized_casm_name is not None:
        optimized_contract["artifacts"]["casm"] = optimized_casm_name
    optimized_index["contracts"][selected_index] = optimized_contract

    optimized_index_path = out_dir / "optimized.starknet_artifacts.json"
    dump_json(optimized_index_path, optimized_index)

    report = {
        "contract_name": args.contract_name,
        "passes": pass_reports,
        "semantic_signature": {"before": before_sig, "after": after_sig},
        "source_metrics": build_metrics(sierra_class, casm_class, sierra_path),
        "optimized_metrics": build_metrics(optimized_sierra, optimized_casm, optimized_sierra_path),
        "source_index": str(index_path),
        "optimized_index": str(optimized_index_path),
    }

    report_path = out_dir / "artifact_optimization_report.json"
    dump_json(report_path, report)

    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
