#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG_REL="roadmap/reports/rgr-deliverables.json"
DELIVERABLE_ID=""
PHASE="all"
DRY_RUN=0

usage() {
  cat <<USAGE
usage: $0 --deliverable <id> [--catalog <path>] [--phase <all|red|green|refactor>] [--dry-run]
USAGE
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --deliverable)
      DELIVERABLE_ID="${2:-}"
      shift 2
      ;;
    --catalog)
      CATALOG_REL="${2:-}"
      shift 2
      ;;
    --phase)
      PHASE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$DELIVERABLE_ID" ]]; then
  usage
  exit 1
fi
if [[ "$PHASE" != "all" && "$PHASE" != "red" && "$PHASE" != "green" && "$PHASE" != "refactor" ]]; then
  echo "invalid phase: $PHASE"
  usage
  exit 1
fi

if [[ "$CATALOG_REL" = /* ]]; then
  CATALOG_PATH="$CATALOG_REL"
else
  CATALOG_PATH="$ROOT_DIR/$CATALOG_REL"
fi
if [[ ! -f "$CATALOG_PATH" ]]; then
  echo "missing catalog: $CATALOG_REL"
  exit 1
fi

python3 "$ROOT_DIR/scripts/roadmap/validate_rgr_deliverables.py" --catalog "$CATALOG_PATH"

RUN_LIST="$(
python3 - <<'PY' "$CATALOG_PATH" "$DELIVERABLE_ID" "$PHASE"
import json
import sys
from pathlib import Path

catalog_path = Path(sys.argv[1])
deliverable_id = sys.argv[2]
phase = sys.argv[3]

payload = json.loads(catalog_path.read_text(encoding='utf-8'))
items = payload.get('deliverables', [])
if not isinstance(items, list):
    raise SystemExit('invalid catalog: missing deliverables list')

selected = None
for item in items:
    if isinstance(item, dict) and item.get('id') == deliverable_id:
        selected = item
        break

if selected is None:
    raise SystemExit(f"deliverable id not found: {deliverable_id}")

phase_order = ['red', 'green', 'refactor'] if phase == 'all' else [phase]
for p in phase_order:
    gates = selected.get('phase_gates', {}).get(p, [])
    if not isinstance(gates, list) or not gates:
        raise SystemExit(f"deliverable '{deliverable_id}' has no gates for phase '{p}'")
    for gate in gates:
        if not isinstance(gate, str) or not gate.strip():
            raise SystemExit(f"invalid gate entry in {deliverable_id}.{p}")
        print(f"{p}\t{gate.strip()}")
PY
)"

run_gate() {
  local phase_label="$1"
  local cmd="$2"
  local first
  first="$(awk '{print $1}' <<< "$cmd")"
  if [[ "$first" == "python3" || "$first" == "bash" || "$first" == "sh" ]]; then
    first="$(awk '{print $2}' <<< "$cmd")"
  fi
  if [[ "$first" == ./* ]]; then
    first="${first#./}"
  fi
  if [[ "$first" == */* && ! -e "$ROOT_DIR/$first" ]]; then
    echo "missing gate command path for deliverable '$DELIVERABLE_ID' phase '$phase_label': $first"
    exit 1
  fi

  echo "[RGR][$phase_label] $cmd"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  (
    cd "$ROOT_DIR"
    eval "$cmd"
  )
}

while IFS=$'\t' read -r phase_label gate_cmd; do
  [[ -z "$phase_label" ]] && continue
  run_gate "$phase_label" "$gate_cmd"
done <<< "$RUN_LIST"

echo "RGR loop completed: deliverable=$DELIVERABLE_ID phase=$PHASE dry_run=$DRY_RUN"
