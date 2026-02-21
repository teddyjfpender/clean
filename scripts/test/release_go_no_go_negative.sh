#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_release_go_no_go.sh"
BASE_THRESHOLDS="$ROOT_DIR/roadmap/reports/release-go-no-go-thresholds.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

STRICT_THRESHOLDS="$TMP_DIR/strict-thresholds.json"
python3 - "$BASE_THRESHOLDS" "$STRICT_THRESHOLDS" <<'PY'
import json
import sys
src, out = sys.argv[1], sys.argv[2]
payload = json.loads(open(src, encoding="utf-8").read())
payload.setdefault("capability", {})["min_overall_implemented_ratio"] = 1.0
with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write("\n")
PY

if RELEASE_GO_NO_GO_THRESHOLDS="$STRICT_THRESHOLDS" "$CHECKER" >"$TMP_DIR/negative.log" 2>&1; then
  echo "expected release go/no-go checker to fail under strict thresholds"
  exit 1
fi

if ! rg -q "release go/no-go failed" "$TMP_DIR/negative.log"; then
  echo "release go/no-go negative run failed, but expected threshold diagnostic was not reported"
  cat "$TMP_DIR/negative.log"
  exit 1
fi

echo "release go/no-go negative checks passed"
