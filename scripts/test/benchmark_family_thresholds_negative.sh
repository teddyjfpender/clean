#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CONFIG_FILE="$TMP_DIR/benchmark-harness.json"
SUMMARY_FILE="$TMP_DIR/benchmark-summary.json"

python3 "$ROOT_DIR/scripts/examples/generate_benchmark_harness.py" \
  --manifest "$ROOT_DIR/config/examples-manifest.json" \
  --out-config "$CONFIG_FILE" \
  --out-script "$TMP_DIR/run_manifest_benchmarks.sh" >/dev/null

python3 - "$CONFIG_FILE" "$SUMMARY_FILE" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
summary_path = Path(sys.argv[2])

cfg = json.loads(config_path.read_text(encoding="utf-8"))
for case in cfg.get("cases", []):
    case["min_sierra_improvement_pct"] = 1.0
    case["min_l2_improvement_pct"] = 1.0
for family in cfg.get("family_thresholds", []):
    family["min_sierra_improvement_pct"] = 1.0
    family["min_l2_improvement_pct"] = 1.0
config_path.write_text(json.dumps(cfg, indent=2, sort_keys=True) + "\n", encoding="utf-8")

cases = []
families = {}
for case in cfg.get("cases", []):
    case_id = case["id"]
    family = case["family"]
    row = {
        "id": case_id,
        "family": family,
        "runner_script": case["runner_script"],
        "log_file": f".artifacts/manifest_benchmark/{case_id}.log",
        "metrics": {
            "baseline_sierra_gas": 1000.0,
            "generated_sierra_gas": 1000.0,
            "baseline_l2_gas": 1000.0,
            "generated_l2_gas": 1000.0,
            "sierra_improvement_pct": 0.0,
            "l2_improvement_pct": 0.0,
            "baseline_fn_avg_gas": 0.0,
            "generated_fn_avg_gas": 0.0,
            "fn_improvement_pct": 0.0,
        },
    }
    cases.append(row)
    families.setdefault(family, []).append(row)

family_rows = []
for family, rows in sorted(families.items()):
    family_rows.append(
        {
            "family": family,
            "case_count": len(rows),
            "avg_sierra_improvement_pct": 0.0,
            "avg_l2_improvement_pct": 0.0,
        }
    )

summary = {
    "version": 1,
    "config": str(config_path),
    "case_count": len(cases),
    "cases": sorted(cases, key=lambda item: item["id"]),
    "families": family_rows,
}
summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/bench/check_manifest_benchmark_thresholds.py" \
  --config "$CONFIG_FILE" \
  --summary "$SUMMARY_FILE" >/dev/null 2>&1; then
  echo "expected manifest benchmark threshold checker to fail on synthetic regression"
  exit 1
fi

echo "benchmark family thresholds negative checks passed"
