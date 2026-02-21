#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="${1:-$ROOT_DIR/config/examples-manifest.json}"
MANIFEST_VALIDATOR="$ROOT_DIR/scripts/examples/validate_examples_manifest.py"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "missing examples manifest: $MANIFEST_FILE"
  exit 1
fi
if [[ ! -f "$MANIFEST_VALIDATOR" ]]; then
  echo "missing examples manifest validator: $MANIFEST_VALIDATOR"
  exit 1
fi

rows_file="$(mktemp)"
trap 'rm -f "$rows_file"' EXIT

python3 "$MANIFEST_VALIDATOR" --manifest "$MANIFEST_FILE" --emit-tsv >"$rows_file"

if [[ -z "$(sed '/^$/d' "$rows_file")" ]]; then
  echo "examples manifest has no ids: $MANIFEST_FILE"
  exit 1
fi

while IFS=$'\t' read -r example_id _module_name lean_dir_rel sierra_dir_rel cairo_dir_rel baseline_dir_rel benchmark_dir_rel sources_csv; do
  [[ -z "$example_id" ]] && continue
  [[ "$baseline_dir_rel" == "-" ]] && baseline_dir_rel=""
  [[ "$benchmark_dir_rel" == "-" ]] && benchmark_dir_rel=""
  lean_dir="$ROOT_DIR/$lean_dir_rel"
  sierra_dir="$ROOT_DIR/$sierra_dir_rel"
  cairo_dir="$ROOT_DIR/$cairo_dir_rel"

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
  if [[ -n "$baseline_dir_rel" && ! -d "$ROOT_DIR/$baseline_dir_rel" ]]; then
    echo "missing Cairo baseline example directory: $ROOT_DIR/$baseline_dir_rel"
    exit 1
  fi
  if [[ -n "$benchmark_dir_rel" && ! -d "$ROOT_DIR/$benchmark_dir_rel" ]]; then
    echo "missing benchmark example directory: $ROOT_DIR/$benchmark_dir_rel"
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
