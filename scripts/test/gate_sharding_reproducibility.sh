#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

for shard_index in 0 1; do
  "$ROOT_DIR/scripts/workflow/run-gates-sharded.sh" \
    --manifest config/gate-manifest.json \
    --shard-index "$shard_index" \
    --shard-count 2 \
    --report "$TMP_A/shard-${shard_index}.json" \
    --dry-run
  "$ROOT_DIR/scripts/workflow/run-gates-sharded.sh" \
    --manifest config/gate-manifest.json \
    --shard-index "$shard_index" \
    --shard-count 2 \
    --report "$TMP_B/shard-${shard_index}.json" \
    --dry-run
  diff -u "$TMP_A/shard-${shard_index}.json" "$TMP_B/shard-${shard_index}.json" >/dev/null

done

echo "gate sharding reproducibility checks passed"
