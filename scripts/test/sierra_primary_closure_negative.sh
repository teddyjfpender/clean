#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if "$ROOT_DIR/scripts/roadmap/check_sierra_primary_closure.sh" >/dev/null 2>&1; then
  echo "expected primary closure gate to fail while non-Starknet closure is incomplete"
  exit 1
fi

echo "primary closure negative gate passed"
