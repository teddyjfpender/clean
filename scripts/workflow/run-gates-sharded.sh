#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/gate-manifest.json"
SHARD_INDEX=""
SHARD_COUNT=""
REPORT_PATH=""
DRY_RUN=0
RETRIES=0
TIMEOUT_SEC=0

usage() {
  cat <<USAGE
usage: $0 --shard-index <idx> --shard-count <count> --report <path> [--manifest <path>] [--dry-run] [--retries <n>] [--timeout-sec <n>]
USAGE
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --shard-index)
      SHARD_INDEX="${2:-}"
      shift 2
      ;;
    --shard-count)
      SHARD_COUNT="${2:-}"
      shift 2
      ;;
    --report)
      REPORT_PATH="${2:-}"
      shift 2
      ;;
    --manifest)
      MANIFEST_REL="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --retries)
      RETRIES="${2:-}"
      shift 2
      ;;
    --timeout-sec)
      TIMEOUT_SEC="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SHARD_INDEX" || -z "$SHARD_COUNT" || -z "$REPORT_PATH" ]]; then
  usage
  exit 1
fi

if ! [[ "$SHARD_INDEX" =~ ^[0-9]+$ ]] || ! [[ "$SHARD_COUNT" =~ ^[0-9]+$ ]]; then
  echo "shard index/count must be non-negative integers"
  exit 1
fi
if (( SHARD_COUNT <= 0 )); then
  echo "shard count must be > 0"
  exit 1
fi
if (( SHARD_INDEX >= SHARD_COUNT )); then
  echo "shard index must be < shard count"
  exit 1
fi
if ! [[ "$RETRIES" =~ ^[0-9]+$ ]]; then
  echo "retries must be a non-negative integer"
  exit 1
fi
if ! [[ "$TIMEOUT_SEC" =~ ^[0-9]+$ ]]; then
  echo "timeout-sec must be a non-negative integer"
  exit 1
fi

MANIFEST_PATH="$ROOT_DIR/$MANIFEST_REL"
if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "missing gate manifest: $MANIFEST_REL"
  exit 1
fi

mapfile_output=$(python3 - "$MANIFEST_PATH" "$SHARD_INDEX" "$SHARD_COUNT" <<'PY'
import json
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
shard_index = int(sys.argv[2])
shard_count = int(sys.argv[3])

payload = json.loads(manifest.read_text(encoding='utf-8'))
gates = payload.get('mandatory_gates', [])
if not isinstance(gates, list):
    raise SystemExit('invalid mandatory_gates list in manifest')

for idx, gate in enumerate(gates):
    if not isinstance(gate, str) or not gate.strip():
        raise SystemExit('invalid gate entry in manifest')
    if idx % shard_count == shard_index:
        print(gate.strip())
PY
)

IFS=$'\n' read -r -d '' -a SHARD_GATES < <(printf '%s\0' "$mapfile_output") || true

RESULTS_TMP="$(mktemp)"
trap 'rm -f "$RESULTS_TMP"' EXIT

FAILURES=0
for gate in "${SHARD_GATES[@]}"; do
  [[ -z "$gate" ]] && continue
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '%s\t%s\n' "$gate" "skipped" >> "$RESULTS_TMP"
    continue
  fi

  if "$ROOT_DIR/scripts/workflow/run_gate_with_retry.sh" --retries "$RETRIES" --timeout-sec "$TIMEOUT_SEC" -- "$ROOT_DIR/$gate"; then
    printf '%s\t%s\n' "$gate" "pass" >> "$RESULTS_TMP"
  else
    printf '%s\t%s\n' "$gate" "fail" >> "$RESULTS_TMP"
    FAILURES=$((FAILURES + 1))
  fi
done

python3 - "$REPORT_PATH" "$MANIFEST_REL" "$SHARD_INDEX" "$SHARD_COUNT" "$DRY_RUN" "$RESULTS_TMP" <<'PY'
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
manifest_rel = sys.argv[2]
shard_index = int(sys.argv[3])
shard_count = int(sys.argv[4])
dry_run = int(sys.argv[5])
results_path = Path(sys.argv[6])

rows = []
for line in results_path.read_text(encoding='utf-8').splitlines():
    if not line.strip():
        continue
    gate, status = line.split('\t', 1)
    rows.append({"gate": gate, "status": status})

rows = sorted(rows, key=lambda row: row['gate'])
payload = {
    "version": 1,
    "manifest": manifest_rel,
    "shard_index": shard_index,
    "shard_count": shard_count,
    "mode": "dry_run" if dry_run == 1 else "execute",
    "gate_count": len(rows),
    "results": rows,
}

report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding='utf-8')
print(f"wrote: {report_path}")
PY

if (( FAILURES > 0 )); then
  echo "sharded gate execution failed with ${FAILURES} gate failure(s)"
  exit 1
fi

echo "sharded gate execution completed"
