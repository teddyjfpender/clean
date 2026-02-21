#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="${1:-$ROOT_DIR/config/examples-manifest.json}"
MANIFEST_VALIDATOR="$ROOT_DIR/scripts/examples/validate_examples_manifest.py"

export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "missing examples manifest: $MANIFEST_FILE"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for manifest parsing"
  exit 1
fi

if [[ ! -f "$MANIFEST_VALIDATOR" ]]; then
  echo "missing manifest validator: $MANIFEST_VALIDATOR"
  exit 1
fi

if ! command -v lake >/dev/null 2>&1; then
  echo "lake is required for Lean/Cairo generation"
  exit 1
fi

ROWS_FILE="$(mktemp)"
trap 'rm -f "$ROWS_FILE"' EXIT

python3 "$MANIFEST_VALIDATOR" --manifest "$MANIFEST_FILE" --emit-tsv >"$ROWS_FILE"

if [[ -z "$(sed '/^$/d' "$ROWS_FILE")" ]]; then
  echo "examples manifest produced no generation rows: $MANIFEST_FILE"
  exit 1
fi

module_roots="$(awk -F'\t' '{ split($2, parts, "."); if (parts[1] != "") print parts[1] }' "$ROWS_FILE" | sort -u)"
if [[ -z "$(printf '%s\n' "$module_roots" | sed '/^$/d')" ]]; then
  echo "failed to derive module roots from examples manifest: $MANIFEST_FILE"
  exit 1
fi

for root_target in $module_roots; do
  echo "building examples root target '$root_target'"
  (
    cd "$ROOT_DIR"
    lake build "$root_target"
  )
done

while IFS=$'\t' read -r example_id module_name lean_dir_rel sierra_dir_rel cairo_dir_rel baseline_dir_rel benchmark_dir_rel sources_csv; do
  [[ -z "$example_id" ]] && continue
  [[ "$baseline_dir_rel" == "-" ]] && baseline_dir_rel=""
  [[ "$benchmark_dir_rel" == "-" ]] && benchmark_dir_rel=""

  lean_dir="$ROOT_DIR/$lean_dir_rel"
  sierra_dir="$ROOT_DIR/$sierra_dir_rel"
  cairo_dir="$ROOT_DIR/$cairo_dir_rel"

  echo "generating example '$example_id' from module '$module_name'"

  if [[ ! -d "$lean_dir" ]]; then
    echo "missing Lean example directory: $lean_dir"
    exit 1
  fi

  rm -rf "$sierra_dir" "$cairo_dir"
  mkdir -p "$sierra_dir" "$cairo_dir"

  if [[ -n "$baseline_dir_rel" && ! -d "$ROOT_DIR/$baseline_dir_rel" ]]; then
    echo "missing baseline mirror directory for '$example_id': $baseline_dir_rel"
    exit 1
  fi
  if [[ -n "$benchmark_dir_rel" && ! -d "$ROOT_DIR/$benchmark_dir_rel" ]]; then
    echo "missing benchmark mirror directory for '$example_id': $benchmark_dir_rel"
    exit 1
  fi

  IFS=',' read -r -a source_paths <<<"$sources_csv"
  for source_rel in "${source_paths[@]}"; do
    source_path="$ROOT_DIR/$source_rel"
    if [[ ! -f "$source_path" ]]; then
      echo "missing Lean source for example '$example_id': $source_rel"
      exit 1
    fi
    case "$source_path" in
      "$lean_dir"/*) ;;
      *)
        echo "Lean source for '$example_id' must live under $lean_dir: $source_rel"
        exit 1
        ;;
    esac
  done

  cat >"$lean_dir/README.md" <<EOF
# Lean Example: $example_id

- Module: \`$module_name\`
- Mirrors:
  - Lean: \`$lean_dir_rel\`
  - Sierra: \`$sierra_dir_rel\`
  - Cairo: \`$cairo_dir_rel\`
  - Cairo baseline: \`${baseline_dir_rel:-none}\`
  - Benchmark: \`${benchmark_dir_rel:-none}\`
- Generated via:
  - \`lake exe leancairo-sierra-gen --module $module_name --out $sierra_dir_rel --optimize true\`
  - \`lake exe leancairo-gen --module $module_name --out $cairo_dir_rel --emit-casm false --optimize true\`

Lean source in this directory is canonical for this example.
EOF

  (
    cd "$ROOT_DIR"
    lake exe leancairo-sierra-gen --module "$module_name" --out "$sierra_dir" --optimize true
    lake exe leancairo-gen --module "$module_name" --out "$cairo_dir" --emit-casm false --optimize true
  )
done <"$ROWS_FILE"

echo "examples generation completed"
