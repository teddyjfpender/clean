#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for shard_index in 0 1; do
  "$ROOT_DIR/scripts/workflow/run-gates-sharded.sh" \
    --manifest config/gate-manifest.json \
    --shard-index "$shard_index" \
    --shard-count 2 \
    --report "$TMP_DIR/shard-${shard_index}.json" \
    --dry-run

done

python3 "$ROOT_DIR/scripts/workflow/aggregate_gate_shard_reports.py" \
  --out "$TMP_DIR/aggregate-a.json" \
  "$TMP_DIR/shard-0.json" "$TMP_DIR/shard-1.json"
python3 "$ROOT_DIR/scripts/workflow/aggregate_gate_shard_reports.py" \
  --out "$TMP_DIR/aggregate-b.json" \
  "$TMP_DIR/shard-0.json" "$TMP_DIR/shard-1.json"

diff -u "$TMP_DIR/aggregate-a.json" "$TMP_DIR/aggregate-b.json" >/dev/null

echo "gate shard aggregation reproducibility checks passed"
