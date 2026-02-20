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
  let baseCtx : EvalContext := {}
  let ctxI8 <- match EvalContext.bindVarStrict baseCtx .i8 "signed" (-129) with
    | .ok next => pure next
    | .error err => throw <| IO.userError s!"unexpected strict i8 bind error: {err}"
  let ctxQm31 <- match EvalContext.bindVarStrict ctxI8 .qm31 "field" (IntegerDomains.qm31Modulus + 4) with
    | .ok next => pure next
    | .error err => throw <| IO.userError s!"unexpected strict qm31 bind error: {err}"
  let ctxU128 <- match EvalContext.bindVarStrict ctxQm31 .u128 "wide" (IntegerDomains.pow2 128 + 7) with
    | .ok next => pure next
    | .error err => throw <| IO.userError s!"unexpected strict u128 bind error: {err}"

  let readSigned <- match EvalContext.readVarStrict ctxU128 .i8 "signed" with
    | .ok value => pure value
    | .error err => throw <| IO.userError s!"unexpected strict i8 read error: {err}"
  let readField <- match EvalContext.readVarStrict ctxU128 .qm31 "field" with
    | .ok value => pure value
    | .error err => throw <| IO.userError s!"unexpected strict qm31 read error: {err}"
  assertCondition (readSigned = 127) "typed strict context should normalize i8 while preserving resource-independent state"
  assertCondition (readField = 4) "typed strict context should normalize qm31 while preserving resource-independent state"

  let seededState : SemanticState :=
    { context := ctxU128, resources := { gas := 5, rangeCheck := 3 }, failure := none }
  let expr : IRExpr .u128 :=
    .letE "tmp" .u128 (.addU128 (.var (ty := .u128) "wide") (.litU128 1))
      (.subU128 (.var (ty := .u128) "tmp") (.litU128 2))

  match evalExprStateStrict seededState expr with
  | .error err =>
      throw <| IO.userError s!"expected strict mixed workload success, got error: {err}"
  | .ok (value, nextState) =>
      assertCondition (value = 6) "strict mixed workload should preserve typed-domain arithmetic semantics"
      assertCondition (nextState.resources.gas = 7) "strict mixed workload should consume gas for two arithmetic nodes"
      assertCondition (nextState.resources.rangeCheck = 3)
        "strict mixed workload should preserve range-check when expression has no range-check ops"
      assertCondition (nextState.failure = none) "strict mixed workload should preserve empty failure channel"

  let failedState : SemanticState := { seededState with failure := some "panic: typed-state" }
  match evalExprStateStrict failedState expr with
  | .error err =>
      assertCondition (err = "panic: typed-state") "strict mixed workload should short-circuit on failure channel"
  | .ok _ =>
      throw <| IO.userError "expected strict mixed workload to fail when failure channel is pre-seeded"
