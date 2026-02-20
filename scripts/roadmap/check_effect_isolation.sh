#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

TARGET_DIRS=(
  "$ROOT_DIR/src/LeanCairo/Compiler/IR"
  "$ROOT_DIR/src/LeanCairo/Compiler/Semantics"
  "$ROOT_DIR/src/LeanCairo/Compiler/Optimize"
)

FORBIDDEN_PATTERN='IO\.Ref|unsafePerformIO|IO\.rand|StdGen|set_option[[:space:]]+maxRecDepth'

if command -v rg >/dev/null 2>&1; then
  MATCHES="$(rg -n "$FORBIDDEN_PATTERN" "${TARGET_DIRS[@]}" -g '*.lean' || true)"
else
  MATCHES="$(grep -R -nE "$FORBIDDEN_PATTERN" "${TARGET_DIRS[@]}" --include='*.lean' || true)"
fi

if [[ -n "$(printf '%s\n' "$MATCHES" | sed '/^$/d')" ]]; then
  echo "hidden global effect usage detected in compiler core:"
  printf '%s\n' "$MATCHES"
  exit 1
fi

echo "effect isolation checks passed"
