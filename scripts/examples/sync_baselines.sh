#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_REL="config/baselines-manifest.json"
EXECUTE=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --manifest)
      MANIFEST_REL="${2:-}"
      shift 2
      ;;
    --execute)
      EXECUTE=1
      shift
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: $0 [--manifest <path>] [--execute]"
      exit 1
      ;;
  esac
done

MANIFEST_PATH="$ROOT_DIR/$MANIFEST_REL"
python3 "$ROOT_DIR/scripts/examples/validate_baselines_manifest.py" \
  --manifest "$MANIFEST_PATH" \
  --examples-manifest "config/examples-manifest.json" >/dev/null

while IFS=$'\t' read -r baseline_id baseline_dir source_repo source_commit sync_script patch_script provenance_doc source_paths_json; do
  [[ -z "$baseline_id" ]] && continue
  SYNC_PATH="$ROOT_DIR/$sync_script"
  PATCH_PATH="$ROOT_DIR/$patch_script"
  ARTIFACT_DIR="$ROOT_DIR/.artifacts/baselines/$baseline_id/$source_commit"

  paths=()
  while IFS= read -r source_path; do
    [[ -z "$source_path" ]] && continue
    paths+=("$source_path")
  done < <(python3 - "$source_paths_json" <<'PY'
import json
import sys
for item in json.loads(sys.argv[1]):
    if isinstance(item, str) and item.strip():
        print(item.strip())
PY
)

  sync_cmd=("$SYNC_PATH" --id "$baseline_id" --repo "$source_repo" --commit "$source_commit" --out-dir "$ARTIFACT_DIR")
  for source_path in "${paths[@]}"; do
    sync_cmd+=(--path "$source_path")
  done
  if [[ "$EXECUTE" -eq 1 ]]; then
    sync_cmd+=(--execute)
  fi

  "${sync_cmd[@]}"
  "$PATCH_PATH" --id "$baseline_id" --baseline-dir "$ROOT_DIR/$baseline_dir" --source-dir "$ARTIFACT_DIR"
  printf 'baseline-provenance id=%s baseline=%s provenance=%s\n' "$baseline_id" "$baseline_dir" "$provenance_doc"
done < <(
  python3 - "$MANIFEST_PATH" <<'PY'
import json
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
payload = json.loads(manifest.read_text(encoding='utf-8'))
rows = payload.get('baselines', [])
for row in sorted((r for r in rows if isinstance(r, dict)), key=lambda item: str(item.get('id', ''))):
    print('\t'.join([
        str(row.get('id', '')).strip(),
        str(row.get('baseline_dir', '')).strip(),
        str(row.get('source_repo', '')).strip(),
        str(row.get('source_commit', '')).strip(),
        str(row.get('sync_script', '')).strip(),
        str(row.get('patch_script', '')).strip(),
        str(row.get('provenance_doc', '')).strip(),
        json.dumps(row.get('source_paths', []), sort_keys=True),
    ]))
PY
)

if [[ "$EXECUTE" -eq 1 ]]; then
  echo "baseline sync completed"
else
  echo "baseline sync dry-run completed"
fi
