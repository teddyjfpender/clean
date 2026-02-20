#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "usage: $0 <generated-project-dir>" >&2
  exit 1
fi

GENERATED_DIR="$1"
(
  cd "$GENERATED_DIR"
  scarb build
)
