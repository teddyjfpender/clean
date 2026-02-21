import LeanCairo.Compiler.Optimize.Expr
import LeanCairo.Compiler.Semantics.Eval

namespace LeanCairo.Compiler.Proof

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize
open LeanCairo.Compiler.Semantics

private theorem evalFoldAddFelt252 (ctx : EvalContext) (lhs rhs : IRExpr .felt252) :
    evalExpr ctx (foldAddFelt252 lhs rhs) = evalExpr ctx lhs + evalExpr ctx rhs := by
  unfold foldAddFelt252
  by_cases hLhs : lhs = .litFelt252 0
  · simp [hLhs, evalExpr]
  · by_cases hRhs : rhs = .litFelt252 0
    · simp [hLhs, hRhs, evalExpr]
    · simp [hLhs, hRhs, evalExpr]

private theorem evalFoldSubFelt252 (ctx : EvalContext) (lhs rhs : IRExpr .felt252) :
    evalExpr ctx (foldSubFelt252 lhs rhs) = evalExpr ctx lhs - evalExpr ctx rhs := by
  unfold foldSubFelt252
  by_cases hRhs : rhs = .litFelt252 0
  · simp [hRhs, evalExpr]
  · simp [hRhs, evalExpr]

private theorem evalFoldMulFelt252 (ctx : EvalContext) (lhs rhs : IRExpr .felt252) :
    evalExpr ctx (foldMulFelt252 lhs rhs) = evalExpr ctx lhs * evalExpr ctx rhs := by
  unfold foldMulFelt252
  by_cases hLhsZero : lhs = .litFelt252 0
  · simp [hLhsZero, evalExpr]
  · by_cases hRhsZero : rhs = .litFelt252 0
    · simp [hLhsZero, hRhsZero, evalExpr]
    · by_cases hLhsOne : lhs = .litFelt252 1
      · simp [hRhsZero, hLhsOne, evalExpr]
      · by_cases hRhsOne : rhs = .litFelt252 1
        · simp [hLhsZero, hLhsOne, hRhsOne, evalExpr]
        · simp [hLhsZero, hRhsZero, hLhsOne, hRhsOne, evalExpr]

private theorem evalFoldAddU128 (ctx : EvalContext) (lhs rhs : IRExpr .u128) :
    evalExpr ctx (foldAddU128 lhs rhs) = evalExpr ctx lhs + evalExpr ctx rhs := by
  unfold foldAddU128
  by_cases hLhs : lhs = .litU128 0
  · simp [hLhs, evalExpr]
  · by_cases hRhs : rhs = .litU128 0
    · simp [hLhs, hRhs, evalExpr]
    · simp [hLhs, hRhs, evalExpr]

private theorem evalFoldSubU128 (ctx : EvalContext) (lhs rhs : IRExpr .u128) :
    evalExpr ctx (foldSubU128 lhs rhs) = evalExpr ctx lhs - evalExpr ctx rhs := by
  unfold foldSubU128
  by_cases hRhs : rhs = .litU128 0
  · simp [hRhs, evalExpr]
  · simp [hRhs, evalExpr]

private theorem evalFoldMulU128 (ctx : EvalContext) (lhs rhs : IRExpr .u128) :
    evalExpr ctx (foldMulU128 lhs rhs) = evalExpr ctx lhs * evalExpr ctx rhs := by
  unfold foldMulU128
  by_cases hLhsZero : lhs = .litU128 0
  · simp [hLhsZero, evalExpr]
  · by_cases hRhsZero : rhs = .litU128 0
    · simp [hLhsZero, hRhsZero, evalExpr]
    · by_cases hLhsOne : lhs = .litU128 1
      · simp [hRhsZero, hLhsOne, evalExpr]
      · by_cases hRhsOne : rhs = .litU128 1
        · simp [hLhsZero, hLhsOne, hRhsOne, evalExpr]
        · simp [hLhsZero, hRhsZero, hLhsOne, hRhsOne, evalExpr]

private theorem evalFoldAddU256 (ctx : EvalContext) (lhs rhs : IRExpr .u256) :
    evalExpr ctx (foldAddU256 lhs rhs) = evalExpr ctx lhs + evalExpr ctx rhs := by
  unfold foldAddU256
  by_cases hLhs : lhs = .litU256 0
  · simp [hLhs, evalExpr]
  · by_cases hRhs : rhs = .litU256 0
    · simp [hLhs, hRhs, evalExpr]
    · simp [hLhs, hRhs, evalExpr]

private theorem evalFoldSubU256 (ctx : EvalContext) (lhs rhs : IRExpr .u256) :
    evalExpr ctx (foldSubU256 lhs rhs) = evalExpr ctx lhs - evalExpr ctx rhs := by
  unfold foldSubU256
  by_cases hRhs : rhs = .litU256 0
  · simp [hRhs, evalExpr]
  · simp [hRhs, evalExpr]

private theorem evalFoldMulU256 (ctx : EvalContext) (lhs rhs : IRExpr .u256) :
    evalExpr ctx (foldMulU256 lhs rhs) = evalExpr ctx lhs * evalExpr ctx rhs := by
  unfold foldMulU256
  by_cases hLhsZero : lhs = .litU256 0
  · simp [hLhsZero, evalExpr]
  · by_cases hRhsZero : rhs = .litU256 0
    · simp [hLhsZero, hRhsZero, evalExpr]
    · by_cases hLhsOne : lhs = .litU256 1
      · simp [hRhsZero, hLhsOne, evalExpr]
      · by_cases hRhsOne : rhs = .litU256 1
        · simp [hLhsZero, hLhsOne, hRhsOne, evalExpr]
        · simp [hLhsZero, hRhsZero, hLhsOne, hRhsOne, evalExpr]

private theorem evalFoldIte (ctx : EvalContext) (cond : IRExpr .bool) (thenBranch elseBranch : IRExpr ty) :
    evalExpr ctx (foldIte cond thenBranch elseBranch) = evalExpr ctx (.ite cond thenBranch elseBranch) := by
  cases cond with
  | litBool value =>
      cases value <;> simp [foldIte, evalExpr]
  | _ =>
      by_cases hEq : thenBranch = elseBranch
      · subst hEq
        simp [foldIte, evalExpr]
      · simp [foldIte, hEq, evalExpr]

theorem optimizeExprSound (ctx : EvalContext) (expr : IRExpr ty) :
    evalExpr ctx (optimizeExpr expr) = evalExpr ctx expr := by
  induction expr generalizing ctx with
  | var name =>
      simp [optimizeExpr, evalExpr]
  | storageRead name =>
      simp [optimizeExpr, evalExpr]
  | litU128 value =>
      simp [optimizeExpr, evalExpr]
  | litU256 value =>
      simp [optimizeExpr, evalExpr]
  | litBool value =>
      simp [optimizeExpr, evalExpr]
  | litFelt252 value =>
      simp [optimizeExpr, evalExpr]
  | addFelt252 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldAddFelt252 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | subFelt252 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldSubFelt252 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | mulFelt252 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldMulFelt252 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | addU128 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldAddU128 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | subU128 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldSubU128 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | mulU128 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldMulU128 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | addU256 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldAddU256 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | subU256 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldSubU256 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | mulU256 lhs rhs ihLhs ihRhs =>
      simpa [ihLhs ctx, ihRhs ctx] using evalFoldMulU256 ctx (optimizeExpr lhs) (optimizeExpr rhs)
  | @eq _ lhs rhs ihLhs ihRhs =>
      simp [optimizeExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | ltU128 lhs rhs ihLhs ihRhs =>
      simp [optimizeExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | leU128 lhs rhs ihLhs ihRhs =>
      simp [optimizeExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | ltU256 lhs rhs ihLhs ihRhs =>
      simp [optimizeExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | leU256 lhs rhs ihLhs ihRhs =>
      simp [optimizeExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | ite cond thenBranch elseBranch ihCond ihThen ihElse =>
      simp [optimizeExpr]
      calc
        evalExpr ctx (foldIte (optimizeExpr cond) (optimizeExpr thenBranch) (optimizeExpr elseBranch)) =
            evalExpr ctx ((optimizeExpr cond).ite (optimizeExpr thenBranch) (optimizeExpr elseBranch)) :=
              evalFoldIte ctx (optimizeExpr cond) (optimizeExpr thenBranch) (optimizeExpr elseBranch)
        _ = evalExpr ctx (cond.ite thenBranch elseBranch) := by
              simp [evalExpr, ihCond ctx, ihThen ctx, ihElse ctx]
  | letE name boundTy bound body ihBound ihBody =>
      simp [optimizeExpr, evalExpr, ihBound ctx]
      exact ihBody (EvalContext.bindVar ctx boundTy name (evalExpr ctx bound))

end LeanCairo.Compiler.Proof
