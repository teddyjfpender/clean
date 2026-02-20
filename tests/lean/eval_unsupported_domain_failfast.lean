import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  let baseState : SemanticState := { context := {}, resources := {}, failure := none }

  let unsupportedVarExpr : IRExpr (.tuple 2) := .var "x"
  let expectedVarError := EvalContext.unsupportedDomainMessage "variable read" (.tuple 2) "x"
  match evalExprStateStrict baseState unsupportedVarExpr with
  | .error err =>
      assertCondition (err = expectedVarError)
        "strict evaluator should fail-fast with stable variable-read error for unsupported tuple domain"
  | .ok _ =>
      throw <| IO.userError "expected strict evaluator to reject unsupported tuple variable read"

  let unsupportedStorageExpr : IRExpr (.array "felt252") := .storageRead "slot"
  let expectedStorageError := EvalContext.unsupportedDomainMessage "storage read" (.array "felt252") "slot"
  match evalExprStateStrict baseState unsupportedStorageExpr with
  | .error err =>
      assertCondition (err = expectedStorageError)
        "strict evaluator should fail-fast with stable storage-read error for unsupported array domain"
  | .ok _ =>
      throw <| IO.userError "expected strict evaluator to reject unsupported array storage read"

  -- Determinism: same input state/expression yields same strict failure payload.
  let deterministicExpr : IRExpr (.span "u128") := .var "arg"
  let resultA := evalExprStateStrict baseState deterministicExpr
  let resultB := evalExprStateStrict baseState deterministicExpr
  match resultA, resultB with
  | .error errA, .error errB =>
      assertCondition (errA = errB) "strict fail-fast errors must be deterministic"
  | _, _ =>
      throw <| IO.userError "expected deterministic strict failure results for unsupported span variable read"

  -- Supported expressions still evaluate successfully in strict mode.
  let supportedExpr : IRExpr .u128 := .addU128 (.litU128 2) (.litU128 4)
  match evalExprStateStrict baseState supportedExpr with
  | .error err =>
      throw <| IO.userError s!"expected supported strict evaluation to succeed, got error: {err}"
  | .ok (value, nextState) =>
      assertCondition (value = 6) "strict evaluator should preserve value for supported expression"
      assertCondition (nextState.resources.gas = 1) "strict evaluator should preserve resource accounting for supported expression"
