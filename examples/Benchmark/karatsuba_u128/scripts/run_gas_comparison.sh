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

echo "[0/2] Syncing generated and baseline function sources"
"$BENCH_DIR/scripts/sync_sources.sh"

echo "[1/2] Running gas benchmark tests"
(
  cd "$BENCH_DIR"
  snforge test test_gas_ --gas-report --detailed-resources --max-n-steps 200000000
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

results = {
    "baseline": {"test": "test_gas_baseline_function_case", "l2_gas": None, "sierra_gas": None},
    "generated": {"test": "test_gas_generated_function_case", "l2_gas": None, "sierra_gas": None},
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

missing = [
    key for key, payload in results.items()
    if payload["l2_gas"] is None or payload["sierra_gas"] is None
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

def pct_improvement(hand: int, opt: int) -> float:
    return ((hand - opt) / hand) * 100.0

print("baseline_sierra_gas=", baseline_sierra)
print("generated_sierra_gas=", generated_sierra)
print("baseline_l2_gas=", baseline_l2)
print("generated_l2_gas=", generated_l2)
print("sierra_improvement_pct=", f"{pct_improvement(baseline_sierra, generated_sierra):.2f}")
print("l2_improvement_pct=", f"{pct_improvement(baseline_l2, generated_l2):.2f}")

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
