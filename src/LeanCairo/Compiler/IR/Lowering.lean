import LeanCairo.Compiler.IR.Expr
import LeanCairo.Core.Syntax.Expr

namespace LeanCairo.Compiler.IR

open LeanCairo.Core.Syntax

def lowerExpr : Expr ty -> IRExpr ty
  | .var name => .var name
  | .storageRead name => .storageRead name
  | .litU128 value => .litU128 value
  | .litU256 value => .litU256 value
  | .litBool value => .litBool value
  | .litFelt252 value => .litFelt252 value
  | .addFelt252 lhs rhs => .addFelt252 (lowerExpr lhs) (lowerExpr rhs)
  | .subFelt252 lhs rhs => .subFelt252 (lowerExpr lhs) (lowerExpr rhs)
  | .mulFelt252 lhs rhs => .mulFelt252 (lowerExpr lhs) (lowerExpr rhs)
  | .addU128 lhs rhs => .addU128 (lowerExpr lhs) (lowerExpr rhs)
  | .subU128 lhs rhs => .subU128 (lowerExpr lhs) (lowerExpr rhs)
  | .mulU128 lhs rhs => .mulU128 (lowerExpr lhs) (lowerExpr rhs)
  | .addU256 lhs rhs => .addU256 (lowerExpr lhs) (lowerExpr rhs)
  | .subU256 lhs rhs => .subU256 (lowerExpr lhs) (lowerExpr rhs)
  | .mulU256 lhs rhs => .mulU256 (lowerExpr lhs) (lowerExpr rhs)
  | .eq lhs rhs => .eq (lowerExpr lhs) (lowerExpr rhs)
  | .ltU128 lhs rhs => .ltU128 (lowerExpr lhs) (lowerExpr rhs)
  | .leU128 lhs rhs => .leU128 (lowerExpr lhs) (lowerExpr rhs)
  | .ltU256 lhs rhs => .ltU256 (lowerExpr lhs) (lowerExpr rhs)
  | .leU256 lhs rhs => .leU256 (lowerExpr lhs) (lowerExpr rhs)
  | .ite cond thenBranch elseBranch => .ite (lowerExpr cond) (lowerExpr thenBranch) (lowerExpr elseBranch)
  | .letE name boundTy bound body => .letE name boundTy (lowerExpr bound) (lowerExpr body)

def raiseExpr : IRExpr ty -> Expr ty
  | .var name => .var name
  | .storageRead name => .storageRead name
  | .litU128 value => .litU128 value
  | .litU256 value => .litU256 value
  | .litBool value => .litBool value
  | .litFelt252 value => .litFelt252 value
  | .addFelt252 lhs rhs => .addFelt252 (raiseExpr lhs) (raiseExpr rhs)
  | .subFelt252 lhs rhs => .subFelt252 (raiseExpr lhs) (raiseExpr rhs)
  | .mulFelt252 lhs rhs => .mulFelt252 (raiseExpr lhs) (raiseExpr rhs)
  | .addU128 lhs rhs => .addU128 (raiseExpr lhs) (raiseExpr rhs)
  | .subU128 lhs rhs => .subU128 (raiseExpr lhs) (raiseExpr rhs)
  | .mulU128 lhs rhs => .mulU128 (raiseExpr lhs) (raiseExpr rhs)
  | .addU256 lhs rhs => .addU256 (raiseExpr lhs) (raiseExpr rhs)
  | .subU256 lhs rhs => .subU256 (raiseExpr lhs) (raiseExpr rhs)
  | .mulU256 lhs rhs => .mulU256 (raiseExpr lhs) (raiseExpr rhs)
  | .eq lhs rhs => .eq (raiseExpr lhs) (raiseExpr rhs)
  | .ltU128 lhs rhs => .ltU128 (raiseExpr lhs) (raiseExpr rhs)
  | .leU128 lhs rhs => .leU128 (raiseExpr lhs) (raiseExpr rhs)
  | .ltU256 lhs rhs => .ltU256 (raiseExpr lhs) (raiseExpr rhs)
  | .leU256 lhs rhs => .leU256 (raiseExpr lhs) (raiseExpr rhs)
  | .ite cond thenBranch elseBranch => .ite (raiseExpr cond) (raiseExpr thenBranch) (raiseExpr elseBranch)
  | .letE name boundTy bound body => .letE name boundTy (raiseExpr bound) (raiseExpr body)

theorem raiseLowerExpr (expr : Expr ty) : raiseExpr (lowerExpr expr) = expr := by
  induction expr with
  | var name =>
      simp [lowerExpr, raiseExpr]
  | storageRead name =>
      simp [lowerExpr, raiseExpr]
  | litU128 value =>
      simp [lowerExpr, raiseExpr]
  | litU256 value =>
      simp [lowerExpr, raiseExpr]
  | litBool value =>
      simp [lowerExpr, raiseExpr]
  | litFelt252 value =>
      simp [lowerExpr, raiseExpr]
  | addFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | addU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | addU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | eq lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ltU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | leU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ltU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | leU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ite cond thenBranch elseBranch ihCond ihThen ihElse =>
      simp [lowerExpr, raiseExpr, ihCond, ihThen, ihElse]
  | letE name boundTy bound body ihBound ihBody =>
      simp [lowerExpr, raiseExpr, ihBound, ihBody]

theorem lowerRaiseExpr (expr : IRExpr ty) : lowerExpr (raiseExpr expr) = expr := by
  induction expr with
  | var name =>
      simp [lowerExpr, raiseExpr]
  | storageRead name =>
      simp [lowerExpr, raiseExpr]
  | litU128 value =>
      simp [lowerExpr, raiseExpr]
  | litU256 value =>
      simp [lowerExpr, raiseExpr]
  | litBool value =>
      simp [lowerExpr, raiseExpr]
  | litFelt252 value =>
      simp [lowerExpr, raiseExpr]
  | addFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | addU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | addU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | eq lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ltU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | leU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ltU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | leU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ite cond thenBranch elseBranch ihCond ihThen ihElse =>
      simp [lowerExpr, raiseExpr, ihCond, ihThen, ihElse]
  | letE name boundTy bound body ihBound ihBody =>
      simp [lowerExpr, raiseExpr, ihBound, ihBody]

end LeanCairo.Compiler.IR
