#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY_REL="roadmap/capabilities/registry.json"
OBLIGATIONS_REL="roadmap/capabilities/obligations.json"

TMP_A="$(mktemp -d)"
TMP_B="$(mktemp -d)"
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

(
  cd "$ROOT_DIR"
  python3 scripts/roadmap/project_capability_obligations.py \
    --registry "$REGISTRY_REL" \
    --obligations "$OBLIGATIONS_REL" \
    --out-json "$TMP_A/capability-obligation-report.json" \
    --out-md "$TMP_A/capability-obligation-report.md"
  python3 scripts/roadmap/project_capability_obligations.py \
    --registry "$REGISTRY_REL" \
    --obligations "$OBLIGATIONS_REL" \
    --out-json "$TMP_B/capability-obligation-report.json" \
    --out-md "$TMP_B/capability-obligation-report.md"
)

diff -u "$TMP_A/capability-obligation-report.json" "$TMP_B/capability-obligation-report.json" >/dev/null
diff -u "$TMP_A/capability-obligation-report.md" "$TMP_B/capability-obligation-report.md" >/dev/null

echo "capability obligation reproducibility checks passed"
