#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BROKEN_CONTRACT="$TMP_DIR/mir-family-contract-broken.json"
cp "$ROOT_DIR/roadmap/capabilities/mir-family-contract.json" "$BROKEN_CONTRACT"

python3 - "$BROKEN_CONTRACT" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
nodes = payload.get("nodes", [])
if not isinstance(nodes, list) or not nodes:
    raise SystemExit("invalid nodes list in copied contract")

payload["nodes"] = nodes[:-1]
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/roadmap/validate_mir_family_contract.py" \
  --contract "$BROKEN_CONTRACT" \
  --ir-expr "$ROOT_DIR/src/LeanCairo/Compiler/IR/Expr.lean" \
  --eval "$ROOT_DIR/src/LeanCairo/Compiler/Semantics/Eval.lean" \
  --optimize "$ROOT_DIR/src/LeanCairo/Compiler/Optimize/Expr.lean" >/dev/null 2>&1; then
  echo "expected broken MIR family contract to fail validation"
  exit 1
fi

echo "MIR family contract negative checks passed"
