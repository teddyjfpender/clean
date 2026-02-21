#!/usr/bin/env python3
"""Validate capability-to-obligation mappings against the capability registry."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, Iterable, List, Set

ALLOWED_STATES = {"planned", "fail_fast", "implemented"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate capability obligations")
    parser.add_argument("--registry", required=True)
    parser.add_argument("--obligations", required=True)
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return payload


def validate_path_ref(root: Path, value: str, ctx: str) -> None:
    ref = Path(value)
    if ref.is_absolute():
        raise ValueError(f"{ctx}: path must be relative, got absolute path '{value}'")
    if ".." in ref.parts:
        raise ValueError(f"{ctx}: path must not contain '..': '{value}'")
    target = (root / ref).resolve()
    if not target.is_file():
        raise ValueError(f"{ctx}: referenced file does not exist: '{value}'")


def collect_theorems(root: Path) -> Set[str]:
    theorem_names: Set[str] = set()
    theorem_re = re.compile(r"\btheorem\s+([A-Za-z0-9_']+)\b")
    for rel in (
        "src/LeanCairo/Compiler/Proof",
        "src/LeanCairo/Compiler/Semantics",
        "src/LeanCairo/Compiler/Optimize",
    ):
        directory = root / rel
        for lean_file in sorted(directory.rglob("*.lean")):
            text = lean_file.read_text(encoding="utf-8")
            for match in theorem_re.finditer(text):
                theorem_names.add(match.group(1))
    return theorem_names


def parse_registry(registry_path: Path) -> Dict[str, Dict[str, str]]:
    payload = load_json(registry_path)
    capabilities = payload.get("capabilities")
    if not isinstance(capabilities, list) or not capabilities:
        raise ValueError(f"{registry_path}: 'capabilities' must be a non-empty list")

    rows: Dict[str, Dict[str, str]] = {}
    for idx, cap in enumerate(capabilities):
        ctx = f"{registry_path}: capabilities[{idx}]"
        if not isinstance(cap, dict):
            raise ValueError(f"{ctx}: expected object")
        cap_id = cap.get("capability_id")
        if not isinstance(cap_id, str) or not cap_id.strip():
            raise ValueError(f"{ctx}: missing non-empty capability_id")
        support = cap.get("support_state")
        if not isinstance(support, dict):
            raise ValueError(f"{ctx}: missing support_state object")
        overall = support.get("overall")
        if overall not in ALLOWED_STATES:
            raise ValueError(f"{ctx}: invalid support_state.overall '{overall}'")
        family = cap.get("family_group")
        if not isinstance(family, str) or not family.strip():
            raise ValueError(f"{ctx}: missing non-empty family_group")
        rows[cap_id] = {
            "overall": overall,
            "family": family,
        }
    return rows


def normalize_list_strings(raw: object, ctx: str) -> List[str]:
    if not isinstance(raw, list):
        raise ValueError(f"{ctx}: expected list")
    out: List[str] = []
    for idx, item in enumerate(raw):
        if not isinstance(item, str) or not item.strip():
            raise ValueError(f"{ctx}[{idx}]: expected non-empty string")
        out.append(item.strip())
    if len(out) != len(set(out)):
        raise ValueError(f"{ctx}: values must be unique")
    return out


def parse_obligations(
    root: Path,
    obligations_path: Path,
    known_capabilities: Dict[str, Dict[str, str]],
    known_theorems: Set[str],
) -> Dict[str, Dict[str, object]]:
    payload = load_json(obligations_path)
    version = payload.get("version")
    if version != 1:
        raise ValueError(f"{obligations_path}: version must be 1")

    raw_obligations = payload.get("obligations")
    if not isinstance(raw_obligations, list) or not raw_obligations:
        raise ValueError(f"{obligations_path}: obligations must be a non-empty list")

    by_capability: Dict[str, Dict[str, object]] = {}
    for idx, entry in enumerate(raw_obligations):
        ctx = f"{obligations_path}: obligations[{idx}]"
        if not isinstance(entry, dict):
            raise ValueError(f"{ctx}: expected object")

        required_keys = {
            "capability_id",
            "required_for_states",
            "proof_refs",
            "test_refs",
            "benchmark_refs",
            "notes",
        }
        missing = sorted(required_keys.difference(entry.keys()))
        if missing:
            raise ValueError(f"{ctx}: missing keys: {', '.join(missing)}")

        cap_id = entry["capability_id"]
        if not isinstance(cap_id, str) or not cap_id.strip():
            raise ValueError(f"{ctx}.capability_id: expected non-empty string")
        cap_id = cap_id.strip()
        if cap_id in by_capability:
            raise ValueError(f"{ctx}: duplicate capability_id '{cap_id}'")
        if cap_id not in known_capabilities:
            raise ValueError(f"{ctx}: unknown capability_id '{cap_id}'")

        states = normalize_list_strings(entry["required_for_states"], f"{ctx}.required_for_states")
        bad_states = sorted(state for state in states if state not in ALLOWED_STATES)
        if bad_states:
            raise ValueError(f"{ctx}.required_for_states: invalid states: {', '.join(bad_states)}")

        proof_refs = normalize_list_strings(entry["proof_refs"], f"{ctx}.proof_refs")
        test_refs = normalize_list_strings(entry["test_refs"], f"{ctx}.test_refs")
        benchmark_refs = normalize_list_strings(entry["benchmark_refs"], f"{ctx}.benchmark_refs")

        notes = entry["notes"]
        if not isinstance(notes, str) or not notes.strip():
            raise ValueError(f"{ctx}.notes: expected non-empty string")

        for theorem in proof_refs:
            if theorem not in known_theorems:
                raise ValueError(f"{ctx}.proof_refs: unknown theorem reference '{theorem}'")

        for path in test_refs:
            validate_path_ref(root, path, f"{ctx}.test_refs")
        for path in benchmark_refs:
            validate_path_ref(root, path, f"{ctx}.benchmark_refs")

        if "implemented" in states:
            if not proof_refs:
                raise ValueError(f"{ctx}: implemented obligations require non-empty proof_refs")
            if not test_refs:
                raise ValueError(f"{ctx}: implemented obligations require non-empty test_refs")
            if not benchmark_refs:
                raise ValueError(f"{ctx}: implemented obligations require non-empty benchmark_refs")

        if "fail_fast" in states and not test_refs:
            raise ValueError(f"{ctx}: fail_fast obligations require non-empty test_refs")

        by_capability[cap_id] = {
            "capability_id": cap_id,
            "required_for_states": states,
            "proof_refs": proof_refs,
            "test_refs": test_refs,
            "benchmark_refs": benchmark_refs,
            "notes": notes.strip(),
        }

    return by_capability


def validate_required_implemented_entries(
    registry_caps: Dict[str, Dict[str, str]],
    obligations: Dict[str, Dict[str, object]],
) -> None:
    implemented_caps = sorted(
        cap_id for cap_id, row in registry_caps.items() if row["overall"] == "implemented"
    )
    missing = []
    for cap_id in implemented_caps:
        entry = obligations.get(cap_id)
        if entry is None:
            missing.append(cap_id)
            continue
        states = entry["required_for_states"]
        if "implemented" not in states:
            missing.append(cap_id)
    if missing:
        raise ValueError(
            "missing obligation entries for implemented capabilities: " + ", ".join(missing)
        )


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    registry_path = Path(args.registry).resolve()
    obligations_path = Path(args.obligations).resolve()

    registry_caps = parse_registry(registry_path)
    theorems = collect_theorems(root)
    obligations = parse_obligations(root, obligations_path, registry_caps, theorems)
    validate_required_implemented_entries(registry_caps, obligations)

    print(
        "capability obligation validation passed "
        f"({len(obligations)} obligation entries, {len(theorems)} known theorems)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
