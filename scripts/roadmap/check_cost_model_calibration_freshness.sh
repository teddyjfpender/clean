#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUMMARY_REL="generated/examples/benchmark-summary.json"
OUT_JSON_REL="generated/examples/cost-model-calibration.json"
OUT_MD_REL="generated/examples/cost-model-calibration.md"
THRESHOLDS_REL="roadmap/reports/cost-model-calibration-thresholds.json"

(
  cd "$ROOT_DIR"
  python3 scripts/bench/generate_cost_model_calibration.py \
    --summary "$SUMMARY_REL" \
    --out-json "$OUT_JSON_REL" \
    --out-md "$OUT_MD_REL"
  python3 scripts/bench/check_cost_model_calibration_thresholds.py \
    --calibration "$OUT_JSON_REL" \
    --thresholds "$THRESHOLDS_REL"
  git diff --exit-code "$OUT_JSON_REL" "$OUT_MD_REL"
)

echo "cost model calibration freshness checks passed"
