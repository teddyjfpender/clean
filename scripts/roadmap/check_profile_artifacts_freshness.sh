#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUMMARY_REL="generated/examples/benchmark-summary.json"
OUT_JSON_REL="generated/examples/profile-artifacts.json"
OUT_MD_REL="generated/examples/profile-artifacts.md"

(
  cd "$ROOT_DIR"
  python3 scripts/bench/generate_profile_artifacts.py \
    --summary "$SUMMARY_REL" \
    --out-json "$OUT_JSON_REL" \
    --out-md "$OUT_MD_REL"
  git diff --exit-code "$OUT_JSON_REL" "$OUT_MD_REL"
)

echo "profile artifact freshness checks passed"
