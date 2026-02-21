#!/usr/bin/env bash
set -euo pipefail

RETRIES=0
TIMEOUT_SEC=0

usage() {
  echo "usage: $0 [--retries <n>] [--timeout-sec <n>] -- <gate-command>"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --retries)
      RETRIES="${2:-}"
      shift 2
      ;;
    --timeout-sec)
      TIMEOUT_SEC="${2:-}"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$#" -eq 0 ]]; then
  usage
  exit 1
fi

if ! [[ "$RETRIES" =~ ^[0-9]+$ ]]; then
  echo "invalid retries value: $RETRIES"
  exit 1
fi
if ! [[ "$TIMEOUT_SEC" =~ ^[0-9]+$ ]]; then
  echo "invalid timeout value: $TIMEOUT_SEC"
  exit 1
fi

ATTEMPT=0
MAX_ATTEMPTS=$((RETRIES + 1))

while (( ATTEMPT < MAX_ATTEMPTS )); do
  ATTEMPT=$((ATTEMPT + 1))

  if (( TIMEOUT_SEC > 0 )) && command -v timeout >/dev/null 2>&1; then
    if timeout "$TIMEOUT_SEC" "$@"; then
      echo "gate retry wrapper: success (attempt=${ATTEMPT}/${MAX_ATTEMPTS})"
      exit 0
    fi
  else
    if "$@"; then
      echo "gate retry wrapper: success (attempt=${ATTEMPT}/${MAX_ATTEMPTS})"
      exit 0
    fi
  fi

  if (( ATTEMPT < MAX_ATTEMPTS )); then
    # deterministic fixed backoff
    sleep 1
  fi
done

echo "gate retry wrapper: failure after ${MAX_ATTEMPTS} attempts"
exit 1
