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
  | litInt lane value =>
      simp [normalizeLet, evalExpr]
  | addFelt252 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | subFelt252 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | mulFelt252 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | addInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | subInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | mulInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | divInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | modInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitAndInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitOrInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitXorInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | shlInt lane lhs shift =>
      simp [normalizeLet, evalExpr]
  | shrInt lane lhs shift =>
      simp [normalizeLet, evalExpr]
  | addU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | subU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | mulU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | divU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | modU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitAndU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitOrU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitXorU128 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | shlU128 lhs shift =>
      simp [normalizeLet, evalExpr]
  | shrU128 lhs shift =>
      simp [normalizeLet, evalExpr]
  | addU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | subU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | mulU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | divU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | modU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitAndU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitOrU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | bitXorU256 lhs rhs =>
      simp [normalizeLet, evalExpr]
  | shlU256 lhs shift =>
      simp [normalizeLet, evalExpr]
  | shrU256 lhs shift =>
      simp [normalizeLet, evalExpr]
  | u256FromLimbs low high =>
      simp [normalizeLet, evalExpr]
  | u256Low value =>
      simp [normalizeLet, evalExpr]
  | u256High value =>
      simp [normalizeLet, evalExpr]
  | @eq eqTy lhs rhs =>
      cases eqTy <;> simp [normalizeLet, evalExpr]
  | ltInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
  | leInt lane lhs rhs =>
      simp [normalizeLet, evalExpr]
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
  | litInt lane value =>
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
  | addInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | subInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | mulInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | divInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | modInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitAndInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitOrInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitXorInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | shlInt lane lhs shift ihLhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx]
  | shrInt lane lhs shift ihLhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx]
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
  | divU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | modU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitAndU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitOrU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitXorU128 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | shlU128 lhs shift ihLhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx]
  | shrU128 lhs shift ihLhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx]
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
  | divU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | modU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitAndU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitOrU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | bitXorU256 lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | shlU256 lhs shift ihLhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx]
  | shrU256 lhs shift ihLhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx]
  | u256FromLimbs low high ihLow ihHigh =>
      simp [cseLetNormExpr, evalExpr, ihLow ctx, ihHigh ctx]
  | u256Low value ihValue =>
      simp [cseLetNormExpr, evalExpr, ihValue ctx]
  | u256High value ihValue =>
      simp [cseLetNormExpr, evalExpr, ihValue ctx]
  | @eq eqTy lhs rhs ihLhs ihRhs =>
      calc
        evalExpr ctx (cseLetNormExpr (.eq lhs rhs)) =
            evalExpr ctx (.eq (cseLetNormExpr lhs) (cseLetNormExpr rhs)) := by
              simpa [cseLetNormExpr] using evalCseEq (ty := eqTy) ctx (cseLetNormExpr lhs) (cseLetNormExpr rhs)
        _ = evalExpr ctx (.eq lhs rhs) := by
              simp [evalExpr, ihLhs ctx, ihRhs ctx]
  | ltInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
  | leInt lane lhs rhs ihLhs ihRhs =>
      simp [cseLetNormExpr, evalExpr, ihLhs ctx, ihRhs ctx]
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
