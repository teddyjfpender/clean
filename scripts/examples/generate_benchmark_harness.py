#!/usr/bin/env python3
"""Generate deterministic benchmark harness artifacts from examples manifest."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate manifest benchmark harness")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--out-config", required=True)
    parser.add_argument("--out-script", required=True)
    return parser.parse_args()


def validate_manifest(root: Path, manifest: Path) -> None:
    validator = root / "scripts" / "examples" / "validate_examples_manifest.py"
    subprocess.run(
        ["python3", str(validator), "--manifest", str(manifest)],
        check=True,
        cwd=root,
    )


def load_cases(manifest: Path) -> Tuple[List[Dict[str, object]], List[Dict[str, object]]]:
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    examples = payload.get("examples", [])
    if not isinstance(examples, list):
        raise ValueError(f"invalid examples list in manifest: {manifest}")

    cases: List[Dict[str, object]] = []
    thresholds_by_family: Dict[str, Tuple[float, float]] = {}

    for entry in examples:
        if not isinstance(entry, dict):
            continue
        example_id = str(entry.get("id", "")).strip()
        benchmark = entry.get("benchmark", {})
        if not example_id or not isinstance(benchmark, dict):
            continue
        if benchmark.get("kind") != "gas_script":
            continue

        family = str(benchmark.get("family", "")).strip()
        runner_script = str(benchmark.get("runner_script", "")).strip()
        min_sierra = float(benchmark.get("min_sierra_improvement_pct", 0.0))
        min_l2 = float(benchmark.get("min_l2_improvement_pct", 0.0))

        cases.append(
            {
                "id": example_id,
                "family": family,
                "runner_script": runner_script,
                "min_sierra_improvement_pct": min_sierra,
                "min_l2_improvement_pct": min_l2,
            }
        )

        prev = thresholds_by_family.get(family)
        if prev is None:
            thresholds_by_family[family] = (min_sierra, min_l2)
        else:
            thresholds_by_family[family] = (
                max(prev[0], min_sierra),
                max(prev[1], min_l2),
            )

    cases = sorted(cases, key=lambda row: str(row["id"]))
    family_thresholds = [
        {
            "family": family,
            "min_sierra_improvement_pct": values[0],
            "min_l2_improvement_pct": values[1],
        }
        for family, values in sorted(thresholds_by_family.items())
    ]
    return cases, family_thresholds


def render_script(config_file_expr: str) -> str:
    return (
        "#!/usr/bin/env bash\n"
        "set -euo pipefail\n\n"
        "ROOT_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")/../../..\" && pwd)\"\n"
        f"CONFIG_FILE=\"{config_file_expr}\"\n"
        "OUT_JSON=\"$ROOT_DIR/generated/examples/benchmark-summary.json\"\n"
        "OUT_MD=\"$ROOT_DIR/generated/examples/benchmark-summary.md\"\n"
        "LOGS_DIR=\"$ROOT_DIR/.artifacts/manifest_benchmark\"\n\n"
        "python3 \"$ROOT_DIR/scripts/bench/run_manifest_benchmark_suite.py\" \\\n"
        "  --config \"$CONFIG_FILE\" \\\n"
        "  --out-json \"$OUT_JSON\" \\\n"
        "  --out-md \"$OUT_MD\" \\\n"
        "  --logs-dir \"$LOGS_DIR\"\n\n"
        "python3 \"$ROOT_DIR/scripts/bench/check_manifest_benchmark_thresholds.py\" \\\n"
        "  --config \"$CONFIG_FILE\" \\\n"
        "  --summary \"$OUT_JSON\"\n\n"
        "echo \"manifest benchmark harness checks passed\"\n"
    )


def main() -> int:
    args = parse_args()
    manifest = Path(args.manifest).resolve()
    out_config = Path(args.out_config).resolve()
    out_script = Path(args.out_script).resolve()
    root = Path(__file__).resolve().parents[2]

    if not manifest.is_file():
        raise SystemExit(f"missing manifest: {manifest}")

    validate_manifest(root, manifest)
    cases, family_thresholds = load_cases(manifest)
    if not cases:
        raise SystemExit("manifest benchmark harness requires at least one gas_script case")

    config_payload = {
        "version": 1,
        "manifest": str(manifest.relative_to(root)),
        "cases": cases,
        "family_thresholds": family_thresholds,
    }
    out_config.parent.mkdir(parents=True, exist_ok=True)
    out_config.write_text(json.dumps(config_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    try:
        out_script_rel = str(out_config.relative_to(root))
        config_file_expr = f"$ROOT_DIR/{out_script_rel}"
    except ValueError:
        config_file_expr = str(out_config)
    out_script.parent.mkdir(parents=True, exist_ok=True)
    out_script.write_text(render_script(config_file_expr), encoding="utf-8")
    out_script.chmod(0o755)

    print(f"wrote: {out_config}")
    print(f"wrote: {out_script}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
