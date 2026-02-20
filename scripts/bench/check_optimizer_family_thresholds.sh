#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${1:-$ROOT_DIR/config/optimizer-family-thresholds.json}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "missing optimizer threshold config: $CONFIG_FILE"
  exit 1
fi

TARGET_ROWS_FILE="$(mktemp)"
trap 'rm -f "$TARGET_ROWS_FILE"' EXIT

python3 - "$CONFIG_FILE" >"$TARGET_ROWS_FILE" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
payload = json.loads(config_path.read_text(encoding="utf-8"))
targets = payload.get("targets")
if not isinstance(targets, list) or not targets:
    raise SystemExit(f"invalid optimizer threshold config: {config_path}")

required = ("family", "module", "contract", "inlining_strategy", "max_regression_pct")
for idx, target in enumerate(targets):
    if not isinstance(target, dict):
        raise SystemExit(f"invalid target at index {idx}: expected object")
    missing = [key for key in required if key not in target]
    if missing:
        raise SystemExit(f"target {idx} missing required keys: {', '.join(missing)}")
    print(
        "\t".join(
            [
                str(target["family"]),
                str(target["module"]),
                str(target["contract"]),
                str(target["inlining_strategy"]),
                str(target["max_regression_pct"]),
            ]
        )
    )
PY

if [[ -z "$(sed '/^$/d' "$TARGET_ROWS_FILE")" ]]; then
  echo "optimizer threshold config has no targets: $CONFIG_FILE"
  exit 1
fi

target_count=0
while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  target_count=$((target_count + 1))
  IFS=$'\t' read -r family module_name contract_name inlining_strategy max_regression_pct <<<"$row"
  echo "optimizer family gate: family=$family module=$module_name contract=$contract_name max_regression_pct=$max_regression_pct"
  "$ROOT_DIR/scripts/bench/check_optimizer_non_regression.sh" \
    "$module_name" \
    "$contract_name" \
    "$inlining_strategy" \
    "$max_regression_pct"
done <"$TARGET_ROWS_FILE"

echo "optimizer family threshold checks passed ($target_count targets)"
