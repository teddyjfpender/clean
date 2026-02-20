import LeanCairo.Compiler.Optimize.Canonicalize

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

private def feltExpr : IRExpr .felt252 :=
  .addFelt252 (.litFelt252 7) (.litFelt252 8)

private def u128Expr : IRExpr .u128 :=
  .letE "x" .u128 (.litU128 3)
    (.addU128 (.var (ty := .u128) "x") (.litU128 5))

private def boolExpr : IRExpr .bool :=
  .eq (.addU128 (.litU128 1) (.litU128 2)) (.addU128 (.litU128 1) (.litU128 3))

private def nestedExpr : IRExpr .u128 :=
  .letE "a" .u128 (.addU128 (.litU128 1) (.litU128 2))
    (.letE "b" .u128 (.addU128 (.var (ty := .u128) "a") (.litU128 2))
      (.addU128 (.var (ty := .u128) "b") (.litU128 1)))

private def snapshotOnce : String :=
  String.intercalate "\n"
    [
      reprStr (normalizeExpr feltExpr),
      reprStr (normalizeExpr u128Expr),
      reprStr (normalizeExpr boolExpr),
      reprStr (normalizeExpr nestedExpr)
    ]

private def snapshotTwice : String :=
  String.intercalate "\n"
    [
      reprStr (normalizeExprN 2 feltExpr),
      reprStr (normalizeExprN 2 u128Expr),
      reprStr (normalizeExprN 2 boolExpr),
      reprStr (normalizeExprN 2 nestedExpr)
    ]

#eval do
  assertCondition (normalizeExprN 2 feltExpr = normalizeExpr feltExpr) "feltExpr normalization should be idempotent"
  assertCondition (normalizeExprN 2 u128Expr = normalizeExpr u128Expr) "u128Expr normalization should be idempotent"
  assertCondition (normalizeExprN 2 boolExpr = normalizeExpr boolExpr) "boolExpr normalization should be idempotent"
  assertCondition (normalizeExprN 2 nestedExpr = normalizeExpr nestedExpr) "nestedExpr normalization should be idempotent"
  assertCondition (snapshotOnce = snapshotTwice) "normalization snapshots should be stable across repeated passes"
