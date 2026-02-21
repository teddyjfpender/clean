#!/usr/bin/env python3
"""Project capability registry into deterministic JSON/Markdown reports."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List

STATES = ["implemented", "fail_fast", "planned"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Project capability coverage reports")
    parser.add_argument("--registry", required=True)
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--out-md", required=True)
    return parser.parse_args()


def load_registry(path: Path) -> Dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def ratio(numerator: int, denominator: int) -> float:
    if denominator <= 0:
        return 0.0
    return round(numerator / denominator, 6)


def summarize(capabilities: List[Dict[str, object]]) -> Dict[str, object]:
    total = len(capabilities)
    overall_counter = Counter()
    sierra_counter = Counter()
    cairo_counter = Counter()
    proof_counter = Counter()
    family_buckets = defaultdict(lambda: {
        "total": 0,
        "overall": Counter(),
        "sierra": Counter(),
        "cairo": Counter(),
    })

    implemented_ids: List[str] = []
    fail_fast_ids: List[str] = []
    planned_ids: List[str] = []
    capability_rows: List[Dict[str, object]] = []
    divergence_ids: List[str] = []

    for cap in capabilities:
        cap_id = str(cap["capability_id"])
        family = str(cap["family_group"])
        support = cap["support_state"]
        overall = str(support["overall"])
        sierra = str(support["sierra"])
        cairo = str(support["cairo"])
        proof_status = str(cap["proof_status"])
        divergence_constraints_raw = cap.get("divergence_constraints", [])
        divergence_constraints = (
            [str(item) for item in divergence_constraints_raw if isinstance(item, str)]
            if isinstance(divergence_constraints_raw, list)
            else []
        )

        overall_counter[overall] += 1
        sierra_counter[sierra] += 1
        cairo_counter[cairo] += 1
        proof_counter[proof_status] += 1

        bucket = family_buckets[family]
        bucket["total"] += 1
        bucket["overall"][overall] += 1
        bucket["sierra"][sierra] += 1
        bucket["cairo"][cairo] += 1

        if overall == "implemented":
            implemented_ids.append(cap_id)
        elif overall == "fail_fast":
            fail_fast_ids.append(cap_id)
        else:
            planned_ids.append(cap_id)

        diverges = sierra != cairo
        if diverges:
            divergence_ids.append(cap_id)
        capability_rows.append(
            {
                "capability_id": cap_id,
                "family_group": family,
                "support_state": {
                    "overall": overall,
                    "sierra": sierra,
                    "cairo": cairo,
                },
                "diverges": diverges,
                "divergence_constraints": sorted(set(divergence_constraints)),
            }
        )

    families = {}
    for family in sorted(family_buckets.keys()):
        bucket = family_buckets[family]
        family_total = bucket["total"]
        family_overall_implemented = bucket["overall"]["implemented"]
        family_sierra_implemented = bucket["sierra"]["implemented"]
        family_cairo_implemented = bucket["cairo"]["implemented"]
        families[family] = {
            "total": family_total,
            "overall": {state: bucket["overall"][state] for state in STATES},
            "sierra": {state: bucket["sierra"][state] for state in STATES},
            "cairo": {state: bucket["cairo"][state] for state in STATES},
            "closure_ratios": {
                "overall_implemented_ratio": ratio(family_overall_implemented, family_total),
                "sierra_implemented_ratio": ratio(family_sierra_implemented, family_total),
                "cairo_implemented_ratio": ratio(family_cairo_implemented, family_total),
            },
        }

    overall_implemented = overall_counter["implemented"]
    sierra_implemented = sierra_counter["implemented"]
    cairo_implemented = cairo_counter["implemented"]

    return {
        "version": 1,
        "total_capabilities": total,
        "overall_status_counts": {state: overall_counter[state] for state in STATES},
        "sierra_status_counts": {state: sierra_counter[state] for state in STATES},
        "cairo_status_counts": {state: cairo_counter[state] for state in STATES},
        "closure_ratios": {
            "overall_implemented_ratio": ratio(overall_implemented, total),
            "sierra_implemented_ratio": ratio(sierra_implemented, total),
            "cairo_implemented_ratio": ratio(cairo_implemented, total),
        },
        "proof_status_counts": {
            "complete": proof_counter["complete"],
            "partial": proof_counter["partial"],
            "planned": proof_counter["planned"],
        },
        "families": families,
        "implemented_capability_ids": sorted(implemented_ids),
        "fail_fast_capability_ids": sorted(fail_fast_ids),
        "planned_capability_ids": sorted(planned_ids),
        "backend_divergence_count": len(set(divergence_ids)),
        "backend_divergence_capability_ids": sorted(set(divergence_ids)),
        "capability_status_rows": capability_rows,
    }


def render_markdown(summary: Dict[str, object], registry_rel: str) -> str:
    lines: List[str] = []
    lines.append("# Capability Coverage Report")
    lines.append("")
    lines.append(f"Source registry: `{registry_rel}`")
    lines.append("")

    lines.append("## Totals")
    lines.append("")
    lines.append(f"- Total capabilities: `{summary['total_capabilities']}`")
    for key in ("overall_status_counts", "sierra_status_counts", "cairo_status_counts"):
        counts = summary[key]
        lines.append(
            f"- {key}: `implemented={counts['implemented']}`, `fail_fast={counts['fail_fast']}`, `planned={counts['planned']}`"
        )
    proof = summary["proof_status_counts"]
    lines.append(
        f"- proof_status_counts: `complete={proof['complete']}`, `partial={proof['partial']}`, `planned={proof['planned']}`"
    )
    closure = summary["closure_ratios"]
    lines.append(
        f"- closure_ratios: `overall={closure['overall_implemented_ratio']}`, `sierra={closure['sierra_implemented_ratio']}`, `cairo={closure['cairo_implemented_ratio']}`"
    )
    lines.append("")

    lines.append("## Family Matrix")
    lines.append("")
    lines.append("| Family | Total | Overall implemented | Overall fail_fast | Overall planned |")
    lines.append("| --- | ---: | ---: | ---: | ---: |")
    for family, bucket in summary["families"].items():
        overall = bucket["overall"]
        lines.append(
            f"| `{family}` | {bucket['total']} | {overall['implemented']} | {overall['fail_fast']} | {overall['planned']} |"
        )
    lines.append("")

    lines.append("## Family Closure Ratios")
    lines.append("")
    lines.append("| Family | Overall implemented ratio | Sierra implemented ratio | Cairo implemented ratio |")
    lines.append("| --- | ---: | ---: | ---: |")
    for family, bucket in summary["families"].items():
        closure = bucket["closure_ratios"]
        lines.append(
            f"| `{family}` | {closure['overall_implemented_ratio']} | {closure['sierra_implemented_ratio']} | {closure['cairo_implemented_ratio']} |"
        )
    lines.append("")

    lines.append("## Capability State Matrix")
    lines.append("")
    lines.append("| Capability ID | Family | Overall | Sierra | Cairo | Diverges | Divergence constraints |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- |")
    for row in summary["capability_status_rows"]:
        support = row["support_state"]
        constraints = row["divergence_constraints"]
        constraint_text = "; ".join(constraints) if constraints else "none"
        diverges_text = "true" if row["diverges"] else "false"
        lines.append(
            f"| `{row['capability_id']}` | `{row['family_group']}` | `{support['overall']}` | `{support['sierra']}` | `{support['cairo']}` | `{diverges_text}` | {constraint_text} |"
        )
    lines.append("")

    lines.append("## Capability IDs")
    lines.append("")
    for key in (
        "implemented_capability_ids",
        "fail_fast_capability_ids",
        "planned_capability_ids",
    ):
        lines.append(f"### {key}")
        ids = summary[key]
        if not ids:
            lines.append("- (none)")
        else:
            for cap_id in ids:
                lines.append(f"- `{cap_id}`")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def write_json(path: Path, payload: Dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def main() -> int:
    args = parse_args()
    registry_path = Path(args.registry)
    out_json = Path(args.out_json)
    out_md = Path(args.out_md)

    payload = load_registry(registry_path)
    capabilities = payload.get("capabilities", [])
    if not isinstance(capabilities, list):
        raise SystemExit(f"invalid registry capabilities list: {registry_path}")

    capabilities_sorted = sorted(capabilities, key=lambda cap: str(cap.get("capability_id", "")))
    summary = summarize(capabilities_sorted)

    write_json(out_json, summary)
    md = render_markdown(summary, str(registry_path))
    write_text(out_md, md)

    print(f"wrote: {out_json}")
    print(f"wrote: {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
