#!/usr/bin/env python3
"""Validate proof-debt policy constraints against capability support state."""

from __future__ import annotations

import argparse
import json
from datetime import date
from pathlib import Path
from typing import Dict, List, Set

ALLOWED_STATUS = {"open", "closed"}
ALLOWED_SEVERITY = {"low", "medium", "high"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check proof debt policy")
    parser.add_argument("--registry", required=True)
    parser.add_argument("--debt", required=True)
    parser.add_argument(
        "--today",
        default="",
        help="ISO date override for deterministic tests (YYYY-MM-DD)",
    )
    return parser.parse_args()


def load_json(path: Path) -> Dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: top-level must be object")
    return payload


def parse_date(value: str, ctx: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise ValueError(f"{ctx}: invalid ISO date '{value}'") from exc


def parse_registry(registry_path: Path) -> Dict[str, str]:
    payload = load_json(registry_path)
    caps = payload.get("capabilities")
    if not isinstance(caps, list):
        raise ValueError(f"{registry_path}: capabilities must be list")

    statuses: Dict[str, str] = {}
    for idx, cap in enumerate(caps):
        ctx = f"{registry_path}: capabilities[{idx}]"
        if not isinstance(cap, dict):
            raise ValueError(f"{ctx}: expected object")
        cap_id = cap.get("capability_id")
        if not isinstance(cap_id, str) or not cap_id.strip():
            raise ValueError(f"{ctx}: missing non-empty capability_id")
        support = cap.get("support_state")
        if not isinstance(support, dict):
            raise ValueError(f"{ctx}: missing support_state")
        overall = support.get("overall")
        if not isinstance(overall, str) or not overall.strip():
            raise ValueError(f"{ctx}: missing support_state.overall")
        statuses[cap_id.strip()] = overall.strip()
    return statuses


def main() -> int:
    args = parse_args()
    registry_path = Path(args.registry).resolve()
    debt_path = Path(args.debt).resolve()

    today = parse_date(args.today, "--today") if args.today else date.today()
    cap_status = parse_registry(registry_path)

    payload = load_json(debt_path)
    version = payload.get("version")
    if version != 2:
        raise SystemExit(f"{debt_path}: version must be 2")

    entries = payload.get("entries")
    if not isinstance(entries, list):
        raise SystemExit(f"{debt_path}: entries must be a list")

    errors: List[str] = []
    seen_ids: Set[str] = set()

    for idx, entry in enumerate(entries):
        ctx = f"{debt_path}: entries[{idx}]"
        if not isinstance(entry, dict):
            errors.append(f"{ctx}: expected object")
            continue

        required = {
            "id",
            "capability_id",
            "summary",
            "status",
            "severity",
            "opened_on",
            "expires_on",
            "mandatory_block",
        }
        missing = sorted(required.difference(entry.keys()))
        if missing:
            errors.append(f"{ctx}: missing keys: {', '.join(missing)}")
            continue

        debt_id = entry["id"]
        if not isinstance(debt_id, str) or not debt_id.strip():
            errors.append(f"{ctx}.id: expected non-empty string")
            continue
        debt_id = debt_id.strip()
        if debt_id in seen_ids:
            errors.append(f"{ctx}: duplicate id '{debt_id}'")
        seen_ids.add(debt_id)

        cap_id = entry["capability_id"]
        if not isinstance(cap_id, str) or not cap_id.strip():
            errors.append(f"{ctx}.capability_id: expected non-empty string")
            continue
        cap_id = cap_id.strip()
        if cap_id not in cap_status:
            errors.append(f"{ctx}.capability_id: unknown capability '{cap_id}'")

        summary = entry["summary"]
        if not isinstance(summary, str) or not summary.strip():
            errors.append(f"{ctx}.summary: expected non-empty string")

        status = entry["status"]
        if status not in ALLOWED_STATUS:
            errors.append(f"{ctx}.status: invalid value '{status}'")
            continue

        severity = entry["severity"]
        if severity not in ALLOWED_SEVERITY:
            errors.append(f"{ctx}.severity: invalid value '{severity}'")

        opened_on_raw = entry["opened_on"]
        expires_on_raw = entry["expires_on"]
        if not isinstance(opened_on_raw, str) or not opened_on_raw.strip():
            errors.append(f"{ctx}.opened_on: expected ISO date string")
            continue
        if not isinstance(expires_on_raw, str) or not expires_on_raw.strip():
            errors.append(f"{ctx}.expires_on: expected ISO date string")
            continue

        try:
            opened_on = parse_date(opened_on_raw.strip(), f"{ctx}.opened_on")
            expires_on = parse_date(expires_on_raw.strip(), f"{ctx}.expires_on")
        except ValueError as exc:
            errors.append(str(exc))
            continue

        if expires_on < opened_on:
            errors.append(f"{ctx}: expires_on must be >= opened_on")

        mandatory_block = entry["mandatory_block"]
        if not isinstance(mandatory_block, bool):
            errors.append(f"{ctx}.mandatory_block: expected boolean")

        resolved_on_raw = entry.get("resolved_on")
        resolved_on = None
        if resolved_on_raw is not None:
            if not isinstance(resolved_on_raw, str) or not resolved_on_raw.strip():
                errors.append(f"{ctx}.resolved_on: expected ISO date string or null")
            else:
                try:
                    resolved_on = parse_date(resolved_on_raw.strip(), f"{ctx}.resolved_on")
                except ValueError as exc:
                    errors.append(str(exc))

        if status == "open":
            if resolved_on is not None:
                errors.append(f"{ctx}: open debt entry cannot define resolved_on")
            if expires_on < today:
                errors.append(f"{ctx}: open debt entry is expired ({expires_on.isoformat()} < {today.isoformat()})")
            if mandatory_block and cap_status.get(cap_id) == "implemented":
                errors.append(
                    f"{ctx}: open mandatory debt blocks implemented capability '{cap_id}'"
                )
        else:
            if resolved_on is None:
                errors.append(f"{ctx}: closed debt entry must define resolved_on")
            else:
                if resolved_on < opened_on:
                    errors.append(f"{ctx}: resolved_on must be >= opened_on")

    if errors:
        for err in errors:
            print(err)
        print(f"proof debt policy checks failed with {len(errors)} error(s)")
        return 1

    print(
        "proof debt policy checks passed "
        f"({len(entries)} entries, today={today.isoformat()})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
