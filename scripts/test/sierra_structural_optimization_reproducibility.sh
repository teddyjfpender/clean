#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

INPUT="$ROOT_DIR/tests/golden/sierra_subset/program.sierra.json"
OUT_A="$TMP_DIR/a.sierra.json"
OUT_B="$TMP_DIR/b.sierra.json"

python3 "$ROOT_DIR/scripts/sierra/optimize_structural.py" --input "$INPUT" --out "$OUT_A"
python3 "$ROOT_DIR/scripts/sierra/optimize_structural.py" --input "$INPUT" --out "$OUT_B"

diff -u "$OUT_A" "$OUT_B" >/dev/null

echo "sierra structural optimization reproducibility checks passed"
