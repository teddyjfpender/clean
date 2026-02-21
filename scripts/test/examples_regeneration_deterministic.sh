#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="${1:-$ROOT_DIR/config/examples-manifest.json}"
VALIDATOR="$ROOT_DIR/scripts/examples/validate_examples_manifest.py"
GEN_SCRIPT="$ROOT_DIR/scripts/examples/generate_examples.sh"

export LC_ALL=C
export LANG=C

snapshot_hashes() {
  local out_file="$1"
  local rows_file
  rows_file="$(mktemp)"

  python3 "$VALIDATOR" --manifest "$MANIFEST_FILE" --emit-tsv >"$rows_file"
  : >"$out_file"

  while IFS=$'\t' read -r example_id _module_name _lean_dir_rel sierra_dir_rel cairo_dir_rel _baseline_dir_rel _benchmark_dir_rel _sources_csv; do
    [[ -z "$example_id" ]] && continue
    local sierra_file="$ROOT_DIR/$sierra_dir_rel/sierra/program.sierra.json"
    local cairo_file="$ROOT_DIR/$cairo_dir_rel/src/lib.cairo"

    if [[ ! -f "$sierra_file" ]]; then
      echo "missing Sierra artifact during determinism snapshot: $sierra_file"
      exit 1
    fi
    if [[ ! -f "$cairo_file" ]]; then
      echo "missing Cairo artifact during determinism snapshot: $cairo_file"
      exit 1
    fi

    local sierra_hash
    sierra_hash="$(shasum -a 256 "$sierra_file" | awk '{print $1}')"
    local cairo_hash
    cairo_hash="$(shasum -a 256 "$cairo_file" | awk '{print $1}')"
    printf '%s\t%s\t%s\n' "$example_id" "sierra" "$sierra_hash" >>"$out_file"
    printf '%s\t%s\t%s\n' "$example_id" "cairo" "$cairo_hash" >>"$out_file"
  done <"$rows_file"

  sort -o "$out_file" "$out_file"
  rm -f "$rows_file"
}

SNAPSHOT_A="$(mktemp)"
SNAPSHOT_B="$(mktemp)"
trap 'rm -f "$SNAPSHOT_A" "$SNAPSHOT_B"' EXIT

"$GEN_SCRIPT" "$MANIFEST_FILE"
snapshot_hashes "$SNAPSHOT_A"

"$GEN_SCRIPT" "$MANIFEST_FILE"
snapshot_hashes "$SNAPSHOT_B"

if ! diff -u "$SNAPSHOT_A" "$SNAPSHOT_B" >/dev/null; then
  echo "example regeneration is non-deterministic"
  diff -u "$SNAPSHOT_A" "$SNAPSHOT_B" || true
  exit 1
fi

echo "examples regeneration determinism checks passed"
