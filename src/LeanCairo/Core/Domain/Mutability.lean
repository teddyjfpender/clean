namespace LeanCairo.Core.Domain

inductive Mutability where
  | view
  | externalMutable
  deriving Repr, DecidableEq, BEq, Inhabited

namespace Mutability

def toInterfaceSelf : Mutability -> String
  | .view => "self: @TContractState"
  | .externalMutable => "ref self: TContractState"

def toImplSelf : Mutability -> String
  | .view => "self: @ContractState"
  | .externalMutable => "ref self: ContractState"

end Mutability
end LeanCairo.Core.Domain
