#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GEN="$ROOT_DIR/scripts/bench/generate_profile_artifacts.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BAD_SUMMARY="$TMP_DIR/bad-summary.json"
cat > "$BAD_SUMMARY" <<'JSON'
{
  "version": 1,
  "cases": [
    {
      "id": "bad-case",
      "family": "integer",
      "metrics": {
        "baseline_sierra_gas": 1.0,
        "generated_sierra_gas": 1.0
      }
    }
  ]
}
JSON

if python3 "$GEN" --summary "$BAD_SUMMARY" --out-json "$TMP_DIR/out.json" --out-md "$TMP_DIR/out.md" >"$TMP_DIR/negative.log" 2>&1; then
  echo "expected profile artifact generator to fail on malformed benchmark summary"
  exit 1
fi

if ! rg -q "missing key" "$TMP_DIR/negative.log"; then
  echo "malformed-summary diagnostic was not reported"
  cat "$TMP_DIR/negative.log"
  exit 1
fi

echo "profile artifact negative checks passed"
