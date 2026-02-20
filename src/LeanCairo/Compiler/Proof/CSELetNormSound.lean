import LeanCairo.Compiler.Optimize.CSELetNorm
import LeanCairo.Compiler.Semantics.Eval

namespace LeanCairo.Compiler.Proof

open LeanCairo.Compiler.IR
open LeanCairo.Compiler.Optimize
open LeanCairo.Compiler.Semantics

private theorem evalCseAddFelt252 (ctx : EvalContext) (lhs rhs : IRExpr .felt252) :
    evalExpr ctx (cseAddFelt252 lhs rhs) = evalExpr ctx (.addFelt252 lhs rhs) := by
  unfold cseAddFelt252
  by_cases h : lhs = rhs
  · subst h
    simp [cseTempFelt252, evalExpr, EvalContext.readVar, EvalContext.bindVar]
  · simp [h, evalExpr]

private theorem evalCseMulFelt252 (ctx : EvalContext) (lhs rhs : IRExpr .felt252) :
    evalExpr ctx (cseMulFelt252 lhs rhs) = evalExpr ctx (.mulFelt252 lhs rhs) := by
  unfold cseMulFelt252
  by_cases h : lhs = rhs
  · subst h
    simp [cseTempFelt252, evalExpr, EvalContext.readVar, EvalContext.bindVar]
  · simp [h, evalExpr]

private theorem evalCseAddU128 (ctx : EvalContext) (lhs rhs : IRExpr .u128) :
    evalExpr ctx (cseAddU128 lhs rhs) = evalExpr ctx (.addU128 lhs rhs) := by
  unfold cseAddU128
  by_cases h : lhs = rhs
  · subst h
    simp [cseTempU128, evalExpr, EvalContext.readVar, EvalContext.bindVar]
  · simp [h, evalExpr]

private theorem evalCseMulU128 (ctx : EvalContext) (lhs rhs : IRExpr .u128) :
    evalExpr ctx (cseMulU128 lhs rhs) = evalExpr ctx (.mulU128 lhs rhs) := by
  unfold cseMulU128
  by_cases h : lhs = rhs
  · subst h
    simp [cseTempU128, evalExpr, EvalContext.readVar, EvalContext.bindVar]
  · simp [h, evalExpr]

private theorem evalCseAddU256 (ctx : EvalContext) (lhs rhs : IRExpr .u256) :
    evalExpr ctx (cseAddU256 lhs rhs) = evalExpr ctx (.addU256 lhs rhs) := by
  unfold cseAddU256
  by_cases h : lhs = rhs
  · subst h
    simp [cseTempU256, evalExpr, EvalContext.readVar, EvalContext.bindVar]
  · simp [h, evalExpr]

private theorem evalCseMulU256 (ctx : EvalContext) (lhs rhs : IRExpr .u256) :
    evalExpr ctx (cseMulU256 lhs rhs) = evalExpr ctx (.mulU256 lhs rhs) := by
  unfold cseMulU256
  by_cases h : lhs = rhs
  · subst h
    simp [cseTempU256, evalExpr, EvalContext.readVar, EvalContext.bindVar]
  · simp [h, evalExpr]

private theorem evalCseEq (ctx : EvalContext) (lhs rhs : IRExpr ty) :
    evalExpr ctx (cseEq lhs rhs) = evalExpr ctx (.eq lhs rhs) := by
  unfold cseEq
  by_cases h : lhs = rhs
  · subst h
    cases ty <;> simp [cseTempEq, evalExpr, EvalContext.readVar, EvalContext.bindVar]
  · simp [h]

private theorem evalNormalizeLet (ctx : EvalContext) (name : String) (boundTy : LeanCairo.Core.Domain.Ty)
    (bound : IRExpr boundTy) (body : IRExpr bodyTy) :
    evalExpr ctx (normalizeLet name boundTy bound body) = evalExpr ctx (.letE name boundTy bound body) := by
  cases body with
  | var bodyName =>
    by_cases h : bodyName = name
    · subst h
      by_cases hTy : bodyTy = boundTy
      · cases hTy
        simpa [normalizeLet, evalExpr] using
          (EvalContext.readVar_bindVar_same ctx bodyTy bodyName (evalExpr ctx bound)).symm
      · simp [normalizeLet, hTy, evalExpr]
    · simp [normalizeLet, h, evalExpr]
  | storageRead fieldName =>
      simp [normalizeLet, evalExpr]
  | litU128 value =>
      simp [normalizeLet, evalExpr]
  | litU256 value =>
      simp [normalizeLet, evalExpr]
  | litBool value =>
      simp [normalizeLet, evalExpr]
  | litFelt252 value =>
      simp [normalizeLet, evalExpr]
  | addFelt252 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | subFelt252 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | mulFelt252 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | addU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | subU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | mulU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | addU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | subU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | mulU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | @eq eqTy lhs rhs =>
      cases eqTy <;> simp [normalizeLet, evalExpr]
  | ltU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | leU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | ltU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | leU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | ite cond thenBranch elseBranch =>
      simp [normalizeLet, evalExpr]
  | letE innerName innerTy innerBound innerBody =>
      simp [normalizeLet, evalExpr]

theorem cseLetNormExprSound (ctx : EvalContext) (expr : IRExpr ty) :
    evalExpr ctx (cseLetNormExpr expr) = evalExpr ctx expr := by
  induction expr generalizing ctx with
  | var name =>
      simp [cseLetNormExpr, evalExpr]
  | storageRead name =>
      simp [cseLetNormExpr, evalExpr]
  | litU128 value =>
      simp [cseLetNormExpr, evalExpr]
  | litU256 value =>
      simp [cseLetNormExpr, evalExpr]
  | litBool value =>
      simp [cseLetNormExpr, evalExpr]
  | litFelt252 value =>
      simp [cseLetNormExpr, evalExpr]
  | addFelt252 lhs rhs ihLhs ihRhs =>
      calc
        evalExpr ctx (cseLetNormExpr (.addFelt252 lhs rhs)) =
            evalExpr ctx (.addFelt252 (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
              simpa [cseLetNormExpr] using evalCseAddFelt252 ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
        _ = evalExpr ctx (.addFelt252 lhs rhs) := by
              simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | subFelt252 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | mulFelt252 lhs rhs ihLhs ihRhs =>
      calc
        evalExpr ctx (cseLetNormExpr (.mulFelt252 lhs rhs)) =
            evalExpr ctx (.mulFelt252 (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
              simpa [cseLetNormExpr] using evalCseMulFelt252 ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
        _ = evalExpr ctx (.mulFelt252 lhs rhs) := by
              simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | addU128 lhs rhs ihLhs ihRhs =>
      calc
        evalExpr ctx (cseLetNormExpr (.addU128 lhs rhs)) =
            evalExpr ctx (.addU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
              simpa [cseLetNormExpr] using evalCseAddU128 ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
        _ = evalExpr ctx (.addU128 lhs rhs) := by
              simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | subU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | mulU128 lhs rhs ihLhs ihRhs =>
      calc
        evalExpr ctx (cseLetNormExpr (.mulU128 lhs rhs)) =
            evalExpr ctx (.mulU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
              simpa [cseLetNormExpr] using evalCseMulU128 ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
        _ = evalExpr ctx (.mulU128 lhs rhs) := by
              simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | addU256 lhs rhs ihLhs ihRhs =>
      calc
        evalExpr ctx (cseLetNormExpr (.addU256 lhs rhs)) =
            evalExpr ctx (.addU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
              simpa [cseLetNormExpr] using evalCseAddU256 ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
        _ = evalExpr ctx (.addU256 lhs rhs) := by
              simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | subU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | mulU256 lhs rhs ihLhs ihRhs =>
      calc
        evalExpr ctx (cseLetNormExpr (.mulU256 lhs rhs)) =
            evalExpr ctx (.mulU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
              simpa [cseLetNormExpr] using evalCseMulU256 ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
        _ = evalExpr ctx (.mulU256 lhs rhs) := by
              simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | @eq eqTy lhs rhs ihLhs ihRhs =>
      cases eqTy with
      | felt252 =>
          calc
            evalExpr ctx (cseLetNormExpr (.eq lhs rhs)) =
                evalExpr ctx (.eq (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
                  simpa [cseLetNormExpr] using evalCseEq (ty := .felt252) ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
            _ = evalExpr ctx (.eq lhs rhs) := by
                  simp [evalExpr, ihLhs ctx, ihRhs ctx]
      | u128 =>
          calc
            evalExpr ctx (cseLetNormExpr (.eq lhs rhs)) =
                evalExpr ctx (.eq (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
                  simpa [cseLetNormExpr] using evalCseEq (ty := .u128) ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
            _ = evalExpr ctx (.eq lhs rhs) := by
                  simp [evalExpr, ihLhs ctx, ihRhs ctx]
      | u256 =>
          calc
            evalExpr ctx (cseLetNormExpr (.eq lhs rhs)) =
                evalExpr ctx (.eq (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
                  simpa [cseLetNormExpr] using evalCseEq (ty := .u256) ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
            _ = evalExpr ctx (.eq lhs rhs) := by
                  simp [evalExpr, ihLhs ctx, ihRhs ctx]
      | bool =>
          calc
            evalExpr ctx (cseLetNormExpr (.eq lhs rhs)) =
                evalExpr ctx (.eq (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
                  simpa [cseLetNormExpr] using evalCseEq (ty := .bool) ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
            _ = evalExpr ctx (.eq lhs rhs) := by
                  simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | ltU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | leU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | ltU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | leU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | ite cond thenBranch elseBranch ihCond ihThen ihElse =>
      simp [cseLetNormExpr, evalExpr, ihCond ctx, ihThen ctx, ihElse ctx]
  | letE name boundTy bound body ihBound ihBody =>
      simp [cseLetNormExpr, evalExpr, evalNormalizeLet, ihBound ctx]
      exact ihBody (EvalContext.bindVar ctx boundTy name (evalExpr ctx bound))

end LeanCairo.Compiler.Proof
