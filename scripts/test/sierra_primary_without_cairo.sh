#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CAIRO_BACKEND_DIR="$ROOT_DIR/src/LeanCairo/Backend/Cairo"
DISABLED_ROOT="$(mktemp -d -t leancairo_disable_cairo.XXXXXX)"
DISABLED_DIR="$DISABLED_ROOT/Cairo"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_primary_without_cairo"
export PATH="$HOME/.elan/bin:$PATH"

if [[ ! -d "$CAIRO_BACKEND_DIR" ]]; then
  echo "missing Cairo backend directory: $CAIRO_BACKEND_DIR"
  exit 1
fi

restore_backend() {
  if [[ -d "$DISABLED_DIR" && ! -d "$CAIRO_BACKEND_DIR" ]]; then
    mv "$DISABLED_DIR" "$CAIRO_BACKEND_DIR"
  fi
  rm -rf "$DISABLED_ROOT"
}
trap restore_backend EXIT

mv "$CAIRO_BACKEND_DIR" "$DISABLED_DIR"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

(
  cd "$ROOT_DIR"
  lake build leancairo-sierra-gen
  lake exe leancairo-sierra-gen --module MyLeanSierraSubset --out "$OUT_DIR" --optimize true
)

if [[ ! -s "$OUT_DIR/sierra/program.sierra.json" ]]; then
  echo "expected Sierra program output at $OUT_DIR/sierra/program.sierra.json"
  exit 1
fi

echo "sierra primary pipeline works with Cairo backend disabled"
