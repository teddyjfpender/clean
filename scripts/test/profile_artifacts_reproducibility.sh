#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUMMARY_REL="generated/examples/benchmark-summary.json"
TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

(
  cd "$ROOT_DIR"
  python3 scripts/bench/generate_profile_artifacts.py \
    --summary "$SUMMARY_REL" \
    --out-json "$TMP_A/profile-artifacts.json" \
    --out-md "$TMP_A/profile-artifacts.md"
  python3 scripts/bench/generate_profile_artifacts.py \
    --summary "$SUMMARY_REL" \
    --out-json "$TMP_B/profile-artifacts.json" \
    --out-md "$TMP_B/profile-artifacts.md"
)

diff -u "$TMP_A/profile-artifacts.json" "$TMP_B/profile-artifacts.json" >/dev/null
diff -u "$TMP_A/profile-artifacts.md" "$TMP_B/profile-artifacts.md" >/dev/null

echo "profile artifact reproducibility checks passed"
