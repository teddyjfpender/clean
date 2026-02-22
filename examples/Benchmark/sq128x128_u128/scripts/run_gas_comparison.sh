#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$BENCH_DIR/../../.." && pwd)"
OUT_DIR="$BENCH_DIR/.artifacts"
LOG_FILE="$OUT_DIR/snforge-gas.log"

mkdir -p "$OUT_DIR"

if ! command -v snforge >/dev/null 2>&1; then
  echo "error: snforge is required but not found on PATH" >&2
  exit 1
fi

if [[ "${SQ128_SKIP_UPSTREAM_PULL:-0}" != "1" ]]; then
  echo "[-/3] Refreshing upstream SQ128 baseline sources from main"
  "$ROOT_DIR/examples/Cairo-Baseline/sq128x128_u128/scripts/pull_upstream_sq128.sh" \
    "$ROOT_DIR/examples/Cairo-Baseline/sq128x128_u128/.artifacts/upstream-sq128-main"
fi

echo "[0/3] Syncing generated and upstream baseline function sources"
"$BENCH_DIR/scripts/sync_sources.sh"

echo "[1/3] Running gas benchmark tests"
(
  cd "$BENCH_DIR"
  snforge test test_gas_ --gas-report --detailed-resources --max-n-steps 200000000
) | tee "$LOG_FILE"

echo "[2/3] Comparing baseline vs generated gas"
python3 - "$LOG_FILE" <<'PY'
import re
import sys
from pathlib import Path

log_path = Path(sys.argv[1])
lines = log_path.read_text(encoding="utf-8").splitlines()

pass_pattern = re.compile(r"^\[PASS\]\s+(\S+)\s+\(.*l2_gas:\s*~([0-9,]+)\)")
sierra_pattern = re.compile(r"^\s*sierra gas:\s*([0-9,]+)")

baseline_prefix = "test_gas_baseline_"
generated_prefix = "test_gas_generated_"

results = {}

current_lane = None
current_side = None

for line in lines:
    pass_match = pass_pattern.search(line)
    if pass_match:
        test_name = pass_match.group(1)
        short_name = test_name.split("::")[-1]
        l2_gas = int(pass_match.group(2).replace(",", ""))

        current_lane = None
        current_side = None

        if short_name.startswith(baseline_prefix):
            current_lane = short_name[len(baseline_prefix):]
            current_side = "baseline"
        elif short_name.startswith(generated_prefix):
            current_lane = short_name[len(generated_prefix):]
            current_side = "generated"

        if current_lane is not None:
            lane = results.setdefault(current_lane, {"baseline": {}, "generated": {}})
            lane[current_side]["l2_gas"] = l2_gas
        continue

    if current_lane is not None and current_side is not None:
        sierra_match = sierra_pattern.search(line)
        if sierra_match:
            lane = results[current_lane]
            lane[current_side]["sierra_gas"] = int(sierra_match.group(1).replace(",", ""))
            current_lane = None
            current_side = None

if not results:
    print("error: no benchmark tests matched baseline/generated naming convention", file=sys.stderr)
    sys.exit(1)

missing = []
for lane_name, lane in sorted(results.items()):
    for side in ("baseline", "generated"):
        payload = lane[side]
        if "l2_gas" not in payload or "sierra_gas" not in payload:
            missing.append(f"{lane_name}:{side}")

if missing:
    print(f"error: failed to parse complete gas rows for: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)


def pct_improvement(hand: int, opt: int) -> float:
    if hand <= 0:
        raise ValueError("baseline gas must be > 0 for improvement calculation")
    return ((hand - opt) / hand) * 100.0

print("lane,baseline_sierra,generated_sierra,sierra_improvement_pct,baseline_l2,generated_l2,l2_improvement_pct")

baseline_sierra_total = 0
generated_sierra_total = 0
baseline_l2_total = 0
generated_l2_total = 0

for lane_name, lane in sorted(results.items()):
    baseline_sierra = lane["baseline"]["sierra_gas"]
    generated_sierra = lane["generated"]["sierra_gas"]
    baseline_l2 = lane["baseline"]["l2_gas"]
    generated_l2 = lane["generated"]["l2_gas"]

    print(
        f"{lane_name},{baseline_sierra},{generated_sierra},{pct_improvement(baseline_sierra, generated_sierra):.2f},"
        f"{baseline_l2},{generated_l2},{pct_improvement(baseline_l2, generated_l2):.2f}"
    )

    if generated_sierra > baseline_sierra:
        print(
            f"error: sierra gas regression in {lane_name} (generated={generated_sierra} baseline={baseline_sierra})",
            file=sys.stderr,
        )
        sys.exit(1)

    if generated_l2 > baseline_l2:
        print(
            f"error: l2 gas regression in {lane_name} (generated={generated_l2} baseline={baseline_l2})",
            file=sys.stderr,
        )
        sys.exit(1)

    baseline_sierra_total += baseline_sierra
    generated_sierra_total += generated_sierra
    baseline_l2_total += baseline_l2
    generated_l2_total += generated_l2

print("baseline_sierra_gas=", baseline_sierra_total)
print("generated_sierra_gas=", generated_sierra_total)
print("baseline_l2_gas=", baseline_l2_total)
print("generated_l2_gas=", generated_l2_total)
print("sierra_improvement_pct=", f"{pct_improvement(baseline_sierra_total, generated_sierra_total):.2f}")
print("l2_improvement_pct=", f"{pct_improvement(baseline_l2_total, generated_l2_total):.2f}")

print("gas comparison passed: generated <= baseline for both Sierra and L2 gas across all lanes")
PY

echo "saved: $LOG_FILE"
