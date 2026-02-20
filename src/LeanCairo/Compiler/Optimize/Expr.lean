import LeanCairo.Compiler.IR.Expr

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR

def foldAddU128 (lhs rhs : IRExpr .u128) : IRExpr .u128 :=
  if lhs = .litU128 0 then rhs
  else if rhs = .litU128 0 then lhs
  else .addU128 lhs rhs

def foldSubU128 (lhs rhs : IRExpr .u128) : IRExpr .u128 :=
  if rhs = .litU128 0 then lhs
  else .subU128 lhs rhs

def foldMulU128 (lhs rhs : IRExpr .u128) : IRExpr .u128 :=
  if lhs = .litU128 0 then .litU128 0
  else if rhs = .litU128 0 then .litU128 0
  else if lhs = .litU128 1 then rhs
  else if rhs = .litU128 1 then lhs
  else .mulU128 lhs rhs

def foldAddU256 (lhs rhs : IRExpr .u256) : IRExpr .u256 :=
  if lhs = .litU256 0 then rhs
  else if rhs = .litU256 0 then lhs
  else .addU256 lhs rhs

def foldSubU256 (lhs rhs : IRExpr .u256) : IRExpr .u256 :=
  if rhs = .litU256 0 then lhs
  else .subU256 lhs rhs

def foldMulU256 (lhs rhs : IRExpr .u256) : IRExpr .u256 :=
  if lhs = .litU256 0 then .litU256 0
  else if rhs = .litU256 0 then .litU256 0
  else if lhs = .litU256 1 then rhs
  else if rhs = .litU256 1 then lhs
  else .mulU256 lhs rhs

def foldIte (cond : IRExpr .bool) (thenBranch elseBranch : IRExpr ty) : IRExpr ty :=
  match cond with
  | .litBool true => thenBranch
  | .litBool false => elseBranch
  | other => .ite other thenBranch elseBranch

def optimizeExpr : IRExpr ty -> IRExpr ty
  | .var name => .var name
  | .storageRead name => .storageRead name
  | .litU128 value => .litU128 value
  | .litU256 value => .litU256 value
  | .litBool value => .litBool value
  | .litFelt252 value => .litFelt252 value
  | .addU128 lhs rhs => foldAddU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .subU128 lhs rhs => foldSubU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .mulU128 lhs rhs => foldMulU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .addU256 lhs rhs => foldAddU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .subU256 lhs rhs => foldSubU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .mulU256 lhs rhs => foldMulU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .eq lhs rhs => .eq (optimizeExpr lhs) (optimizeExpr rhs)
  | .ltU128 lhs rhs => .ltU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .leU128 lhs rhs => .leU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .ltU256 lhs rhs => .ltU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .leU256 lhs rhs => .leU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .ite cond thenBranch elseBranch =>
      foldIte (optimizeExpr cond) (optimizeExpr thenBranch) (optimizeExpr elseBranch)
  | .letE name boundTy bound body =>
      .letE name boundTy (optimizeExpr bound) (optimizeExpr body)

end LeanCairo.Compiler.Optimize
