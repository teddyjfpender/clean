import LeanCairo.Core.Domain.Ty

namespace LeanCairo.Backend.Sierra.Generated

open LeanCairo.Core.Domain

def sierraImplementedCapabilityIds : List String :=
[
  "cap.integer.u128.add.wrapping",
  "cap.integer.u128.mul.wrapping",
  "cap.integer.u128.sub.wrapping",
  "cap.scalar.bool.literal",
  "cap.scalar.felt252.add",
  "cap.scalar.felt252.mul",
  "cap.scalar.felt252.sub",
]

def sierraFailFastCapabilityIds : List String :=
[
  "cap.integer.family.non_u128",
]

def sierraSupportedSignatureTys : List Ty :=
[
  .bool,
  .felt252,
  .u128,
]

def isSierraCapabilityImplemented (capabilityId : String) : Bool :=
  sierraImplementedCapabilityIds.contains capabilityId

def isSierraSignatureTySupported (ty : Ty) : Bool :=
  sierraSupportedSignatureTys.contains ty

end LeanCairo.Backend.Sierra.Generated
