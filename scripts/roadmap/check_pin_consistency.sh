#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PIN_FILE="$ROOT_DIR/config/cairo_pinned_commit.txt"
PINNED_SURFACE_JSON="$ROOT_DIR/generated/sierra/surface/pinned_surface.json"
SURFACE_LEAN="$ROOT_DIR/src/LeanCairo/Backend/Sierra/Generated/Surface.lean"
CARGO_TOML="$ROOT_DIR/tools/sierra_toolchain/Cargo.toml"
TREE_CACHE_JSON="$ROOT_DIR/roadmap/inventory/pinned-tree-paths.json"

EXPECTED_COMMIT=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --expected-commit)
      EXPECTED_COMMIT="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: $0 [--expected-commit <40-hex-commit>]"
      exit 1
      ;;
  esac
done

if [[ ! -f "$PIN_FILE" ]]; then
  echo "missing pin file: $PIN_FILE"
  exit 1
fi

PINNED_COMMIT="$(tr -d '[:space:]' < "$PIN_FILE")"
if [[ ! "$PINNED_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo "invalid commit format in $PIN_FILE: '$PINNED_COMMIT'"
  exit 1
fi

if [[ -n "$EXPECTED_COMMIT" && "$PINNED_COMMIT" != "$EXPECTED_COMMIT" ]]; then
  echo "pin mismatch: expected '$EXPECTED_COMMIT' but found '$PINNED_COMMIT' in $PIN_FILE"
  exit 1
fi

ERRORS=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "pin mismatch in $label: expected '$expected', got '$actual'"
    ERRORS=$((ERRORS + 1))
  fi
}

if [[ ! -f "$PINNED_SURFACE_JSON" ]]; then
  echo "missing pinned surface json: $PINNED_SURFACE_JSON"
  ERRORS=$((ERRORS + 1))
else
  SURFACE_JSON_PIN="$(python3 - <<'PY' "$PINNED_SURFACE_JSON"
import json
import sys
path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    payload = json.load(f)
print(payload.get('pinned_commit', ''))
PY
)"
  assert_eq "$PINNED_COMMIT" "$SURFACE_JSON_PIN" "$PINNED_SURFACE_JSON"
fi

if [[ ! -f "$SURFACE_LEAN" ]]; then
  echo "missing generated surface lean file: $SURFACE_LEAN"
  ERRORS=$((ERRORS + 1))
else
  SURFACE_LEAN_PIN="$(sed -n 's/^def pinnedCommit : String := "\([0-9a-f]\{40\}\)"$/\1/p' "$SURFACE_LEAN")"
  assert_eq "$PINNED_COMMIT" "$SURFACE_LEAN_PIN" "$SURFACE_LEAN"
fi

if [[ ! -f "$CARGO_TOML" ]]; then
  echo "missing cargo manifest: $CARGO_TOML"
  ERRORS=$((ERRORS + 1))
else
  CARGO_REV_LINES="$(grep -E 'rev = "[0-9a-f]{40}"' "$CARGO_TOML" || true)"
  if [[ -z "$CARGO_REV_LINES" ]]; then
    echo "no pinned rev lines found in $CARGO_TOML"
    ERRORS=$((ERRORS + 1))
  else
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      rev="$(printf '%s' "$line" | sed -n 's/.*rev = "\([0-9a-f]\{40\}\)".*/\1/p')"
      assert_eq "$PINNED_COMMIT" "$rev" "$CARGO_TOML"
    done <<< "$CARGO_REV_LINES"
  fi
fi

if [[ ! -f "$TREE_CACHE_JSON" ]]; then
  echo "missing pinned tree cache file: $TREE_CACHE_JSON"
  ERRORS=$((ERRORS + 1))
else
  TREE_CACHE_PIN="$(python3 - <<'PY' "$TREE_CACHE_JSON"
import json
import sys
path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    payload = json.load(f)
print(payload.get('pinned_commit', ''))
PY
)"
  assert_eq "$PINNED_COMMIT" "$TREE_CACHE_PIN" "$TREE_CACHE_JSON"
fi

INVENTORY_FILES="$(find "$ROOT_DIR/roadmap/inventory" -type f -name '*.md' | sort)"
while IFS= read -r inventory_file; do
  [[ -z "$inventory_file" ]] && continue
  commit_lines="$(grep -E "^- Commit: \`[0-9a-f]{40}\`$" "$inventory_file" || true)"
  if [[ -z "$commit_lines" ]]; then
    continue
  fi
  while IFS= read -r commit_line; do
    [[ -z "$commit_line" ]] && continue
    commit_value="$(printf '%s' "$commit_line" | sed -n "s/^- Commit: \`\([0-9a-f]\{40\}\)\`$/\1/p")"
    assert_eq "$PINNED_COMMIT" "$commit_value" "$inventory_file"
  done <<< "$commit_lines"
done <<< "$INVENTORY_FILES"

if [[ "$ERRORS" -ne 0 ]]; then
  echo "pin consistency checks failed with $ERRORS error(s)"
  exit 1
fi

echo "pin consistency checks passed (commit $PINNED_COMMIT)"
