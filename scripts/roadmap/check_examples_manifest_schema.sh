#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="$ROOT_DIR/config/examples-manifest.json"
VALIDATOR="$ROOT_DIR/scripts/examples/validate_examples_manifest.py"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "missing examples manifest: $MANIFEST_FILE"
  exit 1
fi
if [[ ! -f "$VALIDATOR" ]]; then
  echo "missing examples manifest validator: $VALIDATOR"
  exit 1
fi

rows_file="$(mktemp)"
trap 'rm -f "$rows_file"' EXIT

python3 "$VALIDATOR" --manifest "$MANIFEST_FILE" --emit-tsv >"$rows_file"
if [[ -z "$(sed '/^$/d' "$rows_file")" ]]; then
  echo "examples manifest schema check produced no rows"
  exit 1
fi

echo "examples manifest schema checks passed"
