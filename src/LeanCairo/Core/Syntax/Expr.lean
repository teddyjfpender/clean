import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Core.Syntax

open LeanCairo.Core.Domain

inductive Expr : Ty -> Type where
  | var (name : Ident) : Expr ty
  | storageRead (name : Ident) : Expr ty
  | litU128 (value : Nat) : Expr .u128
  | litU256 (value : Nat) : Expr .u256
  | litBool (value : Bool) : Expr .bool
  | litFelt252 (value : Int) : Expr .felt252
  | addFelt252 (lhs rhs : Expr .felt252) : Expr .felt252
  | subFelt252 (lhs rhs : Expr .felt252) : Expr .felt252
  | mulFelt252 (lhs rhs : Expr .felt252) : Expr .felt252
  | addU128 (lhs rhs : Expr .u128) : Expr .u128
  | subU128 (lhs rhs : Expr .u128) : Expr .u128
  | mulU128 (lhs rhs : Expr .u128) : Expr .u128
  | addU256 (lhs rhs : Expr .u256) : Expr .u256
  | subU256 (lhs rhs : Expr .u256) : Expr .u256
  | mulU256 (lhs rhs : Expr .u256) : Expr .u256
  | eq (lhs rhs : Expr ty) : Expr .bool
  | ltU128 (lhs rhs : Expr .u128) : Expr .bool
  | leU128 (lhs rhs : Expr .u128) : Expr .bool
  | ltU256 (lhs rhs : Expr .u256) : Expr .bool
  | leU256 (lhs rhs : Expr .u256) : Expr .bool
  | ite (cond : Expr .bool) (thenBranch elseBranch : Expr ty) : Expr ty
  | letE (name : Ident) (boundTy : Ty) (bound : Expr boundTy) (body : Expr bodyTy) : Expr bodyTy
  deriving Repr

namespace Expr

def tyOf {ty : Ty} (_ : Expr ty) : Ty := ty

end Expr
end LeanCairo.Core.Syntax
