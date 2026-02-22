import LeanCairo.Compiler.IR.Expr

namespace LeanCairo.Compiler.Optimize

open LeanCairo.Compiler.IR

def foldAddFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252 :=
  if lhs = .litFelt252 0 then rhs
  else if rhs = .litFelt252 0 then lhs
  else .addFelt252 lhs rhs

def foldSubFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252 :=
  if rhs = .litFelt252 0 then lhs
  else .subFelt252 lhs rhs

def foldMulFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252 :=
  if lhs = .litFelt252 0 then .litFelt252 0
  else if rhs = .litFelt252 0 then .litFelt252 0
  else if lhs = .litFelt252 1 then rhs
  else if rhs = .litFelt252 1 then lhs
  else .mulFelt252 lhs rhs

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
  | other =>
      if thenBranch = elseBranch then
        thenBranch
      else
        .ite other thenBranch elseBranch

def optimizeExpr : IRExpr ty -> IRExpr ty
  | .var name => .var name
  | .storageRead name => .storageRead name
  | .litU128 value => .litU128 value
  | .litU256 value => .litU256 value
  | .litBool value => .litBool value
  | .litFelt252 value => .litFelt252 value
  | .litInt ty value => .litInt ty value
  | .addFelt252 lhs rhs => foldAddFelt252 (optimizeExpr lhs) (optimizeExpr rhs)
  | .subFelt252 lhs rhs => foldSubFelt252 (optimizeExpr lhs) (optimizeExpr rhs)
  | .mulFelt252 lhs rhs => foldMulFelt252 (optimizeExpr lhs) (optimizeExpr rhs)
  | .addInt ty lhs rhs => .addInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .subInt ty lhs rhs => .subInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .mulInt ty lhs rhs => .mulInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .divInt ty lhs rhs => .divInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .modInt ty lhs rhs => .modInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitAndInt ty lhs rhs => .bitAndInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitOrInt ty lhs rhs => .bitOrInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitXorInt ty lhs rhs => .bitXorInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .shlInt ty lhs shift => .shlInt ty (optimizeExpr lhs) shift
  | .shrInt ty lhs shift => .shrInt ty (optimizeExpr lhs) shift
  | .addU128 lhs rhs => foldAddU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .subU128 lhs rhs => foldSubU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .mulU128 lhs rhs => foldMulU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .divU128 lhs rhs => .divU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .modU128 lhs rhs => .modU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitAndU128 lhs rhs => .bitAndU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitOrU128 lhs rhs => .bitOrU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitXorU128 lhs rhs => .bitXorU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .shlU128 lhs shift => .shlU128 (optimizeExpr lhs) shift
  | .shrU128 lhs shift => .shrU128 (optimizeExpr lhs) shift
  | .addU256 lhs rhs => foldAddU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .subU256 lhs rhs => foldSubU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .mulU256 lhs rhs => foldMulU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .divU256 lhs rhs => .divU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .modU256 lhs rhs => .modU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitAndU256 lhs rhs => .bitAndU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitOrU256 lhs rhs => .bitOrU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .bitXorU256 lhs rhs => .bitXorU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .shlU256 lhs shift => .shlU256 (optimizeExpr lhs) shift
  | .shrU256 lhs shift => .shrU256 (optimizeExpr lhs) shift
  | .u256FromLimbs low high => .u256FromLimbs (optimizeExpr low) (optimizeExpr high)
  | .u256Low value => .u256Low (optimizeExpr value)
  | .u256High value => .u256High (optimizeExpr value)
  | .eq lhs rhs => .eq (optimizeExpr lhs) (optimizeExpr rhs)
  | .ltInt ty lhs rhs => .ltInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .leInt ty lhs rhs => .leInt ty (optimizeExpr lhs) (optimizeExpr rhs)
  | .ltU128 lhs rhs => .ltU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .leU128 lhs rhs => .leU128 (optimizeExpr lhs) (optimizeExpr rhs)
  | .ltU256 lhs rhs => .ltU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .leU256 lhs rhs => .leU256 (optimizeExpr lhs) (optimizeExpr rhs)
  | .ite cond thenBranch elseBranch =>
      foldIte (optimizeExpr cond) (optimizeExpr thenBranch) (optimizeExpr elseBranch)
  | .letE name boundTy bound body =>
      .letE name boundTy (optimizeExpr bound) (optimizeExpr body)

end LeanCairo.Compiler.Optimize
