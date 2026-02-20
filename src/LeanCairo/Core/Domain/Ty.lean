namespace LeanCairo.Core.Domain

inductive Ty where
  | felt252
  | u128
  | u256
  | bool
  deriving Repr, DecidableEq, BEq, Inhabited

namespace Ty

def toCairo : Ty -> String
  | .felt252 => "felt252"
  | .u128 => "u128"
  | .u256 => "u256"
  | .bool => "bool"

def toAbiCanonical : Ty -> String
  | .felt252 => "core::felt252"
  | .u128 => "core::integer::u128"
  | .u256 => "core::integer::u256"
  | .bool => "core::bool"

end Ty
end LeanCairo.Core.Domain
