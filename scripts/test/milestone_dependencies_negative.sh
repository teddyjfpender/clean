#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT_DIR/scripts/roadmap/check_milestone_dependencies.py"
LOG_FILE="$(mktemp -t leancairo_milestone_deps_negative.XXXXXX.log)"

cleanup() {
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

if "$CHECKER" --validate-dag --extra-edge "M-01-1:M-01-3" >"$LOG_FILE" 2>&1; then
  echo "expected milestone checker to fail when cycle is introduced"
  exit 1
fi

if ! grep -q "cycle" "$LOG_FILE"; then
  echo "cycle injection failed without cycle diagnostic"
  cat "$LOG_FILE"
  exit 1
fi

STATUS_EDGE="$(
  cd "$ROOT_DIR"
  python3 - <<'PY'
import re
from pathlib import Path
import importlib.util

spec = importlib.util.spec_from_file_location(
    "milestone_deps",
    "scripts/roadmap/check_milestone_dependencies.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

issue_paths = sorted(Path("roadmap/executable-issues").rglob("*.issue.md"))
statuses, issue_to_milestones = mod.parse_milestones(issue_paths)
deps = mod.build_dependencies(issue_to_milestones, [])

done_nodes = sorted(
    milestone
    for milestone, status in statuses.items()
    if re.match(r"^DONE - [0-9a-f]{7,40}$", status)
)
not_done_nodes = sorted(
    milestone
    for milestone, status in statuses.items()
    if status == "NOT DONE"
)

reverse_deps = {}
for child, parents in deps.items():
    for parent in parents:
        reverse_deps.setdefault(parent, set()).add(child)

def depends_on(start: str, target: str) -> bool:
    stack = list(deps.get(start, set()))
    seen = set()
    while stack:
        node = stack.pop()
        if node == target:
            return True
        if node in seen:
            continue
        seen.add(node)
        stack.extend(deps.get(node, set()))
    return False

for child in done_nodes:
    for parent in not_done_nodes:
        if child == parent:
            continue
        # Avoid cycle injection for this check: we need a pure status violation.
        if depends_on(parent, child):
            continue
        print(f"{child}:{parent}")
        raise SystemExit(0)

raise SystemExit(1)
PY
)"

if [[ -z "$STATUS_EDGE" ]]; then
  echo "failed to derive done->not-done edge for status-order negative test"
  exit 1
fi

if "$CHECKER" --extra-edge "$STATUS_EDGE" >"$LOG_FILE" 2>&1; then
  echo "expected milestone checker to fail when done milestone depends on not-done milestone"
  exit 1
fi

if ! grep -q "dependency violation" "$LOG_FILE"; then
  echo "status-order injection failed without dependency diagnostic"
  cat "$LOG_FILE"
  exit 1
fi

echo "milestone dependency negative regression passed"
