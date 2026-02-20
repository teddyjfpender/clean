#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "missing required tool: $tool" >&2
    exit 1
  fi
}

require_tool rg
require_tool python3

scan_patterns=(
  "*.lean"
  "*.md"
  "*.toml"
  "*.sh"
  "*.py"
  "*.cairo"
  "*.yml"
  "*.yaml"
)

glob_args=()
for pattern in "${scan_patterns[@]}"; do
  glob_args+=(--glob "$pattern")
done
glob_args+=(--glob "!.artifacts/**")
scan_targets=(
  src
  scripts
  tests
  docs
  .github
  README.md
  lakefile.lean
  lean-toolchain
  .editorconfig
  .gitignore
)

if rg --line-number --color never "[[:space:]]+$" "${glob_args[@]}" "${scan_targets[@]}"; then
  echo "trailing whitespace detected" >&2
  exit 1
fi

if rg --line-number --color never $'\t' "${glob_args[@]}" "${scan_targets[@]}"; then
  echo "tab characters detected" >&2
  exit 1
fi

if rg --line-number --color never $'\r$' "${glob_args[@]}" "${scan_targets[@]}"; then
  echo "CRLF line endings detected" >&2
  exit 1
fi

shell_files=()
while IFS= read -r script_path; do
  shell_files+=("$script_path")
done < <(rg --files scripts -g "*.sh")

for script_file in "${shell_files[@]}"; do
  if [[ -z "$script_file" ]]; then
    continue
  fi
  first_line="$(head -n 1 "$script_file")"
  if [[ "$first_line" != "#!/usr/bin/env bash" ]]; then
    echo "shell script missing canonical bash shebang: $script_file" >&2
    exit 1
  fi
  if ! head -n 5 "$script_file" | rg -q "set -euo pipefail"; then
    echo "shell script missing strict mode: $script_file" >&2
    exit 1
  fi
done

python_files=()
while IFS= read -r python_path; do
  python_files+=("$python_path")
done < <(rg --files scripts -g "*.py")
if [[ "${#python_files[@]}" -gt 0 ]]; then
  python3 - "${python_files[@]}" <<'PY'
import ast
import pathlib
import sys

for raw_path in sys.argv[1:]:
    path = pathlib.Path(raw_path)
    ast.parse(path.read_text(), filename=str(path))
PY
fi

if command -v shellcheck >/dev/null 2>&1; then
  if [[ "${#shell_files[@]}" -gt 0 ]]; then
    shellcheck "${shell_files[@]}"
  fi
else
  echo "warning: shellcheck not installed; skipping shellcheck" >&2
fi

echo "pedantic lint checks passed"
