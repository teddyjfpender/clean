#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="$ROOT_DIR/src/LeanCairo"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "missing source directory: $SRC_DIR"
  exit 1
fi

ERRORS=0

layer_for_rel_path() {
  local rel_path="$1"
  case "$rel_path" in
    src/LeanCairo/Core/*)
      echo "core"
      ;;
    src/LeanCairo/Compiler/IR/*)
      echo "compiler_ir"
      ;;
    src/LeanCairo/Compiler/Semantics/*)
      echo "compiler_semantics"
      ;;
    src/LeanCairo/Compiler/Optimize/*)
      echo "compiler_optimize"
      ;;
    src/LeanCairo/Compiler/Proof/*)
      echo "compiler_proof"
      ;;
    src/LeanCairo/Backend/Sierra/*)
      echo "backend_sierra"
      ;;
    src/LeanCairo/Backend/Cairo/*)
      echo "backend_cairo"
      ;;
    src/LeanCairo/Backend/Scarb/*)
      echo "backend_scarb"
      ;;
    src/LeanCairo/Pipeline/Sierra/*)
      echo "pipeline_sierra"
      ;;
    src/LeanCairo/Pipeline/Generation/*)
      echo "pipeline_generation"
      ;;
    src/LeanCairo/CLI/*)
      echo "cli_generation"
      ;;
    src/LeanCairo/SierraCLI/*)
      echo "cli_sierra"
      ;;
    src/LeanCairo.lean)
      echo "root_aggregate"
      ;;
    *)
      echo ""
      ;;
  esac
}

allowed_prefixes_for_layer() {
  local layer="$1"
  case "$layer" in
    core)
      cat <<'EOF'
LeanCairo.Core.
EOF
      ;;
    compiler_ir)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
EOF
      ;;
    compiler_semantics)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
LeanCairo.Compiler.Semantics.
EOF
      ;;
    compiler_optimize)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
LeanCairo.Compiler.Semantics.
LeanCairo.Compiler.Optimize.
LeanCairo.Compiler.Proof.
EOF
      ;;
    compiler_proof)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
LeanCairo.Compiler.Semantics.
LeanCairo.Compiler.Optimize.
LeanCairo.Compiler.Proof.
EOF
      ;;
    backend_sierra)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
LeanCairo.Backend.Sierra.
EOF
      ;;
    backend_cairo)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
LeanCairo.Backend.Cairo.
EOF
      ;;
    backend_scarb)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Backend.Cairo.
LeanCairo.Backend.Scarb.
LeanCairo.Pipeline.Generation.
EOF
      ;;
    pipeline_sierra)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
LeanCairo.Compiler.Optimize.
LeanCairo.Backend.Sierra.
LeanCairo.Pipeline.Sierra.
EOF
      ;;
    pipeline_generation)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.Compiler.IR.
LeanCairo.Compiler.Optimize.
LeanCairo.Backend.Cairo.
LeanCairo.Backend.Scarb.
LeanCairo.Pipeline.Generation.
EOF
      ;;
    cli_generation)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.CLI.
LeanCairo.Pipeline.Generation.
EOF
      ;;
    cli_sierra)
      cat <<'EOF'
LeanCairo.Core.
LeanCairo.SierraCLI.
LeanCairo.Pipeline.Sierra.
EOF
      ;;
    root_aggregate)
      cat <<'EOF'
LeanCairo.
EOF
      ;;
    *)
      return 1
      ;;
  esac
}

module_allowed_for_layer() {
  local layer="$1"
  local module="$2"
  local allowed_prefix
  while IFS= read -r allowed_prefix; do
    [[ -z "$allowed_prefix" ]] && continue
    if [[ "$module" == "$allowed_prefix"* ]]; then
      return 0
    fi
  done <<< "$(allowed_prefixes_for_layer "$layer")"
  return 1
}

check_import_boundaries() {
  local file_path="$1"
  local rel_path="$2"
  local layer="$3"
  local line
  local line_no=0

  while IFS= read -r line; do
    line_no=$((line_no + 1))
    if [[ ! "$line" =~ ^import[[:space:]]+ ]]; then
      continue
    fi

    local imports
    imports="${line#import }"
    local module
    for module in $imports; do
      if [[ "$module" != LeanCairo.* ]]; then
        continue
      fi
      if ! module_allowed_for_layer "$layer" "$module"; then
        echo "architecture boundary violation: $rel_path:$line_no ($layer) imports $module"
        ERRORS=$((ERRORS + 1))
      fi
    done
  done < "$file_path"
}

while IFS= read -r lean_file; do
  [[ -z "$lean_file" ]] && continue
  rel_path="${lean_file#"$ROOT_DIR/"}"
  layer="$(layer_for_rel_path "$rel_path")"
  [[ -z "$layer" ]] && continue
  check_import_boundaries "$lean_file" "$rel_path" "$layer"
done <<<"$(find "$ROOT_DIR/src" -type f -name '*.lean' | sort)"

if [[ "$ERRORS" -ne 0 ]]; then
  echo "architecture boundary checks failed with $ERRORS violation(s)"
  exit 1
fi

echo "architecture boundary checks passed"
