#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_milestone_dependencies.py"
LOG_FILE="$(mktemp -t leancairo_milestone_deps_negative.XXXXXX.log)"

cleanup() {
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

if "$CHECKER" --validate-dag --extra-edge "M-01-1:M-01-3" >"$LOG_FILE" 2>&1; then
  echo "expected milestone checker to fail when cycle is introduced"
  exit 1
fi

if ! grep -q "cycle" "$LOG_FILE"; then
  echo "cycle injection failed without cycle diagnostic"
  cat "$LOG_FILE"
  exit 1
fi

if "$CHECKER" --extra-edge "E5:B2" >"$LOG_FILE" 2>&1; then
  echo "expected milestone checker to fail when done milestone depends on not-done milestone"
  exit 1
fi

if ! grep -q "dependency violation" "$LOG_FILE"; then
  echo "status-order injection failed without dependency diagnostic"
  cat "$LOG_FILE"
  exit 1
fi

echo "milestone dependency negative regression passed"
