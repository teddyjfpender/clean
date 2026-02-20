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

private def refAdd (lhs rhs : Nat) : Nat :=
  normalizeU128 (lhs + rhs)

private def refSub (lhs rhs : Nat) : Nat :=
  normalizeU128 (lhs + IntegerDomains.pow2 128 - rhs)

private def refMul (lhs rhs : Nat) : Nat :=
  normalizeU128 (lhs * rhs)

#eval do
  let maxU128 := IntegerDomains.pow2 128 - 1

  let addCases : List (Nat × Nat) :=
    [
      (0, 0),
      (1, 2),
      (maxU128, 1),
      (maxU128, maxU128),
      (maxU128 + 9, 17)
    ]
  addCases.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u128Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }
    let expr : LeanCairo.Compiler.IR.IRExpr .u128 :=
      .addU128
        (.var (ty := .u128) "lhs")
        (.var (ty := .u128) "rhs")
    let observed <- runExpr ctx expr
    let expected := refAdd (normalizeU128 lhsRaw) (normalizeU128 rhsRaw)
    assertCondition (observed = expected)
      s!"u128 add differential mismatch for lhs={lhsRaw}, rhs={rhsRaw}: observed={observed}, expected={expected}")

  let subCases : List (Nat × Nat) :=
    [
      (0, 0),
      (0, 1),
      (9, 5),
      (5, 9),
      (maxU128, maxU128 + 2)
    ]
  subCases.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u128Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }
    let expr : LeanCairo.Compiler.IR.IRExpr .u128 :=
      .subU128
        (.var (ty := .u128) "lhs")
        (.var (ty := .u128) "rhs")
    let observed <- runExpr ctx expr
    let expected := refSub (normalizeU128 lhsRaw) (normalizeU128 rhsRaw)
    assertCondition (observed = expected)
      s!"u128 sub differential mismatch for lhs={lhsRaw}, rhs={rhsRaw}: observed={observed}, expected={expected}")

  let mulCases : List (Nat × Nat) :=
    [
      (0, 0),
      (1, 2),
      (17, 31),
      (maxU128, 2),
      (maxU128, maxU128),
      (maxU128 + 5, 3)
    ]
  mulCases.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u128Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }
    let expr : LeanCairo.Compiler.IR.IRExpr .u128 :=
      .mulU128
        (.var (ty := .u128) "lhs")
        (.var (ty := .u128) "rhs")
    let observed <- runExpr ctx expr
    let expected := refMul (normalizeU128 lhsRaw) (normalizeU128 rhsRaw)
    assertCondition (observed = expected)
      s!"u128 mul differential mismatch for lhs={lhsRaw}, rhs={rhsRaw}: observed={observed}, expected={expected}")
