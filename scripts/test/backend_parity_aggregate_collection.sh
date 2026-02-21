#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/test/run_backend_parity_case.sh" \
  MyLeanSierraAggregateCollectionParity \
  SierraAggregateCollectionParityContract \
  "aggregate-collection parity"

echo "aggregate/collection backend parity checks passed"
