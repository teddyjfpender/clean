import LeanCairo.Compiler.IR.Expr

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

def cseTempU128 : String :=
  "__leancairo_internal_cse_u128"

def cseTempU256 : String :=
  "__leancairo_internal_cse_u256"

def cseTempFelt252 : String :=
  "__leancairo_internal_cse_felt252"

def cseTempEq : String :=
  "__leancairo_internal_cse_eq"

def cseAddFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252 :=
  if lhs = rhs then
    .letE cseTempFelt252 .felt252 lhs
      (.addFelt252 (.var (ty := .felt252) cseTempFelt252) (.var (ty := .felt252) cseTempFelt252))
  else
    .addFelt252 lhs rhs

def cseMulFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252 :=
  if lhs = rhs then
    .letE cseTempFelt252 .felt252 lhs
      (.mulFelt252 (.var (ty := .felt252) cseTempFelt252) (.var (ty := .felt252) cseTempFelt252))
  else
    .mulFelt252 lhs rhs

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
  | .litInt ty value => .litInt ty value
  | .addFelt252 lhs rhs => cseAddFelt252 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .subFelt252 lhs rhs => .subFelt252 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .mulFelt252 lhs rhs => cseMulFelt252 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .addInt ty lhs rhs => .addInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .subInt ty lhs rhs => .subInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .mulInt ty lhs rhs => .mulInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .divInt ty lhs rhs => .divInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .modInt ty lhs rhs => .modInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitAndInt ty lhs rhs => .bitAndInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitOrInt ty lhs rhs => .bitOrInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitXorInt ty lhs rhs => .bitXorInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .shlInt ty lhs shift => .shlInt ty (cseLetNormExpr lhs) shift
  | .shrInt ty lhs shift => .shrInt ty (cseLetNormExpr lhs) shift
  | .addU128 lhs rhs => cseAddU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .subU128 lhs rhs => .subU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .mulU128 lhs rhs => cseMulU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .divU128 lhs rhs => .divU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .modU128 lhs rhs => .modU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitAndU128 lhs rhs => .bitAndU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitOrU128 lhs rhs => .bitOrU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitXorU128 lhs rhs => .bitXorU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .shlU128 lhs shift => .shlU128 (cseLetNormExpr lhs) shift
  | .shrU128 lhs shift => .shrU128 (cseLetNormExpr lhs) shift
  | .addU256 lhs rhs => cseAddU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .subU256 lhs rhs => .subU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .mulU256 lhs rhs => cseMulU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .divU256 lhs rhs => .divU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .modU256 lhs rhs => .modU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitAndU256 lhs rhs => .bitAndU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitOrU256 lhs rhs => .bitOrU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .bitXorU256 lhs rhs => .bitXorU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .shlU256 lhs shift => .shlU256 (cseLetNormExpr lhs) shift
  | .shrU256 lhs shift => .shrU256 (cseLetNormExpr lhs) shift
  | .u256FromLimbs low high => .u256FromLimbs (cseLetNormExpr low) (cseLetNormExpr high)
  | .u256Low value => .u256Low (cseLetNormExpr value)
  | .u256High value => .u256High (cseLetNormExpr value)
  | .eq lhs rhs => cseEq (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .ltInt ty lhs rhs => .ltInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .leInt ty lhs rhs => .leInt ty (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .ltU128 lhs rhs => .ltU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .leU128 lhs rhs => .leU128 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .ltU256 lhs rhs => .ltU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .leU256 lhs rhs => .leU256 (cseLetNormExpr lhs) (cseLetNormExpr rhs)
  | .ite cond thenBranch elseBranch =>
      .ite (cseLetNormExpr cond) (cseLetNormExpr thenBranch) (cseLetNormExpr elseBranch)
  | .letE name boundTy bound body =>
      normalizeLet name boundTy (cseLetNormExpr bound) (cseLetNormExpr body)

end LeanCairo.Compiler.Optimize
