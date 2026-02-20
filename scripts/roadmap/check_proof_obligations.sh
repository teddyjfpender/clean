#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROOF_DIR="$ROOT_DIR/src/LeanCairo/Compiler/Proof"
SEM_DIR="$ROOT_DIR/src/LeanCairo/Compiler/Semantics"
OPT_DIR="$ROOT_DIR/src/LeanCairo/Compiler/Optimize"
RELATION_FILE="$ROOT_DIR/src/LeanCairo/Compiler/Proof/TranslationRelation.lean"

REQUIRED_THEOREMS=(
  "optimizeExprSound"
  "cseLetNormExprSound"
  "optimizeExprPipelineSound"
  "sourceMIRRoundTrip_holds"
  "mirSourceRoundTrip_holds"
  "evalExprState_success_transition"
  "evalExprState_failure_channel"
)

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --require-theorem)
      REQUIRED_THEOREMS+=("${2:-}")
      shift 2
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: $0 [--require-theorem <name>]"
      exit 1
      ;;
  esac
done

ERRORS=0

check_no_sorry() {
  local matches
  if command -v rg >/dev/null 2>&1; then
    matches="$(rg -n '\bsorry\b|\badmit\b' "$PROOF_DIR" "$SEM_DIR" -g '*.lean' || true)"
  else
    matches="$(grep -R -nE '\bsorry\b|\badmit\b' "$PROOF_DIR" "$SEM_DIR" --include='*.lean' || true)"
  fi
  if [[ -n "$(printf '%s\n' "$matches" | sed '/^$/d')" ]]; then
    echo "proof obligations violation: found theorem placeholders"
    printf '%s\n' "$matches"
    ERRORS=$((ERRORS + 1))
  fi
}

check_required_theorems() {
  local theorem_name
  for theorem_name in "${REQUIRED_THEOREMS[@]}"; do
    if [[ -z "$theorem_name" ]]; then
      continue
    fi
    if ! rg -n "theorem[[:space:]]+${theorem_name}\\b" "$PROOF_DIR" "$SEM_DIR" "$OPT_DIR" -g '*.lean' >/dev/null 2>&1; then
      echo "proof obligations violation: missing required theorem '$theorem_name'"
      ERRORS=$((ERRORS + 1))
    fi
  done
}

check_relation_library() {
  if [[ ! -f "$RELATION_FILE" ]]; then
    echo "proof obligations violation: missing translation relation library $RELATION_FILE"
    ERRORS=$((ERRORS + 1))
    return
  fi

  local required_defs=(
    "SourceToMIRRel"
    "MIRToSourceRel"
    "SourceMIRRoundTripRel"
    "MIRSourceRoundTripRel"
  )

  local def_name
  for def_name in "${required_defs[@]}"; do
    if ! rg -n "def[[:space:]]+${def_name}\\b" "$RELATION_FILE" >/dev/null 2>&1; then
      echo "proof obligations violation: missing relation definition '$def_name' in $RELATION_FILE"
      ERRORS=$((ERRORS + 1))
    fi
  done
}

check_pass_sound_bindings() {
  local pass_defs_count
  pass_defs_count="$(rg -n 'def[[:space:]]+[A-Za-z0-9_]+Pass[[:space:]]*:[[:space:]]*VerifiedExprPass[[:space:]]+where' "$OPT_DIR" -g '*.lean' | wc -l | tr -d ' ')"
  local pass_sound_count
  pass_sound_count="$(rg -n 'sound[[:space:]]*:=' "$OPT_DIR" -g '*.lean' | wc -l | tr -d ' ')"

  if [[ "$pass_sound_count" -lt "$pass_defs_count" ]]; then
    echo "proof obligations violation: fewer sound proofs ($pass_sound_count) than pass declarations ($pass_defs_count)"
    ERRORS=$((ERRORS + 1))
  fi
}

check_no_sorry
check_required_theorems
check_relation_library
check_pass_sound_bindings

if [[ "$ERRORS" -ne 0 ]]; then
  echo "proof obligation checks failed with $ERRORS error(s)"
  exit 1
fi

echo "proof obligation checks passed"
