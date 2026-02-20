#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if "$ROOT_DIR/scripts/roadmap/check_risk_controls.sh" --run-controls --fail-on-high-risk >/dev/null 2>&1; then
  echo "expected risk controls high-risk gate to fail while primary closure is unresolved"
  exit 1
fi

echo "release risk gate negative check passed"
