import LeanCairo.Compiler.Optimize.Canonicalize
import LeanCairo.Compiler.Optimize.Expr
import LeanCairo.Compiler.Semantics.Eval

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize
open LeanCairo.Compiler.Semantics

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  let ctxTrue : EvalContext := { boolVars := fun name => name = "flag" }
  let ctxFalse : EvalContext := { boolVars := fun _ => false }

  let constantBranchExpr : IRExpr .u128 := .ite (.litBool true) (.litU128 7) (.litU128 9)
  let normalizedConstant := optimizeExpr constantBranchExpr
  assertCondition (normalizedConstant = IRExpr.litU128 7) "constant true branch should normalize to then-branch"

  let joinExpr : IRExpr .u128 :=
    .ite (.var (ty := .bool) "flag") (.litU128 5) (.litU128 5)
  let normalizedJoin := optimizeExpr joinExpr
  assertCondition (normalizedJoin = IRExpr.litU128 5) "identical branch join should normalize to shared branch expression"

  -- Semantic preservation across control-flow normalization.
  assertCondition (evalExpr ctxTrue normalizedJoin = evalExpr ctxTrue joinExpr)
    "normalized join expression must preserve semantics under true branch context"
  assertCondition (evalExpr ctxFalse normalizedJoin = evalExpr ctxFalse joinExpr)
    "normalized join expression must preserve semantics under false branch context"

  -- Deterministic normalization contract.
  let nestedControlExpr : IRExpr .u128 :=
    .ite (.var (ty := .bool) "flag")
      (.ite (.litBool false) (.litU128 11) (.litU128 12))
      (.letE "tmp" .u128 (.litU128 3) (.var (ty := .u128) "tmp"))
  let runA := normalizeExpr nestedControlExpr
  let runB := normalizeExpr nestedControlExpr
  assertCondition (runA = runB) "control-flow normalization must be deterministic for fixed input"
