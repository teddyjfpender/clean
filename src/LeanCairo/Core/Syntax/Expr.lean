import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Domain.IntLane
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
  | litInt (ty : Ty) (value : Ty.denote ty) : Expr ty
  | addFelt252 (lhs rhs : Expr .felt252) : Expr .felt252
  | subFelt252 (lhs rhs : Expr .felt252) : Expr .felt252
  | mulFelt252 (lhs rhs : Expr .felt252) : Expr .felt252
  | addInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | subInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | mulInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | divInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | modInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | bitAndInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | bitOrInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | bitXorInt (ty : Ty) (lhs rhs : Expr ty) : Expr ty
  | shlInt (ty : Ty) (lhs : Expr ty) (shift : Nat) : Expr ty
  | shrInt (ty : Ty) (lhs : Expr ty) (shift : Nat) : Expr ty
  | addU128 (lhs rhs : Expr .u128) : Expr .u128
  | subU128 (lhs rhs : Expr .u128) : Expr .u128
  | mulU128 (lhs rhs : Expr .u128) : Expr .u128
  | divU128 (lhs rhs : Expr .u128) : Expr .u128
  | modU128 (lhs rhs : Expr .u128) : Expr .u128
  | bitAndU128 (lhs rhs : Expr .u128) : Expr .u128
  | bitOrU128 (lhs rhs : Expr .u128) : Expr .u128
  | bitXorU128 (lhs rhs : Expr .u128) : Expr .u128
  | shlU128 (lhs : Expr .u128) (shift : Nat) : Expr .u128
  | shrU128 (lhs : Expr .u128) (shift : Nat) : Expr .u128
  | addU256 (lhs rhs : Expr .u256) : Expr .u256
  | subU256 (lhs rhs : Expr .u256) : Expr .u256
  | mulU256 (lhs rhs : Expr .u256) : Expr .u256
  | divU256 (lhs rhs : Expr .u256) : Expr .u256
  | modU256 (lhs rhs : Expr .u256) : Expr .u256
  | bitAndU256 (lhs rhs : Expr .u256) : Expr .u256
  | bitOrU256 (lhs rhs : Expr .u256) : Expr .u256
  | bitXorU256 (lhs rhs : Expr .u256) : Expr .u256
  | shlU256 (lhs : Expr .u256) (shift : Nat) : Expr .u256
  | shrU256 (lhs : Expr .u256) (shift : Nat) : Expr .u256
  | u256FromLimbs (low high : Expr .u128) : Expr .u256
  | u256Low (value : Expr .u256) : Expr .u128
  | u256High (value : Expr .u256) : Expr .u128
  | eq (lhs rhs : Expr ty) : Expr .bool
  | ltInt (ty : Ty) (lhs rhs : Expr ty) : Expr .bool
  | leInt (ty : Ty) (lhs rhs : Expr ty) : Expr .bool
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
