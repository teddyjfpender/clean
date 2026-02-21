#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$BENCH_DIR/.artifacts"
LOG_FILE="$OUT_DIR/snforge-gas.log"

mkdir -p "$OUT_DIR"

if ! command -v snforge >/dev/null 2>&1; then
  echo "error: snforge is required but not found on PATH" >&2
  exit 1
fi

echo "[0/2] Syncing generated and baseline contract sources"
"$BENCH_DIR/scripts/sync_sources.sh"

echo "[1/2] Running gas benchmark tests"
(
  cd "$BENCH_DIR"
  snforge test test_gas_ --gas-report --detailed-resources --max-n-steps 50000000
) | tee "$LOG_FILE"

echo "[2/2] Comparing baseline vs generated gas"
python3 - "$LOG_FILE" <<'PY'
import re
import sys
from pathlib import Path

log_path = Path(sys.argv[1])
lines = log_path.read_text(encoding="utf-8").splitlines()

pass_pattern = re.compile(r"^\[PASS\]\s+(\S+)\s+\(.*l2_gas:\s*~([0-9,]+)\)")
sierra_pattern = re.compile(r"^\s*sierra gas:\s*([0-9,]+)")
generated_row_pattern = re.compile(
    r"^\|\s*newton_reciprocal_two_steps\s*\|\s*[0-9,]+\s*\|\s*[0-9,]+\s*\|\s*([0-9,]+)\s*\|\s*[^|]*\|\s*([0-9,]+)\s*\|"
)
baseline_row_pattern = re.compile(
    r"^\|\s*newton_reciprocal_two_steps_looped\s*\|\s*[0-9,]+\s*\|\s*[0-9,]+\s*\|\s*([0-9,]+)\s*\|\s*[^|]*\|\s*([0-9,]+)\s*\|"
)

results = {
    "baseline": {
        "test": "test_gas_baseline_contract_case",
        "l2_gas": None,
        "sierra_gas": None,
        "fn_avg_gas": None,
        "fn_calls": None,
    },
    "generated": {
        "test": "test_gas_generated_contract_case",
        "l2_gas": None,
        "sierra_gas": None,
        "fn_avg_gas": None,
        "fn_calls": None,
    },
}

current_key = None
for line in lines:
    pass_match = pass_pattern.search(line)
    if pass_match:
        test_name = pass_match.group(1)
        l2_gas = int(pass_match.group(2).replace(",", ""))
        current_key = None
        for key, payload in results.items():
            if payload["test"] in test_name:
                payload["l2_gas"] = l2_gas
                current_key = key
                break
        continue

    if current_key is not None:
        sierra_match = sierra_pattern.search(line)
        if sierra_match:
            results[current_key]["sierra_gas"] = int(sierra_match.group(1).replace(",", ""))
            current_key = None
            continue

    generated_row = generated_row_pattern.search(line)
    if generated_row:
        results["generated"]["fn_avg_gas"] = int(generated_row.group(1).replace(",", ""))
        results["generated"]["fn_calls"] = int(generated_row.group(2).replace(",", ""))
        continue

    baseline_row = baseline_row_pattern.search(line)
    if baseline_row:
        results["baseline"]["fn_avg_gas"] = int(baseline_row.group(1).replace(",", ""))
        results["baseline"]["fn_calls"] = int(baseline_row.group(2).replace(",", ""))
        continue

missing = [
    key for key, payload in results.items()
    if payload["l2_gas"] is None
    or payload["sierra_gas"] is None
    or payload["fn_avg_gas"] is None
    or payload["fn_calls"] is None
]
if missing:
    print(f"error: failed to parse complete gas rows for: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

baseline = results["baseline"]
generated = results["generated"]

baseline_sierra = baseline["sierra_gas"]
generated_sierra = generated["sierra_gas"]
baseline_l2 = baseline["l2_gas"]
generated_l2 = generated["l2_gas"]
baseline_fn_avg = baseline["fn_avg_gas"]
generated_fn_avg = generated["fn_avg_gas"]
baseline_calls = baseline["fn_calls"]
generated_calls = generated["fn_calls"]

def pct_improvement(hand: int, opt: int) -> float:
    return ((hand - opt) / hand) * 100.0

print("baseline_sierra_gas=", baseline_sierra)
print("generated_sierra_gas=", generated_sierra)
print("baseline_l2_gas=", baseline_l2)
print("generated_l2_gas=", generated_l2)
print("sierra_improvement_pct=", f"{pct_improvement(baseline_sierra, generated_sierra):.2f}")
print("l2_improvement_pct=", f"{pct_improvement(baseline_l2, generated_l2):.2f}")
print("baseline_fn_avg_gas=", baseline_fn_avg)
print("generated_fn_avg_gas=", generated_fn_avg)
print("baseline_fn_calls=", baseline_calls)
print("generated_fn_calls=", generated_calls)
print("fn_improvement_pct=", f"{pct_improvement(baseline_fn_avg, generated_fn_avg):.2f}")

baseline_fixed_overhead = baseline_sierra - baseline_fn_avg * baseline_calls
generated_fixed_overhead = generated_sierra - generated_fn_avg * generated_calls
print("baseline_fixed_overhead_estimate=", baseline_fixed_overhead)
print("generated_fixed_overhead_estimate=", generated_fixed_overhead)

if generated_sierra > baseline_sierra:
    print(
        f"error: sierra gas regression (generated={generated_sierra} baseline={baseline_sierra})",
        file=sys.stderr,
    )
    sys.exit(1)

if generated_l2 > baseline_l2:
    print(
        f"error: l2 gas regression (generated={generated_l2} baseline={baseline_l2})",
        file=sys.stderr,
    )
    sys.exit(1)

print("gas comparison passed: generated <= baseline for both Sierra and L2 gas")
PY

echo "saved: $LOG_FILE"
