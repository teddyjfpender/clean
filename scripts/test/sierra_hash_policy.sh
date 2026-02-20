#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/.artifacts/sierra_hash_policy"
PROGRAM_JSON="$OUT_DIR/sierra/program.sierra.json"
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

(
  cd "$ROOT_DIR"
  lake exe leancairo-sierra-gen --module MyLeanSierraSubset --out "$OUT_DIR" --optimize true
)

python3 - <<'PY' "$PROGRAM_JSON"
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as infile:
    payload = json.load(infile)

FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1


def fnv1a64(value: str) -> int:
    h = FNV_OFFSET
    for byte in value.encode("utf-8"):
        h ^= byte
        h = (h * FNV_PRIME) & MASK64
    return h


violations = []
checked = 0


def walk(node, path_fragment: str) -> None:
    global checked
    if isinstance(node, dict):
        if (
            "id" in node
            and "debug_name" in node
            and isinstance(node["id"], int)
            and isinstance(node["debug_name"], str)
        ):
            checked += 1
            expected = fnv1a64(node["debug_name"])
            if node["id"] != expected:
                violations.append(
                    f"{path_fragment}: debug_name={node['debug_name']!r}, id={node['id']}, expected={expected}"
                )
        for key, value in node.items():
            walk(value, f"{path_fragment}/{key}")
    elif isinstance(node, list):
        for idx, value in enumerate(node):
            walk(value, f"{path_fragment}[{idx}]")


walk(payload, "$")

if checked == 0:
    print(f"no id/debug_name pairs found in {path}")
    sys.exit(1)

if violations:
    print("Sierra hash policy violations detected:")
    for violation in violations:
        print(violation)
    sys.exit(1)

print(f"sierra hash policy check passed ({checked} id/debug_name pairs)")
PY
