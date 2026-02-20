import LeanCairo.Compiler.IR.Expr

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

def cseTempU128 : String :=
  "__leancairo_internal_cse_u128"

def cseTempU256 : String :=
  "__leancairo_internal_cse_u256"

def cseTempEq : String :=
  "__leancairo_internal_cse_eq"

def cseAddU128 (lhs rhs : IRExpr .u128) : IRExpr .u128 :=
  if lhs = rhs then
    .letE cseTempU128 .u128 lhs
      (.addU128 (.var (ty := .u128) cseTempU128) (.var (ty := .u128) cseTempU128))
  else
    .addU128 lhs rhs

def cseMulU128 (lhs rhs : IRExpr .u128) : IRExpr .u128 :=
  if lhs = rhs then
    .letE cseTempU128 .u128 lhs
      (.mulU128 (.var (ty := .u128) cseTempU128) (.var (ty := .u128) cseTempU128))
  else
    .mulU128 lhs rhs

def cseAddU256 (lhs rhs : IRExpr .u256) : IRExpr .u256 :=
  if lhs = rhs then
    .letE cseTempU256 .u256 lhs
      (.addU256 (.var (ty := .u256) cseTempU256) (.var (ty := .u256) cseTempU256))
  else
    .addU256 lhs rhs

def cseMulU256 (lhs rhs : IRExpr .u256) : IRExpr .u256 :=
  if lhs = rhs then
    .letE cseTempU256 .u256 lhs
      (.mulU256 (.var (ty := .u256) cseTempU256) (.var (ty := .u256) cseTempU256))
  else
    .mulU256 lhs rhs

def cseEq (lhs rhs : IRExpr ty) : IRExpr .bool :=
  if lhs = rhs then
    .letE cseTempEq ty lhs
      (.eq (.var (ty := ty) cseTempEq) (.var (ty := ty) cseTempEq))
  else
    .eq lhs rhs

def normalizeLet (name : String) (boundTy : Ty) (bound : IRExpr boundTy) (body : IRExpr bodyTy) : IRExpr bodyTy :=
  match body with
  | .var bodyName =>
      if bodyName = name then
        if hTy : bodyTy = boundTy then
          cast (congrArg IRExpr hTy.symm) bound
        else
          .letE name boundTy bound body
      else
        .letE name boundTy bound body
  | _ =>
      .letE name boundTy bound body

def cseLetNormExpr : IRExpr ty -> IRExpr ty
  | .var name => .var name
  | .storageRead name => .storageRead name
  | .litU128 value => .litU128 value
  | .litU256 value => .litU256 value
  | .litBool value => .litBool value
  | .litFelt252 value => .litFelt252 value
  | .addU128 lhs rhs => cseAddU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .subU128 lhs rhs => .subU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .mulU128 lhs rhs => cseMulU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .addU256 lhs rhs => cseAddU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .subU256 lhs rhs => .subU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .mulU256 lhs rhs => cseMulU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .eq lhs rhs => cseEq (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .ltU128 lhs rhs => .ltU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .leU128 lhs rhs => .leU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .ltU256 lhs rhs => .ltU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .leU256 lhs rhs => .leU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .ite cond thenBranch elseBranch =>
      .ite (cseLetNormExpr cond) (cseLetNormExpr thenBranch) (cseLetNormExpr elseBranch)
  | .letE name boundTy bound body =>
      normalizeLet name boundTy (cseLetNormExpr bound) (cseLetNormExpr body)

end LeanCairo.Compiler.Optimize
