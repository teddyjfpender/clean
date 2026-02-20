#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_architecture_boundaries.sh"
TMP_FILE="$ROOT_DIR/src/LeanCairo/Pipeline/Sierra/_CairoCouplingViolationTest.lean"
LOG_FILE="$(mktemp -t leancairo_sierra_cairo_coupling.XXXXXX.log)"

cleanup() {
  rm -f "$TMP_FILE"
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

cat > "$TMP_FILE" <<'EOF'
import LeanCairo.Backend.Cairo.EmitIRContract

namespace LeanCairo.Pipeline.Sierra
def __cairoCouplingSentinel : Nat := 0
end LeanCairo.Pipeline.Sierra
EOF

if "$CHECKER" >"$LOG_FILE" 2>&1; then
  echo "expected architecture checker to fail for Sierra primary-path Cairo coupling"
  exit 1
fi

if ! grep -q "_CairoCouplingViolationTest.lean" "$LOG_FILE"; then
  echo "architecture checker failed, but did not report the injected coupling file"
  cat "$LOG_FILE"
  exit 1
fi

echo "sierra primary-path Cairo coupling guard passed"
