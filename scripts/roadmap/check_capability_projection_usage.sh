#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKEND_FILE="$ROOT_DIR/src/LeanCairo/Backend/Sierra/Emit/Subset/Function.lean"
PROJECTION_FILE="$ROOT_DIR/src/LeanCairo/Backend/Sierra/Generated/CapabilityProjection.lean"

if [[ ! -f "$BACKEND_FILE" ]]; then
  echo "missing backend file: $BACKEND_FILE"
  exit 1
fi
if [[ ! -f "$PROJECTION_FILE" ]]; then
  echo "missing projection file: $PROJECTION_FILE"
  exit 1
fi

python3 - "$BACKEND_FILE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

if "import LeanCairo.Backend.Sierra.Generated.CapabilityProjection" not in text:
    print("missing capability projection import in subset backend")
    raise SystemExit(1)

start = re.search(r"def\s+ensureFunctionTySupported\b", text)
if not start:
    print("unable to locate ensureFunctionTySupported body")
    raise SystemExit(1)

tail = text[start.start():]
next_def = re.search(r"\n\ndef\s+\w+", tail)
body = tail if not next_def else tail[:next_def.start()]

if "isSierraSignatureTySupported ty" not in body:
    print("ensureFunctionTySupported must consume generated projection lookup")
    raise SystemExit(1)
if "match ty with" in body:
    print("manual type-match support map detected in ensureFunctionTySupported")
    raise SystemExit(1)

print("capability projection usage checks passed")
PY
