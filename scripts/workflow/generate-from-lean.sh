#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/.elan/bin:$PATH"
cd "$ROOT_DIR"

lake exe leancairo-gen "$@"
