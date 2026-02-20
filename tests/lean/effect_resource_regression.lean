import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Semantics

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  let ctx : EvalContext := {}
  let seed : ResourceCarriers := { rangeCheck := 2, gas := 5, segmentArena := 1 }

  -- Arithmetic consumes gas while preserving seeded range-check counts.
  let addExpr : IRExpr .u128 := .addU128 (.litU128 2) (.litU128 3)
  let (addValue, addState) := evalExprWithResources ctx seed addExpr
  assertCondition (addValue = 5) "u128 addition value should evaluate to 5"
  assertCondition (addState.gas = 6) "u128 addition should consume one gas unit"
  assertCondition (addState.rangeCheck = 2) "u128 addition should not consume range-check units"

  -- Comparison consumes gas plus one range-check unit.
  let cmpExpr : IRExpr .bool := .ltU128 (.litU128 1) (.litU128 4)
  let (cmpValue, cmpState) := evalExprWithResources ctx {} cmpExpr
  assertCondition cmpValue "lt_u128 should evaluate to true for 1 < 4"
  assertCondition (cmpState.gas = 1) "lt_u128 should consume one gas unit"
  assertCondition (cmpState.rangeCheck = 1) "lt_u128 should consume one range-check unit"

  -- Resource cost is compositional through let bindings.
  let nestedExpr : IRExpr .u128 :=
    .letE "tmp" .u128 (.addU128 (.litU128 1) (.litU128 1))
      (.addU128 (.var (ty := .u128) "tmp") (.litU128 5))
  let (_, nestedState) := evalExprWithResources ctx {} nestedExpr
  assertCondition (nestedState.gas = 2) "two u128 additions in let-chain should consume two gas units"

  -- EffectExpr threads explicit initial resource carriers.
  let seeded : EffectExpr .u128 := { expr := addExpr, resources := { gas := 10 } }
  let (_, seededState) := evalEffectExpr ctx seeded
  assertCondition (seededState.gas = 11) "effect evaluator should preserve and increment seeded gas"
