import LeanCairo.Backend.Cairo.Generated.LoweringScaffold
import LeanCairo.Backend.Sierra.Generated.LoweringScaffold
import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Semantics

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  -- Panic/failure propagation remains explicit and deterministic.
  let preFailed : SemanticState :=
    { context := {}, resources := { gas := 4, rangeCheck := 2 }, failure := some "panic:control" }
  let expr : IRExpr .u128 := .addU128 (.litU128 1) (.litU128 2)
  match evalExprStateStrict preFailed expr with
  | .ok _ =>
      throw <| IO.userError "strict evaluator should not execute call-like work after panic channel is set"
  | .error err =>
      assertCondition (err = "panic:control") "panic channel should short-circuit strict evaluation deterministically"

  -- Call/recursion capability remains explicit fail-fast in both lowering scaffolds.
  let capId := "cap.control.calls_loops_panic"
  let sierraMessage := LeanCairo.Backend.Sierra.Generated.sierraLoweringFailFastMessage capId
  let cairoMessage := LeanCairo.Backend.Cairo.Generated.cairoLoweringFailFastMessage capId
  let expectedSierra :=
    "capability 'cap.control.calls_loops_panic' is not implemented for Sierra lowering (state: planned)"
  let expectedCairo :=
    "capability 'cap.control.calls_loops_panic' is not implemented for Cairo lowering (state: planned)"
  assertCondition (sierraMessage = expectedSierra) "Sierra lowering must expose deterministic fail-fast for unsupported call/loop capability"
  assertCondition (cairoMessage = expectedCairo) "Cairo lowering must expose deterministic fail-fast for unsupported call/loop capability"
