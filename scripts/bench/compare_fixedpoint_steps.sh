#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$ROOT_DIR/packages/fixedpoint_bench"
OUT_DIR="$ROOT_DIR/.artifacts/bench/fixedpoint_steps"
LOG_DIR="$OUT_DIR/logs"
SUMMARY_FILE="$OUT_DIR/summary.csv"

mkdir -p "$LOG_DIR"

if ! command -v scarb >/dev/null 2>&1; then
  echo "error: scarb is required but not found on PATH" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required but not found on PATH" >&2
  exit 1
fi

if [[ ! -f "$PKG_DIR/Scarb.toml" ]]; then
  echo "error: benchmark package not found at $PKG_DIR" >&2
  exit 1
fi

echo "[1/4] Generating benchmark package source"
"$ROOT_DIR/scripts/bench/generate_fixedpoint_bench.sh"

echo "[2/4] Running equivalence tests (hand vs optimized outputs)"
(
  cd "$PKG_DIR"
  scarb test
)

extract_steps() {
  local log_file="$1"
  awk '
    match($0, /steps:[[:space:]]*[0-9,]+/) {
      s = substr($0, RSTART, RLENGTH)
      sub(/steps:[[:space:]]*/, "", s)
      gsub(/,/, "", s)
      print s
      exit
    }
  ' "$log_file"
}

run_exec() {
  local executable="$1"
  local log_file="$LOG_DIR/${executable}.log"

  if [[ -d "$PKG_DIR/target/execute/fixedpoint_bench" ]]; then
    rm -r "$PKG_DIR/target/execute/fixedpoint_bench"
  fi
  (
    cd "$PKG_DIR"
    scarb execute --executable-name "$executable" --print-resource-usage
  ) >"$log_file" 2>&1

  local steps
  steps="$(extract_steps "$log_file")"
  if [[ -z "$steps" ]]; then
    echo "error: failed to extract step count from $log_file" >&2
    exit 1
  fi
  printf '%s\n' "$steps"
}

echo "[3/4] Running step benchmarks"

qmul_hand="$(run_exec bench_qmul_hand)"
qmul_opt="$(run_exec bench_qmul_opt)"
qexp_hand="$(run_exec bench_qexp_hand)"
qexp_opt="$(run_exec bench_qexp_opt)"
qlog_hand="$(run_exec bench_qlog_hand)"
qlog_opt="$(run_exec bench_qlog_opt)"
qnewton_hand="$(run_exec bench_qnewton_hand)"
qnewton_opt="$(run_exec bench_qnewton_opt)"
fib_naive="$(run_exec bench_fib_naive)"
fib_fast="$(run_exec bench_fib_fast)"

cat >"$SUMMARY_FILE" <<EOF
kernel,hand_steps,opt_steps
qmul,$qmul_hand,$qmul_opt
qexp,$qexp_hand,$qexp_opt
qlog,$qlog_hand,$qlog_opt
qnewton,$qnewton_hand,$qnewton_opt
fib,$fib_naive,$fib_fast
EOF

echo "[4/4] Summary"
python3 - "$SUMMARY_FILE" <<'PY'
import csv
import sys

summary_file = sys.argv[1]

rows = []
with open(summary_file, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        hand = int(row["hand_steps"])
        opt = int(row["opt_steps"])
        delta = hand - opt
        pct = (delta / hand) * 100.0
        speedup = hand / opt
        rows.append((row["kernel"], hand, opt, delta, pct, speedup))

print("kernel hand_steps opt_steps delta improvement_pct speedup")
for kernel, hand, opt, delta, pct, speedup in rows:
    print(f"{kernel} {hand} {opt} {delta} {pct:.2f} {speedup:.2f}")
PY

echo "saved: $SUMMARY_FILE"
