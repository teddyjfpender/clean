#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-.artifacts/upstream-sq128}"
REPO="teddyjfpender/the-situation"
BASE_PATH="contracts/src/types/sq128"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

FILES=(
  "advanced.cairo"
  "arithmetic.cairo"
  "constructors.cairo"
  "internal.cairo"
  "traits.cairo"
  "types.cairo"
)

for f in "${FILES[@]}"; do
  gh api "repos/${REPO}/contents/${BASE_PATH}/${f}" --jq .content | base64 --decode > "$OUT_DIR/$f"
  echo "pulled: $OUT_DIR/$f"
done

gh api "repos/${REPO}/contents/contracts/src/types/sq128.cairo" --jq .content | base64 --decode > "$OUT_DIR/sq128.cairo"
gh api "repos/${REPO}/contents/contracts/src/types/common.cairo" --jq .content | base64 --decode > "$OUT_DIR/common.cairo"
echo "pulled: $OUT_DIR/sq128.cairo"
echo "pulled: $OUT_DIR/common.cairo"
