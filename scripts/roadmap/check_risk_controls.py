#!/usr/bin/env python3
"""Validate and execute risk controls mapped to roadmap risk IDs."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RISK_DOC = ROOT / "roadmap" / "10-risk-register-and-mitigations.md"
RISK_MAP = ROOT / "roadmap" / "risk-controls.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate-mapping", action="store_true")
    parser.add_argument("--run-controls", action="store_true")
    parser.add_argument("--fail-on-high-risk", action="store_true")
    return parser.parse_args()


def load_risk_ids(path: Path) -> list[str]:
    pattern = re.compile(r"^## (R[0-9]+):")
    result: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line.strip())
        if match:
            result.append(match.group(1))
    if not result:
        raise ValueError(f"no risk IDs found in {path}")
    return result


def load_mapping(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"invalid mapping payload (expected object): {path}")
    risks = payload.get("risks")
    if not isinstance(risks, list):
        raise ValueError(f"missing `risks` list in mapping: {path}")
    return payload


def command_path(command: str) -> Path | None:
    token = command.split(maxsplit=1)[0].strip()
    if not token:
        return None
    if token.startswith("./"):
        token = token[2:]
    if "/" not in token:
        return None
    return ROOT / token


def run_command(command: str) -> tuple[bool, str]:
    proc = subprocess.run(
        ["bash", "-lc", command],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    ok = proc.returncode == 0
    output = (proc.stdout or "") + (proc.stderr or "")
    return ok, output.strip()


def main() -> int:
    args = parse_args()
    if not args.validate_mapping and not args.run_controls:
        args.validate_mapping = True

    risk_ids = load_risk_ids(RISK_DOC)
    mapping = load_mapping(RISK_MAP)
    mapped = mapping["risks"]

    errors: list[str] = []
    unresolved: dict[str, list[str]] = defaultdict(list)
    severities: dict[str, str] = {}

    by_id: dict[str, dict] = {}
    for entry in mapped:
        if not isinstance(entry, dict):
            errors.append("risk mapping contains non-object entry")
            continue
        risk_id = entry.get("risk_id")
        severity = entry.get("severity")
        controls = entry.get("controls")
        if not isinstance(risk_id, str) or not risk_id:
            errors.append("risk mapping entry missing `risk_id`")
            continue
        if not isinstance(severity, str) or not severity:
            errors.append(f"risk mapping entry missing `severity` for {risk_id}")
            continue
        if not isinstance(controls, list) or not controls:
            errors.append(f"risk mapping entry missing non-empty `controls` for {risk_id}")
            continue
        by_id[risk_id] = entry
        severities[risk_id] = severity

    missing_from_mapping = [risk_id for risk_id in risk_ids if risk_id not in by_id]
    if missing_from_mapping:
        errors.append(
            "missing risk mappings for: " + ", ".join(sorted(missing_from_mapping))
        )

    for risk_id, entry in by_id.items():
        controls = entry["controls"]
        for control in controls:
            if not isinstance(control, dict):
                unresolved[risk_id].append("invalid control entry (non-object)")
                continue
            control_id = control.get("id")
            command = control.get("command")
            if not isinstance(control_id, str) or not control_id:
                unresolved[risk_id].append("control missing `id`")
                continue
            if not isinstance(command, str) or not command.strip():
                unresolved[risk_id].append(f"{control_id}: missing command")
                continue

            command_file = command_path(command)
            if command_file is not None and not command_file.exists():
                unresolved[risk_id].append(
                    f"{control_id}: command path missing ({command_file.relative_to(ROOT)})"
                )
                continue

            if args.run_controls:
                ok, output = run_command(command)
                if not ok:
                    short_output = output.splitlines()[:3]
                    suffix = " | ".join(line.strip() for line in short_output if line.strip())
                    message = f"{control_id}: command failed"
                    if suffix:
                        message = f"{message} ({suffix})"
                    unresolved[risk_id].append(message)

    if errors:
        for err in errors:
            print(err)
        print(f"risk control checks failed with {len(errors)} mapping error(s)")
        return 1

    unresolved_count = sum(len(v) for v in unresolved.values())
    if unresolved_count:
        print("unresolved controls by risk:")
        for risk_id in sorted(unresolved):
            items = unresolved[risk_id]
            if not items:
                continue
            print(f"- {risk_id} ({severities.get(risk_id, 'unknown')}):")
            for item in items:
                print(f"  - {item}")

        if args.fail_on_high_risk:
            has_high = any(
                severities.get(risk_id) == "high" and len(items) > 0
                for risk_id, items in unresolved.items()
            )
            if has_high:
                print("risk control checks failed: unresolved high-risk controls remain")
                return 1
            print("risk control checks passed: only non-high unresolved controls remain")
            return 0

        print("risk control checks failed: unresolved controls remain")
        return 1

    print("risk control checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
