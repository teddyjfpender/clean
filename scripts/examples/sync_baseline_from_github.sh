#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
usage: $0 --id <baseline-id> --repo <owner/repo> --commit <sha> --out-dir <dir> --path <upstream/path> [--path ...] [--execute]
USAGE
}

BASELINE_ID=""
REPO=""
COMMIT=""
OUT_DIR=""
EXECUTE=0
PATHS=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --id)
      BASELINE_ID="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --commit)
      COMMIT="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --path)
      PATHS+=("${2:-}")
      shift 2
      ;;
    --execute)
      EXECUTE=1
      shift
      ;;
    *)
      echo "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$BASELINE_ID" || -z "$REPO" || -z "$COMMIT" || -z "$OUT_DIR" || "${#PATHS[@]}" -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "$EXECUTE" -ne 1 ]]; then
  printf 'baseline-sync-plan id=%s repo=%s commit=%s out=%s files=%s\n' \
    "$BASELINE_ID" "$REPO" "$COMMIT" "$OUT_DIR" "${#PATHS[@]}"
  for path in "${PATHS[@]}"; do
    printf '  - %s\n' "$path"
  done
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required for --execute" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

for path in "${PATHS[@]}"; do
  rel_out="${path//\//__}"
  target="$OUT_DIR/$rel_out"
  gh api "repos/${REPO}/contents/${path}?ref=${COMMIT}" --jq .content | base64 --decode > "$target"
  echo "pulled: $target"
done
