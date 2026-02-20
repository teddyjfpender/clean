#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_proof_obligations.sh"
LOG_FILE="$(mktemp -t leancairo_proof_obligations_negative.XXXXXX.log)"

cleanup() {
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

if "$CHECKER" --require-theorem "__simulated_missing_theorem__" >"$LOG_FILE" 2>&1; then
  echo "expected proof obligation checker to fail for simulated missing theorem"
  exit 1
fi

if ! grep -q "__simulated_missing_theorem__" "$LOG_FILE"; then
  echo "proof obligation checker failed, but missing-theorem diagnostic was not reported"
  cat "$LOG_FILE"
  exit 1
fi

echo "proof obligation negative regression passed"
