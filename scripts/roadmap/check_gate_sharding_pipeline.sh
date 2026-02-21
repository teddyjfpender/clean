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
  --out "$TMP_DIR/aggregate.json" \
  "$TMP_DIR/shard-0.json" "$TMP_DIR/shard-1.json"

python3 - "$TMP_DIR/aggregate.json" "$ROOT_DIR/config/gate-manifest.json" <<'PY'
import json
import sys
from pathlib import Path

aggregate = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
manifest = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))

expected = len(manifest.get('mandatory_gates', []))
actual = int(aggregate.get('gate_count', 0))
if actual != expected:
    raise SystemExit(f"aggregate gate count mismatch: actual={actual} expected={expected}")
if aggregate.get('failure_count') != 0:
    raise SystemExit(f"expected zero failures in dry-run aggregate: {aggregate.get('failure_count')}")
print("gate sharding pipeline checks passed")
PY
