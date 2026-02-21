#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY_REL="roadmap/capabilities/registry.json"
DEBT_REL="roadmap/proof-debt.json"
if [[ -n "${PROOF_DEBT_TODAY:-}" ]]; then
  python3 "$ROOT_DIR/scripts/roadmap/check_proof_debt_policy.py" \
    --registry "$ROOT_DIR/$REGISTRY_REL" \
    --debt "$ROOT_DIR/$DEBT_REL" \
    --today "$PROOF_DEBT_TODAY" \
    "$@"
else
  python3 "$ROOT_DIR/scripts/roadmap/check_proof_debt_policy.py" \
    --registry "$ROOT_DIR/$REGISTRY_REL" \
    --debt "$ROOT_DIR/$DEBT_REL" \
    "$@"
fi

echo "proof debt policy gate passed"
