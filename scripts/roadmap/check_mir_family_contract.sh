#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 "$ROOT_DIR/scripts/roadmap/validate_mir_family_contract.py" \
  --contract "$ROOT_DIR/roadmap/capabilities/mir-family-contract.json" \
  --ir-expr "$ROOT_DIR/src/LeanCairo/Compiler/IR/Expr.lean" \
  --eval "$ROOT_DIR/src/LeanCairo/Compiler/Semantics/Eval.lean" \
  --optimize "$ROOT_DIR/src/LeanCairo/Compiler/Optimize/Expr.lean"

echo "MIR family contract checks passed"
