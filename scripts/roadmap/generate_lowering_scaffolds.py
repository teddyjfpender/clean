#!/usr/bin/env python3
"""Generate deterministic backend lowering scaffold modules from capability registry."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate backend lowering scaffolds")
    parser.add_argument("--registry", required=True)
    parser.add_argument("--out-sierra", required=True)
    parser.add_argument("--out-cairo", required=True)
    return parser.parse_args()


def list_string_def(name: str, values: List[str]) -> str:
    lines = [f"def {name} : List String :=", "["]
    for value in values:
        lines.append(f'  "{value}",')
    lines.append("]")
    return "\n".join(lines)


def list_stub_def(name: str, values: List[Tuple[str, str]]) -> str:
    lines = [f"def {name} : List (String × String) :=", "["]
    for cap_id, message in values:
        lines.append(f'  ("{cap_id}", "{message}"),')
    lines.append("]")
    return "\n".join(lines)


def render_module(namespace: str, lane_label: str, implemented: List[str], stubs: List[Tuple[str, str]]) -> str:
    lane_prefix = lane_label.lower()
    implemented_def = f"{lane_prefix}LoweringImplementedCapabilityIds"
    stubs_def = f"{lane_prefix}LoweringFailFastStubs"
    lookup_def = f"{lane_prefix}LoweringLookupStubMessage"
    message_def = f"{lane_prefix}LoweringFailFastMessage"

    blocks = [
        f"namespace {namespace}",
        list_string_def(implemented_def, implemented),
        list_stub_def(stubs_def, stubs),
        (
            f"def {lookup_def} (capabilityId : String) : Option String :=\n"
            f"  ({stubs_def}.find? (fun entry => entry.fst = capabilityId)).map Prod.snd"
        ),
        (
            f"def {message_def} (capabilityId : String) : String :=\n"
            f"  match {lookup_def} capabilityId with\n"
            "  | some msg => msg\n"
            f"  | none => s!\"unsupported unregistered capability '{{capabilityId}}' in {lane_label} lowering scaffold\""
        ),
        f"end {namespace}",
    ]

    header = [
        "-- This file is generated. Do not edit manually.",
        "-- Regenerate with: python3 scripts/roadmap/generate_lowering_scaffolds.py ...",
        "",
    ]
    return "\n\n".join(header + blocks) + "\n"


def main() -> int:
    args = parse_args()
    registry = Path(args.registry)
    out_sierra = Path(args.out_sierra)
    out_cairo = Path(args.out_cairo)

    payload = json.loads(registry.read_text(encoding="utf-8"))
    capabilities = payload.get("capabilities", [])
    if not isinstance(capabilities, list):
        raise SystemExit(f"invalid capabilities list in registry: {registry}")

    sierra_implemented: List[str] = []
    sierra_stubs: List[Tuple[str, str]] = []
    cairo_implemented: List[str] = []
    cairo_stubs: List[Tuple[str, str]] = []

    for cap in capabilities:
        if not isinstance(cap, dict):
            continue
        cap_id = str(cap.get("capability_id", "")).strip()
        support = cap.get("support_state", {})
        if not cap_id or not isinstance(support, dict):
            continue

        sierra_state = str(support.get("sierra", "")).strip()
        cairo_state = str(support.get("cairo", "")).strip()

        if sierra_state == "implemented":
            sierra_implemented.append(cap_id)
        elif sierra_state in {"planned", "fail_fast"}:
            sierra_stubs.append(
                (
                    cap_id,
                    f"capability '{cap_id}' is not implemented for Sierra lowering (state: {sierra_state})",
                )
            )

        if cairo_state == "implemented":
            cairo_implemented.append(cap_id)
        elif cairo_state in {"planned", "fail_fast"}:
            cairo_stubs.append(
                (
                    cap_id,
                    f"capability '{cap_id}' is not implemented for Cairo lowering (state: {cairo_state})",
                )
            )

    sierra_implemented = sorted(set(sierra_implemented))
    sierra_stubs = sorted(set(sierra_stubs), key=lambda item: item[0])
    cairo_implemented = sorted(set(cairo_implemented))
    cairo_stubs = sorted(set(cairo_stubs), key=lambda item: item[0])

    sierra_module = render_module(
        "LeanCairo.Backend.Sierra.Generated",
        "Sierra",
        sierra_implemented,
        sierra_stubs,
    )
    cairo_module = render_module(
        "LeanCairo.Backend.Cairo.Generated",
        "Cairo",
        cairo_implemented,
        cairo_stubs,
    )

    out_sierra.parent.mkdir(parents=True, exist_ok=True)
    out_sierra.write_text(sierra_module, encoding="utf-8")
    out_cairo.parent.mkdir(parents=True, exist_ok=True)
    out_cairo.write_text(cairo_module, encoding="utf-8")

    print(f"wrote: {out_sierra}")
    print(f"wrote: {out_cairo}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
