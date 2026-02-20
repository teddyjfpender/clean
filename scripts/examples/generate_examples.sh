#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="${1:-$ROOT_DIR/config/examples-manifest.json}"
EXAMPLES_ROOT="$ROOT_DIR/examples"
LEAN_ROOT="$EXAMPLES_ROOT/Lean"
SIERRA_ROOT="$EXAMPLES_ROOT/Sierra"
CAIRO_ROOT="$EXAMPLES_ROOT/Cairo"

export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "missing examples manifest: $MANIFEST_FILE"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for manifest parsing"
  exit 1
fi

if ! command -v lake >/dev/null 2>&1; then
  echo "lake is required for Lean/Cairo generation"
  exit 1
fi

mkdir -p "$LEAN_ROOT" "$SIERRA_ROOT" "$CAIRO_ROOT"

ROWS_FILE="$(mktemp)"
trap 'rm -f "$ROWS_FILE"' EXIT

python3 - "$MANIFEST_FILE" >"$ROWS_FILE" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
payload = json.loads(manifest_path.read_text(encoding="utf-8"))
examples = payload.get("examples")

if not isinstance(examples, list) or not examples:
    raise SystemExit(f"invalid examples manifest (no examples): {manifest_path}")

required = ("id", "module", "lean_sources")
seen = set()
for idx, entry in enumerate(examples):
    if not isinstance(entry, dict):
        raise SystemExit(f"invalid examples manifest entry {idx}: expected object")
    missing = [key for key in required if key not in entry]
    if missing:
        raise SystemExit(f"manifest entry {idx} missing keys: {', '.join(missing)}")
    example_id = str(entry["id"]).strip()
    module_name = str(entry["module"]).strip()
    lean_sources = entry["lean_sources"]
    if not example_id or not module_name:
        raise SystemExit(f"manifest entry {idx} has empty id/module")
    if example_id in seen:
        raise SystemExit(f"duplicate example id in manifest: {example_id}")
    seen.add(example_id)
    if not isinstance(lean_sources, list) or not lean_sources:
        raise SystemExit(f"manifest entry {example_id} has empty lean_sources")
    normalized_sources = []
    for source in lean_sources:
        source_str = str(source).strip()
        if not source_str:
            raise SystemExit(f"manifest entry {example_id} has empty source path")
        normalized_sources.append(source_str)
    print("\t".join([example_id, module_name, ",".join(normalized_sources)]))
PY

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

while IFS=$'\t' read -r example_id module_name sources_csv; do
  [[ -z "$example_id" ]] && continue

  lean_dir="$LEAN_ROOT/$example_id"
  sierra_dir="$SIERRA_ROOT/$example_id"
  cairo_dir="$CAIRO_ROOT/$example_id"

  echo "generating example '$example_id' from module '$module_name'"

  if [[ ! -d "$lean_dir" ]]; then
    echo "missing Lean example directory: $lean_dir"
    exit 1
  fi

  rm -rf "$sierra_dir" "$cairo_dir"
  mkdir -p "$sierra_dir" "$cairo_dir"

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
- Generated via:
  - \`lake exe leancairo-sierra-gen --module $module_name --out examples/Sierra/$example_id --optimize true\`
  - \`lake exe leancairo-gen --module $module_name --out examples/Cairo/$example_id --emit-casm false --optimize true\`

Lean source in this directory is canonical for this example.
EOF

  (
    cd "$ROOT_DIR"
    lake exe leancairo-sierra-gen --module "$module_name" --out "$sierra_dir" --optimize true
    lake exe leancairo-gen --module "$module_name" --out "$cairo_dir" --emit-casm false --optimize true
  )
done <"$ROWS_FILE"

echo "examples generation completed"
