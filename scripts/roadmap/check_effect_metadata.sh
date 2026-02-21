#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
METADATA_PATH="$ROOT_DIR/config/effect-metadata.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --metadata)
      METADATA_PATH="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: $0 [--metadata <path>]"
      exit 1
      ;;
  esac
done

python3 "$ROOT_DIR/scripts/roadmap/validate_effect_metadata.py" --metadata "$METADATA_PATH"

echo "effect metadata checks passed"
