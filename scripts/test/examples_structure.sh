#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="$ROOT_DIR/config/examples-manifest.json"
EXAMPLES_ROOT="$ROOT_DIR/examples"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "missing examples manifest: $MANIFEST_FILE"
  exit 1
fi

rows_file="$(mktemp)"
trap 'rm -f "$rows_file"' EXIT

python3 - "$MANIFEST_FILE" >"$rows_file" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
payload = json.loads(manifest_path.read_text(encoding="utf-8"))
examples = payload.get("examples", [])
if not isinstance(examples, list) or not examples:
    raise SystemExit(f"invalid examples manifest: {manifest_path}")
for entry in examples:
    example_id = str(entry.get("id", "")).strip()
    lean_sources = entry.get("lean_sources", [])
    if not isinstance(lean_sources, list) or not lean_sources:
        raise SystemExit(f"invalid lean_sources for example: {example_id}")
    print("\t".join([example_id, ",".join(str(p).strip() for p in lean_sources)]))
PY

if [[ -z "$(sed '/^$/d' "$rows_file")" ]]; then
  echo "examples manifest has no ids: $MANIFEST_FILE"
  exit 1
fi

while IFS=$'\t' read -r example_id sources_csv; do
  [[ -z "$example_id" ]] && continue
  lean_dir="$EXAMPLES_ROOT/Lean/$example_id"
  sierra_dir="$EXAMPLES_ROOT/Sierra/$example_id"
  cairo_dir="$EXAMPLES_ROOT/Cairo/$example_id"

  if [[ ! -d "$lean_dir" ]]; then
    echo "missing Lean example directory: $lean_dir"
    exit 1
  fi
  if [[ ! -d "$sierra_dir" ]]; then
    echo "missing Sierra example directory: $sierra_dir"
    exit 1
  fi
  if [[ ! -d "$cairo_dir" ]]; then
    echo "missing Cairo example directory: $cairo_dir"
    exit 1
  fi

  if [[ ! -f "$lean_dir/README.md" ]]; then
    echo "missing Lean example README: $lean_dir/README.md"
    exit 1
  fi

  IFS=',' read -r -a source_paths <<<"$sources_csv"
  for source_rel in "${source_paths[@]}"; do
    source_path="$ROOT_DIR/$source_rel"
    if [[ ! -f "$source_path" ]]; then
      echo "missing Lean source from manifest: $source_rel"
      exit 1
    fi
    case "$source_path" in
      "$lean_dir"/*) ;;
      *)
        echo "manifest source must be under Lean example directory $lean_dir: $source_rel"
        exit 1
        ;;
    esac
  done

  if [[ ! -f "$sierra_dir/sierra/program.sierra.json" ]]; then
    echo "missing generated Sierra program: $sierra_dir/sierra/program.sierra.json"
    exit 1
  fi
  if [[ ! -f "$cairo_dir/src/lib.cairo" ]]; then
    echo "missing generated Cairo source: $cairo_dir/src/lib.cairo"
    exit 1
  fi
done <"$rows_file"

echo "examples structure checks passed"
