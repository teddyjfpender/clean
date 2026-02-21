#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_REL="config/completion-matrix-schema.json"
MATRIX_JSON_REL="roadmap/reports/completion-matrix.json"
MATRIX_MD_REL="roadmap/reports/completion-matrix.md"
GEN_SCRIPT="$ROOT_DIR/scripts/roadmap/generate_completion_matrix.py"
VALIDATE_SCRIPT="$ROOT_DIR/scripts/roadmap/validate_completion_matrix.py"

TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
TMP_NEG="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B" "$TMP_NEG"' EXIT

python3 "$GEN_SCRIPT" --out-dir "$TMP_A"
python3 "$GEN_SCRIPT" --out-dir "$TMP_B"

python3 "$VALIDATE_SCRIPT" \
  --schema "$ROOT_DIR/$SCHEMA_REL" \
  --matrix "$TMP_A/completion-matrix.json"
python3 "$VALIDATE_SCRIPT" \
  --schema "$ROOT_DIR/$SCHEMA_REL" \
  --matrix "$TMP_B/completion-matrix.json"

if ! diff -u "$TMP_A/completion-matrix.json" "$TMP_B/completion-matrix.json" >/dev/null; then
  echo "non-deterministic completion matrix JSON output"
  exit 1
fi

if ! diff -u "$TMP_A/completion-matrix.md" "$TMP_B/completion-matrix.md" >/dev/null; then
  echo "non-deterministic completion matrix Markdown output"
  exit 1
fi

if python3 "$GEN_SCRIPT" \
  --sierra-matrix "$TMP_NEG/does-not-exist.json" \
  --out-dir "$TMP_NEG" >/dev/null 2>&1; then
  echo "expected completion matrix generation to fail when required source is missing"
  exit 1
fi

python3 "$GEN_SCRIPT" --out-dir "$TMP_A"

if [[ ! -f "$ROOT_DIR/$MATRIX_JSON_REL" ]]; then
  echo "missing committed completion matrix report: $MATRIX_JSON_REL"
  exit 1
fi
if [[ ! -f "$ROOT_DIR/$MATRIX_MD_REL" ]]; then
  echo "missing committed completion matrix report: $MATRIX_MD_REL"
  exit 1
fi

if ! diff -u "$ROOT_DIR/$MATRIX_JSON_REL" "$TMP_A/completion-matrix.json" >/dev/null; then
  echo "completion matrix JSON is stale: $MATRIX_JSON_REL"
  exit 1
fi
if ! diff -u "$ROOT_DIR/$MATRIX_MD_REL" "$TMP_A/completion-matrix.md" >/dev/null; then
  echo "completion matrix Markdown is stale: $MATRIX_MD_REL"
  exit 1
fi

echo "completion matrix checks passed"
