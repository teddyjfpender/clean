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
  | .litInt ty value => .litInt ty value
  | .addFelt252 lhs rhs => .addFelt252 (lowerExpr lhs) (lowerExpr rhs)
  | .subFelt252 lhs rhs => .subFelt252 (lowerExpr lhs) (lowerExpr rhs)
  | .mulFelt252 lhs rhs => .mulFelt252 (lowerExpr lhs) (lowerExpr rhs)
  | .addInt ty lhs rhs => .addInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .subInt ty lhs rhs => .subInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .mulInt ty lhs rhs => .mulInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .divInt ty lhs rhs => .divInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .modInt ty lhs rhs => .modInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .bitAndInt ty lhs rhs => .bitAndInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .bitOrInt ty lhs rhs => .bitOrInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .bitXorInt ty lhs rhs => .bitXorInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .shlInt ty lhs shift => .shlInt ty (lowerExpr lhs) shift
  | .shrInt ty lhs shift => .shrInt ty (lowerExpr lhs) shift
  | .addU128 lhs rhs => .addU128 (lowerExpr lhs) (lowerExpr rhs)
  | .subU128 lhs rhs => .subU128 (lowerExpr lhs) (lowerExpr rhs)
  | .mulU128 lhs rhs => .mulU128 (lowerExpr lhs) (lowerExpr rhs)
  | .divU128 lhs rhs => .divU128 (lowerExpr lhs) (lowerExpr rhs)
  | .modU128 lhs rhs => .modU128 (lowerExpr lhs) (lowerExpr rhs)
  | .bitAndU128 lhs rhs => .bitAndU128 (lowerExpr lhs) (lowerExpr rhs)
  | .bitOrU128 lhs rhs => .bitOrU128 (lowerExpr lhs) (lowerExpr rhs)
  | .bitXorU128 lhs rhs => .bitXorU128 (lowerExpr lhs) (lowerExpr rhs)
  | .shlU128 lhs shift => .shlU128 (lowerExpr lhs) shift
  | .shrU128 lhs shift => .shrU128 (lowerExpr lhs) shift
  | .addU256 lhs rhs => .addU256 (lowerExpr lhs) (lowerExpr rhs)
  | .subU256 lhs rhs => .subU256 (lowerExpr lhs) (lowerExpr rhs)
  | .mulU256 lhs rhs => .mulU256 (lowerExpr lhs) (lowerExpr rhs)
  | .divU256 lhs rhs => .divU256 (lowerExpr lhs) (lowerExpr rhs)
  | .modU256 lhs rhs => .modU256 (lowerExpr lhs) (lowerExpr rhs)
  | .bitAndU256 lhs rhs => .bitAndU256 (lowerExpr lhs) (lowerExpr rhs)
  | .bitOrU256 lhs rhs => .bitOrU256 (lowerExpr lhs) (lowerExpr rhs)
  | .bitXorU256 lhs rhs => .bitXorU256 (lowerExpr lhs) (lowerExpr rhs)
  | .shlU256 lhs shift => .shlU256 (lowerExpr lhs) shift
  | .shrU256 lhs shift => .shrU256 (lowerExpr lhs) shift
  | .u256FromLimbs low high => .u256FromLimbs (lowerExpr low) (lowerExpr high)
  | .u256Low value => .u256Low (lowerExpr value)
  | .u256High value => .u256High (lowerExpr value)
  | .eq lhs rhs => .eq (lowerExpr lhs) (lowerExpr rhs)
  | .ltInt ty lhs rhs => .ltInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .leInt ty lhs rhs => .leInt ty (lowerExpr lhs) (lowerExpr rhs)
  | .ltU128 lhs rhs => .ltU128 (lowerExpr lhs) (lowerExpr rhs)
  | .leU128 lhs rhs => .leU128 (lowerExpr lhs) (lowerExpr rhs)
  | .ltU256 lhs rhs => .ltU256 (lowerExpr lhs) (lowerExpr rhs)
  | .leU256 lhs rhs => .leU256 (lowerExpr lhs) (lowerExpr rhs)
  | .ite cond thenBranch elseBranch => .ite (lowerExpr cond) (lowerExpr thenBranch) (lowerExpr elseBranch)
  | .letE name boundTy bound body => .letE name boundTy (lowerExpr bound) (lowerExpr body)

def lowerExprWithResources (resources : ResourceCarriers) (expr : Expr ty) : EffectExpr ty :=
  {
    expr := lowerExpr expr
    resources := resources
  }

def lowerExprPure (expr : Expr ty) : EffectExpr ty :=
  lowerExprWithResources {} expr

def raiseExpr : IRExpr ty -> Expr ty
  | .var name => .var name
  | .storageRead name => .storageRead name
  | .litU128 value => .litU128 value
  | .litU256 value => .litU256 value
  | .litBool value => .litBool value
  | .litFelt252 value => .litFelt252 value
  | .litInt ty value => .litInt ty value
  | .addFelt252 lhs rhs => .addFelt252 (raiseExpr lhs) (raiseExpr rhs)
  | .subFelt252 lhs rhs => .subFelt252 (raiseExpr lhs) (raiseExpr rhs)
  | .mulFelt252 lhs rhs => .mulFelt252 (raiseExpr lhs) (raiseExpr rhs)
  | .addInt ty lhs rhs => .addInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .subInt ty lhs rhs => .subInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .mulInt ty lhs rhs => .mulInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .divInt ty lhs rhs => .divInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .modInt ty lhs rhs => .modInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .bitAndInt ty lhs rhs => .bitAndInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .bitOrInt ty lhs rhs => .bitOrInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .bitXorInt ty lhs rhs => .bitXorInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .shlInt ty lhs shift => .shlInt ty (raiseExpr lhs) shift
  | .shrInt ty lhs shift => .shrInt ty (raiseExpr lhs) shift
  | .addU128 lhs rhs => .addU128 (raiseExpr lhs) (raiseExpr rhs)
  | .subU128 lhs rhs => .subU128 (raiseExpr lhs) (raiseExpr rhs)
  | .mulU128 lhs rhs => .mulU128 (raiseExpr lhs) (raiseExpr rhs)
  | .divU128 lhs rhs => .divU128 (raiseExpr lhs) (raiseExpr rhs)
  | .modU128 lhs rhs => .modU128 (raiseExpr lhs) (raiseExpr rhs)
  | .bitAndU128 lhs rhs => .bitAndU128 (raiseExpr lhs) (raiseExpr rhs)
  | .bitOrU128 lhs rhs => .bitOrU128 (raiseExpr lhs) (raiseExpr rhs)
  | .bitXorU128 lhs rhs => .bitXorU128 (raiseExpr lhs) (raiseExpr rhs)
  | .shlU128 lhs shift => .shlU128 (raiseExpr lhs) shift
  | .shrU128 lhs shift => .shrU128 (raiseExpr lhs) shift
  | .addU256 lhs rhs => .addU256 (raiseExpr lhs) (raiseExpr rhs)
  | .subU256 lhs rhs => .subU256 (raiseExpr lhs) (raiseExpr rhs)
  | .mulU256 lhs rhs => .mulU256 (raiseExpr lhs) (raiseExpr rhs)
  | .divU256 lhs rhs => .divU256 (raiseExpr lhs) (raiseExpr rhs)
  | .modU256 lhs rhs => .modU256 (raiseExpr lhs) (raiseExpr rhs)
  | .bitAndU256 lhs rhs => .bitAndU256 (raiseExpr lhs) (raiseExpr rhs)
  | .bitOrU256 lhs rhs => .bitOrU256 (raiseExpr lhs) (raiseExpr rhs)
  | .bitXorU256 lhs rhs => .bitXorU256 (raiseExpr lhs) (raiseExpr rhs)
  | .shlU256 lhs shift => .shlU256 (raiseExpr lhs) shift
  | .shrU256 lhs shift => .shrU256 (raiseExpr lhs) shift
  | .u256FromLimbs low high => .u256FromLimbs (raiseExpr low) (raiseExpr high)
  | .u256Low value => .u256Low (raiseExpr value)
  | .u256High value => .u256High (raiseExpr value)
  | .eq lhs rhs => .eq (raiseExpr lhs) (raiseExpr rhs)
  | .ltInt ty lhs rhs => .ltInt ty (raiseExpr lhs) (raiseExpr rhs)
  | .leInt ty lhs rhs => .leInt ty (raiseExpr lhs) (raiseExpr rhs)
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
  | litInt lane value =>
      simp [lowerExpr, raiseExpr]
  | addFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | addInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | divInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | modInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitAndInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitOrInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitXorInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | shlInt lane lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | shrInt lane lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | addU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | divU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | modU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitAndU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitOrU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitXorU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | shlU128 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | shrU128 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | addU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | divU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | modU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitAndU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitOrU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitXorU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | shlU256 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | shrU256 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | u256FromLimbs low high ihLow ihHigh =>
      simp [lowerExpr, raiseExpr, ihLow, ihHigh]
  | u256Low value ihValue =>
      simp [lowerExpr, raiseExpr, ihValue]
  | u256High value ihValue =>
      simp [lowerExpr, raiseExpr, ihValue]
  | eq lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ltInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | leInt lane lhs rhs ihLhs ihRhs =>
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
  | litInt lane value =>
      simp [lowerExpr, raiseExpr]
  | addFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulFelt252 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | addInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | divInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | modInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitAndInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitOrInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitXorInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | shlInt lane lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | shrInt lane lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | addU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | divU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | modU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitAndU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitOrU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitXorU128 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | shlU128 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | shrU128 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | addU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | subU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | mulU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | divU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | modU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitAndU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitOrU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | bitXorU256 lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | shlU256 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | shrU256 lhs shift ihLhs =>
      simp [lowerExpr, raiseExpr, ihLhs]
  | u256FromLimbs low high ihLow ihHigh =>
      simp [lowerExpr, raiseExpr, ihLow, ihHigh]
  | u256Low value ihValue =>
      simp [lowerExpr, raiseExpr, ihValue]
  | u256High value ihValue =>
      simp [lowerExpr, raiseExpr, ihValue]
  | eq lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | ltInt lane lhs rhs ihLhs ihRhs =>
      simp [lowerExpr, raiseExpr, ihLhs, ihRhs]
  | leInt lane lhs rhs ihLhs ihRhs =>
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
