import LeanCairo.Compiler.Semantics.Eval
import LeanCairo.Core.Syntax.Expr
import LeanCairo.Core.Domain.Ty

open LeanCairo.Compiler.Semantics
open LeanCairo.Core.Domain
open LeanCairo.Core.Syntax

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

private def runExpr (ctx : EvalContext) (expr : LeanCairo.Compiler.IR.IRExpr ty) :
    IO (Ty.denote ty) := do
  let state : SemanticState := { context := ctx, resources := {}, failure := none }
  match evalExprStateStrict state expr with
  | .ok (value, _) => pure value
  | .error err => throw <| IO.userError s!"unexpected strict evaluation error: {err}"

private def normalizeU128 (value : Nat) : Nat :=
  IntegerDomains.normalizeUnsigned 128 value

private def refFeltAffine (x y : Int) : Int :=
  ((x + 7) * y) - x

#eval do
  -- felt252 arithmetic differential checks.
  let feltCases : List (Int × Int) :=
    [(-7, 0), (0, 13), (2, -11), (35, 9)]
  feltCases.forM (fun pair => do
    let (x, y) := pair
    let ctx : EvalContext :=
      {
        feltVars := fun name =>
          if name = "x" then x
          else if name = "y" then y
          else 0
      }
    let expr : LeanCairo.Compiler.IR.IRExpr .felt252 :=
      .letE
        "sum"
        .felt252
        (.addFelt252 (.var (ty := .felt252) "x") (.litFelt252 7))
        (.subFelt252
          (.mulFelt252
            (.var (ty := .felt252) "sum")
            (.var (ty := .felt252) "y"))
          (.var (ty := .felt252) "x"))
    let observed <- runExpr ctx expr
    let expected := refFeltAffine x y
    assertCondition (observed = expected)
      s!"felt differential mismatch for case x={x}, y={y}: observed={observed}, expected={expected}")

  -- felt252 equality differential checks.
  let feltEqCases : List (Int × Int) :=
    [(-1, -1), (0, 1), (12, 12), (42, -42)]
  feltEqCases.forM (fun pair => do
    let (lhs, rhs) := pair
    let ctx : EvalContext :=
      {
        feltVars := fun name =>
          if name = "lhs" then lhs
          else if name = "rhs" then rhs
          else 0
      }
    let expr : LeanCairo.Compiler.IR.IRExpr .bool :=
      .eq
        (.var (ty := .felt252) "lhs")
        (.var (ty := .felt252) "rhs")
    let observed <- runExpr ctx expr
    let expected := decide (lhs = rhs)
    assertCondition (observed = expected)
      s!"felt eq differential mismatch for case lhs={lhs}, rhs={rhs}")

  -- u128 equality differential checks (normalized 128-bit domain).
  let maxU128 := IntegerDomains.pow2 128 - 1
  let u128EqCases : List (Nat × Nat) :=
    [(0, 0), (maxU128, maxU128), (maxU128 + 1, 0), (5, 9)]
  u128EqCases.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u128Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }
    let expr : LeanCairo.Compiler.IR.IRExpr .bool :=
      .eq
        (.var (ty := .u128) "lhs")
        (.var (ty := .u128) "rhs")
    let observed <- runExpr ctx expr
    let expected := decide (normalizeU128 lhsRaw = normalizeU128 rhsRaw)
    assertCondition (observed = expected)
      s!"u128 eq differential mismatch for case lhs={lhsRaw}, rhs={rhsRaw}")

  -- Bool literals and identity differential checks.
  let literalTrueExpr : LeanCairo.Compiler.IR.IRExpr .bool := .litBool true
  let literalTrue <- runExpr {} literalTrueExpr
  assertCondition literalTrue "literal true differential mismatch"

  let boolCtx : EvalContext := { boolVars := fun name => name = "flag" }
  let boolIdentityExpr : LeanCairo.Compiler.IR.IRExpr .bool := .var (ty := .bool) "flag"
  let observedIdentity <- runExpr boolCtx boolIdentityExpr
  assertCondition observedIdentity "bool identity differential mismatch"
