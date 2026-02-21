#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/test/run_backend_parity_case.sh" \
  circuit_gate_felt.Example \
  CircuitGateContract \
  "advanced-family parity circuit_gate_felt"

"$ROOT_DIR/scripts/test/run_backend_parity_case.sh" \
  crypto_round_felt.Example \
  CryptoRoundContract \
  "advanced-family parity crypto_round_felt"

echo "advanced-family backend parity checks passed"
