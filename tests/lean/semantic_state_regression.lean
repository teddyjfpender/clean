import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Semantics

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  let baseState : SemanticState :=
    {
      context := {}
      resources := { gas := 3, rangeCheck := 2 }
      failure := none
    }
  let expr : IRExpr .u128 := .addU128 (.litU128 4) (.litU128 5)
  match evalExprState baseState expr with
  | .error err =>
      throw <| IO.userError s!"expected successful semantic state transition, got error: {err}"
  | .ok (value, nextState) =>
      assertCondition (value = 9) "semantic state evaluator should preserve expression value"
      assertCondition (nextState.resources.gas = 4) "semantic state evaluator should increment gas by one for addition"
      assertCondition (nextState.resources.rangeCheck = 2) "semantic state evaluator should preserve range-check for addition"
      assertCondition (nextState.failure = none) "semantic state evaluator should preserve empty failure channel"

  let failedState : SemanticState := { baseState with failure := some "panic: forced" }
  match evalExprState failedState expr with
  | .error err =>
      assertCondition (err = "panic: forced") "semantic state evaluator should short-circuit on existing failure channel"
  | .ok _ =>
      throw <| IO.userError "expected evaluator failure when failure channel is seeded"

  let seededEffect : EffectExpr .bool :=
    {
      expr := .ltU128 (.litU128 1) (.litU128 3)
      resources := { gas := 10, rangeCheck := 7 }
    }
  match evalEffectExprState { baseState with resources := { gas := 2, rangeCheck := 1 } } seededEffect with
  | .error err =>
      throw <| IO.userError s!"expected effect-state success, got error: {err}"
  | .ok (value, nextState) =>
      assertCondition value "effect-state evaluator should preserve comparison value"
      assertCondition (nextState.resources.gas = 13) "effect-state evaluator should merge seed gas and consumed gas"
      assertCondition (nextState.resources.rangeCheck = 9)
        "effect-state evaluator should merge seed range-check and consumed range-check"
