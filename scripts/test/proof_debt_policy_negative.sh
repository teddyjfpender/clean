#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_proof_debt_policy.py"
REGISTRY="$ROOT_DIR/roadmap/capabilities/registry.json"
BASE_DEBT="$ROOT_DIR/roadmap/proof-debt.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Case 1: missing capability linkage metadata.
MISSING_FILE="$TMP_DIR/debt-missing-capability.json"
python3 - "$MISSING_FILE" <<'PY'
import json
import sys
path = sys.argv[1]
payload = {
  "version": 2,
  "entries": [
    {
      "id": "DEBT-MISSING-1",
      "summary": "missing capability id",
      "status": "open",
      "severity": "medium",
      "opened_on": "2026-01-01",
      "expires_on": "2026-12-31",
      "mandatory_block": False
    }
  ]
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write("\n")
PY

if python3 "$CHECKER" --registry "$REGISTRY" --debt "$MISSING_FILE" --today 2026-02-21 >"$TMP_DIR/missing.log" 2>&1; then
  echo "expected proof debt checker to fail for missing capability linkage"
  exit 1
fi
if ! rg -q "missing keys: capability_id" "$TMP_DIR/missing.log"; then
  echo "missing-linkage diagnostic was not reported"
  cat "$TMP_DIR/missing.log"
  exit 1
fi

# Case 2: expired open debt entry must fail.
EXPIRED_FILE="$TMP_DIR/debt-expired.json"
python3 - "$EXPIRED_FILE" <<'PY'
import json
import sys
path = sys.argv[1]
payload = {
  "version": 2,
  "entries": [
    {
      "id": "DEBT-EXPIRED-1",
      "capability_id": "cap.scalar.felt252.add",
      "summary": "expired debt",
      "status": "open",
      "severity": "low",
      "opened_on": "2025-01-01",
      "expires_on": "2026-01-01",
      "mandatory_block": False
    }
  ]
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write("\n")
PY

if python3 "$CHECKER" --registry "$REGISTRY" --debt "$EXPIRED_FILE" --today 2026-02-21 >"$TMP_DIR/expired.log" 2>&1; then
  echo "expected proof debt checker to fail for expired open debt"
  exit 1
fi
if ! rg -q "open debt entry is expired" "$TMP_DIR/expired.log"; then
  echo "expired-debt diagnostic was not reported"
  cat "$TMP_DIR/expired.log"
  exit 1
fi

# Case 3: mandatory unresolved debt cannot coexist with implemented capability.
BLOCKING_FILE="$TMP_DIR/debt-blocking.json"
python3 - "$BLOCKING_FILE" <<'PY'
import json
import sys
path = sys.argv[1]
payload = {
  "version": 2,
  "entries": [
    {
      "id": "DEBT-BLOCK-1",
      "capability_id": "cap.scalar.felt252.add",
      "summary": "mandatory unresolved debt",
      "status": "open",
      "severity": "high",
      "opened_on": "2026-01-01",
      "expires_on": "2026-12-31",
      "mandatory_block": True
    }
  ]
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write("\n")
PY

if python3 "$CHECKER" --registry "$REGISTRY" --debt "$BLOCKING_FILE" --today 2026-02-21 >"$TMP_DIR/blocking.log" 2>&1; then
  echo "expected proof debt checker to fail for unresolved mandatory debt on implemented capability"
  exit 1
fi
if ! rg -q "open mandatory debt blocks implemented capability" "$TMP_DIR/blocking.log"; then
  echo "mandatory-block diagnostic was not reported"
  cat "$TMP_DIR/blocking.log"
  exit 1
fi

# Sanity check: baseline debt file remains valid.
python3 "$CHECKER" --registry "$REGISTRY" --debt "$BASE_DEBT" --today 2026-02-21 >/dev/null

echo "proof debt policy negative checks passed"
