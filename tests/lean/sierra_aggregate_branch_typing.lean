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
  let ctx : EvalContext := {}

  let tupleExpr : IRExpr (.tuple 2) :=
    .ite
      (.litBool true)
      (.var (ty := .tuple 2) "lhs")
      (.var (ty := .tuple 2) "rhs")
  let tupleObserved := evalExpr ctx tupleExpr
  assertCondition (tupleObserved = ()) "tuple branch typing should evaluate in aggregate lane"

  let structExpr : IRExpr (.structTy "AggPair") :=
    .ite
      (.litBool false)
      (.var (ty := .structTy "AggPair") "lhs")
      (.var (ty := .structTy "AggPair") "rhs")
  let structObserved := evalExpr ctx structExpr
  assertCondition (structObserved = ()) "struct branch typing should evaluate in aggregate lane"

  let enumExpr : IRExpr (.enumTy "AggChoice") :=
    .ite
      (.litBool true)
      (.var (ty := .enumTy "AggChoice") "lhs")
      (.var (ty := .enumTy "AggChoice") "rhs")
  let enumObserved := evalExpr ctx enumExpr
  assertCondition (enumObserved = ()) "enum branch typing should evaluate in aggregate lane"
