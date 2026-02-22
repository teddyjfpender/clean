import LeanCairo.Core.Domain.Identifier
import LeanCairo.Core.Domain.IntLane
import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Compiler.IR

open LeanCairo.Core.Domain

inductive IRExpr : Ty -> Type where
  | var (name : Ident) : IRExpr ty
  | storageRead (name : Ident) : IRExpr ty
  | litU128 (value : Nat) : IRExpr .u128
  | litU256 (value : Nat) : IRExpr .u256
  | litBool (value : Bool) : IRExpr .bool
  | litFelt252 (value : Int) : IRExpr .felt252
  | litInt (ty : Ty) (value : Ty.denote ty) : IRExpr ty
  | addFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252
  | subFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252
  | mulFelt252 (lhs rhs : IRExpr .felt252) : IRExpr .felt252
  | addInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | subInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | mulInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | divInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | modInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | bitAndInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | bitOrInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | bitXorInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr ty
  | shlInt (ty : Ty) (lhs : IRExpr ty) (shift : Nat) : IRExpr ty
  | shrInt (ty : Ty) (lhs : IRExpr ty) (shift : Nat) : IRExpr ty
  | addU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | subU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | mulU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | divU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | modU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | bitAndU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | bitOrU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | bitXorU128 (lhs rhs : IRExpr .u128) : IRExpr .u128
  | shlU128 (lhs : IRExpr .u128) (shift : Nat) : IRExpr .u128
  | shrU128 (lhs : IRExpr .u128) (shift : Nat) : IRExpr .u128
  | addU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | subU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | mulU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | divU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | modU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | bitAndU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | bitOrU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | bitXorU256 (lhs rhs : IRExpr .u256) : IRExpr .u256
  | shlU256 (lhs : IRExpr .u256) (shift : Nat) : IRExpr .u256
  | shrU256 (lhs : IRExpr .u256) (shift : Nat) : IRExpr .u256
  | u256FromLimbs (low high : IRExpr .u128) : IRExpr .u256
  | u256Low (value : IRExpr .u256) : IRExpr .u128
  | u256High (value : IRExpr .u256) : IRExpr .u128
  | eq (lhs rhs : IRExpr ty) : IRExpr .bool
  | ltInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr .bool
  | leInt (ty : Ty) (lhs rhs : IRExpr ty) : IRExpr .bool
  | ltU128 (lhs rhs : IRExpr .u128) : IRExpr .bool
  | leU128 (lhs rhs : IRExpr .u128) : IRExpr .bool
  | ltU256 (lhs rhs : IRExpr .u256) : IRExpr .bool
  | leU256 (lhs rhs : IRExpr .u256) : IRExpr .bool
  | ite (cond : IRExpr .bool) (thenBranch elseBranch : IRExpr ty) : IRExpr ty
  | letE (name : Ident) (boundTy : Ty) (bound : IRExpr boundTy) (body : IRExpr bodyTy) : IRExpr bodyTy
  deriving Repr, DecidableEq

structure ResourceCarriers where
  rangeCheck : Nat := 0
  gas : Nat := 0
  segmentArena : Nat := 0
  panicChannel : Option String := none
  deriving Repr, DecidableEq, Inhabited

structure EffectExpr (ty : Ty) where
  expr : IRExpr ty
  resources : ResourceCarriers := {}
  deriving Repr, DecidableEq

end LeanCairo.Compiler.IR
