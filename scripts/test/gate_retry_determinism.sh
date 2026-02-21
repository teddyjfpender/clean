#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RETRY_WRAPPER="$ROOT_DIR/scripts/workflow/run_gate_with_retry.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ALWAYS_FAIL="$TMP_DIR/always_fail.sh"
cat > "$ALWAYS_FAIL" <<'SH'
#!/usr/bin/env bash
exit 1
SH
chmod +x "$ALWAYS_FAIL"

if "$RETRY_WRAPPER" --retries 2 --timeout-sec 0 -- "$ALWAYS_FAIL" >"$TMP_DIR/fail.log" 2>&1; then
  echo "expected retry wrapper to fail for deterministic always-fail gate"
  exit 1
fi
if ! rg -q "failure after 3 attempts" "$TMP_DIR/fail.log"; then
  echo "retry wrapper did not report deterministic attempt count"
  cat "$TMP_DIR/fail.log"
  exit 1
fi

ALWAYS_PASS="$TMP_DIR/always_pass.sh"
cat > "$ALWAYS_PASS" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$ALWAYS_PASS"

"$RETRY_WRAPPER" --retries 2 --timeout-sec 0 -- "$ALWAYS_PASS" >"$TMP_DIR/pass.log" 2>&1
if ! rg -q "success \(attempt=1/3\)" "$TMP_DIR/pass.log"; then
  echo "retry wrapper did not report deterministic success attempt"
  cat "$TMP_DIR/pass.log"
  exit 1
fi

echo "gate retry determinism checks passed"
