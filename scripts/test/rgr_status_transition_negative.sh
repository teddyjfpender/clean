#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MARKER="$ROOT_DIR/scripts/roadmap/mark_rgr_deliverable_done.py"
VALIDATOR="$ROOT_DIR/scripts/roadmap/validate_rgr_deliverables.py"
SOURCE_CATALOG="$ROOT_DIR/roadmap/reports/rgr-deliverables.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CATALOG="$TMP_DIR/rgr-deliverables.json"
CATALOG_MD="$TMP_DIR/rgr-deliverables.md"
cp "$SOURCE_CATALOG" "$CATALOG"
cp "$ROOT_DIR/roadmap/reports/rgr-deliverables.md" "$CATALOG_MD"

HEAD_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short=12 HEAD)"

# Case 1: non-ready deliverable cannot be marked done.
if python3 "$MARKER" \
  --catalog "$CATALOG" \
  --deliverable d01-range-and-integer-families \
  --commit "$HEAD_COMMIT" \
  --out-md "$CATALOG_MD" >"$TMP_DIR/nonready.log" 2>&1; then
  echo "expected marker to fail for non-ready deliverable"
  exit 1
fi
if ! rg -q "not computed-ready" "$TMP_DIR/nonready.log"; then
  echo "missing computed-ready diagnostic"
  cat "$TMP_DIR/nonready.log"
  exit 1
fi

# Case 2: invalid commit hash cannot be marked.
if python3 "$MARKER" \
  --catalog "$CATALOG" \
  --deliverable d00-non-starknet-closure-guard \
  --commit deadbeef \
  --out-md "$CATALOG_MD" >"$TMP_DIR/badcommit.log" 2>&1; then
  echo "expected marker to fail for invalid commit hash"
  exit 1
fi
if ! rg -q "commit does not exist" "$TMP_DIR/badcommit.log"; then
  echo "missing invalid-commit diagnostic"
  cat "$TMP_DIR/badcommit.log"
  exit 1
fi

# Case 3: second DONE transition attempt must fail.
python3 "$MARKER" \
  --catalog "$CATALOG" \
  --deliverable d00-non-starknet-closure-guard \
  --commit "$HEAD_COMMIT" \
  --out-md "$CATALOG_MD" >"$TMP_DIR/first_done.log"

if python3 "$MARKER" \
  --catalog "$CATALOG" \
  --deliverable d00-non-starknet-closure-guard \
  --commit "$HEAD_COMMIT" \
  --out-md "$CATALOG_MD" >"$TMP_DIR/second_done.log" 2>&1; then
  echo "expected marker to fail on second DONE transition"
  exit 1
fi
if ! rg -q "must be NOT DONE" "$TMP_DIR/second_done.log"; then
  echo "missing transition-state diagnostic"
  cat "$TMP_DIR/second_done.log"
  exit 1
fi

python3 "$VALIDATOR" --catalog "$CATALOG" --matrix "$ROOT_DIR/roadmap/inventory/sierra-coverage-matrix.json" >/dev/null

echo "RGR status-transition negative checks passed"
