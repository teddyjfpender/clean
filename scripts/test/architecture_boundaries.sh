#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_architecture_boundaries.sh"
TMP_FILE="$ROOT_DIR/src/LeanCairo/Core/_BoundaryViolationTest.lean"
LOG_FILE="$(mktemp -t leancairo_arch_boundary_negative.XXXXXX.log)"

cleanup() {
  rm -f "$TMP_FILE"
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

"$CHECKER"

cat > "$TMP_FILE" <<'EOF'
import LeanCairo.Backend.Cairo.EmitContract

namespace LeanCairo.Core
def __boundaryViolationSentinel : Nat := 0
end LeanCairo.Core
EOF

if "$CHECKER" >"$LOG_FILE" 2>&1; then
  echo "expected architecture checker to fail when forbidden import is introduced"
  exit 1
fi

if ! grep -q "_BoundaryViolationTest.lean" "$LOG_FILE"; then
  echo "architecture checker failed, but did not report the injected violating file"
  cat "$LOG_FILE"
  exit 1
fi

echo "architecture boundary regression test passed"
