#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
usage: $0 --id <baseline-id> --baseline-dir <dir> --source-dir <dir>
USAGE
}

BASELINE_ID=""
BASELINE_DIR=""
SOURCE_DIR=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --id)
      BASELINE_ID="${2:-}"
      shift 2
      ;;
    --baseline-dir)
      BASELINE_DIR="${2:-}"
      shift 2
      ;;
    --source-dir)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$BASELINE_ID" || -z "$BASELINE_DIR" || -z "$SOURCE_DIR" ]]; then
  usage
  exit 1
fi

# Current baseline patch lane is audit-only: patches are applied in curated benchmark sync scripts.
# This command remains deterministic and explicit for governance tracking.
case "$BASELINE_ID" in
  fast_power_u128|fast_power_u128_p63|karatsuba_u128|newton_u128|sq128x128_u128)
    printf 'baseline-patch-plan id=%s baseline=%s source=%s mode=audit_only\n' \
      "$BASELINE_ID" "$BASELINE_DIR" "$SOURCE_DIR"
    ;;
  *)
    echo "unknown baseline id: $BASELINE_ID"
    exit 1
    ;;
esac
