#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAILFAST_GATE="$ROOT_DIR/scripts/test/sierra_failfast_unsupported.sh"

REQUIRED_FIXTURES=(
  "$ROOT_DIR/src/MyLeanSierraSubsetUnsupportedU128Arith.lean"
  "$ROOT_DIR/src/MyLeanSierraSubsetUnsupportedU256Sig.lean"
  "$ROOT_DIR/src/MyLeanSierraSubsetUnsupportedDictSig.lean"
)

REQUIRED_WORKFLOWS=(
  "$ROOT_DIR/scripts/workflow/run-sierra-checks.sh"
  "$ROOT_DIR/scripts/workflow/run-mvp-checks.sh"
)

if [[ ! -x "$FAILFAST_GATE" ]]; then
  echo "missing executable fail-fast gate script: $FAILFAST_GATE"
  exit 1
fi

for fixture in "${REQUIRED_FIXTURES[@]}"; do
  if [[ ! -f "$fixture" ]]; then
    echo "missing canonical fail-fast fixture: $fixture"
    exit 1
  fi
done

for workflow in "${REQUIRED_WORKFLOWS[@]}"; do
  if [[ ! -f "$workflow" ]]; then
    echo "missing workflow script: $workflow"
    exit 1
  fi
  if ! grep -Fq "check_failfast_policy_lock.sh" "$workflow"; then
    echo "workflow missing locked fail-fast policy gate call: $workflow"
    exit 1
  fi
done

"$FAILFAST_GATE"

echo "fail-fast policy lock checks passed"
