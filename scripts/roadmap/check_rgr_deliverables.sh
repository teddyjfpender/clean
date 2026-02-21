#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPEC_REL="config/rgr-deliverable-spec.json"
MATRIX_REL="roadmap/inventory/sierra-coverage-matrix.json"
CATALOG_JSON_REL="roadmap/reports/rgr-deliverables.json"
CATALOG_MD_REL="roadmap/reports/rgr-deliverables.md"
GEN_SCRIPT="$ROOT_DIR/scripts/roadmap/generate_rgr_deliverables.py"
VAL_SCRIPT="$ROOT_DIR/scripts/roadmap/validate_rgr_deliverables.py"

TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
TMP_NEG="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B" "$TMP_NEG"' EXIT

python3 "$GEN_SCRIPT" \
  --spec "$SPEC_REL" \
  --matrix "$MATRIX_REL" \
  --status-source "$CATALOG_JSON_REL" \
  --out-json "$TMP_A/rgr-deliverables.json" \
  --out-md "$TMP_A/rgr-deliverables.md"

python3 "$GEN_SCRIPT" \
  --spec "$SPEC_REL" \
  --matrix "$MATRIX_REL" \
  --status-source "$CATALOG_JSON_REL" \
  --out-json "$TMP_B/rgr-deliverables.json" \
  --out-md "$TMP_B/rgr-deliverables.md"

python3 "$VAL_SCRIPT" --catalog "$TMP_A/rgr-deliverables.json" --matrix "$MATRIX_REL"
python3 "$VAL_SCRIPT" --catalog "$TMP_B/rgr-deliverables.json" --matrix "$MATRIX_REL"

if ! diff -u "$TMP_A/rgr-deliverables.json" "$TMP_B/rgr-deliverables.json" >/dev/null; then
  echo "non-deterministic RGR deliverable JSON output"
  exit 1
fi
if ! diff -u "$TMP_A/rgr-deliverables.md" "$TMP_B/rgr-deliverables.md" >/dev/null; then
  echo "non-deterministic RGR deliverable Markdown output"
  exit 1
fi

if python3 "$GEN_SCRIPT" \
  --spec "$SPEC_REL" \
  --matrix "$TMP_NEG/does-not-exist.json" \
  --status-source "$CATALOG_JSON_REL" \
  --out-json "$TMP_NEG/out.json" \
  --out-md "$TMP_NEG/out.md" >/dev/null 2>&1; then
  echo "expected RGR deliverable generator to fail with missing matrix source"
  exit 1
fi

if [[ ! -f "$ROOT_DIR/$CATALOG_JSON_REL" || ! -f "$ROOT_DIR/$CATALOG_MD_REL" ]]; then
  echo "missing committed RGR deliverable artifacts"
  exit 1
fi

if ! diff -u "$ROOT_DIR/$CATALOG_JSON_REL" "$TMP_A/rgr-deliverables.json" >/dev/null; then
  echo "stale RGR deliverable JSON: $CATALOG_JSON_REL"
  exit 1
fi
if ! diff -u "$ROOT_DIR/$CATALOG_MD_REL" "$TMP_A/rgr-deliverables.md" >/dev/null; then
  echo "stale RGR deliverable Markdown: $CATALOG_MD_REL"
  exit 1
fi

echo "RGR deliverable checks passed"
