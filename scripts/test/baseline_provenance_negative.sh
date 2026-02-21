#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATOR="$ROOT_DIR/scripts/examples/validate_baselines_manifest.py"
BASE_MANIFEST="$ROOT_DIR/config/baselines-manifest.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Case 1: invalid commit pin format.
BAD_COMMIT_MANIFEST="$TMP_DIR/bad-commit.json"
python3 - "$BASE_MANIFEST" "$BAD_COMMIT_MANIFEST" <<'PY'
import json
import sys
src, out = sys.argv[1], sys.argv[2]
payload = json.loads(open(src, encoding='utf-8').read())
payload['baselines'][0]['source_commit'] = 'main'
with open(out, 'w', encoding='utf-8') as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write('\n')
PY

if python3 "$VALIDATOR" --manifest "$BAD_COMMIT_MANIFEST" --examples-manifest "config/examples-manifest.json" >"$TMP_DIR/bad-commit.log" 2>&1; then
  echo "expected baseline validator to fail for invalid commit pin"
  exit 1
fi
if ! rg -q "source_commit" "$TMP_DIR/bad-commit.log"; then
  echo "invalid commit diagnostic was not reported"
  cat "$TMP_DIR/bad-commit.log"
  exit 1
fi

# Case 2: missing required baseline entry for examples manifest.
MISSING_ENTRY_MANIFEST="$TMP_DIR/missing-entry.json"
python3 - "$BASE_MANIFEST" "$MISSING_ENTRY_MANIFEST" <<'PY'
import json
import sys
src, out = sys.argv[1], sys.argv[2]
payload = json.loads(open(src, encoding='utf-8').read())
payload['baselines'] = [
    row for row in payload.get('baselines', [])
    if row.get('id') != 'newton_u128'
]
with open(out, 'w', encoding='utf-8') as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write('\n')
PY

if python3 "$VALIDATOR" --manifest "$MISSING_ENTRY_MANIFEST" --examples-manifest "config/examples-manifest.json" >"$TMP_DIR/missing-entry.log" 2>&1; then
  echo "expected baseline validator to fail for missing baseline manifest entry"
  exit 1
fi
if ! rg -q "manifest missing baseline entries" "$TMP_DIR/missing-entry.log"; then
  echo "missing-entry diagnostic was not reported"
  cat "$TMP_DIR/missing-entry.log"
  exit 1
fi

echo "baseline provenance negative checks passed"
