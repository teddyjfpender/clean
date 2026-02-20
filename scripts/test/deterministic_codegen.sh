#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_ROOT="$ROOT_DIR/.artifacts/deterministic_codegen"
CAIRO_A="$OUT_ROOT/cairo_run_a"
CAIRO_B="$OUT_ROOT/cairo_run_b"
SIERRA_A="$OUT_ROOT/sierra_run_a"
SIERRA_B="$OUT_ROOT/sierra_run_b"
export PATH="$HOME/.elan/bin:$PATH"
export LC_ALL=C
export LANG=C

hash_tree_manifest() {
  local target_dir="$1"
  while IFS= read -r file_path; do
    [[ -z "$file_path" ]] && continue
    local rel_path="${file_path#"$target_dir/"}"
    local file_hash
    file_hash="$(shasum -a 256 "$file_path" | awk '{print $1}')"
    printf '%s  %s\n' "$file_hash" "$rel_path"
  done <<< "$(find "$target_dir" -type f | LC_ALL=C sort)"
}

tree_digest() {
  local target_dir="$1"
  hash_tree_manifest "$target_dir" | shasum -a 256 | awk '{print $1}'
}

assert_identical_trees() {
  local left_dir="$1"
  local right_dir="$2"
  local label="$3"
  local diff_file="$OUT_ROOT/${label}.diff"

  if ! diff -ru "$left_dir" "$right_dir" >"$diff_file"; then
    echo "determinism check failed for $label: generated trees differ"
    cat "$diff_file"
    exit 1
  fi
  rm -f "$diff_file"

  local left_digest
  left_digest="$(tree_digest "$left_dir")"
  local right_digest
  right_digest="$(tree_digest "$right_dir")"

  if [[ "$left_digest" != "$right_digest" ]]; then
    echo "determinism hash mismatch for $label: $left_digest != $right_digest"
    exit 1
  fi

  echo "$label deterministic digest: $left_digest"
}

rm -rf "$OUT_ROOT"
mkdir -p "$OUT_ROOT"

(
  cd "$ROOT_DIR"
  lake exe leancairo-gen --module Examples.Hello --out "$CAIRO_A" --emit-casm false --optimize true --inlining-strategy default
  lake exe leancairo-gen --module Examples.Hello --out "$CAIRO_B" --emit-casm false --optimize true --inlining-strategy default
  lake exe leancairo-sierra-gen --module MyLeanSierraSubset --out "$SIERRA_A" --optimize true
  lake exe leancairo-sierra-gen --module MyLeanSierraSubset --out "$SIERRA_B" --optimize true
)

assert_identical_trees "$CAIRO_A" "$CAIRO_B" "cairo_codegen"
assert_identical_trees "$SIERRA_A" "$SIERRA_B" "sierra_codegen"

echo "deterministic codegen checks passed"
